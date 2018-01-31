#' Feeding BED: Load BED data model in neo4j
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @importFrom utils packageName
#' @importFrom neo2R readCql
#'
loadBedModel <- function(){
    pkgname <- packageName()
    ## Model
    cqlFile <- system.file(
        "Documentation", "BED-Model", "BED-model.cql",
        package=pkgname
    )
    queries <- readCql(cqlFile)
    for(query in queries){
        bedCall(cypher, query=query)
    }
    ## Entity types
    cqlFile <- system.file(
        "Documentation", "BED-Model", "BEType.cql",
        package=pkgname
    )
    queries <- readCql(cqlFile)
    for(query in queries){
        bedCall(cypher, query=query)
    }
    ##
    invisible(TRUE)
}

######################################################

#' Feeding BED: Load additional indexes in neo4j
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @importFrom utils packageName
#' @importFrom neo2R readCql
#'
loadBedOtherIndexes <- function(){
    pkgname <- packageName()
    ## Model
    cqlFile <- system.file(
        "Documentation", "BED-Model", "BED-other-indexes.cql",
        package=pkgname
    )
    queries <- readCql(cqlFile)
    for(query in queries){
        bedCall(cypher, query=query)
    }
    ##
    invisible(TRUE)
}
