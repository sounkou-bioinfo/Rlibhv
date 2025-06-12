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
```

## Example usage (from the bundled binary examples)

### TCP Echo Server

```r
# Start a TCP echo server on port 8080
Rlibhv::TcpEchoServer(8080)
    
# In another R session or terminal:
# echo "Hello, world!" | nc localhost 8080
```

## How it works ?

## Dependencies

This package includes bundled  versions (for linux) of:

- [libhv](https://github.com/ithewei/libhv)
- [libev](http://software.schmorp.de/pkg/libev.html)
- [c-ares](https://c-ares.org/)
- [nghttp2](https://nghttp2.org/)

## Licence

This package is licensed under the MIT License. See the [LICENSE](LICENSE). Bundled libraries are licensed under their respective licenses.
