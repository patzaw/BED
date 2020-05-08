#' Get organism names from taxonomy IDs
#'
#' @param taxID a vector of taxonomy IDs. If NULL (default) the function lists
#' all taxonomy IDs available in the DB.
#'
#' @return A data.frame mapping taxonomy IDs to organism names with the
#' following fields:
#'
#'  - **taxID**: the taxonomy ID
#'  - **name**: the organism name
#'  - **nameClass**: the class of the name
#'
#' @examples \dontrun{
#' getOrgNames(c("9606", "10090"))
#' getOrgNames("9606")
#' }
#'
#' @seealso [getTaxId], [listOrganisms]
#'
#' @export
#'
getOrgNames <- function(taxID=NULL){
    if(!is.null(taxID) && !is.atomic(taxID)){
        stop("taxID should be NULL or a character vector")
    }
    ##
    if(is.null(taxID)){
        cql <- 'MATCH (tid:TaxID)-[r:is_named]->(on:OrganismName)'
    }else{
        cql <- c(
            'MATCH (tid:TaxID)-[r:is_named]->(on:OrganismName)',
            'WHERE tid.value IN $tid'
        )
    }
    cql <- c(
        cql,
        'RETURN tid.value as taxID, on.value as name, r.nameClass as nameClass',
        'ORDER BY taxID, nameClass'
    )
    toRet <- unique(bedCall(
        neo2R::cypher,
        query=neo2R::prepCql(cql),
        parameters=list(tid=as.list(as.character(taxID)))
    ))
    return(toRet)
}
