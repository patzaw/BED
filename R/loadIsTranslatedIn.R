#' Feeding BED: Load correspondance between transcripts and peptides as
#' translation events
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the translation events.
#' It should contain the following fields: "tid", "pid"
#' and "canonical" (optional).
#' @param tdb the DB of Transcript IDs
#' @param pdb the DB of Peptide IDs
#'
loadIsTranslatedIn <- function(d, tdb, pdb){

   ##
   dColNames <- c("tid", "pid")
   if(any(!dColNames %in% colnames(d))){
      stop(paste(
         "The following columns are missing:",
         paste(setdiff(dColNames, colnames(d)), collapse=", ")
      ))
   }

   ################################################
   cql <- c(
      sprintf(
         'MATCH (tid:TranscriptID {value:row.tid, database:"%s"})',
         tdb
      ),
      '-[:is_replaced_by|is_associated_to*0..]->()',
      '-[:identifies]->(t:Transcript)',
      sprintf(
         'MATCH (pid:PeptideID {value:row.pid, database:"%s"})',
         pdb
      ),
      '-[:is_replaced_by|is_associated_to*0..]->()',
      '-[:identifies]->(p:Peptide)',
      "MERGE (tid)-[r:is_translated_in]->(pid)",
      "MERGE (t)-[r2:is_translated_in]->(p)"
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
      #     cql,
      #     sprintf(
      #         'ON CREATE SET r2.canonical=%s',
      #         canStr
      #     ),
      #     sprintf(
      #         ', r.canonical=%s',
      #         canStr
      #     ),
      #     sprintf(
      #         'ON MATCH SET r2.canonical=%s',
      #         '(case row.canonical when "TRUE" then true else r2.canonical end)'
      #     ),
      #     sprintf(
      #         ', r.canonical=%s',
      #         canStr
      #     )
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
