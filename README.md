# Rlibhv

[libhv](https://github.com/ithewei/libhv) static library for R package use.

## Overview

Rlibhv provides libhv static library for package usage. [libhv](https://github.com/ithewei/libhv) is a C/C++ networking library. It offers high-performance event-driven networking capabilities including HTTP1/2 client/server, WebSocket, TCP/UDP servers, and more.

## Installation

```r
# Install the development version from GitHub
# devtools::install_github("sounkou-bioinfo/Rlibhv@develop")
```

## Usage

```r
# Get package version 
Rlibhv::LibhvInfo()
```

## Example usage (adapted from the bundled binary examples' C/C++ code)

### TCP Echo Server

```r
# Start a TCP echo server on port 8080
Rlibhv::TcpEchoServer(8080)
# In another R session or terminal:
# echo "Hello, world!" | nc localhost 8080
```

## What's in the box ?

We build libhv static library and provide the headers in the installed directory of this package.
Package users can then link against the static library and use the headers to build their own R packages that depend on libhv.
For linux, libev, c-ares, nghttp2 headers are also provided. 

To use the provided library in your package, use the Linking to machanism or get the flags direcly using `Rlibhv::packageCflags()` and `Rlibhv::packageLibs()`

## Dependencies

This package includes bundled  versions (for linux) of the following libraries:

- [libhv](https://github.com/ithewei/libhv)
- [libev](http://software.schmorp.de/pkg/libev.html)
- [c-ares](https://c-ares.org/)
- [nghttp2](https://nghttp2.org/)

## Issues

- No windows support and no plans to add it
- The configure script for macOS is brittle and ssl will likely not be supported

## Licence

This package is licensed under the MIT License. See the [LICENSE](LICENSE). Bundled libraries are licensed under their respective licenses.
