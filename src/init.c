#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

#include "Rlibhv.h"

/* .Call calls */
static const R_CallMethodDef CallEntries[] = {
    /* Version information functions */
    {"R_libhv_version",        (DL_FUNC) &R_libhv_version,        0},
    {"R_libhv_compile_version",(DL_FUNC) &R_libhv_compile_version,0},
    {"R_libhv_version_number", (DL_FUNC) &R_libhv_version_number, 0},
    
    /* TCP server functions */
    {"R_tcp_echo_server",      (DL_FUNC) &R_tcp_echo_server,      1},
    
    {NULL, NULL, 0}
};

void R_init_Rlibhv(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    
    /* Register the symbols for .Call */
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
    
   }