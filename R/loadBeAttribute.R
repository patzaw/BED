#' Feeding BED: Load attributes for biological entities in BED
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame providing for each BE ID ("id" column) an attribute
#' value ("value" column). There can be several values for each id.
#' @param be a character corresponding to the BE type (default: "Gene")
#' @param dbname the DB from which the BE ID are taken
#' @param attribute the name of the attribute to be loaded
#'
loadBeAttribute <- function(
   d,
   be="Gene",
   dbname,
   attribute
){

   beid <- paste0(be, "ID")

   ##
   dColNames <- c("id", "value")
   if(any(!dColNames %in% colnames(d))){
      stop(paste(
         "The following columns are missing:",
         paste(setdiff(dColNames, colnames(d)), collapse=", ")
      ))
   }

   ##
   if(any(is.na(d$value))){
      stop("NA value not allowed")
   }

   ## Associate attribute to DB
   cql <- c(
      sprintf(
         'MATCH (db:BEDB {name: "%s"})',
         dbname
      ),
      sprintf(
         'MERGE (at:Attribute {name: "%s"})',
         attribute
      ),
      'MERGE (db)-[:provides]->(at)'
   )
   bedCall(neo2R::cypher, query=neo2R::prepCql(cql))

   ########################
   ## Load attribute values
   toImport <- unique(d[,c("id", "value"), drop=FALSE])
   cql <- c(
      sprintf(
         'MATCH (beid:%s {value:row.id, database:"%s"})',
         beid, dbname
      ),
      sprintf(
         'USING INDEX beid:%s(value)',
         beid
      ),
      sprintf(
         'MATCH (at:Attribute {name: "%s"})',
         attribute
      ),
      'MERGE (beid)-[:has {value:row.value}]->(at)'
   )
   bedImport(cql, toImport)


}
