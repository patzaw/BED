#' Cached neo4j call
#'
#' This function calls neo4j DB the first time a query is sent and puts
#' the result in the cache SQLite database. The next time the same query is
#' called, it loads the results directly from cache SQLite database.
#'
#' Use only with "row" result returned by DB request.
#'
#' Internal use.
#'
#' @param ... params for [bedCall]
#' @param tn the name of the cached table
#' @param recache boolean indicating if the CQL query should be run even if
#' the table is already in cache
#'
#' @return The results of the [bedCall].
#'
#' @seealso [cacheBedResult], [bedCall]
#'
cacheBedCall <- function(
   ...,
   tn,
   recache=FALSE
){
   cache <- checkBedCache()
   if(tn %in% rownames(cache) & !recache){
      toRet <- loadBedResult(tn)
   }else{
      toRet <- bedCall(...)
      cacheBedResult(value=toRet, name=tn)
   }
   return(toRet)
}
