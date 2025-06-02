#include <R.h>
#include <Rinternals.h>
#include <string.h>
#include <stdlib.h>
#include <regex.h>

// Helper: replace all regex matches with ""
char *regex_sub(char *input, const char *pattern) {
   regex_t regex;
   regmatch_t match;
   regcomp(&regex, pattern, REG_EXTENDED);
   while (regexec(&regex, input, 1, &match, 0) == 0) {
      size_t len = strlen(input);
      memmove(input + match.rm_so, input + match.rm_eo, len - match.rm_eo + 1);
   }
   regfree(&regex);
   return input;
}

// Helper: extract part after "="
char *substring_after_equal(char *input) {
   char *eq = strchr(input, '=');
   if (!eq) return input;
   return eq + 1;
}

// Helper: final removal of { ...}
char *remove_trailing_brace(char *input) {
   char *brace = strchr(input, '{');
   if (brace) *brace = '\0';
   return input;
}

SEXP extract_u_gn(SEXP value) {
   if (!Rf_isString(value) || Rf_length(value) != 1)
      Rf_error("Input must be a single string");

   const char *input = CHAR(STRING_ELT(value, 0));
   char *input_copy = strdup(input);

   // Step 1: split on ; *
   char *saveptr1 = NULL;
   char *token = strtok_r(input_copy, ";", &saveptr1);
   char **temp_list = (char **)malloc(1000 * sizeof(char *));
   int count = 0;

   while (token) {
      // Trim leading spaces
      while (*token == ' ') token++;

      // Step 2: remove {...}
      regex_sub(token, " *\\{[^\\{]*\\}");

      // Step 3: extract after =
      char *eq_part = substring_after_equal(token);

      // Step 4: split on comma or space
      char *saveptr2 = NULL;
      char *subtok = strtok_r(eq_part, ", ", &saveptr2);

      while (subtok) {
         // Step 5: split on slash
         char *saveptr3 = NULL;
         char *subsubtok = strtok_r(subtok, "/", &saveptr3);
         while (subsubtok) {
            // Step 6: remove trailing {
            char *cleaned = strdup(remove_trailing_brace(subsubtok));
            temp_list[count++] = cleaned;
            subsubtok = strtok_r(NULL, "/", &saveptr3);
         }
         subtok = strtok_r(NULL, ", ", &saveptr2);
      }

      token = strtok_r(NULL, ";", &saveptr1);
   }

   // Return result as character vector
   SEXP result = PROTECT(Rf_allocVector(STRSXP, count));
   for (int i = 0; i < count; i++) {
      SET_STRING_ELT(result, i, Rf_mkChar(temp_list[i]));
      free(temp_list[i]);
   }

   free(temp_list);
   free(input_copy);
   UNPROTECT(1);
   return result;
}
