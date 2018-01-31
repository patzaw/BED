#' Check biological entities (BE) identifiers
#'
#' This function takes a vector of identifiers and verify if they can
#' be found in the provided source database according to the BE type and
#' the organism of interest. If an ID is in the DB but not linked directly nor
#' indirectly to any entity then it is considered as not found.
#'
#' @param ids a vector of identifiers to be checked
#' @param be biological entity. See \code{\link{getBeIds}}.
#' @param source source of the ids. See \code{\link{getBeIds}}.
#' @param organism the organism of interest. See \code{\link{getBeIds}}.
#' @param stopThr proportion of non-recognized IDs above which an error is
#' thrown. Default: 1 ==> no check
#' @param caseSensitive if FALSE (default) the case is not taken into account
#' when checking ids.
#'
#' @return invisible(TRUE). Stop if too many (see \code{stopThr}) ids are not
#' found. Warning if any id is not found.
#'
#' @examples \dontrun{
#' checkBeIds(ids=c("10", "100"), be="Gene", source="EntrezGene", organism="human")
#' checkBeIds(ids=c("10", "100"), be="Gene", source="Ens_gene", organism="human")
#' }
#'
#' @seealso \code{\link{getBeIds}}, \code{\link{listBeIdSources}},
#' \code{\link{getAllBeIdSources}}
#'
#' @export
#'
checkBeIds <- function(
    ids,
    be,
    source,
    organism,
    stopThr=1,
    caseSensitive=FALSE
){
    beInDb <- getBeIds(
        be=be,
        source=source,
        organism=organism,
        restricted=FALSE
    )
    if(is.null(beInDb)){
        stop("Could not find BE information")
    }
    #########
    ids <- unique(ids)
    lids <- length(ids)
    if(caseSensitive){
        notIn <- length(setdiff(ids, beInDb$id))
    }else{
        notIn <- length(setdiff(tolower(ids), tolower(beInDb$id)))
    }
    if(notIn > 0){
        warning("Could not find ", notIn, " IDs among ", lids, "!")
    }
    if((notIn/lids) > stopThr){
        stop("Too many missing IDs")
    }
    #########
    invisible(TRUE)
}
