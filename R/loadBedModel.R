###############################################################################@
#' Feeding BED: Load BED data model in neo4j
#'
#' Not exported to avoid unintended modifications of the DB.
#'
loadBedModel <- function(){
    pkgname <- utils::packageName()
    nmv <- bedEnv$graph$version[1]
    if(nmv == "3"){
       mfile <- "BED-model-v3.cql"
    }
    if(nmv == "5"){
       mfile <- "BED-model-v5.cql"
    }
    ## Model
    cqlFile <- system.file(
        "Documentation", "BED-Model",
        mfile,
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
