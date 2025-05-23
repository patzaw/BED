#' Feeding BED: Load names associated to BEIDs
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the names
#' to be loaded. It should contain the following fields: "id", "name"
#' and "canonical" (optional).
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
        sprintf(
           'MERGE (n:BEName {value:row.name, value_up:%s(row.name)})',
           bedEnv$neo4j_syntax$upper
        )
    )
    bedImport(cql, unique(d[,"name", drop=FALSE]))

    ################################################
    cql <- c(
       sprintf(
          'MATCH (beid:%s {value:row.id, database:"%s"}) USING INDEX beid:%s(value)',
          beid, dbname, beid
       ),
       'MATCH (n:BEName {value:row.name})',
       'MERGE (beid)-[r:is_named]->(n)'
    )
    if("canonical" %in% colnames(d)){
       cql <- c(
          cql,
          sprintf(
             'SET r.canonical=%s',
             '(case row.canonical when "TRUE" then true else false end)'
          )
       )
    }else{
       cql <- c(
          cql,
          'ON CREATE SET r.canonical=false'
       )
    }
    bedImport(cql, d)

}
