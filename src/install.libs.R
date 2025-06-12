# Installation script for Rlibhv package
# This script handles the copying of headers and libraries from the build directories
# to the appropriate locations in the R package installation directory.

#' Helper function to copy files from source to destination
#'
#' @param srcPattern Source file pattern for Sys.glob
#' @param destDir Destination directory
#' @param destSubdir Optional subdirectory to create within destDir
#' @param recursive Whether to copy recursively
#' @return Invisible NULL
CopyFiles <- function(srcPattern, destDir, destSubdir = NULL, recursive = TRUE) {
    files <- Sys.glob(srcPattern)
    if (length(files) > 0) {
        if (!is.null(destSubdir)) {
            fullDestDir <- file.path(destDir, destSubdir)
        } else {
            fullDestDir <- destDir
        }

        dir.create(fullDestDir, recursive = TRUE, showWarnings = FALSE)
        file.copy(files, fullDestDir, recursive = recursive)
    }
    invisible(NULL)
}

#' Helper function to copy files and then clean up source directory
#'
#' @param baseDir Base directory
#' @param component Component name (e.g., "cares", "ev")
#' @param destIncludeDir Destination include directory
#' @param destLibDir Destination library directory
#' @return Invisible NULL
CopyAndCleanup <- function(baseDir, component, destIncludeDir, destLibDir) {
    # Copy include files
    srcInclude <- file.path(baseDir, component, "include", "*")
    CopyFiles(srcInclude, destIncludeDir, component)

    # Copy lib files
    srcLib <- file.path(baseDir, component, "lib", "*")
    CopyFiles(srcLib, destLibDir)

    # Clean up source directory
    componentDir <- file.path(baseDir, component)
    unlink(componentDir, recursive = TRUE, force = TRUE)

    invisible(NULL)
}

# ===== Main Installation Process =====

message("Installing Rlibhv components...")

# Define paths
baseDir <- "../inst"
includeDir <- file.path(R_PACKAGE_DIR, "include")
libDir <- file.path(R_PACKAGE_DIR, "libs", R_ARCH)

# 1. Copy libhv main headers
message("1. Copying libhv headers...")
CopyFiles(file.path(baseDir, "include/hv/*"), includeDir, "hv")

# 2. Process c-ares component
message("2. Processing c-ares component...")
CopyAndCleanup(baseDir, "cares", includeDir, libDir)

# 3. Process libev component
message("3. Processing libev component...")
CopyAndCleanup(baseDir, "ev", includeDir, libDir)

# 4. Copy remaining libraries
message("4. Copying additional libraries...")
CopyFiles(file.path(baseDir, "lib/*"), libDir)

# 5. Copy binary tools if they exist
message("5. Copying binary tools...")
binFiles <- Sys.glob("libhv/bin/*")
if (length(binFiles) > 0) {
    instBinDir <- file.path(R_PACKAGE_DIR, "bin")
    dir.create(instBinDir, recursive = TRUE, showWarnings = FALSE)
    file.copy(binFiles, instBinDir, overwrite = TRUE)

    # Make binary files executable on Unix-like systems
    if (.Platform$OS.type == "unix") {
        binDestFiles <- file.path(instBinDir, basename(binFiles))
        Sys.chmod(binDestFiles, mode = "0755")
        message("   Made binary files executable")
    }
}

# 6. Copy the package shared library
message("6. Copying package shared libraries...")
soFiles <- Sys.glob(paste0("*", .Platform$dynlib.ext))
if (length(soFiles) > 0) {
    dir.create(libDir, recursive = TRUE, showWarnings = FALSE)
    file.copy(soFiles, libDir, overwrite = TRUE)
    message(sprintf("   Copied %d shared libraries", length(soFiles)))
} else {
    warning("No shared libraries found to copy")
}

# 7. Final cleanup
message("7. Performing final cleanup...")
if (dir.exists("../inst/lib")) {
    unlink("../inst/lib", recursive = TRUE, force = TRUE)
    message("   Removed temporary lib directory")
}

message("Installation completed successfully!")
