#' Get gene homologs between 2 organisms
#'
#' @param from.org organism name
#' @param to.org organism name
#' @param from.source the from gene ID database
#' @param to.source the to gene ID database
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also returned:
#' \strong{Depending on history it can take a very long time to return
#' a very large result!}
#' @param verbose boolean indicating if the CQL query should be displayed
#' @param recache boolean indicating if the CQL query should be run even if
#' the table is already in cache
#' @param filter character vector on which to filter from IDs.
#' If NULL (default), the result is not filtered:
#' all from IDs are taken into account.
#'
#' @return a data.frame mapping gene IDs with the
#' following fields:
#' \describe{
#'  \item{from}{the from gene ID}
#'  \item{to}{the to gene ID}
#' }
#'
#' @examples \dontrun{
#' getHomTable(
#'    from.org="human",
#'    to.org="mouse"
#' )
#' }
#'
#' @seealso \code{\link{getBeIdConvTable}}
#'
#' @importFrom neo2R prepCql cypher
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
    filter=NULL
){
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

    ## Filter
    if(length(filter)>0 && !inherits(filter, "character")){
        stop("filter should be a character vector")
    }

    ## From
    fqs <- paste0(
        sprintf(
            'MATCH (f:GeneID {database:"%s"})',
            from.source
        ),
        '-[:is_replaced_by|is_associated_to*0..]->(:GeneID)',
        '-[:identifies]->(fbe:Gene)',
        sprintf(
            '-[:belongs_to]->(:TaxID {value:"%s"})',
            fromTaxId
        )
    )
    ## To
    tqs <- paste0(
        sprintf(
            'MATCH (t:GeneID {database:"%s"})',
            to.source
        ),
        # '-[:is_replaced_by|is_associated_to*0..]->(:GeneID)',
        ifelse(
           restricted,
           '-[:is_associated_to*0..]->(:GeneID)',
           '-[:is_replaced_by|is_associated_to*0..]->(:GeneID)'
        ),
        '-[:identifies]->(tbe:Gene)',
        sprintf(
            '-[:belongs_to]->(:TaxID {value:"%s"})',
            toTaxId
        )
    )

    ## From fromBE to toBE
    ftqs <- paste0(
        'MATCH (fbe)<-[:identifies]-(:GeneID)-[:is_member_of]->(:GeneIDFamily)',
        '<-[:is_member_of]-(:GeneID)-[:identifies]->(tbe)'
    )

    ##
    cql <- setdiff(c(fqs, tqs, ftqs), "")

    ## Filter
    if(length(filter)>0){
        cql <- c(cql, 'WHERE f.value IN $filter')
    }

    ## RETURN
    cql <- c(
        cql,
        'RETURN f.value as from, t.value as to'
    )
    if(verbose){
        message(prepCql(cql))
    }
    ##
    if(length(filter)==0){
        tn <- gsub(
            "[^[:alnum:]]", "_",
            paste(
                match.call()[[1]],
                fromTaxId, from.source,
                toTaxId, to.source,
                ifelse(restricted, "restricted", "full"),
                sep="_"
            )
        )
        toRet <- cacheBedCall(
            f=cypher,
            query=prepCql(cql),
            tn=tn,
            recache=recache
        )
    }else{
        toRet <- bedCall(
            f=cypher,
            query=prepCql(cql),
            parameters=list(filter=as.list(filter))
        )
    }
    toRet <- unique(toRet)
    ##
    return(toRet)

}
