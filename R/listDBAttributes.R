#' List all attributes provided by a BEDB
#'
#' @param dbname the name of the database
#'
#' @return A character vector of attribute names
#'
#' @importFrom neo2R prepCql cypher
#' @export
#'
listDBAttributes <- function(dbname){
   if(length(dbname)!=1){
      stop("dbname should be a character vector of lenght 1")
   }
   bedCall(
      cypher,
      query=prepCql(c(
         'MATCH (db:BEDB {name:$dbname})-[:provides]->(at:Attribute)',
         'RETURN DISTINCT at.name'
      )),
      parameters=list(
         dbname=as.character(dbname)
      )
   )$at.name
}
