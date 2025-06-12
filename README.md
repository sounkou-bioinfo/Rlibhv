# Rlibhv

R bindings to `libhv` - a high-performance cross-platform network library

## Overview

Rlibhv provides R bindings to the libhv C/C++ networking library. It offers high-performance event-driven networking capabilities including HTTP1/2 client/server, WebSocket, TCP/UDP servers, and more.

## Installation

```r
# Install from GitHub
# devtools::install_github("username/Rlibhv")
```

## Get The library version

- Version information: `LibhvVersion()`, `LibhvCompileVersion()`, `LibhvVersionNumber()`
- TCP Echo Server: `TcpEchoServer(port)`
- Package information: `LibhvInfo()`

## Examples

### Version Information

```r

# Show all libhv information
Rlibhv::LibhvInfo()


# Get libhv version
Rlibhv::LibhvVersion()
```

### TCP Echo Server

```r
# Start a TCP echo server on port 8080
Rlibhv::TcpEchoServer(8080)

# In another R session or terminal:
# echo "Hello, world!" | nc localhost 8080
```

## Dependencies

This package includes bundled versions of:

- libhv
- libev
- c-ares
- nghttp2
