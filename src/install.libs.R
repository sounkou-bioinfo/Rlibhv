# Copy libhv headers and libraries to the package installation directory

# Copy header files
files <- Sys.glob(paste0("../inst/include/hv/*"))
if (length(files) > 0) {
    inst_include_dir <- file.path(R_PACKAGE_DIR, "include", "hv")
    dir.create(inst_include_dir, recursive = TRUE, showWarnings = FALSE)
    file.copy(files, inst_include_dir, recursive = TRUE)
}
# Copy cares headers
files <- Sys.glob(paste0("../inst/cares/include/*"))
if (length(files) > 0) {
    inst_include_dir <- file.path(R_PACKAGE_DIR, "include", "cares")
    dir.create(inst_include_dir, recursive = TRUE, showWarnings = FALSE)
    file.copy(files, inst_include_dir, recursive = TRUE)
}
# copy cares library files
files <- Sys.glob(paste0("../inst/cares/lib/*"))
if (length(files) > 0) {
    inst_lib_dir <- file.path(R_PACKAGE_DIR, "libs", R_ARCH)
    dir.create(inst_lib_dir, recursive = TRUE, showWarnings = FALSE)
    file.copy(files, inst_lib_dir, recursive = TRUE)
}
# remove reminder cares directory
unlink("../inst/cares/", recursive = TRUE, force = TRUE)
# copy ev headers
files <- Sys.glob(paste0("../inst/ev/include/*"))
if (length(files) > 0) {
    inst_include_dir <- file.path(R_PACKAGE_DIR, "include", "ev")
    dir.create(inst_include_dir, recursive = TRUE, showWarnings = FALSE)
    file.copy(files, inst_include_dir, recursive = TRUE)
}
# copy ev library files
files <- Sys.glob(paste0("../inst/ev/lib/*"))
if (length(files) > 0) {
    inst_lib_dir <- file.path(R_PACKAGE_DIR, "libs", R_ARCH)
    dir.create(inst_lib_dir, recursive = TRUE, showWarnings = FALSE)
    file.copy(files, inst_lib_dir, recursive = TRUE)
}
# remove reminder ev directory files
unlink("../inst/ev/", recursive = TRUE, force = TRUE)
# Copy library files
files <- Sys.glob(paste0("../inst/lib/*"))
if (length(files) > 0) {
    inst_lib_dir <- file.path(R_PACKAGE_DIR, "libs", R_ARCH)
    dir.create(inst_lib_dir, recursive = TRUE, showWarnings = FALSE)
    file.copy(files, inst_lib_dir, recursive = TRUE)
}

# Copy libhv binary tools to inst/bin
bin_files <- Sys.glob("libhv/bin/*")
if (length(bin_files) > 0) {
    inst_bin_dir <- file.path(R_PACKAGE_DIR, "bin")
    dir.create(inst_bin_dir, recursive = TRUE, showWarnings = FALSE)
    file.copy(bin_files, inst_bin_dir, overwrite = TRUE)

    # Make the binary files executable
    if (.Platform$OS.type == "unix") {
        bin_dest_files <- file.path(inst_bin_dir, basename(bin_files))
        Sys.chmod(bin_dest_files, mode = "0755")
    }
}

# Copy the package shared library to the package libs directory
so_files <- Sys.glob(paste0("*", .Platform$dynlib.ext))
if (length(so_files) > 0) {
    inst_libs_dir <- file.path(R_PACKAGE_DIR, "libs", R_ARCH)
    dir.create(inst_libs_dir, recursive = TRUE, showWarnings = FALSE)
    file.copy(so_files, inst_libs_dir, overwrite = TRUE)
}
# remoe the dangling lib dir

if (dir.exists("../inst/lib")) {
    unlink("../inst/lib", recursive = TRUE, force = TRUE)
}
