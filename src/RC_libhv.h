#ifndef RLIBHV_H
#define RLIBHV_H

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>

/* libhv includes */
#include "hv.h"
#include "hloop.h"
#include "hsocket.h"
#include "hssl.h"

/* R wrapper functions for libhv */
SEXP RC_libhv_version();
SEXP RC_libhv_compile_version();
SEXP RC_libhv_version_number();

/* TCP echo server function */
SEXP RC_tcp_echo_server(SEXP port_sexp);

#endif /* RLIBHV_H */