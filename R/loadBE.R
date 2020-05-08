#' Feeding BED: Load biological entities in BED
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the entities to be loaded.
#' It should contain the following fields: "id".
#' If there is a boolean column named "preferred", the value is loaded.
#' @param be a character corresponding to the BE type (default: "Gene")
#' @param dbname the DB from which the BE ID are taken
#' @param version the version of the DB from which the BE IDs are taken
#' @param deprecated NA (default) or the date when the ID was deprecated
#' @param taxId the taxonomy ID of the BE organism
#' @param onlyId a logical. If TRUE, only an BEID is created and not the
#' corresponding BE.
#'
loadBE <- function(
   d,
   be="Gene",
   dbname,
   version=NA,
   deprecated=NA,
   taxId=NA,
   onlyId=FALSE
){

   beid <- paste0(be, "ID")

   ##
   dColNames <- c("id")
   if(any(!dColNames %in% colnames(d))){
      stop(paste(
         "The following columns are missing:",
         paste(setdiff(dColNames, colnames(d)), collapse=", ")
      ))
   }

   ##
   prefInfo <- "preferred" %in% colnames(d)
   if(prefInfo){
      toImport <- unique(d[, c("id", "preferred"), drop=F])
      if(!inherits(d$preferred, "logical") || any(is.na(d$preferred))){
         stop("preferred column should be logical values without any NA")
      }
      if(length(unique(d$id)) != nrow(d)){
         stop("Each id should have only one preferred value")
      }
   }else{
      toImport <- unique(d[, "id", drop=F])
   }

   ################################################
   ## Add IDs
   if(prefInfo){
      cql <- sprintf(
         'MERGE (beid:%s:BEID {value: row.id, database:$db})',
         beid
      )
      prefStr <- '(case row.preferred when "TRUE" then true else false end)'
      cql <- c(
         cql,
         sprintf(
            'ON CREATE SET beid.preferred=%s',
            prefStr
         ),
         sprintf(
            'ON MATCH SET beid.preferred=%s',
            prefStr
         )
      )
   }else{
      cql <- c(
         sprintf(
            'MERGE (beid:%s:BEID {value: row.id, database:$db})',
            beid
         ),
         'ON CREATE SET beid.preferred=false'
      )
   }
   ##
   bedImport(cql, toImport, parameters=list(db=dbname))

   if(!onlyId){
      cql <- c(
         sprintf(
            'MATCH (beid:%s {value: row.id, database:$db})',
            beid
         ),
         sprintf(
            'USING INDEX beid:%s(value)',
            beid
         ),
         sprintf(
            'MERGE (beid)-[:identifies]->(be:%s)',
            be
         )
      )
      ##
      bedImport(cql, toImport, parameters=list(db=dbname))
   }

   #########################
   ## Database and organism
   if(inherits(deprecated, "Date")){
      depStr <- paste0('"', format(deprecated, "%Y%m%d"), '"')
   }else{
      if(!is.na(deprecated)){
         stop("Provide a date for deprecation")
      }else{
         depStr <- "false"
      }
   }
   dbcql <- '(db:BEDB{name:$db})'
   if(!is.na(version)){
      cql <- c('MERGE', dbcql)
      ##
      bedCall(neo2R::cypher, neo2R::prepCql(cql), parameters=list(db=dbname))

      cql <- c(
         sprintf(
            'MATCH (beid:%s {value: row.id, database:$db})',
            beid
         ),
         sprintf(
            'USING INDEX beid:%s(value)',
            beid
         ),
         'MATCH', dbcql,
         'MERGE (beid)',
         sprintf(
            '-[:is_recorded_in {version:"%s", deprecated:%s}]->',
            version, depStr
         ),
         '(db)'
      )
      ##
      bedImport(cql, toImport, parameters=list(db=dbname))

   }else{
      if(!is.na(deprecated)){
         cql <- c('MERGE', dbcql)
         ##
         bedCall(neo2R::cypher, neo2R::prepCql(cql), parameters=list(db=dbname))

         cql <- c(
            sprintf(
               'MATCH (beid:%s {value: row.id, database:$db})',
               beid
            ),
            sprintf(
               'USING INDEX beid:%s(value)',
               beid
            ),
            'MATCH', dbcql,
            'MERGE (beid)',
            sprintf(
               '-[:is_recorded_in {deprecated:%s}]->',
               depStr
            ),
            '(db)'
         )
         ##
         bedImport(cql, toImport, parameters=list(db=dbname))

      }
   }
   if(!is.na(taxId)){
      orgcql <- sprintf(
         '(o:TaxID {value:"%s"})',
         taxId
      )
      cql <- c('MERGE', orgcql)
      ##
      bedCall(neo2R::cypher, neo2R::prepCql(cql), parameters=list(db=dbname))

      if(be=="Gene"){
         cql <- c(
            sprintf(
               'MATCH (beid:%s {value: row.id, database:$db})',
               beid
            ),
            sprintf(
               'USING INDEX beid:%s(value)',
               beid
            ),
            'MATCH (beid)-[:identifies]->(be)',
            'MATCH', orgcql,
            'MERGE (be)-[:belongs_to]->(o)'
         )
      }
      ##
      bedImport(cql, toImport, parameters=list(db=dbname))

   }

}
