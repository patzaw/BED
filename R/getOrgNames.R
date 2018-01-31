#' Get organism names from taxonomy IDs
#'
#' @param taxID a vector of taxonomy IDs. If NULL (default) the function lists
#' all taxonomy IDs available in the DB.
#'
#' @return A data.frame mapping taxonomy IDs to organism names with the
#' following fields:
#' \describe{
#'  \item{taxID}{the taxonomy ID}
#'  \item{name}{the organism name}
#'  \item{nameClass}{the class of the name}
#' }
#'
#' @examples \dontrun{
#' getOrgNames(c("9606", "10090"))
#' getOrgNames("9606")
#' }
#'
#' @seealso \code{\link{getTaxId}}, \code{\link{listOrganisms}}
#'
#' @importFrom neo2R prepCql cypher
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
        cypher,
        query=prepCql(cql),
        parameters=list(tid=as.list(as.character(taxID)))
    ))
    return(toRet)
}
