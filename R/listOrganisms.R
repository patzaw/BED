#' Lists all the organisms available in the BED database
#'
#' @return A character vector of organism scientific names
#'
#' @seealso [listPlatforms], [listBeIdSources],
#' [listBe], [getTaxId], [getOrgNames]
#'
#' @export
#'
listOrganisms <- function(){
    cql <- c(
        'MATCH (t)-[:is_named {nameClass:"scientific name"}]->(o:OrganismName)',
        'RETURN DISTINCT o.value as name'
    )
    toRet <- bedCall(neo2R::cypher, neo2R::prepCql(cql))
    return(toRet$name)
}
