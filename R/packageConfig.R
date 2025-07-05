#' Package CFLAGS for compilation
#' @return A string containing the CFLAGS for compiling with libhv and its dependencies
#' @export
#' @examples
#' \dontrun{
#' # Get the CFLAGS for compiling with libhv
#' packageCflags()
#' }
packageCflags <- function() {
    paste0(
        "-I", system.file("include/hv", package = "Rlibhv"), " ",
        "-I", system.file("include/ev", package = "Rlibhv"), " ",
        "-I", system.file("include/cares", package = "Rlibhv"), " ",
        "-I", system.file("include/nghttp2", package = "Rlibhv")
    )
}

#' Package libraries for linking
#' @return A string containing the libraries to link against
#' @export
#' @examples
#' \dontrun{
#' # Get the libraries for linking with libhv
#' packageLibs()
#' }
packageLibs <- function() {
    paste0(
        "-L", system.file("libs", package = "Rlibhv"), " ",
        "-lhv -lev -lcares -lnghttp2"
    )
}
