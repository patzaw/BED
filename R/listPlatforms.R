#' Lists all the probe platforms available in the BED database
#'
#' @param be a character vector of BE on which to focus.
#' if NA (default) all the BE are considered.
#'
#' @return A data.frame mapping platforms to BE with the following fields:
#'
#'  - **name**: the platform nam
#'  - **description**: platform description
#'  - **focus**: Targeted BE
#'
#' @examples \dontrun{
#' listPlatforms(be="Gene")
#' listPlatforms()
#' }
#'
#' @seealso [listBe], [listBeIdSources],
#' [listOrganisms], [getTargetedBe]
#'
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
        neo2R::cypher,
        query=neo2R::prepCql(cql),
        parameters=list(bes=as.list(as.character(be)))
    )
    rownames(toRet) <- toRet$name
    return(toRet)
}
