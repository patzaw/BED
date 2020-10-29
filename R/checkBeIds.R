#' Check biological entities (BE) identifiers
#'
#' This function takes a vector of identifiers and verify if they can
#' be found in the provided source database according to the BE type and
#' the organism of interest. If an ID is in the DB but not linked directly nor
#' indirectly to any entity then it is considered as not found.
#'
#' @param ids a vector of identifiers to be checked
#' @param be biological entity. See [getBeIds]. **Guessed if not provided**
#' @param source source of the ids. See [getBeIds]. **Guessed if not provided**
#' @param organism the organism of interest. See [getBeIds].
#' **Guessed if not provided**
#' @param stopThr proportion of non-recognized IDs above which an error is
#' thrown. Default: 1 ==> no check
#' @param caseSensitive if FALSE (default) the case is not taken into account
#' when checking ids.
#'
#' @return invisible(TRUE). Stop if too many (see stopThr parameter) ids are not
#' found. Warning if any id is not found.
#'
#' @examples \dontrun{
#' checkBeIds(
#'    ids=c("10", "100"), be="Gene", source="EntrezGene", organism="human"
#' )
#' checkBeIds(
#'    ids=c("10", "100"), be="Gene", source="Ens_gene", organism="human"
#' )
#' }
#'
#' @seealso [getBeIds], [listBeIdSources], [getAllBeIdSources]
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
    ids <- as.character(ids)
    ##
    if(missing(be) || missing(source) || missing(organism)){
        toWarn <- TRUE
    }else{
        toWarn <- FALSE
    }
    guess <- guessIdScope(ids=ids, be=be, source=source, organism=organism)
    if(is.null(guess)){
        warning("Could not find the provided ids")
        if(missing(be) || missing(source) || missing(organism)){
            stop("Missing be, source or organism information")
        }
    }else{
        if(is.na(guess$be)){
            warning(
                "The provided ids does not match the provided scope",
                " (be, source or organism)"
            )
            if(missing(be) || missing(source) || missing(organism)){
                stop("Missing be, source or organism information")
            }
        }else{
            be <- guess$be
            source <- guess$source
            organism <- guess$organism
        }
    }
    if(toWarn){
        warning(
            "Guessing ID scope:",
            sprintf("\n   - be: %s", be),
            sprintf("\n   - source: %s", source),
            sprintf("\n   - organism: %s", organism)
        )
    }
    ##
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
