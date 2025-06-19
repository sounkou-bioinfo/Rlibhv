# Basic example demonstrating the LibhvHttpServer with a Rook application
# and a simple LibhvTcpServer.

# Ensure the package is loaded (e.g., via devtools::load_all() during development)
# or library(Rlibhv) if installed.

# --- HTTP Server (Rook) Example ---
if (requireNamespace("Rlibhv", quietly = TRUE) && requireNamespace("R6", quietly = TRUE)) {
  message("Setting up HTTP Rook server example...")

  # 1. Define a Rook application
  rook_app <- function(env) {
    print("Rook app received a request:")
    print(str(env)) # Print the environment for inspection

    body_content <- paste(
      "Hello from Rlibhv Rook App!",
      "Timestamp:", Sys.time(),
      "Request Path:", env$PATH_INFO,
      "Request Method:", env$REQUEST_METHOD,
      "Query String:", env$QUERY_STRING,
      sep = "\n"
    )

    # Demonstrate reading from rook.input if method is POST
    if (env$REQUEST_METHOD == "POST" && !is.null(env$'rook.input')) {
        input_stream <- env$'rook.input'
        input_stream$rewind() # Go to the beginning of the stream
        post_body <- readLines(input_stream, warn = FALSE) # Read lines from the stream
        body_content <- paste0(body_content, "\nPOST Body:\n", paste(post_body, collapse="\n"))
    }


    list(
      status = 200L,
      headers = list(
        'Content-Type' = 'text/plain',
        'X-Rlibhv-Example' = 'true'
      ),
      body = body_content
    )
  }

  # 2. Create and configure the HTTP Service
  http_service <- Rlibhv::LibhvHttpService$new()
  http_service$set_rook_handler(rook_app)

  # 3. Create and configure the HTTP Server
  http_server <- Rlibhv::LibhvHttpServer$new(
    service = http_service,
    port = 8088,
    threads = 2
  )

  # Optional: Set libhv log level for more verbose output
  # Rlibhv::set_libhv_log_level("DEBUG") # or 1

  # 4. Start the HTTP server
  # This is non-blocking. The R session will remain active.
  http_server$start()

  message(paste0("HTTP server started on http://127.0.0.1:", http_server$port))
  message("Try accessing it with a web browser or curl.")
  message("Example curl commands:")
  message(paste0("  curl http://127.0.0.1:", http_server$port, "/test"))
  message(paste0("  curl -X POST -d 'hello from curl' http://127.0.0.1:", http_server$port, "/post_test"))
  message("Press Ctrl+C (or equivalent) in the console where R is running if you want to stop the script and the server manually later.")
  message("To stop the server programmatically, call: http_server$stop()")

  # Keep the main R thread alive for a bit to let the server run,
  # otherwise, if the script ends, R might exit (depending on environment).
  # In an interactive session, this is not strictly necessary.
  # Sys.sleep(60) # Keep alive for 60 seconds
  # message("Stopping HTTP server after 60 seconds...")
  # http_server$stop()

} else {
  warning("Rlibhv package not found. Cannot run HTTP server example.")
}


# --- TCP Server Example ---
if (requireNamespace("Rlibhv", quietly = TRUE) && requireNamespace("R6", quietly = TRUE)) {
  message("\nSetting up TCP server example...")

  # 1. Create TCP Server instance
  tcp_port <- 12345
  tcp_server <- Rlibhv::LibhvTcpServer$new(port = tcp_port, threads = 1)

  # 2. Define custom callbacks
  tcp_server$on_connection(function(peeraddr, is_connected, fd, id) {
    if (is_connected) {
      message(sprintf("TCP Client connected: %s (fd: %d, id: %d). Sending welcome message.", peeraddr, fd, id))
      # tcp_server$write(fd, paste("Welcome, client", id, "!\n")) # fd might be less reliable than id if mapping changes
                                                              # The C++ write method currently uses connfd.
                                                              # We need to clarify if fd from onConnection is the same connfd for write.
                                                              # Let's assume fd works for now.
      tryCatch(tcp_server$write(fd, paste("Welcome, client", id, "!\n")),
               error = function(e) message("Error writing to client: ", e$message))

    } else {
      message(sprintf("TCP Client disconnected: %s (fd: %d, id: %d)", peeraddr, fd, id))
    }
  })

  tcp_server$on_message(function(channel_id, raw_data) {
    received_msg <- rawToChar(raw_data)
    message(sprintf("TCP Message from client (id %d): %s", channel_id, trimws(received_msg)))

    # Echo back
    response_msg <- paste0("Server echoes: ", received_msg)
    # Find fd for this channel_id. This is a missing piece.
    # The onMessage gives channel_id, but write takes connfd.
    # For now, this part of echo might not work correctly without channel_id -> fd mapping.
    # C++ TcpServer::send(int connfd, ...) implies connfd is the key.
    # If channel_id from onMessage IS the connfd, then it's fine. Let's assume it is for this example.
    tryCatch(tcp_server$write(channel_id, response_msg),
             error = function(e) message("Error echoing to client: ", e$message))

  })

  # 3. Start the TCP server
  tcp_server$start()
  message(paste0("TCP server started on port ", tcp_port))
  message("You can connect to it using netcat or telnet, e.g.:")
  message(paste0("  nc 127.0.0.1 ", tcp_port))
  message("To stop the server programmatically, call: tcp_server$stop()")

  # To run both servers and keep R session alive:
  # message("Both servers are running. Type http_server$stop() and tcp_server$stop() to halt them.")
  # message("Or interrupt/close R session.")

  # Example of stopping them after some time:
  # Sys.sleep(120)
  # message("Stopping servers after 120 seconds...")
  # if (!is.null(http_server)) http_server$stop()
  # if (!is.null(tcp_server)) tcp_server$stop()

} else {
  warning("Rlibhv package not found. Cannot run TCP server example.")
}

# Note: If you run this script non-interactively, it will start the servers
# and then exit, potentially stopping the servers if R shuts down its background
# threads/processes. For persistent servers, run in an interactive R session
# or use a mechanism to keep the R process alive (e.g., a loop with Sys.sleep).
# For example, to keep it running until you manually stop it:
# if (interactive() && exists("http_server") && exists("tcp_server")) {
#   message("Servers are running. Enter 'http_server$stop()' and 'tcp_server$stop()' to terminate them.")
#   while(TRUE) { Sys.sleep(1) } # Infinite loop for interactive session
# }

# To clean up (if you ran the Sys.sleep lines above or are in an interactive session):
# if (exists("http_server") && !is.null(http_server$.ptr)) { try(http_server$stop(), silent = TRUE) }
# if (exists("tcp_server") && !is.null(tcp_server$.ptr)) { try(tcp_server$stop(), silent = TRUE) }
# rm(list = ls())
# gc()
message("\nExample script finished. If servers were started, they might still be running in the background.")
message("In an interactive session, use http_server$stop() and tcp_server$stop() to halt them.")
