// [[Rcpp::plugins(cpp11)]]
#include <Rcpp.h>
#include "hv/TcpServer.h" // libhv TCP server class
#include "hv/HttpServer.h" // libhv HTTP server and service classes
#include "hv/hv.h"         // libhv general utilities, e.g., hlog_set_level

/*
 * Rcpp Module for libhv Server Functionalities
 *
 * This module exposes libhv's TcpServer, HttpService, and HttpServer classes to R,
 * enabling the creation of TCP and HTTP (Rook-compatible) servers within an R environment.
 *
 * Key features:
 * - Asynchronous server operations managed by libhv's event loop.
 * - Callbacks from C++ (libhv events) to R functions for handling connections, messages, and HTTP requests.
 * - Rook interface compatibility for the HTTP server.
 *
 * Thread Safety Considerations:
 * Callbacks from libhv's worker threads into R are a critical point. Rcpp generally handles
 * transitions between C++ and R, and R's Global Interpreter Lock (GIL) serializes access
 * to the R interpreter. However, long-running R callbacks can block libhv's event loop threads.
 * Ensure R callback functions are efficient or consider asynchronous dispatch within R if needed.
 * Rcpp::Rcout, Rcpp::Rcerr, and Rcpp::stop are designed to be callable from threads.
 */

// Note: The RCallbacks struct was an initial idea but is not currently used,
// as Rcpp::Function objects are captured by lambdas directly.
// struct RCallbacks {
//     Rcpp::Function onConnection;
//     Rcpp::Function onMessage;
//     Rcpp::Function httpHandler;
// };

RCPP_MODULE(libhv_servers) {
    using namespace Rcpp;
    using namespace hv;

    // Expose hlog_set_level for debugging from R
    function("hlog_set_level", &hlog_set_level, "Set libhv log level");

    // Expose hv::TcpServer class to R
    class_<TcpServer>("TcpServer")
        .constructor("Creates a new hv::TcpServer instance.")
        .method("createsocket", &TcpServer::createsocket,
                "Creates a listen socket. Call as createsocket(port, host_ip_str). Returns listen_fd or <0 on error.")
        .method("start", &TcpServer::start,
                "Starts the TCP server's event loop (non-blocking).")
        .method("stop", &TcpServer::stop,
                "Stops the TCP server's event loop.")
        .method("setThreadNum", &TcpServer::setThreadNum,
                "Sets the number of worker threads for the server.")

        // Method to set an R function as the onConnection callback
        .method("onConnectionR", [](TcpServer& self, Rcpp::Function r_callback) {
            // This C++ lambda is assigned to hv::TcpServer::onConnection
            // It captures the R_Function provided by the user.
            self.onConnection = [r_callback](const SocketChannelPtr& channel) {
                // This code runs when a client connects or disconnects.
                // It's executed in one of libhv's worker threads.
                std::string peeraddr_str = channel->peeraddr();
                bool is_connected_flag = channel->isConnected();
                int file_descriptor = channel->fd();
                int channel_identifier = channel->id();

                try {
                    // Call the R callback function with connection details
                    r_callback(peeraddr_str, is_connected_flag, file_descriptor, channel_identifier);
                } catch (Rcpp::exception& e) {
                    Rcpp::Rcerr << "Rlibhv: Error in onConnectionR R callback: " << e.what() << std::endl;
                } catch (...) {
                    Rcpp::Rcerr << "Rlibhv: Unknown error in onConnectionR R callback." << std::endl;
                }
            };
        }, "Sets the R callback for connection events. R fn(peeraddr_str, is_connected, fd, id)")

        // Method to set an R function as the onMessage callback
        .method("onMessageR", [](TcpServer& self, Rcpp::Function r_callback) {
            // This C++ lambda is assigned to hv::TcpServer::onMessage
            self.onMessage = [r_callback](const SocketChannelPtr& channel, Buffer* buf) {
                // This code runs when data is received from a client.
                // Executed in a libhv worker thread.
                Rcpp::RawVector raw_data(buf->size());
                if (buf->size() > 0) { // memcpy is unsafe with size 0 if buf->data() is NULL
                    memcpy(raw_data.begin(), buf->data(), buf->size());
                }
                int channel_identifier = channel->id();

                try {
                    // Call the R callback function with channel ID and raw data
                    r_callback(channel_identifier, raw_data);
                } catch (Rcpp::exception& e) {
                    Rcpp::Rcerr << "Rlibhv: Error in onMessageR R callback: " << e.what() << std::endl;
                } catch (...) {
                    Rcpp::Rcerr << "Rlibhv: Unknown error in onMessageR R callback." << std::endl;
                }
            };
        }, "Sets the R callback for message events. R fn(channel_id, raw_vector_data)")

        // Method to send data to a specific connection
        // Note: libhv::TcpServer::send takes connfd (int), data (const void*), length (int)
        .method("write", [](TcpServer& self, int connfd, Rcpp::RawVector data_to_send) {
             return self.send(connfd, (void*)data_to_send.begin(), data_to_send.size());
        }, "Sends raw data to a specific connection. Args: (connfd, raw_vector_data)")

        // Method to broadcast data to all connected clients
        .method("broadcast", [](TcpServer& self, Rcpp::RawVector data_to_send) {
            return self.broadcast((void*)data_to_send.begin(), data_to_send.size());
        }, "Broadcasts raw data to all connected clients. Args: (raw_vector_data)");

    // Expose hv::HttpServer class to R
    class_<HttpServer>("HttpServer")
        .constructor("Creates a new hv::HttpServer instance.")
        .property("port", &HttpServer::port, &HttpServer::setPort,
                  "The HTTP listening port (e.g., 8080).")
        .property("https_port", &HttpServer::https_port, &HttpServer::setHttpsPort,
                  "The HTTPS listening port (e.g., 8443). SSL context must be configured separately.")
        .method("setThreadNum", &HttpServer::setThreadNum,
                "Sets the number of worker threads for the HTTP server.")
        .method("run", &HttpServer::run,
                "Starts the HTTP server and blocks the current thread (usually not preferred for R).")
        .method("start", &HttpServer::start,
                "Starts the HTTP server in non-blocking mode (event loop in background threads).")
        .method("stop", &HttpServer::stop,
                "Stops the HTTP server.")
        // Method to associate an hv::HttpService instance with this server
        .method("setService", [](HttpServer& self, HttpService& service_obj) {
            // hv::HttpServer stores a raw pointer to the HttpService.
            // The R side (R6 classes) must ensure `service_obj` outlives `self`.
            self.service = &service_obj;
        }, "Sets the hv::HttpService that will handle requests for this server.")
        .method("getService", [](HttpServer& self) {
            // Returns a raw pointer; use with caution on the R side.
            return self.service;
        }, "Gets the associated hv::HttpService. Returns a pointer (handle with care).");

    // Expose hv::HttpService class to R
    // This class is primarily used to define request routing and handlers.
    class_<HttpService>("HttpService")
        .constructor("Creates a new hv::HttpService instance for request routing.")
        // Exposing specific HTTP method routing (GET, POST, etc.) with R callbacks:
        // This is more idiomatic libhv but less like a standard Rook interface.
        // The setRookCatchAll method is preferred for Rook compatibility.
        .method("GET", [](HttpService& self, const std::string& path_str, Rcpp::Function r_handler_fn){
            self.GET(path_str, [r_handler_fn](HttpRequest* req, HttpResponse* resp){
                // This is a simplified, non-Rook direct handler.
                // It would require converting req/resp to R objects, calling r_handler_fn,
                // and then translating the R response back to the HttpResponse.
                // This is complex and not the primary goal here.
                // The setRookCatchAll provides the main Rook interface.
                try {
                    // Example: pass path and a representation of query params
                    Rcpp::List query_params_list;
                    for(auto const& [key, val] : req->query_params) {
                        query_params_list[key] = val;
                    }
                    r_handler_fn(req->path(), query_params_list);
                } catch(Rcpp::exception& e) {
                    Rcpp::Rcerr << "Rlibhv: Error in HttpService GET R callback: " << e.what() << std::endl;
                } catch(...) {
                    Rcpp::Rcerr << "Rlibhv: Unknown error in HttpService GET R callback." << std::endl;
                }
                // Send a placeholder response
                resp->SetContentType(TEXT_PLAIN);
                resp->SetBody("Handled by R GET (simplified path-specific handler)");
                return 200; // HTTP status OK
            });
        }, "Registers an R callback for GET requests on a specific path. (Simplified, non-Rook)")

        // Method to set a single R function as the Rook-style catch-all handler
        .method("setRookCatchAll", [](HttpService& self, Rcpp::Function r_rook_handler_fn) {
            // The C++ lambda passed to HttpService::Handle will process all requests
            // if this service is used by an HttpServer and this is the primary/default handler.
            // libhv's HttpService::Handle (without a path) or with a wildcard path
            // can serve as a catch-all. Exact behavior depends on libhv's routing logic.
            // For this Rook interface, we assume this effectively becomes the main handler.
            self.Handle([r_rook_handler_fn](const HttpContextPtr& ctx) {
                // This code runs when an HTTP request is received.
                // Executed in one of libhv's worker threads.

                // 1. Prepare the Rook environment list for the R callback
                Rcpp::List r_request_env;
                r_request_env["REQUEST_METHOD"] = ctx->method_str.c_str(); // e.g., "GET", "POST"
                r_request_env["PATH_INFO"] = ctx->path();                 // e.g., "/foo/bar"
                r_request_env["QUERY_STRING"] = ctx->query();             // e.g., "a=1&b=2"

                // Convert HTTP headers (std::map) to an R named list
                Rcpp::List r_headers;
                for (auto const& [key, val] : ctx->headers()) {
                    r_headers[key] = val;
                }
                r_request_env["HEADERS"] = r_headers;

                // Prepare rook.input (request body stream)
                // Copy request body into a string, then create a RawVector for Rhttpuv::createRookInput
                std::string body_str(ctx->body().data(), ctx->body().size());
                Rcpp::RawVector body_raw_vector(body_str.begin(), body_str.end());

                // Get Rhttpuv::createRookInput function from Rhttpuv namespace
                // This requires Rhttpuv to be installed and loadable.
                Rcpp::Environment RhttpuvNS = Rcpp::Environment::namespace_env("Rhttpuv");
                Rcpp::Function createRookInputStream = RhttpuvNS["createRookInput"];
                r_request_env["rook.input"] = createRookInputStream(body_raw_vector);

                // 2. Call the R Rook handler function
                Rcpp::List r_response_list;
                try {
                    r_response_list = r_rook_handler_fn(r_request_env);
                } catch (Rcpp::exception& e) {
                    Rcpp::Rcerr << "Rlibhv: Error in Rook R handler: " << e.what() << std::endl;
                    // Send a 500 Internal Server Error response
                    ctx->set_status_code(HTTP_STATUS_INTERNAL_SERVER_ERROR);
                    ctx->set_content_type(TEXT_PLAIN);
                    ctx->set_body("Internal Server Error occurred in R Rook handler.");
                    return ctx->send(); // Send the error response
                } catch (...) {
                    Rcpp::Rcerr << "Rlibhv: Unknown error in Rook R handler." << std::endl;
                    ctx->set_status_code(HTTP_STATUS_INTERNAL_SERVER_ERROR);
                    ctx->set_content_type(TEXT_PLAIN);
                    ctx->set_body("Unknown Internal Server Error occurred in R Rook handler.");
                    return ctx->send();
                }

                // 3. Process the response from the R Rook handler
                int http_status_code = r_response_list["status"];
                Rcpp::List r_response_headers = Rcpp::as<Rcpp::List>(r_response_list["headers"]);
                SEXP r_response_body_sexp = r_response_list["body"];

                ctx->set_status_code(http_status_code);

                // Set response headers
                for (int i = 0; i < r_response_headers.size(); ++i) {
                    std::string header_key = Rcpp::as<std::string>(r_response_headers.names()[i]);
                    SEXP header_val_sexp = r_response_headers[i];
                    std::string header_value_str;
                    // Ensure header value is converted to string if it's numeric, etc.
                    if (TYPEOF(header_val_sexp) == STRSXP && Rf_length(header_val_sexp) > 0) {
                        header_value_str = Rcpp::as<std::string>(header_val_sexp);
                    } else if (TYPEOF(header_val_sexp) == INTSXP || TYPEOF(header_val_sexp) == REALSXP) {
                         header_value_str = Rcpp::as<std::string>(Rcpp::Language("as.character", header_val_sexp).eval());
                    } else {
                        // Default to empty string for other types or log a warning
                        header_value_str = "";
                    }
                    ctx->set_header(header_key, header_value_str);
                }

                // Set a default Content-Type for string bodies if not provided by Rook app
                // This is a common convenience.
                if (ctx->content_type() == NULL && TYPEOF(r_response_body_sexp) == STRSXP) {
                    ctx->set_content_type(TEXT_PLAIN);
                }

                // Set response body and send
                if (TYPEOF(r_response_body_sexp) == STRSXP && Rf_length(r_response_body_sexp) > 0) {
                    // Body is a character string
                    std::string resp_body_str = Rcpp::as<std::string>(r_response_body_sexp);
                    ctx->set_body(resp_body_str);
                } else if (TYPEOF(r_response_body_sexp) == RAWSXP) {
                    // Body is a raw vector
                    Rcpp::RawVector raw_body_vec = Rcpp::as<Rcpp::RawVector>(r_response_body_sexp);
                    // hv::HttpContext::set_body can take (const void* data, size_t len)
                    ctx->set_body((const char*)raw_body_vec.begin(), raw_body_vec.size());
                } else {
                    // Empty body for other types (e.g., NULL) or if body is not string/raw
                    ctx->set_body("");
                }
                return ctx->send(); // Send the complete response
            });
        }, "Sets the R function(env) for Rook-style request handling. This acts as a catch-all for the service.");
}

// General Notes on C++ implementation:
// - Lifetime Management: Rcpp handles garbage collection of the exposed C++ objects (`TcpServer`, `HttpService`, `HttpServer`)
//   when their corresponding R objects are no longer referenced. The R6 classes in R/rook_interface.R
//   store Rcpp::Function callbacks, protecting them from premature GC.
// - HttpService and HttpServer Interaction: `hv::HttpServer` holds a raw pointer `HttpService* service`.
//   The R-level `LibhvHttpServer` class must ensure that the `LibhvHttpService` instance (and its C++ counterpart)
//   remains valid for the lifetime of the `LibhvHttpServer` that uses it. This is managed by the R6 classes.
// - Data Marshalling:
//   - TCP: Raw data is passed as R `RawVector` to/from C++.
//   - HTTP (Rook): Request details are converted into an R `list` (the Rook `env`). The response from the R Rook
//     function (a `list` with status, headers, body) is converted back to an HTTP response.
// - Rhttpuv Dependency: `Rhttpuv::createRookInput` is used for creating the `rook.input` stream object,
//   aligning with common Rook server behavior in R. This means `Rhttpuv` package is an operational dependency.
// - Error Handling: R-to-C++ calls are wrapped in try-catch blocks to prevent R errors from crashing C++ layer.
//   Errors are reported to `Rcpp::Rcerr`.
// - Header Naming: libhv headers like "hv/TcpServer.h" are used directly.
// - String Conversions: `std::string` is used for exchanging text with R character vectors.
//   `Rcpp::RawVector` for binary data.
// - `HttpContext::body()` returns `std::string&`, so `ctx->body().data()` and `ctx->body().size()` are correct.
// - `ctx->send()` is the final call to send the response after setting status, headers, and body on `HttpContextPtr`.
