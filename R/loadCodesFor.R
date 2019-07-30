#' Feeding BED: Load correspondance between genes and objects as coding events
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the coding events.
#' It should contain the following fields: "gid" and "oid"
#' @param gdb the DB of Gene IDs
#' @param odb the DB of Object IDs
#'
loadCodesFor <- function(
    d, gdb, odb
){

    ##
    dColNames <- c("gid", "oid")
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
            'MATCH (oid:ObjectID {value:row.oid, database:"%s"})',
            odb
        ),
        'USING INDEX oid:ObjectID(value)',
        "MERGE (gid)-[r:codes_for]->(oid)"
    )
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
          'MATCH (oid:ObjectID {value:row.oid, database:"%s"})',
          odb
       ),
       'USING INDEX oid:ObjectID(value)',
       'MATCH (oid)-[:is_associated_to*0..]->()',
       '-[:identifies]->(o:Object)',
       "MERGE (g)-[r2:codes_for]->(o)"
    )
    ##
    bedImport(cql, d)

}
