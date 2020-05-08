#' Get taxonomy ID of an organism name
#'
#' @param  name the name of the organism
#'
#' @return A vector of taxonomy ID
#'
#' @examples \dontrun{
#' getTaxId("human")
#' }
#'
#' @seealso [getOrgNames], [listOrganisms]
#'
#' @export
#'
getTaxId <- function(name){
    if(!is.atomic(name) || length(name)!=1){
        stop("name should be a character vector of length one")
    }
    cql <- c(
        'MATCH (tid:TaxID)-[:is_named]->(on:OrganismName)',
        'WHERE on.value_up=$name',
        'RETURN DISTINCT tid.value'
    )
    toRet <- bedCall(
        neo2R::cypher,
        query=neo2R::prepCql(cql),
        parameters=list(name=toupper(name))
    )$tid.value
    return(toRet)
}
