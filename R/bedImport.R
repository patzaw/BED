#' Feeding BED: Imports a data.frame in the BED graph database
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param cql the CQL query to be applied on each row of toImport
#' @param toImport the data.frame to be imported as "row".
#' Use "row.FIELD" in the cql query to refer to one FIELD of the toImport
#' data.frame
#' @param periodicCommit use periodic commit when loading the data
#' (default: 1000).
#'
#' @return the results of the query
#'
#' @seealso \code{\link{bedCall}}
#'
#' @importFrom neo2R cypher
#' @importFrom utils write.table
#'
bedImport <- function(cql, toImport, periodicCommit=10000){
   tf = tempfile()
   for(cn in colnames(toImport)){
      toImport[,cn] <- as.character(toImport[,cn])
   }
   write.table(
      toImport,
      file=tf,
      sep="\t",
      quote=T,
      row.names=F, col.names=T
   )
   pc <- c()
   if(is.numeric(periodicCommit) && length(periodicCommit)==1){
      pc <- sprintf("USING PERIODIC COMMIT %s", periodicCommit)
   }
   cql <- prepCql(c(
      pc,
      paste0(
         'LOAD CSV WITH HEADERS FROM "file:',
         tf,
         '" AS row FIELDTERMINATOR "\\t"'
      ),
      cql
   ))
   toRet <- bedCall(cypher, query=cql)
   file.remove(tf)
   ##
   invisible(toRet)
}
