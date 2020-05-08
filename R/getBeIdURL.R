#' Get reference URLs for BE IDs
#'
#' @param ids the BE ID
#' @param databases the databases from which each ID has been taken
#' (if only one database is provided it is chosen for all ids)
#'
#' @return A character vector of the same length than ids
#' corresponding to the relevant URLs.
#' NA is returned is there is no URL corresponding to the provided database.
#'
#' @examples \dontrun{
#' getBeIdURL(c("100", "ENSG00000145335"), c("EntrezGene", "Ens_gene"))
#' }
#'
#' @export
#'
getBeIdURL <- function(ids, databases){
    stopifnot(
        length(databases)==1 | length(databases)==length(ids)
    )
    dbs <- bedCall(
        f=neo2R::cypher,
        query=neo2R::prepCql("MATCH (db:BEDB) RETURN db.name, db.idURL")
    )
    baseUrls <- dbs[match(databases, dbs$db.name), ]$"db.idURL"
    if(length(databases)==1){
        baseUrls <- rep(baseUrls, length(ids))
    }
    ifelse(
        !is.na(baseUrls),
        sprintf(baseUrls, ids),
        rep(NA, length(ids))
    )
}
