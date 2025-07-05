#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>
#include <signal.h>             
#include "RC_libhv.h"


/* Global variable to store the event loop */
static hloop_t* g_loop = NULL;
static int continue_running = 1;

/* Signal handler for SIGINT */
static void handle_sigint(int sig) {
    if (g_loop) {
        hloop_stop(g_loop);
        REprintf("libhv server interrupted by user\n");
        continue_running = 0;
    }
}

/* Libhv version functions */
SEXP RC_libhv_version() {
    return Rf_mkString(hv_version());
}

SEXP RC_libhv_compile_version() {
    return Rf_mkString(hv_compile_version());
}

SEXP RC_libhv_version_number() {
    return Rf_ScalarInteger(HV_VERSION_NUMBER);
}

/* TCP Echo Server implementation */
static void on_close(hio_t* io) {
    REprintf("Connection closed: fd=%d error=%d\n", hio_fd(io), hio_error(io));
}

static void on_recv(hio_t* io, void* buf, int readbytes) {
    char localaddrstr[SOCKADDR_STRLEN] = {0};
    char peeraddrstr[SOCKADDR_STRLEN] = {0};
    
    REprintf("Received: %d bytes from [%s] to [%s]\n", 
            readbytes,
            SOCKADDR_STR(hio_peeraddr(io), peeraddrstr),
            SOCKADDR_STR(hio_localaddr(io), localaddrstr));
            
    REprintf("< %.*s", readbytes, (char*)buf);
    
    /* Echo the received data back to the client */
    REprintf("> %.*s", readbytes, (char*)buf);
    hio_write(io, buf, readbytes);
}

static void on_accept(hio_t* io) {
    char localaddrstr[SOCKADDR_STRLEN] = {0};
    char peeraddrstr[SOCKADDR_STRLEN] = {0};
    
    REprintf("New connection: fd=%d [%s] <= [%s]\n", 
            hio_fd(io),
            SOCKADDR_STR(hio_localaddr(io), localaddrstr),
            SOCKADDR_STR(hio_peeraddr(io), peeraddrstr));
    
    /* Set callbacks for the new connection */
    hio_setcb_close(io, on_close);
    hio_setcb_read(io, on_recv);
    hio_read_start(io);
}

SEXP RC_tcp_echo_server(SEXP port_sexp) {
    if (!Rf_isInteger(port_sexp) && !Rf_isReal(port_sexp))
        Rf_error("'port' must be an integer");
    
    int port = Rf_asInteger(port_sexp);
    if (port <= 0 || port > 65535)
        Rf_error("'port' must be between 1 and 65535");
    
    const char* host = "0.0.0.0";
    
    /* Create new event loop */
    g_loop = hloop_new(0);
    if (!g_loop) {
        Rf_error("Failed to create event loop");
    }
    
    /* Create TCP server */
    hio_t* listenio = hloop_create_tcp_server(g_loop, host, port, on_accept);
    if (listenio == NULL) {
        hloop_free(&g_loop);
        Rf_error("Failed to create TCP server on port %d", port);
    }
    
    REprintf("TCP echo server started on %s:%d\n", host, port);
    REprintf("Server listening on fd=%d\n", hio_fd(listenio));
    
    /* Set up interrupt handler */
    continue_running = 1;
    signal(SIGINT, handle_sigint);
    
    /* Run the event loop */
    hloop_run(g_loop);
    
    /* Cleanup */
    hloop_free(&g_loop);
    g_loop = NULL;
    
    return R_NilValue;
}
