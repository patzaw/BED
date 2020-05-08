#' Identify the biological entity (BE) targeted by probes and
#' construct the CQL sub-query to map probes to the BE
#'
#' Internal use
#'
#' @param platform the platform of the probes
#'
#' @return A character value corresponding to the sub-query.
#' The `attr(,"be")` correspond to the BE targeted by probes
#'
#' @seealso [genBePath], [listPlatforms]
#'
genProbePath <- function(platform){
    be <- getTargetedBe(platform)
    beid <- paste0(be, "ID")
    qs <- sprintf(
        '-[:targets]->(:%s)-[:is_replaced_by|is_associated_to*0..]->()-[:identifies]->',
        beid
    )
    attr(qs, "be") <- be
    return(qs)
}
