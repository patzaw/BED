#' Lists all the organisms available in the BED database
#'
#' @return A character vector of organism scientific names
#'
#' @seealso \code{\link{listPlatforms}}, \code{\link{listBeIdSources}},
#' \code{\link{listBe}}, \code{\link{getTaxId}}, \code{\link{getOrgNames}}
#'
#' @importFrom neo2R prepCql cypher
#' @export
#'
listOrganisms <- function(){
    cql <- c(
        'MATCH (t)-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
        'RETURN DISTINCT o.value as name'
    )
    toRet <- bedCall(cypher, prepCql(cql))
    return(toRet$name)
}
