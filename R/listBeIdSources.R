#' Lists all the databases taken into account in the BED database
#' for a biological entity (BE)
#'
#' @param be the BE on which to focus
#' @param organism the name of the organism to focus on.
#' @param direct a logical value indicating if only "direct" BE identifiers
#' should be considered
#' @param rel a type of relationship to consider in the query
#' (e.g. "is_member_of") in order to focus on specific information.
#' If NA (default) all be are taken into account whatever their available
#' relationships.
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also returned.
#' There is no impact if direct is set to TRUE.
#' @param recache boolean indicating if the CQL query should be run even if
#' the table is already in cache
#' @param verbose boolean indicating if the CQL query should be shown.
#' @param exclude database to exclude from possible selection. Used to filter
#' out technical database names such as "BEDTech_gene" and "BEDTech_transcript"
#' used to manage orphan IDs (not linked to any gene based on information
#' taken from sources)
#'
#' @return A data.frame indicating the number of ID in each available database
#' with the following fields:
#'
#'  - **database**: the database name
#'  - **nbBe**: number of distinct entities
#'  - **nbId**: number of identifiers
#'  - **be**: the BE under focus
#'
#' @examples \dontrun{
#' listBeIdSources(be="Transcript", organism="mouse")
#' }
#'
#' @seealso [listBe], [largestBeSource]
#'
#' @export
#'
listBeIdSources <- function(
    be=listBe(), organism,
    direct=FALSE,
    rel=NA,
    restricted=FALSE,
    recache=FALSE,
    verbose=FALSE,
    exclude=c()
){
    fn <- sub(
        sprintf("^%s[:][::]", utils::packageName()), "",
        sub("[(].*$", "", deparse(sys.call(), nlines=1, width.cutoff=500L))
    )

    be <- match.arg(be)
    if(!is.logical(direct)){
        stop("direct should be a logical vector of length 1")
    }
    if(!is.logical(restricted)){
        stop("restricted should be a logical vector of length 1")
    }
    if(!is.logical(recache)){
        stop("recache should be a logical vector of length 1")
    }
    if(!is.logical(verbose)){
        stop("verbose should be a logical vector of length 1")
    }
    if(length(organism)!=1 || is.na(organism)){
        stop("organism should be a character vector of length 1")
    }
    if(length(rel)!=1){
       stop("rel should be a character vector of length 1")
    }
    ## Organism
    taxId <- getTaxId(name=organism)
    if(length(taxId)==0){
        stop("organism not found")
    }
    if(length(taxId)>1){
        print(getOrgNames(taxId))
        stop("Multiple TaxIDs match organism")
    }
    if(be=="Gene"){
        subqs <- ""
    }else{
        subqs <- paste0(
            genBePath(from=be, to="Gene"),
            '(:Gene)'
        )
    }
    cql <- c(
        paste0(
            sprintf('MATCH (be:%s)', be),
            subqs,
            '-[:belongs_to]->',
            '(:TaxID {value:$taxId}) WITH DISTINCT be'
        )
    )
    parameters <- list(taxId=taxId)
    ##
    beid <- paste0(be, "ID")
    if(!is.na(rel)){
       cql <- c(cql, sprintf('MATCH (beid)-[:%s]->()', rel))
    }
    if(direct){
        cql <- c(cql, sprintf(
            'MATCH (beid:%s)-[:identifies]->(be)',
            beid
        ))
    }else{
        cql <- c(cql, sprintf(
            paste0(
                'MATCH (beid:%s)',
                ifelse(
                    restricted,
                    '-[:is_associated_to*0..]->',
                    '-[:is_replaced_by|is_associated_to*0..]->'
                ),
                '(:%s)-[:identifies]->(be)'
            ),
            beid, beid
        ))
    }
    cql <- c(
        cql,
        'WITH DISTINCT beid, be',
        'RETURN beid.database as database, count(DISTINCT be) as nbBe',
        ', count(DISTINCT beid) as nbId'
    )
    if(verbose){
        message(neo2R::prepCql(cql))
    }
    ##
    tn <- gsub(
        "[^[:alnum:]]", "_",
        paste(
            fn,
            be, taxId,
            rel,
            ifelse(direct, "direct", "indirect"),
            ifelse(restricted, "restricted", "full"),
            sep="_"
        )
    )
    toRet <- cacheBedCall(
        f=neo2R::cypher,
        query=neo2R::prepCql(cql),
        parameters=parameters,
        tn=tn,
        recache=recache
    )
    if(!is.null(toRet)){
        toRet$be <- be
        toRet <- toRet[which(!toRet$database %in% exclude),]
    }
    return(toRet)
}
