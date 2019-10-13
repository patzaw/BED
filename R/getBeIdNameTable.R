#' Get a table of biological entity (BE) identifiers and names
#'
#' @param be one BE
#' @param source the BE ID database
#' @param organism organism name
#' @param restricted boolean indicating if the results should be restricted to
#' direct names
#' @param entity boolean indicating if the technical ID of BE should be
#' returned
#' @param verbose boolean indicating if the CQL query should be displayed
#' @param recache boolean indicating if the CQL query should be run even if
#' the table is already in cache
#' @param filter character vector on which to filter id. If NULL (default),
#' the result is not filtered: all IDs are taken into account.
#'
#' @return a data.frame with the
#' following fields:
#' \describe{
#'  \item{id}{the from BE ID}
#'  \item{name}{the BE name}
#'  \item{direct}{false if the symbol is not directly associated to the BE ID}
#'  \item{entity}{(optional) the technical ID of to BE}
#' }
#'
#' @examples \dontrun{
#' getBeIdNameTable(
#'    be="Gene",
#'    source="EntrezGene",
#'    organism="human"
#' )
#' }
#'
#' @seealso \code{\link{getBeIdNames}},
#' \code{\link{getBeIdSymbolTable}}
#'
#' @importFrom neo2R prepCql cypher
#' @importFrom dplyr arrange select filter distinct
#' @export
#'
getBeIdNameTable <- function(
    be,
    source,
    organism,
    restricted,
    entity=TRUE,
    verbose=FALSE,
    recache=FALSE,
    filter=NULL
){
    ## Organism
    taxId <- getTaxId(name=organism)
    if(length(taxId)==0){
        stop("organism not found")
    }
    if(length(taxId)>1){
        print(getOrgNames(taxId))
        stop("Multiple TaxIDs match organism")
    }

    ## Filter
    if(length(filter)>0 && !inherits(filter, "character")){
        stop("filter should be a character vector")
    }

    ## Other verifications
    echoices <- c(listBe())
    match.arg(be, echoices)
    match.arg(source, listBeIdSources(be, organism)$database)

    ## Entity
    qs <- c(
        sprintf(
            paste0(
                'MATCH (id:%s {database:"%s"})',
                '-[:is_replaced_by|is_associated_to*0..]->()',
                '-[:identifies]->(be:%s)'
            ),
            paste0(be, "ID"), source, be
        )
    )

    ## Organism
    oqs <- paste0(
        'MATCH (og)',
        '-[:belongs_to]->',
        sprintf(
            '(:TaxID {value:"%s"})',
            taxId
        )
    )
    if(be=="Gene"){
        oqs <- c(
            oqs,
            'MATCH (be)-[*0]-(og)'
        )
    }else{
        oqs <- c(
            oqs,
            paste0(
                'MATCH (be)',
                genBePath(from=be, to="Gene"),
                '(og)'
            )
        )
    }
    qs <- c(qs, oqs)

    ## Filter
    if(length(filter)>0){
        qs <- c(qs, 'WHERE id.value IN $filter')
    }

    ## Names
    qs <- c(
        qs,
        'WITH DISTINCT id, be',
        'MATCH (bes:BEName)<-[c:is_named]-(sid)',
        '-[:is_associated_to*0..]->()-[:identifies]->(be)'
    )

    ##
    cql <- c(
        qs,
        paste(
            'RETURN DISTINCT id.value as id, bes.value as name',
            ', id(id)=id(sid) as direct',
            ', sid.preferred as preferred',
            ', id(be) as entity'
        )
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
                be, source,
                taxId,
                sep="_"
            )
        )
        toRet <- unique(cacheBedCall(
            f=cypher,
            query=prepCql(cql),
            tn=tn,
            recache=recache
        ))
    }else{
        toRet <- bedCall(
            f=cypher,
            query=prepCql(cql),
            parameters=list(filter=as.list(filter))
        )
    }
    toRet <- unique(toRet)
    ##
    if(!is.null(toRet)){
        toRet$direct <- as.logical(toRet$direct)
        # toRet <- toRet[order(toRet$direct, decreasing=T),]
        toRet <- arrange(toRet, desc(direct))
        toRet <- distinct(toRet, id, name, .keep_all=TRUE)
        # toRet <- toRet[which(!duplicated(toRet[,c("id", "name")])),]
        ##
        if(!entity){
            toRet <- unique(toRet[
               ,
               setdiff(colnames(toRet), c("entity"))
            ])
        }
        if(restricted){
            toRet <- filter(toRet, direct)
            # toRet <- toRet[which(toRet$direct),]
        }
    }
    ##
    return(toRet)
}
