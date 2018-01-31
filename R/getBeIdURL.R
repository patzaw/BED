#' Get a reference URL for a BE ID
#'
#' @param id the BE ID
#' @param database the database from which the ID has been taken
#'
#' @return A character vector of length one corresponding to the relevant URL.
#' NA is returned is there is no URL corresponding to the provided database.
#'
#' @examples \dontrun{
#' getBeIdURL("100", "EntrezGene")
#' }
#'
#' @importFrom neo2R prepCql cypher
#' @export
#'
getBeIdURL <- function(id, database){
    dbs=bedCall(
        f=cypher,
        query=prepCql("MATCH (db:BEDB) RETURN db.name, db.idURL")
    )
    rownames(dbs) <- dbs$db.name
    baseUrl <- dbs[database, "db.idURL"]
    if(!is.na(baseUrl)){
        return(sprintf(baseUrl, id))
    }else{
        return(rep(NA, length(id)))
    }
}
