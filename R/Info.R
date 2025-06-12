#' Rlibhv Package Information
#'
#' Returns information about the Rlibhv package including the libhv version
#' and other dependencies.
#'
#' @return A list containing version information for libhv and its dependencies
#' @export
#'
#' @examples
#' LibhvInfo()
LibhvInfo <- function() {
    result <- list(
        LibhvVersion = LibhvVersion(),
        LibhvCompileVersion = LibhvCompileVersion(),
        LibhvVersionNumber = LibhvVersionNumber(),
        Package = utils::packageVersion("Rlibhv")
    )

    class(result) <- "libhv_info"
    return(result)
}

#' @export
print.libhv_info <- function(x, ...) {
    cat("Rlibhv Package Information:", "\n")
    cat("---------------------------", "\n")
    cat("Package version:     ", as.character(x$Package), "\n")
    cat("libhv version:       ", x$LibhvVersion, "\n")
    cat("libhv compile ver.:  ", x$LibhvCompileVersion, "\n")
    cat("libhv version num.:  ", x$LibhvVersionNumber, " (hex: ",
        sprintf("0x%06x", x$LibhvVersionNumber), ")\n",
        sep = ""
    )

    invisible(x)
}
