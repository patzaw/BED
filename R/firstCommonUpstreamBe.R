#' First common upstream BE
#'
#' Returns the first common Biological Entity (BE) upstream a set of BE.
#'
#' This function is used to identified the level at which different BE should be
#' compared. Peptides and transcripts should be compared at the level of
#' transcripts whereas transcripts and objects should be compared at the
#' level of genes. BE from different organism should be compared at the level
#' of genes using homologs.
#'
#' @param beList a character vector containing BE
#' @param uniqueOrg a logical value indicating if as single organism is under
#' focus. If false "Gene" is returned.
#'
#' @examples \dontrun{
#' firstCommonUpstreamBe(c("Object", "Transcript"))
#' firstCommonUpstreamBe(c("Peptide", "Transcript"))
#' firstCommonUpstreamBe(c("Peptide", "Transcript"), uniqueOrg=FALSE)
#' }
#'
#' @seealso [listBe]
#'
#' @export
#'
firstCommonUpstreamBe <- function(beList=listBe(), uniqueOrg=TRUE){
    if(!is.logical(uniqueOrg)){
        stop("uniqueOrg should be a logical")
    }
    if(!is.atomic(beList) || length(beList)==0){
        stop("beList should be a non-empty character vector")
    }
    ##
    if(!uniqueOrg){
        return("Gene")
    }
    checkedBe <- match.arg(beList, several.ok=TRUE)
    notFound <- setdiff(beList, checkedBe)
    if(length(notFound)>0){
        stop(paste(
            "Could not find the following entities among possible BE:",
            paste(notFound, collapse=", "),
            "\nPossible BE: ", paste(listBe(), collapse=", ")
        ))
    }
    if(length(beList)==1){
        return(beList)
    }else{
        cql <- 'MATCH (o:BEType)'
        cid <- 0
        for(be in beList){
            cid <- cid+1
            cql <- c(
                cql,
                sprintf(
                    'MATCH (%s:BEType {value:"%s"})',
                    paste0("be", cid), be
                ),
                sprintf(
                    'MATCH (o)-[:produces*0..]->(%s)',
                    paste0("be", cid)
                )
            )
        }
        cql <- c(
            cql,
            'WITH o, be1',
            'MATCH p=shortestPath((o)-[:produces*0..]->(be1))',
            'RETURN o.value as be, length(p) as lp',
            'ORDER BY lp'
        )
        cqRes <- bedCall(
            neo2R::cypher,
            query=neo2R::prepCql(cql)
        )
        return(cqRes[1,1])
    }
}
