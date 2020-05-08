#' Identify the biological entity (BE) targeted by probes
#'
#' @param platform the platform of the probes
#'
#' @return The BE targeted by the platform
#'
#' @examples \dontrun{
#' getTargetedBe("GPL570")
#' }
#'
#' @seealso [listPlatforms]
#'
#' @export
#'
getTargetedBe <- function(platform){
    if(!is.atomic(platform) || length(platform)!=1){
        stop("platform should be a character vector of length 1")
    }
    cqRes <- bedCall(
        neo2R::cypher,
        query=neo2R::prepCql(c(
            'MATCH (pl:Platform {name:$platform})',
            '-[:is_focused_on]->(bet:BEType)',
            'RETURN bet.value'
        )),
        parameters=list(platform=as.character(platform))
    )
    if(is.null(cqRes)){
        stop("platform not found.")
    }
    return(cqRes$bet.value)
}
