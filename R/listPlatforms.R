#' Lists all the probe platforms available in the BED database
#'
#' @param be a character vector of BE on which to focus.
#' if NA (default) all the BE are considered.
#'
#' @return A data.frame mapping platforms to BE with the following fields:
#' \describe{
#'  \item{name}{the platform nam}
#'  \item{description}{platform description}
#'  \item{focus}{Targeted BE}
#' }
#'
#' @examples \dontrun{
#' listPlatforms(be="Gene")
#' listPlatforms()
#' }
#'
#' @seealso \code{\link{listBe}}, \code{\link{listBeIdSources}},
#' \code{\link{listOrganisms}}, \code{\link{getTargetedBe}}
#'
#' @importFrom neo2R prepCql cypher
#' @export
#'
listPlatforms <- function(be=c(NA, listBe())){
    be <- match.arg(be)
    cql <- 'MATCH (p:Platform)-[:is_focused_on]->(be:BEType)'
    if(!is.na(be)){
        cql <- c(
            cql,
            sprintf(
                'WHERE be.value IN $bes'
            )
        )
    }
    cql <- c(
        cql,
        'RETURN p.name as name, p.description as description, be.value as focus'
    )
    toRet <- bedCall(
        cypher,
        query=prepCql(cql),
        parameters=list(bes=as.list(as.character(be)))
    )
    rownames(toRet) <- toRet$name
    return(toRet)
}
