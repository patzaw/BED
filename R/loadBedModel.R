###############################################################################@
#' Feeding BED: Load BED data model in neo4j
#'
#' Not exported to avoid unintended modifications of the DB.
#'
loadBedModel <- function(){
    pkgname <- utils::packageName()
    ## Model
    cqlFile <- system.file(
        "Documentation", "BED-Model", "BED-model.cql",
        package=pkgname
    )
    queries <- neo2R::readCql(cqlFile)
    for(query in queries){
        bedCall(neo2R::cypher, query=query)
    }
    ## Entity types
    cqlFile <- system.file(
        "Documentation", "BED-Model", "BEType.cql",
        package=pkgname
    )
    queries <- neo2R::readCql(cqlFile)
    for(query in queries){
        bedCall(neo2R::cypher, query=query)
    }
    ##
    invisible(TRUE)
}

###############################################################################@
#' Feeding BED: Load additional indexes in neo4j
#'
#' Not exported to avoid unintended modifications of the DB.
#'
loadBedOtherIndexes <- function(){
    pkgname <- utils::packageName()
    ## Model
    cqlFile <- system.file(
        "Documentation", "BED-Model", "BED-other-indexes.cql",
        package=pkgname
    )
    queries <- neo2R::readCql(cqlFile)
    for(query in queries){
        bedCall(neo2R::cypher, query=query)
    }
    ##
    invisible(TRUE)
}
