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
      '-[:is_replaced_by|is_associated_to*0..]->()',
      '-[:identifies]->(g:Gene)',
      sprintf(
         'MATCH (tid:TranscriptID {value:row.tid, database:"%s"})',
         tdb
      ),
      '-[:is_replaced_by|is_associated_to*0..]->()',
      '-[:identifies]->(t:Transcript)',
      "MERGE (gid)-[r:is_expressed_as]->(tid)",
      "MERGE (g)-[r2:is_expressed_as]->(t)"
   )
   if("canonical" %in% colnames(d)){
      canStr <- '(case row.canonical when "TRUE" then true else false end)'
      cql <- c(
         cql,
         sprintf(
            'SET r.canonical=%s',
            canStr
         )
      )
      # cql <- c(
      #    cql,
      #    sprintf(
      #       'ON CREATE SET r.canonical=%s',
      #       canStr
      #    ),
      #    # sprintf(
      #    #     ', r2.canonical=%s',
      #    #     canStr
      #    # ),
      #    sprintf(
      #       'ON MATCH SET r.canonical=%s',
      #       canStr
      #    )
      #    # sprintf(
      #    #     ', r2.canonical=%s',
      #    #     '(case row.canonical when "TRUE" then true else r2.canonical end)'
      #    # )
      # )
   }else{
      cql <- c(
         cql,
         'ON CREATE SET r.canonical=false'
         # 'ON CREATE SET r2.canonical=false'
      )
   }
   ##
   bedImport(cql, d)

}
