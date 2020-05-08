#' Feeding BED: Load a probes platform
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param name the name of the platform
#' @param description a description of the platform
#' @param be the type of BE targeted by the platform
#'
loadPlf <- function(name, description, be){

    cql <- c(
        sprintf(
            'MATCH (bet:BEType {value:"%s"})',
            be
        ),
        sprintf(
            'MERGE (plf:Platform {name:"%s"})',
            name
        ),
        sprintf(
            'SET plf.description="%s"',
            description
        ),
        'MERGE (plf)-[:is_focused_on]->(bet)'
    )
    bedCall(f=neo2R::cypher, neo2R::prepCql(cql))

}

