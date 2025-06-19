# tinytest test suite for Rlibhv server functionalities

# --- Setup ---
# Ensure the package is loaded. In a `R CMD check` or `tinytest::test_package()` context,
# the package namespace is typically available.
# If running interactively, use `devtools::load_all()` or `library(Rlibhv)`.

# Helper to skip tests if Rcpp module not properly loaded
# This is less of a 'skip' in tinytest and more of a conditional execution.
# We can return early from a test block or use if() around test sections.
module_loaded_check <- function() {
  ptr <- try(silent = TRUE, {
    .Call(paste0("C_new_", "HttpService"))
  })
  if (inherits(ptr, "try-error") || is.null(ptr)) {
    message("Rlibhv: Rcpp module 'libhv_servers' not loaded or basic object creation failed. Some tests may not run.")
    return(FALSE)
  }
  return(TRUE)
}

module_is_loaded <- module_loaded_check()

# --- Test Cases ---

# Group: LibhvHttpService
if (module_is_loaded) {
  service <- NULL
  expect_silent(service <- Rlibhv::LibhvHttpService$new())
  expect_true(inherits(service, "LibhvHttpService"), info = "LibhvHttpService object creation")

  dummy_rook_app <- function(env) {
    list(status = 200L, headers = list('Content-Type' = 'text/plain'), body = "test")
  }
  expect_silent(service$set_rook_handler(dummy_rook_app), info = "Setting Rook handler on HttpService")
}

# Group: LibhvHttpServer
if (module_is_loaded) {
  service <- Rlibhv::LibhvHttpService$new()
  dummy_rook_app <- function(env) {
    list(status = 200L, headers = list('Content-Type' = 'text/plain'), body = "test")
  }
  service$set_rook_handler(dummy_rook_app)

  http_server <- NULL
  test_port <- 18081

  expect_silent(
    http_server <- Rlibhv::LibhvHttpServer$new(service = service, port = test_port, threads = 1),
    info = "LibhvHttpServer object creation with service"
  )
  expect_true(inherits(http_server, "LibhvHttpServer"), info = "LibhvHttpServer class check")

  expect_equal(http_server$port, test_port, info = "HttpServer port getter/setter")

  # Test start and stop
  expect_silent(http_server$start(), info = "HttpServer start")
  Sys.sleep(0.1)
  expect_silent(http_server$stop(), info = "HttpServer stop")
  Sys.sleep(0.1)

  http_server_no_service <- Rlibhv::LibhvHttpServer$new(port = test_port + 1)
  expect_error(
    http_server_no_service$start(),
    pattern = "HTTP service not set",
    info = "HttpServer start without service should error"
  )
}

# Group: LibhvTcpServer
if (module_is_loaded) {
  tcp_server <- NULL
  test_tcp_port <- 12346

  expect_silent(
    tcp_server <- Rlibhv::LibhvTcpServer$new(port = test_tcp_port, threads = 1),
    info = "LibhvTcpServer object creation"
  )
  expect_true(inherits(tcp_server, "LibhvTcpServer"), info = "LibhvTcpServer class check")

  # Test setting callbacks
  conn_cb_called_flag <- FALSE # Use a different name to avoid potential scope issues if tests run in same env
  msg_cb_called_flag <- FALSE

  expect_silent(
    tcp_server$on_connection(function(peeraddr, is_connected, fd, id) {
      conn_cb_called_flag <<- TRUE
    }),
    info = "Setting TCP on_connection callback"
  )

  expect_silent(
    tcp_server$on_message(function(channel_id, raw_data) {
      msg_cb_called_flag <<- TRUE
    }),
    info = "Setting TCP on_message callback"
  )

  # Test start and stop
  expect_silent(tcp_server$start(), info = "TcpServer start")
  Sys.sleep(0.1)
  expect_silent(tcp_server$stop(), info = "TcpServer stop")
  Sys.sleep(0.1)

  expect_false(conn_cb_called_flag, info = "TCP on_connection callback should not have fired without connection")
  expect_false(msg_cb_called_flag, info = "TCP on_message callback should not have fired without message")
}

# Group: Logging
if (module_is_loaded) {
  expect_silent(Rlibhv::set_libhv_log_level("INFO"), info = "set_libhv_log_level with 'INFO'")
  expect_silent(Rlibhv::set_libhv_log_level(2), info = "set_libhv_log_level with 2 (INFO)")

  expect_error(
    Rlibhv::set_libhv_log_level("INVALID_LEVEL_STRING"),
    info = "set_libhv_log_level with invalid string"
  )

  # Reset to a sensible default
  expect_silent(Rlibhv::set_libhv_log_level("WARN"), info = "Reset log_level to WARN")
}

# --- Notes on more comprehensive tests (similar to testthat version) ---
# These would require actual network connections and are more like integration tests.
# They can be added here or in a separate file (e.g., test_integration.R).

# Example structure for a live HTTP test with tinytest:
# if (module_is_loaded && requireNamespace("httr", quietly = TRUE)) {
#   # Test: HTTP server responds to basic GET request
#   service <- Rlibhv::LibhvHttpService$new()
#   test_body_content <- paste("Test OK:", Sys.time())
#   simple_app <- function(env) {
#     list(status = 200L, headers = list('Content-Type' = 'text/plain'), body = test_body_content)
#   }
#   service$set_rook_handler(simple_app)
#
#   test_port_http_live <- 18082
#   http_server_live <- Rlibhv::LibhvHttpServer$new(service = service, port = test_port_http_live, threads = 1)
#
#   expect_silent(http_server_live$start())
#   Sys.sleep(0.2)
#
#   response <- NULL
#   response_error <- FALSE
#   tryCatch({
#     response <- httr::GET(paste0("http://127.0.0.1:", test_port_http_live, "/testpath"))
#   }, error = function(e) response_error <<- TRUE)
#
#   expect_false(response_error, info = "httr::GET should not error")
#   expect_false(is.null(response), info = "httr::GET response should not be NULL")
#
#   if (!is.null(response)) {
#     expect_equal(httr::status_code(response), 200L, info = "Live HTTP GET status code")
#     expect_equal(httr::content(response, "text", encoding = "UTF-8"), test_body_content, info = "Live HTTP GET body content")
#     expect_equal(response$headers$`content-type`, "text/plain", info = "Live HTTP GET content-type header")
#   }
#
#   expect_silent(http_server_live$stop())
#   Sys.sleep(0.1)
# }

# Example structure for a live TCP test with tinytest:
# if (module_is_loaded) {
#   # Test: TCP server echoes messages
#   test_tcp_port_live <- 12347
#   tcp_server_live <- Rlibhv::LibhvTcpServer$new(port = test_tcp_port_live)
#
#   # Basic echo handler
#   tcp_server_live$on_message(function(channel_id, raw_data) {
#     tcp_server_live$write(channel_id, raw_data) # Echo back
#   })
#
#   expect_silent(tcp_server_live$start())
#   Sys.sleep(0.2)
#
#   conn <- NULL
#   response_str <- ""
#   conn_error <- FALSE
#   test_msg <- "Hello TCP from tinytest"
#
#   tryCatch({
#     conn <- socketConnection(host = "127.0.0.1", port = test_tcp_port_live, open = "rwb", timeout = 2)
#     Sys.sleep(0.1)
#     if (isOpen(conn)) {
#        writeLines(test_msg, conn)
#        response_str <- readLines(conn, n = 1, warn = FALSE)
#     } else {
#        conn_error <- TRUE # Failed to open connection
#     }
#   }, error = function(e) {
#     conn_error <<- TRUE
#     message("Live TCP test connection/communication error: ", e$message)
#   }, finally = {
#     if (!is.null(conn) && isOpen(conn)) close(conn)
#   })
#
#   expect_silent(tcp_server_live$stop())
#   Sys.sleep(0.1)
#
#   expect_false(conn_error, info = "Live TCP connection should not error")
#   expect_equal(response_str, test_msg, info = "Live TCP echo response")
# }

# Final message for test file
message("Rlibhv tinytest suite (test_servers.R) finished.")
NULL # Ensure the file evaluates to something non-error if last line is a comment/message.
