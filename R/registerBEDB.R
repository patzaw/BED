#' Feeding BED: Register a database of biological entities in BED DB
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param name of the database (e.g. "Ens_gene")
#' @param description a short description of the database (e.g. "Ensembl gene")
#' @param currentVersion the version taken into account in BED (e.g. 83)
#' @param idURL the URL template to use to retrieve id information. A '%s'
#' corresponding to the ID should be present in this character vector of
#' length one.
#'
registerBEDB <- function(
    name,
    description=NA,
    currentVersion=NA,
    idURL=NA
){
    cql <- c(
        sprintf(
            'MERGE (bedb:BEDB {name:"%s"})',
            name
        )
    )
    if(!is.na(description)){
        cql <- c(
            cql,
            sprintf(
                'SET bedb.description="%s"',
                description
            )
        )
    }
    if(!is.na(currentVersion)){
        cql <- c(
            cql,
            sprintf(
                'SET bedb.currentVersion="%s"',
                currentVersion
            )
        )
    }
    if(!is.na(idURL)){
        cql <- c(
            cql,
            sprintf(
                'SET bedb.idURL="%s"',
                idURL
            )
        )
    }
    bedCall(neo2R::cypher, neo2R::prepCql(cql))
}
