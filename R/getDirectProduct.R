#' Get the direct product of BE identifiers
#'
#' The product is directly taken as provided by the original database.
#' This function does not return indirect relationships.
#'
#' @param ids list of origin identifiers
#' @param sources a character vector corresponding to the possible origin ID
#' sources. If NULL (default), all sources are considered
#' @param process the production process among:
#' "is_expressed_as", "is_translated_in", "codes_for".
#' @param canonical If TRUE returns only canonical production process.
#' If FALSE returns only non-canonical production processes.
#' If NA (default) canonical information is taken into account.
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
#' oriId <- c("10", "100")
#' res <- getDirectProduct(
#'    ids=oriId,
#'    source="EntrezGene",
#'    process="is_expressed_as",
#'    canonical=NA
#' )
#' attr(res, "process")
#' }
#'
#' @seealso [getDirectOrigin], [convBeIds]
#'
#' @export
#'
getDirectProduct <- function(
   ids,
   sources=NULL,
   process=c("is_expressed_as", "is_translated_in", "codes_for"),
   canonical=NA
){
   process <- match.arg(process)
   cql <- c(
      sprintf('MATCH (f:BEID)-[p:%s]->(t:BEID)', process),
      'WHERE f.value IN $ids'
   )
   if(!is.null(sources)){
      cql <- c(
         cql,
         'AND f.database IN $sources'
      )
   }
   if(!is.na(canonical)){
      if(!identical(canonical, TRUE) & !identical(canonical, FALSE)){
         stop("canonical should be a logical of length 1")
      }
      cql <- c(
         cql,
         sprintf ('AND %s p.canonical', ifelse(canonical, "", "NOT"))
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
