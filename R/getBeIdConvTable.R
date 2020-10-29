#' Get a conversion table between biological entity (BE) identifiers
#'
#' @param from one BE or "Probe"
#' @param to one BE or "Probe"
#' @param from.source the from BE ID database if BE or
#' the from probe platform if Probe
#' @param to.source the to BE ID database if BE or
#' the to probe platform if Probe
#' @param organism organism name
#' @param caseSensitive if TRUE the case of provided symbols
#' is taken into account
#' during the conversion and selection.
#' This option will only affect the conversion from "Symbol"
#' (default: caseSensitive=FALSE).
#' All the other conversion will be case sensitive.
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
#' all from IDs are taken into account.
#' @param limForCache if there are more filter than limForCache results are
#' collected for all IDs (beyond provided ids) and cached for futur queries.
#' If not, results are collected only for provided ids and not cached.
#'
#' @return a data.frame mapping BE IDs with the
#' following fields:
#'
#'  - **from**: the from BE ID
#'  - **to**: the to BE ID
#'  - **entity**: (optional) the technical ID of to BE
#'
#' @examples \dontrun{
#' getBeIdConvTable(
#'     from="Gene", from.source="EntrezGene",
#'     to.source="Ens_gene",
#'     organism="human"
#' )
#' }
#'
#' @seealso [getHomTable], [listBe], [listPlatforms], [listBeIdSources]
#'
#' @export
#'
getBeIdConvTable <- function(
    from,
    to=from,
    from.source,
    to.source,
    organism,
    caseSensitive=FALSE,
    restricted=TRUE,
    entity=TRUE,
    verbose=FALSE,
    recache=FALSE,
    filter=NULL,
    limForCache=100
){

    fn <- sub(
        sprintf("^%s[:][::]", utils::packageName()), "",
        sub("[(].*$", "", deparse(sys.call(), nlines=1, width.cutoff=500L))
    )

    ## Null results ----
    nullRes <- data.frame(
        from=character(),
        to=character(),
        preferred=logical(),
        entity=character(),
        # fika=logical(),
        # tika=logical(),
        stringsAsFactors=FALSE
    )


    ## BE ----
    if(from=="Probe"){
        fromBE <- attr(genProbePath(platform=from.source), "be")
    }else{
        fromBE <- from
    }
    if(to=="Probe"){
        toBE <- attr(genProbePath(platform=to.source), "be")
    }else{
        toBE <- to
    }

    ## From ----
    fbeid <- getBeIds(
        be=from,
        source=from.source,
        organism=organism,
        caseSensitive=caseSensitive,
        restricted=FALSE,
        entity=TRUE,
        verbose=verbose,
        recache=recache,
        filter=filter,
        limForCache=limForCache
    )
    if(is.null(fbeid) || nrow(fbeid)==0){
        return(nullRes)
    }
    if(!"canonical" %in% colnames(fbeid)){
        fbeid$canonical <- NA
    }
    fbeid <- dplyr::rename(
        fbeid,
        "from"="id",
        # "fpref"="preferred",
        "entity"=!!fromBE,
        "fika"="canonical"
    )
    fbeid <- dplyr::select(fbeid, "from", "fika", "entity")

    ## From fromBE to  ----
    bef <- unique(fbeid$entity)
    if(fromBE!=toBE){
        if(length(bef)>0 && length(bef)<=limForCache){
            noCache <- TRUE
            parameters <- list(filter=as.list(bef))
        }else{
            noCache <- FALSE
        }
        ftqs <- genBePath(from=fromBE, to=toBE)
        ftqs <- c(
            'MATCH',
            sprintf('(fbe:%s)', fromBE),
            ftqs,
            sprintf('(tbe:%s)', toBE),
            ifelse(
                noCache,
                'WHERE id(fbe) IN $filter',
                ''
            ),
            'RETURN id(fbe) as fent, id(tbe) as tent'
        )
        if(noCache){
            toRet <- bedCall(
                neo2R::cypher,
                neo2R::prepCql(ftqs),
                parameters=parameters
            )
        }else{
            tn <- gsub(
                "[^[:alnum:]]", "_",
                paste(
                    fn,
                    fromBE, toBE,
                    sep="_"
                )
            )
            toRet <- cacheBedCall(
                f=neo2R::cypher,
                query=neo2R::prepCql(ftqs),
                tn=tn,
                recache=recache
            )
        }
        if(is.null(toRet) || nrow(toRet)==0){
            return(nullRes)
        }
        toRet <- dplyr::inner_join(
            toRet, fbeid, by=c("fent"="entity")
        )
        toRet <- dplyr::select(toRet, -"fent")
        bef <- unique(toRet$tent)
    }

    ## To ----
    tbeid <- getBeIds(
        be=to,
        source=to.source,
        organism=organism,
        caseSensitive=caseSensitive,
        restricted=restricted,
        entity=TRUE,
        verbose=verbose,
        recache=recache,
        bef=bef,
        limForCache=limForCache
    )
    if(is.null(tbeid) || nrow(tbeid)==0){
        return(nullRes)
    }
    if(!"canonical" %in% colnames(tbeid)){
        tbeid$canonical <- NA
    }
    tbeid <- dplyr::rename(
        tbeid,
        "to"="id",
        # "tpref"="preferred",
        "entity"=!!toBE,
        "tika"="canonical"
    )
    tbeid <- dplyr::select(tbeid, "to", "preferred", "tika", "entity")

    ## Joining ----
    if(fromBE==toBE){
        toRet <- dplyr::inner_join(
            fbeid, tbeid, by="entity"
        )
        if(is.null(toRet) || nrow(toRet)==0){
            return(nullRes)
        }
    }else{
        toRet <- dplyr::inner_join(
            tbeid, toRet, by=c("entity"="tent")
        )
    }

    ## Post-processing ----

    toRet <- toRet[order(toRet$fika+toRet$tika, decreasing=TRUE),]
    toRet$preferred <- as.logical(toRet$preferred)
    ##
    if(caseSensitive){
       toDel <- union(
          which(
             toRet$fika==0 &
                (toRet$from) %in% (toRet$from[which(toRet$fika==1)])
          ),
          which(
             toRet$tika==0 &
                (toRet$to) %in% (toRet$to[which(toRet$tika==1)])
          )
       )
    }else{
       toDel <- union(
           which(
               toRet$fika==0 &
               toupper(toRet$from) %in% toupper(toRet$from[which(toRet$fika==1)])
           ),
           which(
               toRet$tika==0 &
               toupper(toRet$to) %in% toupper(toRet$to[which(toRet$tika==1)])
           )
       )
    }
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
