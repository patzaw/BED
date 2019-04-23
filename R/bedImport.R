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
bedImport <- function(
   cql, toImport, periodicCommit=10000, ...
){
   if(!inherits(toImport, "data.frame")){
      stop("toImport must be a data.frame")
   }
   importPath <- get("importPath", bedEnv)
   if(!is.null(importPath)){
      if(!file.exists(importPath)){
         stop(sprintf("Import path (%s) does not exist.", importPath))
      }
      tf <- tempfile(tmpdir=importPath)
   }else{
      tf <- tempfile()
   }
   for(cn in colnames(toImport)){
      toImport[,cn] <- as.character(toImport[,cn])
   }
   pc <- c()
   if(is.numeric(periodicCommit) && length(periodicCommit)==1){
      pc <- sprintf("USING PERIODIC COMMIT %s", periodicCommit)
   }
   cql <- prepCql(c(
      pc,
      paste0(
         'LOAD CSV WITH HEADERS FROM "file:',
         ifelse(
            !is.null(importPath),
            file.path("", basename(tf)),
            tf
         ),
         '" AS row '# FIELDTERMINATOR "\\t"'
      ),
      cql
   ))
   if(nrow(toImport)<=100){
      write.table(
         toImport,
         file=tf,
         sep=",", #"\t",
         quote=T,
         row.names=F, col.names=T
      )
      on.exit(file.remove(tf))
      toRet <- bedCall(cypher, query=cql, ...)
      invisible(toRet)
   }else{
      write.table(
         toImport[c(1:100), , drop=FALSE],
         file=tf,
         sep=",", #"\t",
         quote=T,
         row.names=F, col.names=T
      )
      on.exit(file.remove(tf))
      toRet <- bedCall(cypher, query=cql, ...)
      write.table(
         toImport[-c(1:100), , drop=FALSE],
         file=tf,
         sep=",", #"\t",
         quote=T,
         row.names=F, col.names=T
      )
      toRet <- c(toRet, bedCall(cypher, query=cql, ...))
      invisible(toRet)
   }
}
