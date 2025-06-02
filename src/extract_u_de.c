#include <R.h>
#include <Rinternals.h>
#include <stdlib.h>
#include <string.h>

// Helper function to extract value between "Full="
// or "Short=" and the next semicolon
char *extract_field(const char *str) {
   const char *start = strstr(str, "Full=");
   if (!start) {
      start = strstr(str, "Short=");
   }
   if (!start) return NULL;

   start = strchr(start, '=');  // move to '='
   if (!start) return NULL;
   start++;  // move past '='

   const char *end = strchr(start, ';');
   size_t len = end ? (size_t)(end - start) : strlen(start);

   char *result = malloc(len + 1);
   if (!result) return NULL;
   strncpy(result, start, len);
   result[len] = '\0';
   return result;
}

// Helper to trim " *[{].*$"
void clean_field(char *str) {
   char *brace = strchr(str, '{');
   if (brace) {
      while (brace > str && (*(brace - 1) == ' ')) {
         brace--;
      }
      *brace = '\0';
   }
}

SEXP extract_u_de(SEXP values) {
   if (!isString(values)) {
      error("Input must be a character vector");
   }

   int n = length(values);
   SEXP result = PROTECT(allocVector(STRSXP, n));
   int res_index = 0;

   for (int i = 0; i < n; i++) {
      const char *input = CHAR(STRING_ELT(values, i));
      char *extracted = extract_field(input);

      if (extracted) {
         if (strcmp(extracted, "Contains:") == 0) {
            free(extracted);
            break;
         }
         clean_field(extracted);
         SET_STRING_ELT(result, res_index++, mkChar(extracted));
         free(extracted);
      }
   }

   if (res_index == 0) {
      UNPROTECT(1);
      return R_NilValue;
   }

   // Trim to actual number of results
   SEXP final = PROTECT(allocVector(STRSXP, res_index));
   for (int i = 0; i < res_index; i++) {
      SET_STRING_ELT(final, i, STRING_ELT(result, i));
   }

   UNPROTECT(2);
   return final;
}
