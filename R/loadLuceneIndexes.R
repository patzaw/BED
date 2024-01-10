#' Feeding BED: Create Lucene indexes in neo4j
#'
#' Not exported to avoid unintended modifications of the DB.
#'
loadLuceneIndexes <- function(){
    pkgname <- utils::packageName()
    nmv <- bedEnv$graph$version[1]
    if(nmv == "3"){
       mfile <- "BED-lucene-v3.cql"
    }
    if(nmv == "5"){
       mfile <- "BED-lucene-v5.cql"
    }
    ## Indexes
    cqlFile <- system.file(
        "Documentation", "BED-Model", mfile,
        package=pkgname
    )
    queries <- neo2R::readCql(cqlFile)
    for(query in queries){
        bedCall(neo2R::cypher, query=query)
    }
    ##
    invisible(TRUE)
}
