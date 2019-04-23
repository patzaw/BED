#' Feeding BED: Load names associated to BEIDs
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the names
#' to be loaded. It should contain the following fields: "id", "name".
#' @param be a character corresponding to the BE type (default: "Gene")
#' @param dbname the DB of BEID
#'
loadBENames <- function(d, be="Gene", dbname){

    beid <- paste0(be, "ID")

    ##
    dColNames <- c("id", "name")
    if(any(!dColNames %in% colnames(d))){
        stop(paste(
            "The following columns are missing:",
            paste(setdiff(dColNames, colnames(d)), collapse=", ")
        ))
    }

    ################################################
    cql <- c(
        'MERGE (n:BEName {value:row.name, value_up:upper(row.name)})'
    )
    bedImport(cql, unique(d[,"name", drop=FALSE]))

    ################################################
    cql <- c(
       sprintf(
          'MATCH (beid:%s {value:row.id, database:"%s"}) USING INDEX beid:%s(value)',
          beid, dbname, beid
       ),
       'MATCH (n:BEName {value:row.name})',
       'MERGE (beid)-[:is_named]->(n)'
    )
    bedImport(cql, d)

}
