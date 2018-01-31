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
      prefStr <- '(case row.preferred when "TRUE" then true else false end)'
      cql <- sprintf(
         'MERGE (beid:BEID:%s {value: row.id, database: "%s"}) SET beid.preferred=%s',
         beid, dbname, prefStr
      )
   }else{
      cql <- sprintf(
         'MERGE (beid:BEID:%s {value: row.id, database: "%s"}) ON CREATE SET beid.preferred=false',
         beid, dbname
      )
   }
   withStr <- 'WITH beid'
   if(!onlyId){
      cql <- c(
         cql,
         sprintf(
            'MERGE (beid)-[:identifies]->(be:%s)',
            be
         )
      )
      withStr <- paste0(withStr, ', be')
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
   dbcql <- sprintf(
      '(db:BEDB{name: "%s"})',
      dbname
   )
   if(!is.na(version)){
      cql <- c(
         cql, withStr,
         'MERGE', dbcql,
         'CREATE UNIQUE (beid)',
         sprintf(
            '-[:is_recorded_in {version:"%s", deprecated:%s}]->',
            version, depStr
         ),
         '(db)'
      )
   }else{
      if(!is.na(deprecated)){
         cql <- c(
            cql, withStr,
            'MERGE', dbcql,
            'CREATE UNIQUE (beid)',
            sprintf(
               '-[:is_recorded_in {deprecated:%s}]->',
               depStr
            ),
            '(db)'
         )
      }
   }
   if(!is.na(taxId)){
      orgcql <- sprintf(
         '(o:TaxID {value:"%s"})',
         taxId
      )
      cql <- c(
         cql, withStr,
         'MERGE', orgcql
      )
      if(be=="Gene"){
         cql <- c(
            cql,
            'CREATE UNIQUE (be)-[:belongs_to]->(o)'
         )
      }
   }

   #########################
   bedImport(cql, toImport)

}
