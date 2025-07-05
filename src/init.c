#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> 
#include <R_ext/Rdynload.h>

#include "RC_libhv.h"

/* .Call calls */
static const R_CallMethodDef CallEntries[] = {
    /* Version information functions */
    {"RC_libhv_version",        (DL_FUNC) &RC_libhv_version,        0},
    {"RC_libhv_compile_version",(DL_FUNC) &RC_libhv_compile_version,0},
    {"RC_libhv_version_number", (DL_FUNC) &RC_libhv_version_number, 0},
    /* TCP server functions */
    {"RC_tcp_echo_server",      (DL_FUNC) &RC_tcp_echo_server,      1},
    /**/
    {NULL, NULL, 0}
};

void R_init_Rlibhv(DllInfo *dll)
{
    R_registerRoutines(
                    dll,
                    NULL,
                    CallEntries, 
                    NULL,
                    NULL);
    /* Register the symbols for .Call */
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
   }
