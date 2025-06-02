#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

extern SEXP extract_u_de(SEXP);
extern SEXP extract_u_gn(SEXP);


static const R_CallMethodDef CallEntries[] = {
   {"extract_u_de", (DL_FUNC) &extract_u_de, 1},
   {"extract_u_gn", (DL_FUNC) &extract_u_gn, 1},
   {NULL, NULL, 0}
};

void R_init_BED(DllInfo *dll) {
   R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
   R_useDynamicSymbols(dll, FALSE);
}
