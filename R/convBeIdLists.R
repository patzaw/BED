#' Converts lists of BE IDs
#'
#' @param idList a list of IDs lists
#' @param entity if TRUE returns BE instead of BEID (default: FALSE).
#' BE CAREFUL, THIS INTERNAL ID IS NOT STABLE AND CANNOT BE USED AS A REFERENCE.
#' This internal identifier is useful to avoid biases related to identifier
#' redundancy. See <../doc/BED.html#3_managing_identifiers>
#' @param ... params for the [convBeIds] function
#'
#' @return A list of [convBeIds] ouput ids.
#' Scope ("be", "source" "organism" and "entity" (see Arguments))
#' is provided as a named list
#' in the "scope" attributes: `attr(x, "scope")`
#'
#' @examples \dontrun{
#' convBeIdLists(
#'    idList=list(a=c("10", "100"), b=c("1000")),
#'    from="Gene",
#'    from.source="EntrezGene",
#'    from.org="human",
#'    to.source="Ens_gene"
#' )
#' }
#'
#' @seealso [convBeIds], [convDfBeIds]
#'
#' @export
#'
convBeIdLists <- function(
   idList,
   entity=FALSE,
   ...
){
   ct <- convBeIds(unique(unlist(idList)), ...)
   toRet <- lapply(
      idList,
      function(x){
         if(entity){
            setdiff(unique(ct$to.entity[which(ct$from %in% x)]), NA)
         }else{
            setdiff(unique(ct$to[which(ct$from %in% x)]), NA)
         }
      }
   )
   attr(toRet, "scope") <- c(attr(ct, "scope"), list(entity=entity))
   return(toRet)
}
