#' Autoselect source of biological entity identifiers
#'
#' The selection is based on direct identifiers
#'
#' @param be the biological entity under focus
#' @param organism the organism under focus
#' @param rel a type of relationship to consider in the query
#' (e.g. "is_member_of") in order to focus on specific information.
#' If NA (default) all be are taken into account whatever their available
#' relationships.
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also taken
#' into account.
#' @param exclude database to exclude from possible selection. Used to filter
#' out technical database names such as "BEDTech_gene" and "BEDTech_transcript"
#' used to manage orphan IDs (not linked to any gene based on information
#' taken from sources)
#'
#' @return The name of the selected source. The selected source will be the one
#' providing the largest number of current identifiers.
#'
#' @examples \dontrun{
#' largestBeSource(be="Gene", "Mus musculus")
#' }
#'
#' @seealso [listBeIdSources]
#'
#' @export
#'
largestBeSource <- function(
    be, organism, rel=NA, restricted=TRUE,
    exclude=c("BEDTech_gene", "BEDTech_transcript")
){
    dbList <- listBeIdSources(
        be=be, organism=organism, rel=rel,
        direct=TRUE, restricted=restricted,
        exclude=exclude
    )
    return(dbList[which.max(dbList$nbBe), "database"])
}
