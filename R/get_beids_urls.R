#' Get a reference URL for a BE ID
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
#' get_beids_urls(c("100", "ENSG00000145335"), c("EntrezGene", "Ens_gene"))
#' }
#'
#' @export
#'
get_beids_urls <- function(ids, databases){
   stopifnot(
      length(databases)==1 | length(databases)==length(ids)
   )
   dbs <- bedCall(
      f=cypher,
      query=prepCql("MATCH (db:BEDB) RETURN db.name, db.idURL")
   )
   baseUrls <- dbs[match(databases, dbs$db.name), ]$"db.idURL"
   ifelse(
      !is.na(baseUrls),
      sprintf(baseUrls, ids),
      rep(NA, length(ids))
   )
}
