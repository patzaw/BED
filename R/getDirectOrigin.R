#' Get the direct origin of BE identifiers
#'
#' The origin is directly taken as provided by the original database.
#' This function does not return indirect relationships.
#'
#' @param ids list of product identifiers
#' @param sources a character vector corresponding to the possible product ID
#' sources. If NULL (default), all sources are considered
#' @param process the production process among:
#' "is_expressed_as", "is_translated_in", "codes_for".
#'
#' @return a data.frame with the following columns:
#'
#'  - **origin**: the origin BE identifiers
#'  - **osource**: the origin database
#'  - **product**: the product BE identifiers
#'  - **psource**: the production database
#'  - **canonical**: whether the production process is canonical or not
#'
#' The process is also returned as an attribute of the data.frame.
#'
#' @examples \dontrun{
#' oriId <- c("XP_016868427", "NP_001308979")
#' res <- getDirectOrigin(
#'    ids=oriId,
#'    source="RefSeq_peptide",
#'    process="is_translated_in"
#' )
#' attr(res, "process")
#' }
#'
#' @seealso [getDirectOrigin], [convBeIds]
#'
#' @export
#'
getDirectOrigin <- function(
   ids,
   sources=NULL,
   process=c("is_expressed_as", "is_translated_in", "codes_for")
){
   process <- match.arg(process)
   cql <- c(
      sprintf('MATCH (f:BEID)-[p:%s]->(t:BEID)', process),
      'WHERE t.value IN $ids'
   )
   if(!is.null(sources)){
      cql <- c(
         cql,
         'AND t.database IN $sources'
      )
   }
   cql <- c(
      cql,
      paste(
         'RETURN f.value as origin, f.database as osource',
         't.value as product, t.database as psource',
         'p.canonical as canonical',
         sep=", "
      )
   )
   toRet <- bedCall(
      f=neo2R::cypher,
      query=neo2R::prepCql(cql),
      parameters=list(
         ids=as.list(unique(as.character(ids))),
         sources=as.list(unique(as.character(sources)))
      )
   )
   if(!is.null(toRet) && nrow(toRet)>0){
      toRet$canonical <- as.logical(toupper(toRet$canonical))
      attr(toRet, "process") <- process
   }
   return(toRet)
}
