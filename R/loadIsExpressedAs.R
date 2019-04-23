#' Feeding BED: Load correspondance between genes and transcripts as
#' expression events
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the expression events.
#' It should contain the following fields: "gid", "tid"
#' and "canonical" (optional).
#' @param gdb the DB of Gene IDs
#' @param tdb the DB of Transcript IDs
#'
loadIsExpressedAs <- function(d, gdb, tdb){

   ##
   dColNames <- c("gid", "tid")
   if(any(!dColNames %in% colnames(d))){
      stop(paste(
         "The following columns are missing:",
         paste(setdiff(dColNames, colnames(d)), collapse=", ")
      ))
   }

   ################################################
   cql <- c(
      sprintf(
         'MATCH (gid:GeneID {value:row.gid, database:"%s"})',
         gdb
      ),
      'USING INDEX gid:GeneID(value)',
      sprintf(
         'MATCH (tid:TranscriptID {value:row.tid, database:"%s"})',
         tdb
      ),
      'USING INDEX tid:TranscriptID(value)',
      "MERGE (gid)-[r:is_expressed_as]->(tid)"
   )
   if("canonical" %in% colnames(d)){
      canStr <- '(case row.canonical when "TRUE" then true else false end)'
      cql <- c(
         cql,
         sprintf(
            'ON CREATE SET r.canonical=%s',
            canStr
         )
      )
   }else{
      cql <- c(
         cql,
         'ON CREATE SET r.canonical=false'
      )
   }
   ##
   bedImport(cql, d)

   ################################################
   cql <- c(
      sprintf(
         'MATCH (gid:GeneID {value:row.gid, database:"%s"})',
         gdb
      ),
      'USING INDEX gid:GeneID(value)',
      'MATCH (gid)-[:is_associated_to*0..]->()',
      '-[:identifies]->(g:Gene)',
      sprintf(
         'MATCH (tid:TranscriptID {value:row.tid, database:"%s"})',
         tdb
      ),
      'USING INDEX tid:TranscriptID(value)',
      'MATCH (tid)-[:is_associated_to*0..]->()',
      '-[:identifies]->(t:Transcript)',
      "MERGE (g)-[r2:is_expressed_as]->(t)"
   )
   ##
   bedImport(cql, d)

}
