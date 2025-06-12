#' Start a TCP Echo Server
#'
#' This function starts a TCP Echo server using the libhv library.
#' The server will echo back any data sent to it by clients.
#'
#' @param port Integer. The port number to listen on (1-65535)
#' @return NULL invisibly, called for its side effect of running the server
#' @export
#'
#' @examples
#' \dontrun{
#' # Start an echo server on port 8080
#' TcpEchoServer(8080)
#' }
TcpEchoServer <- function(port) {
    if (!is.numeric(port) || length(port) != 1 || port < 1 || port > 65535) {
        stop("'port' must be a single integer between 1 and 65535")
    }

    port <- as.integer(port)

    message("Starting TCP echo server on port ", port)
    message("Press Ctrl+C to stop the server")

    # Use .Call with native symbol object
    .Call(R_tcp_echo_server, port)

    invisible(NULL)
}
