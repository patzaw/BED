#' Feeding BED: Imports a data.frame in the BED graph database
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param cql the CQL query to be applied on each row of toImport
#' @param toImport the data.frame to be imported as "row".
#' Use "row.FIELD" in the cql query to refer to one FIELD of the toImport
#' data.frame
#' @param periodicCommit use periodic commit when loading the data
#' (default: 1000).
#' @param ... additional parameters for [bedCall]
#'
#' @return the results of the query
#'
#' @seealso [bedCall], [neo2R::import_from_df]
#'
bedImport <- function(
   cql, toImport, periodicCommit=10000, ...
){
   invisible(bedCall(
      neo2R::import_from_df,
      cql=cql, toImport=toImport,
      periodicCommit=periodicCommit,
      ...
   ))
}
