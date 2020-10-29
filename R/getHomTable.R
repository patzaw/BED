#' Get gene homologs between 2 organisms
#'
#' @param from.org organism name
#' @param to.org organism name
#' @param from.source the from gene ID database
#' @param to.source the to gene ID database
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also returned:
#' **Depending on history it can take a very long time to return a very**
#' **large result!**
#' @param verbose boolean indicating if the CQL query should be displayed
#' @param recache boolean indicating if the CQL query should be run even if
#' the table is already in cache
#' @param filter character vector on which to filter from IDs.
#' If NULL (default), the result is not filtered:
#' all from IDs are taken into account.
#' @param limForCache if there are more filter than limForCache results are
#' collected for all IDs (beyond provided ids) and cached for futur queries.
#' If not, results are collected only for provided ids and not cached.
#'
#' @return a data.frame mapping gene IDs with the
#' following fields:
#'
#'  - **from**: the from gene ID
#'  - **to**: the to gene ID
#'
#' @examples \dontrun{
#' getHomTable(
#'    from.org="human",
#'    to.org="mouse"
#' )
#' }
#'
#' @seealso [getBeIdConvTable]
#'
#' @export
#'
getHomTable <- function(
    from.org,
    to.org,
    from.source="Ens_gene",
    to.source=from.source,
    restricted=TRUE,
    verbose=FALSE,
    recache=FALSE,
    filter=NULL,
    limForCache=100
){

    fn <- sub(
        sprintf("^%s[:][::]", utils::packageName()), "",
        sub("[(].*$", "", deparse(sys.call(), nlines=1, width.cutoff=500L))
    )

    to.source <- to.source
    ## Organisms
    fromTaxId <- getTaxId(name=from.org)
    if(length(fromTaxId)==0){
        stop("from.org not found")
    }
    if(length(fromTaxId)>1){
        print(getOrgNames(fromTaxId))
        stop("Multiple TaxIDs match from.org")
    }
    ##
    toTaxId <- getTaxId(name=to.org)
    if(length(toTaxId)==0){
        stop("to.org not found")
    }
    if(length(toTaxId)>1){
        print(getOrgNames(toTaxId))
        stop("Multiple TaxIDs match to.org")
    }
    ##
    if(fromTaxId==toTaxId){
        stop("Identical organisms. Use 'getBeIdConvTable' to convert DB IDs.")
    }

    ## From ----
    fr <- getBeIds(
        be="Gene", source=from.source, organism=from.org,
        restricted=FALSE, filter=filter, recache=recache, verbose=verbose,
        limForCache=limForCache
    )
    if(is.null(fr) || nrow(fr)==0){
        return(NULL)
    }
    fr <- dplyr::select(fr, "id", "Gene")
    fr <- dplyr::rename(fr, "from"="id")
    bef <- unique(fr$Gene)

    ## Conv ----
    if(length(bef)>0 && length(bef)<=limForCache){
        noCache <- TRUE
        parameters <- list(filter=as.list(bef))
    }else{
        noCache <- FALSE
    }
    cql <- c(
        sprintf(
            'MATCH (fbe:Gene)-[:belongs_to]->(:TaxID {value:"%s"})',
            fromTaxId
        ),
        ifelse(
            noCache,
            'WHERE id(fbe) IN $filter',
            ''
        ),
        sprintf(
            'MATCH (tbe:Gene)-[:belongs_to]->(:TaxID {value:"%s"})',
            toTaxId
        ),
        'MATCH (fbe)<-[:identifies]-(:GeneID)-[:is_member_of]->(:GeneIDFamily)',
        '<-[:is_member_of]-(:GeneID)-[:identifies]->(tbe:Gene)',
        'RETURN DISTINCT id(fbe) as fromb, id(tbe) as tob'
    )
    if(noCache){
        cr <- bedCall(
            neo2R::cypher,
            neo2R::prepCql(cql),
            parameters=parameters
        )
    }else{
        tn <- gsub(
            "[^[:alnum:]]", "_",
            paste(
                fn,
                fromTaxId,
                toTaxId,
                sep="_"
            )
        )
        cr <- cacheBedCall(
            f=neo2R::cypher,
            query=neo2R::prepCql(cql),
            tn=tn,
            recache=recache
        )
    }
    if(is.null(cr) || nrow(cr)==0){
        return(NULL)
    }
    bef <- unique(cr$tob)

    ## To ----
    tr <- getBeIds(
        be="Gene", source=to.source, organism=to.org,
        restricted=restricted, recache=recache, verbose=verbose,
        bef=bef,
        limForCache=limForCache
    )
    if(is.null(tr) || nrow(tr)==0){
        return(NULL)
    }
    tr <- dplyr::select(tr, "id", "Gene")
    tr <- dplyr::rename(tr, "to"="id")

    ## Results
    toRet <- dplyr::inner_join(
        cr, fr, by=c("fromb"="Gene")
    )
    if(is.null(toRet) || nrow(toRet)==0){
        return(NULL)
    }
    toRet <- unique(dplyr::select(toRet, "from", "tob"))
    toRet <- dplyr::inner_join(
        toRet, tr, by=c("tob"="Gene")
    )
    if(is.null(toRet) || nrow(toRet)==0){
        return(NULL)
    }
    toRet <- unique(dplyr::select(toRet, "from", "to"))

    # ## Filter
    # if(length(filter)>0 && !inherits(filter, "character")){
    #     stop("filter should be a character vector")
    # }
    #
    # ## From
    # fqs <- paste0(
    #     sprintf(
    #         'MATCH (f:GeneID {database:"%s"})',
    #         from.source
    #     ),
    #     '-[:is_replaced_by|is_associated_to*0..]->(:GeneID)',
    #     '-[:identifies]->(fbe)'
    # )
    # ## To
    # tqs <- paste0(
    #     sprintf(
    #         'MATCH (t:GeneID {database:"%s"})',
    #         to.source
    #     ),
    #     # '-[:is_replaced_by|is_associated_to*0..]->(:GeneID)',
    #     ifelse(
    #        restricted,
    #        '-[:is_associated_to*0..]->(:GeneID)',
    #        '-[:is_replaced_by|is_associated_to*0..]->(:GeneID)'
    #     ),
    #     '-[:identifies]->(tbe)'
    # )
    #
    # ## From fromBE to toBE
    # ftqs <- c(
    #     sprintf(
    #         'MATCH (fbe:Gene)-[:belongs_to]->(:TaxID {value:"%s"})',
    #         fromTaxId
    #     ),
    #     sprintf(
    #         'MATCH (tbe:Gene)-[:belongs_to]->(:TaxID {value:"%s"})',
    #         toTaxId
    #     ),
    #     'MATCH (fbe)<-[:identifies]-(:GeneID)-[:is_member_of]->(:GeneIDFamily)',
    #     '<-[:is_member_of]-(:GeneID)-[:identifies]->(tbe:Gene)',
    #     'WITH DISTINCT fbe, tbe'
    # )
    #
    # ##
    # cql <- setdiff(c(ftqs, fqs, tqs), "")
    #
    # ## Filter
    # if(length(filter)>0){
    #     cql <- c(cql, 'WHERE f.value IN $filter')
    # }
    #
    # ## RETURN
    # cql <- c(
    #     cql,
    #     'RETURN DISTINCT f.value as from, t.value as to'
    # )
    # if(verbose){
    #     message(neo2R::prepCql(cql))
    # }
    # ##
    # if(length(filter)==0){
    #     tn <- gsub(
    #         "[^[:alnum:]]", "_",
    #         paste(
    #             fn,
    #             fromTaxId, from.source,
    #             toTaxId, to.source,
    #             ifelse(restricted, "restricted", "full"),
    #             sep="_"
    #         )
    #     )
    #     toRet <- cacheBedCall(
    #         f=neo2R::cypher,
    #         query=neo2R::prepCql(cql),
    #         tn=tn,
    #         recache=recache
    #     )
    # }else{
    #     toRet <- bedCall(
    #         f=neo2R::cypher,
    #         query=neo2R::prepCql(cql),
    #         parameters=list(filter=as.list(filter))
    #     )
    # }
    # toRet <- unique(toRet)
    ##

    return(toRet)

}
