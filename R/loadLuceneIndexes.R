#' Feeding BED: Create Lucene indexes in neo4j
#'
#' Not exported to avoid unintended modifications of the DB.
#'
loadLuceneIndexes <- function(){
    pkgname <- utils::packageName()
    ## Indexes
    cqlFile <- system.file(
        "Documentation", "BED-Model", "BED-lucene.cql",
        package=pkgname
    )
    queries <- neo2R::readCql(cqlFile)
    for(query in queries){
        bedCall(neo2R::cypher, query=query)
    }
    ##
    invisible(TRUE)
}
