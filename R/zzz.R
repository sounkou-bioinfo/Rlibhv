#' @useDynLib Rlibhv, .registration = TRUE
NULL

#' Get the libhv Version
#'
#' Returns the version string of the libhv library
#'
#' @return A character string with the version of libhv
#' @export
LibhvVersion <- function() {
    .Call(RC_libhv_version)
}

#' Get the libhv Compile Version
#'
#' Returns the compile-time version string of the libhv library
#'
#' @return A character string with the compile-time version of libhv
#' @export
LibhvCompileVersion <- function() {
    .Call(RC_libhv_compile_version)
}

#' Get the libhv Version Number
#'
#' Returns the version number of the libhv library as an integer
#'
#' @return An integer representing the version number of libhv
#' @export
LibhvVersionNumber <- function() {
    .Call(RC_libhv_version_number)
}
