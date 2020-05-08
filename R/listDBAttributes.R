#' List all attributes provided by a BEDB
#'
#' @param dbname the name of the database
#'
#' @return A character vector of attribute names
#'
#' @export
#'
listDBAttributes <- function(dbname){
   if(length(dbname)!=1){
      stop("dbname should be a character vector of lenght 1")
   }
   bedCall(
      neo2R::cypher,
      query=neo2R::prepCql(c(
         'MATCH (db:BEDB {name:$dbname})-[:provides]->(at:Attribute)',
         'RETURN DISTINCT at.name'
      )),
      parameters=list(
         dbname=as.character(dbname)
      )
   )$at.name
}
