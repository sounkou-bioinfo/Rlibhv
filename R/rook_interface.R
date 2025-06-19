#' @useDynLib Rlibhv, .registration = TRUE
#' @import Rcpp
#' @import R6
#' @importFrom Rhttpuv createRookInput # For documentation purposes, actual use is C++ lookup
NULL

#' Libhv TCP Server
#'
#' @description
#' R6 class to manage a `libhv` TCP server.
#'
#' @details
#' This class provides an R interface to the TCP server functionality of the `libhv`
#' C++ library. It allows users to create a TCP server, define callbacks for
#' connection events and incoming messages, start and stop the server, and
#' send data to connected clients.
#'
#' The server operates asynchronously, handling multiple client connections
#' concurrently using an event loop managed by `libhv`. Callbacks from C++
#' into R are executed for events like new connections, disconnections, and
#' received messages.
#'
#' @export
LibhvTcpServer <- R6::R6Class("LibhvTcpServer",
  public = list(
    #' @field .ptr Internal pointer to the C++ TcpServer object. For internal use.
    .ptr = NULL,
    #' @field .on_connection_callback Stores the R function for connection events. For internal use.
    .on_connection_callback = NULL,
    #' @field .on_message_callback Stores the R function for message events. For internal use.
    .on_message_callback = NULL,

    #' @description
    #' Creates a new `LibhvTcpServer` instance.
    #' @param port The integer port number to listen on.
    #' @param host The character string host address to bind to (default: "0.0.0.0", listens on all interfaces).
    #' @param threads The integer number of worker threads for the server (default: 1).
    #' @examples
    #' \dontrun{
    #'   tcp_server <- LibhvTcpServer$new(port = 12345)
    #'   tcp_server$start()
    #'   # ... later ...
    #'   tcp_server$stop()
    #' }
    initialize = function(port, host = "0.0.0.0", threads = 1) {
      stopifnot(is.numeric(port), port > 0, port < 65536)
      stopifnot(is.character(host), length(host) == 1)
      stopifnot(is.numeric(threads), threads > 0)

      self$.ptr <- .Call(paste0("C_new_", "TcpServer"))
      if (is.null(self$.ptr)) {
        stop("Failed to create C++ TcpServer object. Rcpp module 'libhv_servers' might not be loaded correctly.")
      }

      listenfd <- self$.ptr$createsocket(as.integer(port), host)
      if (listenfd < 0) {
        stop(paste("Failed to create listen socket. libhv error code:", listenfd))
      }
      self$.ptr$setThreadNum(as.integer(threads))

      # Set up default informational callbacks
      self$on_connection(function(peeraddr, is_connected, fd, id) {
        if (is_connected) {
          cat(sprintf("LibhvTcpServer: Client connected: %s (fd: %d, id: %d)\n", peeraddr, fd, id))
        } else {
          cat(sprintf("LibhvTcpServer: Client disconnected: %s (fd: %d, id: %d)\n", peeraddr, fd, id))
        }
      })
      self$on_message(function(channel_id, raw_data) {
        cat(sprintf("LibhvTcpServer: Message from client %d: %s\n", channel_id, rawToChar(raw_data)))
      })

      invisible(self)
    },

    #' @description
    #' Sets the R callback function for connection events.
    #'
    #' The callback function will be invoked when a client connects or disconnects.
    #' @param callback A function that accepts four arguments:
    #'   \describe{
    #'     \item{`peeraddr`}{A character string representing the client's address (e.g., "ip:port").}
    #'     \item{`is_connected`}{A logical value: `TRUE` if a new connection is established, `FALSE` if a connection is closed.}
    #'     \item{`fd`}{An integer representing the connection's file descriptor.}
    #'     \item{`id`}{An integer representing a unique ID for the connection channel.}
    #'   }
    #' @return The `LibhvTcpServer` object, invisibly, for chaining.
    on_connection = function(callback) {
      if (!is.function(callback)) stop("callback must be a function")
      private$.on_connection_callback <- callback # Store to prevent GC
      self$.ptr$onConnectionR(private$.on_connection_callback)
      invisible(self)
    },

    #' @description
    #' Sets the R callback function for incoming messages.
    #'
    #' The callback function will be invoked when the server receives data from a client.
    #' @param callback A function that accepts two arguments:
    #'   \describe{
    #'     \item{`channel_id`}{An integer representing the unique ID of the connection channel from which the message was received.}
    #'     \item{`raw_data`}{A raw vector containing the received data.}
    #'   }
    #' @return The `LibhvTcpServer` object, invisibly, for chaining.
    on_message = function(callback) {
      if (!is.function(callback)) stop("callback must be a function")
      private$.on_message_callback <- callback # Store to prevent GC
      self$.ptr$onMessageR(private$.on_message_callback)
      invisible(self)
    },

    #' @description
    #' Starts the TCP server.
    #' This is a non-blocking call; the server's event loop runs in background threads.
    #' @return The `LibhvTcpServer` object, invisibly.
    start = function() {
      self$.ptr$start()
      # cat("LibhvTcpServer: Server started.\n")
      invisible(self)
    },

    #' @description
    #' Stops the TCP server.
    #' @return The `LibhvTcpServer` object, invisibly.
    stop = function() {
      self$.ptr$stop()
      # cat("LibhvTcpServer: Server stopped.\n")
      invisible(self)
    },

    #' @description
    #' Sends data to a specific connected client.
    #' @param connfd The integer connection file descriptor (or channel ID) of the client.
    #'   This typically corresponds to the `fd` or `id` provided by the `on_connection`
    #'   or `on_message` callbacks.
    #' @param data The data to send. Can be a character string (which will be converted to raw)
    #'   or a raw vector.
    #' @return The `LibhvTcpServer` object, invisibly.
    write = function(connfd, data) {
      if (is.character(data)) {
        data <- charToRaw(paste0(data, collapse="\n"))
      }
      if (!is.raw(data)) stop("data must be a string or raw vector")
      stopifnot(is.numeric(connfd))
      self$.ptr$write(as.integer(connfd), data)
      invisible(self)
    },

    #' @description
    #' Broadcasts data to all currently connected clients.
    #' @param data The data to send. Can be a character string (converted to raw) or a raw vector.
    #' @return The `LibhvTcpServer` object, invisibly.
    broadcast = function(data) {
      if (is.character(data)) {
        data <- charToRaw(paste0(data, collapse="\n"))
      }
      if (!is.raw(data)) stop("data must be a string or raw vector")
      self$.ptr$broadcast(data)
      invisible(self)
    },

    #' @description
    #' Finalizer method, automatically called when the object is garbage collected.
    #' It's good practice to explicitly call `$stop()` on the server when it's no longer needed.
    finalize = function() {
      if (!is.null(self$.ptr)) {
        # Consider if automatic stopping is safe or desired.
        # Explicit stop by user is generally preferred.
        # self$.ptr$stop()
        # cat("LibhvTcpServer object finalized. If server was running, it might still be. Please use $stop() explicitly.\n")
      }
    }
  ),
  private = list(
    # .on_connection_callback and .on_message_callback are now in public for roxygen to see them as fields.
    # However, R6 fields are always public. If true privacy for these fields was intended,
    # they should remain in private list and accessed via active bindings or methods if needed.
    # For callback storage, having them in public list but marked as "For internal use" is common.
  )
)

#' Libhv HTTP Service
#'
#' @description
#' R6 class to manage a `libhv` HTTP service, which is responsible for defining
#' how HTTP requests are routed and handled.
#'
#' @details
#' This class wraps the `hv::HttpService` C++ class. Its primary role in this
#' interface is to be configured with a Rook application handler. This service
#' object is then passed to a `LibhvHttpServer` instance.
#'
#' @export
LibhvHttpService <- R6::R6Class("LibhvHttpService",
  public = list(
    #' @field .ptr Internal pointer to the C++ HttpService object. For internal use.
    .ptr = NULL,
    #' @field .rook_handler_callback Stores the R Rook application function. For internal use.
    .rook_handler_callback = NULL,

    #' @description
    #' Creates a new `LibhvHttpService` instance.
    #' @examples
    #' \dontrun{
    #'   http_service <- LibhvHttpService$new()
    #' }
    initialize = function() {
      self$.ptr <- .Call(paste0("C_new_", "HttpService"))
      if (is.null(self$.ptr)) {
        stop("Failed to create C++ HttpService object. Rcpp module 'libhv_servers' might not be loaded correctly.")
      }
      invisible(self)
    },

    #' @description
    #' Sets the Rook application handler for this service.
    #'
    #' All HTTP requests received by a `LibhvHttpServer` using this service
    #' will be processed by the provided Rook application function.
    #' @param handler A Rook application function. This function must take one
    #'   argument, `env` (an R environment or list containing request details like
    #'   `REQUEST_METHOD`, `PATH_INFO`, `HEADERS`, `rook.input`, etc.), and
    #'   must return a list with three named elements: `status` (integer HTTP status code),
    #'   `headers` (a named list of HTTP response headers), and `body` (character string,
    #'   raw vector, or path to a file for the response body).
    #' @return The `LibhvHttpService` object, invisibly.
    #' @examples
    #' \dontrun{
    #'   app <- function(env) {
    #'     list(
    #'       status = 200L,
    #'       headers = list('Content-Type' = 'text/plain'),
    #'       body = paste("Hello from Rook at", env$PATH_INFO)
    #'     )
    #'   }
    #'   http_service <- LibhvHttpService$new()
    #'   http_service$set_rook_handler(app)
    #' }
    set_rook_handler = function(handler) {
      if (!is.function(handler)) stop("handler must be a Rook application function")
      private$.rook_handler_callback <- handler # Store to prevent GC
      self$.ptr$setRookCatchAll(private$.rook_handler_callback)
      invisible(self)
    },

    #' @description
    #' Finalizer method.
    finalize = function() {
      # cat("LibhvHttpService object finalized.\n")
    }
  )
)

#' Libhv HTTP Server
#'
#' @description
#' R6 class to manage a `libhv` HTTP server.
#'
#' @details
#' This class provides an R interface to the HTTP server functionality of `libhv`.
#' It requires a configured `LibhvHttpService` object to handle incoming requests
#' according to Rook specifications. The server operates asynchronously.
#'
#' @export
LibhvHttpServer <- R6::R6Class("LibhvHttpServer",
  public = list(
    #' @field .ptr Internal pointer to the C++ HttpServer object. For internal use.
    .ptr = NULL,
    #' @field .service The `LibhvHttpService` instance associated with this server. For internal use.
    #' @md
    .service = NULL,

    #' @description
    #' Creates a new `LibhvHttpServer` instance.
    #' @param service An instance of `LibhvHttpService` that has been configured
    #'   (e.g., with a Rook handler via `$set_rook_handler()`). If `NULL` (default),
    #'   a service must be assigned using `$set_service()` before starting the server.
    #' @param port The integer HTTP port to listen on (default: 8080).
    #' @param https_port The integer HTTPS port to listen on (default: 0, meaning HTTPS is disabled).
    #'   Note: Enabling HTTPS (`https_port > 0`) requires SSL/TLS certificates to be
    #'   configured in the underlying `libhv` library. This R wrapper currently does
    #'   not provide methods to configure SSL contexts from R.
    #' @param threads An optional integer specifying the number of worker threads for the server.
    #'   If `NULL` (default), `libhv`'s default thread count is used (often based on CPU cores).
    #' @examples
    #' \dontrun{
    #'   # Assume 'app' is a Rook application function and 'http_service' is configured
    #'   # http_service <- LibhvHttpService$new()$set_rook_handler(app)
    #'
    #'   http_server <- LibhvHttpServer$new(service = http_service, port = 8088)
    #'   http_server$start()
    #'   # ... later ...
    #'   http_server$stop()
    #' }
    initialize = function(service = NULL, port = 8080, https_port = 0, threads = NULL) {
      stopifnot(is.numeric(port), port > 0, port < 65536)
      stopifnot(is.numeric(https_port), https_port >= 0, https_port < 65536)
      if(!is.null(threads)) stopifnot(is.numeric(threads), threads > 0)

      self$.ptr <- .Call(paste0("C_new_", "HttpServer"))
      if (is.null(self$.ptr)) {
        stop("Failed to create C++ HttpServer object. Rcpp module 'libhv_servers' might not be loaded correctly.")
      }

      if (!is.null(service)) {
        self$set_service(service)
      }

      self$port <- port # Use active binding
      if (https_port > 0) {
        self$https_port <- https_port # Use active binding
        warning("HTTPS port set, but SSL context must be configured separately for HTTPS to function (not exposed in this R wrapper).")
      }
      if (!is.null(threads)) {
        self$threads <- threads # Use active binding
      }
      invisible(self)
    },

    #' @description
    #' Sets or associates an HTTP service with this server.
    #' The service object contains the request handling logic (e.g., a Rook app).
    #' @param service An instance of `LibhvHttpService`.
    #' @return The `LibhvHttpServer` object, invisibly.
    set_service = function(service) {
      if (!inherits(service, "LibhvHttpService")) {
        stop("service must be an instance of LibhvHttpService")
      }
      if (is.null(service$.ptr)) {
          stop("Provided LibhvHttpService has an invalid internal C++ pointer (service$.ptr is NULL).")
      }
      self$.service <- service
      self$.ptr$setService(service$.ptr) # Pass the C++ pointer of the service's .ptr field
      invisible(self)
    },

    #' @description
    #' Starts the HTTP server.
    #' This is a non-blocking call. The server runs in background threads.
    #' An HTTP service must be associated with the server before starting.
    #' @return The `LibhvHttpServer` object, invisibly.
    start = function() {
      if (is.null(self$.service)) {
        stop("HTTP service not set. Call $set_service() with a valid LibhvHttpService instance first.")
      }
      self$.ptr$start()
      # cat(sprintf("LibhvHttpServer: Server started on port %d.\n", self$port))
      # if (self$https_port > 0) {
      #     cat(sprintf("LibhvHttpServer: HTTPS potentially started on port %d (if SSL configured).\n", self$https_port))
      # }
      invisible(self)
    },

    #' @description
    #' Stops the HTTP server.
    #' @return The `LibhvHttpServer` object, invisibly.
    stop = function() {
      self$.ptr$stop()
      # cat("LibhvHttpServer: Server stopped.\n")
      invisible(self)
    },

    #' @description
    #' Finalizer method.
    finalize = function() {
       if (!is.null(self$.ptr)) {
        # cat("LibhvHttpServer object finalized. If server was running, it might still be. Please use $stop() explicitly.\n")
      }
    }
  ),
  active = list(
    #' @field port (integer) The HTTP listening port. Can be set.
    port = function(value) {
      if (missing(value)) {
        return(self$.ptr$port)
      } else {
        stopifnot(is.numeric(value), value > 0, value < 65536)
        self$.ptr$port <- as.integer(value)
      }
    },
    #' @field https_port (integer) The HTTPS listening port. Can be set. `0` means disabled.
    https_port = function(value) {
      if (missing(value)) {
        return(self$.ptr$https_port)
      } else {
        stopifnot(is.numeric(value), value >= 0, value < 65536)
        self$.ptr$https_port <- as.integer(value)
      }
    },
    #' @field threads (integer) Number of worker threads. Can be set.
    #' @details Reading this field returns the last value set from R, or `NA_integer_`
    #' if not set from R (as `libhv` doesn't provide a getter for thread count by default).
    #' Setting this field configures the number of worker threads for the server.
    threads = function(value) {
      if (missing(value)) {
        return(private$.threads_r_side %||% NA_integer_)
      } else {
        stopifnot(is.numeric(value), value > 0)
        self$.ptr$setThreadNum(as.integer(value))
        private$.threads_r_side <- as.integer(value)
      }
    }
  ),
  private = list(
    .threads_r_side = NULL # Cache for thread count on R side for getter
  )
)

# Internal helper for providing default values (e.g., in active bindings)
'%||%' <- function(a, b) if (is.null(a)) b else a

#' Set libhv Global Log Level
#'
#' @description
#' Sets the logging verbosity for the underlying `libhv` C++ library globally.
#'
#' @param level An integer or character string representing the desired log level.
#'   Accepted string values (case-insensitive):
#'   `"VERBOSE"`, `"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`, `"FATAL"`, `"SILENT"` (or `"NONE"`).
#'   Corresponding integer values for `libhv`'s `hlog_level_e` enum:
#'   \itemize{
#'     \item `VERBOSE = 0`
#'     \item `DEBUG   = 1`
#'     \item `INFO    = 2`
#'     \item `WARN    = 3`
#'     \item `ERROR   = 4`
#'     \item `FATAL   = 5`
#'     \item `SILENT  = 6` (same as `NONE`)
#'   }
#' @return `NULL` (invisibly). This function is called for its side effect of changing the log level.
#' @export
#' @examples
#' \dontrun{
#'   set_libhv_log_level("DEBUG")  # Set log level to DEBUG
#'   set_libhv_log_level(2)      # Set log level to INFO (integer value)
#' }
set_libhv_log_level <- function(level) {
  level_val <- NA_integer_
  if (is.character(level)) {
    level_map <- c(
      "VERBOSE" = 0L, "DEBUG" = 1L, "INFO" = 2L, "WARN" = 3L,
      "ERROR" = 4L, "FATAL" = 5L, "SILENT" = 6L, "NONE" = 6L
    )
    level_val <- level_map[toupper(level)]
    if (is.na(level_val)) {
      stop(paste("Invalid log level string. Use one of:", paste(names(level_map), collapse=", ")))
    }
  } else if (is.numeric(level) && length(level) == 1 && level == as.integer(level) && level >= 0 && level <= 6) {
    level_val <- as.integer(level)
  } else {
    stop("Invalid level. Must be an integer between 0 and 6 or a recognized level string.")
  }

  # Access the Rcpp module function.
  # This relies on `loadModule("libhv_servers", TRUE)` in NAMESPACE making functions accessible.
  # A common way Rcpp makes module functions available is prepending the module name,
  # e.g., ModuleName_functionName, or directly if no conflict.
  # The most robust way from within a package is to use getFunction from the module environment.
  fn <- NULL
  module_env_name <- ".__C__libhv_servers" # Default environment name for Rcpp modules
  if (exists(module_env_name, mode = "environment")) {
      mod_env <- get(module_env_name, mode = "environment")
      if (exists("hlog_set_level", envir = mod_env, mode = "function")) {
          fn <- get("hlog_set_level", envir = mod_env, mode = "function")
      }
  }

  if (is.null(fn)) {
    # Fallback attempt: check if function is directly available in package namespace
    # This might happen based on how Rcpp exports or if `loadModule(..., loadFunctions=TRUE)`
    if(exists("hlog_set_level", mode = "function", envir = asNamespace(packageName()))) {
        fn <- get("hlog_set_level", mode = "function", envir = asNamespace(packageName()))
    } else {
        warning(paste0("Rlibhv: 'hlog_set_level' function from Rcpp module 'libhv_servers' not found. ",
                       "Logging level not set. Ensure package is correctly built and loaded."))
        return(invisible(NULL))
    }
  }

  fn(level_val)
  invisible(NULL)
}

.onLoad <- function(libname, pkgname) {
  # The NAMESPACE file should contain:
  #   loadModule(module = "libhv_servers", TRUE)
  # This ensures the Rcpp module is loaded when the package is loaded.
  packageStartupMessage("Rlibhv (version ", utils::packageVersion("Rlibhv"), ") loaded.")
  packageStartupMessage("Use Rlibhv::set_libhv_log_level() to adjust C++ library verbosity (e.g., 'INFO' or 'DEBUG').")
}
