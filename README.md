# Rlibhv

[libhv](https://github.com/ithewei/libhv) static library for R package use.

## Overview

Rlibhv provides libhv static library for package usage. [libhv](https://github.com/ithewei/libhv) is a C/C++ networking library. It offers high-performance event-driven networking capabilities including HTTP1/2 client/server, WebSocket, TCP/UDP servers, and more.

## Installation

```r
# Install from GitHub
# devtools::install_github("sounkou-bioinfo/Rlibhv")
```

## Usage

```r
# Get package version 
Rlibhv::LibhvInfo()

# For detailed examples of the new TCP and HTTP/Rook server interfaces,
# please see the example script located in the package installation directory:
# system.file("examples", "rook_example.R", package = "Rlibhv")
# You can run it via: source(system.file("examples", "rook_example.R", package = "Rlibhv"))
```

## New Server Interfaces (v1.3.3+)

Starting from version 1.3.3, `Rlibhv` provides R6 classes for more flexible TCP and HTTP server implementation, including a Rook-compatible HTTP server.

### Basic Rook HTTP Server Example

```r
if (requireNamespace("Rlibhv", quietly = TRUE)) {
  # 1. Define a Rook application
  my_rook_app <- function(env) {
    list(
      status = 200L,
      headers = list('Content-Type' = 'text/plain'),
      body = paste("Hello from Rlibhv Rook App! Path:", env$PATH_INFO)
    )
  }

  # 2. Create and configure HTTP Service and Server
  http_service <- Rlibhv::LibhvHttpService$new()
  http_service$set_rook_handler(my_rook_app)

  http_server <- Rlibhv::LibhvHttpServer$new(
    service = http_service,
    port = 8088
  )

  # 3. Start the server (non-blocking)
  http_server$start()
  message("HTTP server running on http://127.0.0.1:8088")
  message("Access /test path: curl http://127.0.0.1:8088/test")

  # To stop later: http_server$stop()
}
```

### Basic TCP Server Example

```r
if (requireNamespace("Rlibhv", quietly = TRUE)) {
  # 1. Create TCP Server
  tcp_server <- Rlibhv::LibhvTcpServer$new(port = 12345)

  # 2. Set callbacks (optional, default callbacks log to console)
  tcp_server$on_connection(function(peeraddr, is_connected, fd, id) {
    if (is_connected) {
      message(paste("Client", id, "connected from", peeraddr))
      tcp_server$write(fd, paste0("Welcome client ", id, "\n"))
    } else {
      message(paste("Client", id, "disconnected"))
    }
  })

  tcp_server$on_message(function(channel_id, raw_data) {
    msg <- rawToChar(raw_data)
    message(paste("Message from client", channel_id, ":", trimws(msg)))
    tcp_server$write(channel_id, paste0("Server echoes: ", msg))
  })

  # 3. Start the server (non-blocking)
  tcp_server$start()
  message("TCP server running on port 12345. Connect with 'nc 127.0.0.1 12345'")

  # To stop later: tcp_server$stop()
}
```

For more detailed examples, including how to handle POST requests with the Rook server and more, please refer to the script available via `system.file("examples", "rook_example.R", package = "Rlibhv")`.

You can also adjust the C++ library's logging level:
```r
# Rlibhv::set_libhv_log_level("DEBUG") # For verbose output
# Rlibhv::set_libhv_log_level("INFO")  # Default-like
```

## Original Example usage (from bundled binary examples)

### TCP Echo Server

This function is part of the older interface.
```r
# Start a TCP echo server on port 8080
# Rlibhv::TcpEchoServer(8080)
# Note: This function might be superseded or conflict with the new R6 interface if run concurrently.
    
# In another R session or terminal:
# echo "Hello, world!" | nc localhost 8080
```

## How it works?
The package compiles `libhv` and its dependencies (libev, c-ares, nghttp2) as static libraries.
Rcpp modules then expose `libhv`'s C++ server classes (TcpServer, HttpServer, HttpService) to R.
R6 classes in R provide a more user-friendly interface to these Rcpp objects.

## Dependencies

This package includes bundled  versions (for linux) of:

- [libhv](https://github.com/ithewei/libhv)
- [libev](http://software.schmorp.de/pkg/libev.html)
- [c-ares](https://c-ares.org/)
- [nghttp2](https://nghttp2.org/)

## Licence

This package is licensed under the MIT License. See the [LICENSE](LICENSE). Bundled libraries are licensed under their respective licenses.

## Testing

This package uses `tinytest` for unit testing. If you have cloned the source repository, you can run tests from within R using:

```r
# Ensure tinytest is installed: install.packages("tinytest")
if (requireNamespace("tinytest", quietly = TRUE)) {
  tinytest::test_package("Rlibhv")
}
```
During `R CMD check`, tests in `inst/tinytest/` will be run automatically.
