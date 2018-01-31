#' Get a conversion table between biological entity (BE) identifiers
#'
#' @param from one BE or "Probe"
#' @param to one BE or "Probe"
#' @param from.source the from BE ID database if BE or
#' the from probe platform if Probe
#' @param to.source the to BE ID database if BE or
#' the to probe platform if Probe
#' @param organism organism name
#' @param restricted boolean indicating if the results should be restricted to
#' current version of to BEID db. If FALSE former BEID are also returned:
#' \strong{Depending on history it can take a very long time to return
#' a very large result!}
#' @param entity boolean indicating if the technical ID of to BE should be
#' returned
#' @param verbose boolean indicating if the CQL query should be displayed
#' @param recache boolean indicating if the CQL query should be run even if
#' the table is already in cache
#' @param filter character vector on which to filter from IDs.
#' If NULL (default), the result is not filtered:
#' all from IDs are taken into account. Filtering is case insensitive.
#'
#' @return a data.frame mapping BE IDs with the
#' following fields:
#' \describe{
#'  \item{from}{the from BE ID}
#'  \item{to}{the to BE ID}
#'  \item{entity}{(optional) the technical ID of to BE}
#' }
#'
#' @examples \dontrun{
#' getBeIdConvTable(
#'     from="Gene", from.source="EntrezGene",
#'     to.source="Ens_gene",
#'     organism="human"
#' )
#' }
#'
#' @seealso \code{\link{getHomTable}}, \code{\link{listBe}},
#' \code{\link{listPlatforms}}, \code{\link{listBeIdSources}}
#'
#' @importFrom neo2R prepCql cypher
#' @export
#'
getBeIdConvTable <- function(
    from,
    to=from,
    from.source,
    to.source,
    organism,
    restricted=TRUE,
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
    echoices <- c("Probe", listBe())
    match.arg(from, echoices)
    match.arg(to, echoices)

    ## From
    if(from=="Probe"){
        fqs <- genProbePath(platform=from.source)
        fromBE <- attr(fqs, "be")
        fqs <- paste0(
            sprintf(
                '(f:ProbeID {platform:"%s"})',
                from.source
            ),
            fqs,
            sprintf(
                '(fbe:%s)',
                fromBE
            )
        )
    }else{
        fromBE <- from
        if(from.source=="Symbol"){
            fqs <- paste0(
                '(f:BESymbol)<-[fika:is_known_as]-',
                sprintf(
                    '(fid:%s)',
                    paste0(from, "ID")
                ),
                '-[:is_replaced_by|is_associated_to*0..]->()',
                '-[:identifies]->',
                sprintf(
                    '(fbe:%s)',
                    from
                )
            )
        }else{
            fqs <- paste0(
                sprintf(
                    '(f:%s {database:"%s"})',
                    paste0(from, "ID"), from.source
                ),
                # ifelse(
                #     restricted,
                #     '-[:is_associated_to*0..]->',
                #     '-[:is_replaced_by|is_associated_to*0..]->'
                # ),
                '-[:is_replaced_by|is_associated_to*0..]->',
                sprintf(
                    '(:%s)',
                    paste0(from, "ID")
                ),
                '-[:identifies]->',
                sprintf(
                    '(fbe:%s)',
                    from
                )
            )
        }
    }

    ## To
    if(to=="Probe"){
        tqs <- genProbePath(platform=to.source)
        toBE <- attr(tqs, "be")
        tqs <- paste0(
            sprintf(
                '(t:ProbeID {platform:"%s"})',
                to.source
            ),
            tqs,
            sprintf(
                '(%s%s)',
                ifelse(toBE==fromBE, "fbe", "tbe"),
                ifelse(toBE==fromBE, "", paste0(":", toBE))
            )
        )
    }else{
        toBE <- to
        if(to.source=="Symbol"){
            tqs <- paste0(
                '(t:BESymbol)<-[tika:is_known_as]-',
                sprintf(
                    '(tid:%s)',
                    paste0(to, "ID")
                ),
                '-[:is_replaced_by|is_associated_to*0..]->()',
                '-[:identifies]->',
                sprintf(
                    '(%s%s)',
                    ifelse(toBE==fromBE, "fbe", "tbe"),
                    ifelse(toBE==fromBE, "", paste0(":", toBE))
                )
            )
        }else{
            tqs <- paste0(
                sprintf(
                    '(t:%s {database:"%s"})',
                    paste0(to, "ID"), to.source
                ),
                ifelse(
                    restricted,
                    '-[:is_associated_to*0..]->',
                    '-[:is_replaced_by|is_associated_to*0..]->'
                ),
                sprintf(
                    '(:%s)',
                    paste0(to, "ID")
                ),
                '-[:identifies]->',
                sprintf(
                    '(%s%s)',
                    ifelse(toBE==fromBE, "fbe", "tbe"),
                    ifelse(toBE==fromBE, "", paste0(":", toBE))
                )
            )
        }
    }

    ## From fromBE to toBE
    if(fromBE==toBE){
        ftqs <- ""
    }else{
        ftqs <- genBePath(from=fromBE, to=toBE)
        ftqs <- paste0(
            '(fbe)',
            ftqs,
            '(tbe)'
        )
    }

    ## Organism
    oqs <- paste0(
        '(og:Gene)-[:belongs_to]->',
        sprintf(
            '(:TaxID {value:"%s"})',
            taxId
        )
    )
    ## From Organism
    if(fromBE=="Gene"){
        foqs <- '(fbe)-[*0]-(og)'
    }else{
        foqs <- paste0(
            '(fbe)',
            genBePath(from=fromBE, to="Gene"),
            '(og)'
        )
    }
    ## To Organism
    if(fromBE==toBE){
        toqs <- ""
    }else{
        if(toBE=="Gene"){
            toqs <- '(tbe)-[*0]-(og)'
        }else{
            toqs <- paste0(
                '(tbe)',
                genBePath(from=toBE, to="Gene"),
                '(og)'
            )
        }
    }

    ##
    cql <- paste('MATCH', setdiff(c(fqs, tqs, oqs), ""))
    toRep <- '[(][:]Gene[)]'
    if(length(grep(toRep, ftqs))==1){
        ftqs <- sub(toRep, "(og)", ftqs)
        cql <- c(cql, paste('MATCH', ftqs))
    }else{
        cql <- c(
            cql,
            ifelse(ftqs=="", "", paste('MATCH', ftqs)),
            paste(
                'MATCH',
                ifelse(nchar(toqs)<nchar(foqs) & nchar(toqs)>0, toqs, foqs)
            )
        )
    }

    ## Filter
    if(length(filter)>0){
        cql <- c(
            cql,
            sprintf(
                'WHERE f.%s IN $filter',
                ifelse(
                    from.source=="Symbol",
                    "value_up",
                    "value"
                )
            )
        )
    }

    ## RETURN
    cql <- c(
        cql,
        paste(
            'RETURN f.value as from',
            ', t.value as to, t.preferred as preferred',
            sprintf(
                ifelse(
                    fromBE==toBE,
                    ', id(fbe) as %s',
                    ', id(tbe) as %s'
                ),
                "entity"
            )
        )
    )

    if(from.source=="Symbol"){
        cql <- c(
            cql,
            ', CASE WHEN fika.canonical THEN 1 ELSE 0 END as fika'
        )
    }else{
        cql <- c(
            cql,
            ', 0 as fika'
        )
    }
    if(to.source=="Symbol"){
        cql <- c(
            cql,
            ', CASE WHEN tika.canonical THEN 1 ELSE 0 END as tika'
        )
    }else{
        cql <- c(
            cql,
            ', 0 as tika'
        )
    }

    if(verbose){
        message(prepCql(cql))
    }
    ##
    if(length(filter)==0){
        tn <- gsub(
            "[^[:alnum:]]", "_",
            paste(
                match.call()[[1]],
                from, from.source,
                to, to.source,
                taxId,
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
            parameters=list(filter=as.list(
                unique(c(filter, tolower(filter), toupper(filter)))
            ))
        )
    }
    toRet <- unique(toRet)
    if(is.null(toRet)){
       toRet <- data.frame(
          from=character(),
          to=character(),
          preferred=logical(),
          entity=character(),
          fika=numeric(),
          tika=numeric(),
          stringsAsFactors=FALSE
       )
    }
    toRet <- toRet[order(toRet$fika+toRet$tika, decreasing=TRUE),]
    toRet$preferred <- as.logical(toRet$preferred)
    ##
    toDel <- union(
        which(
            toRet$fika==0 & (toRet$from %in% toRet$from[which(toRet$fika==1)])
        ),
        which(
            toRet$tika==0 & (toRet$to %in% toRet$to[which(toRet$tika==1)])
        )
    )
    if(length(toDel)>0){
        toRet <- toRet[-toDel,]
    }
    ##
    toRet <- unique(
        toRet[, setdiff(colnames(toRet), c("fika", "tika")), drop=FALSE]
    )
    if(!entity){
        toRet <- unique(toRet[, setdiff(colnames(toRet), c("entity", "preferred"))])
    }
    ##
    return(toRet)
}
