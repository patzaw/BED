#' Feeding BED: Load symbols associated to BEIDs
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with information about the symbols
#' to be loaded. It should contain the following fields: "id", "symbol"
#' and "canonical" (optional).
#' @param be a character corresponding to the BE type (default: "Gene")
#' @param dbname the DB of BEID
#'
loadBESymbols <- function(d, be="Gene", dbname){

    beid <- paste0(be, "ID")

    ##
    dColNames <- c("id", "symbol")
    if(any(!dColNames %in% colnames(d))){
        stop(paste(
            "The following columns are missing:",
            paste(setdiff(dColNames, colnames(d)), collapse=", ")
        ))
    }

    ################################################
    cql <- c(
        'MERGE (s:BESymbol {value:row.symbol, value_up:upper(row.symbol)})'
    )
    bedImport(cql, unique(d[,"symbol", drop=FALSE]))

    ################################################
    cql <- c(
       sprintf(
          'MATCH (beid:%s {value:row.id, database:"%s"}) USING INDEX beid:%s(value)',
          beid, dbname, beid
       ),
       'MATCH (s:BESymbol {value:row.symbol})',
       'MERGE (beid)-[r:is_known_as]->(s)'
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
