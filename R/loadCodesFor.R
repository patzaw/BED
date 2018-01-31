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
        '-[:is_replaced_by|is_associated_to*0..]->()',
        '-[:identifies]->(g:Gene)',
        sprintf(
            'MATCH (oid:ObjectID {value:row.oid, database:"%s"})',
            odb
        ),
        '-[:is_replaced_by|is_associated_to*0..]->()',
        '-[:identifies]->(o:Object)',
        "MERGE (gid)-[r:codes_for]->(oid)",
        "MERGE (g)-[r2:codes_for]->(o)"
    )
    ##
    bedImport(cql, d)

}
