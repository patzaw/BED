#' Get symbols of Biological Entity identifiers
#'
#' @param ids list of identifiers
# @param source the BE ID database
# @param organism organism name
# @param restricted boolean indicating if the results should be restricted to
# direct symbols
#' @param limForCache if there are more ids than limForCache. Results are
#' collected for all IDs (beyond provided ids) and cached for futur queries.
#' If not, results are collected only for provided ids and not cached.
#' @param ... params for the [getBeIdSymbolTable] function
#'
#' @return a data.frame with the
#' following fields:
#'
#'  - **id**: the from BE ID
#'  - **symbol**: the BE symbol
#'  - **canonical**: true if the symbol is canonical for the direct BE ID
#'  - **direct**: false if the symbol is not directly associated to the BE ID
#'  - **entity**: (optional) the technical ID of to BE
#'
#' @examples \dontrun{
#' getBeIdSymbols(
#'    ids=c("10", "100"),
#'    be="Gene",
#'    source="EntrezGene",
#'    organism="human"
#' )
#' }
#'
#' @seealso [getBeIdSymbolTable], [getBeIdNames]
#'
#' @export
#'
getBeIdSymbols <- function(
    ids,
    limForCache=4000,
    ...
){
    ids <- setdiff(ids, NA)
    prepNotFound <- function(x, entity){
        toRet <- data.frame(
            id=x,
            symbol=NA,
            canonical=NA,
            direct=NA,
            preferred=NA,
            stringsAsFactors=F,
            check.names=F
        )
        if(entity){
            toRet$entity <- NA
        }
        return(toRet)
    }
    if(length(ids) > limForCache){
        toRet <- getBeIdSymbolTable(...)
    }else{
        toRet <- getBeIdSymbolTable(filter=ids, ...)
    }
    if(is.null(toRet)){
        toRet <- prepNotFound(ids, entity=TRUE)
    }else{
        toRet <- toRet[which(toRet$id %in% ids),]
        notFound <- setdiff(ids, toRet$id)
        if(length(notFound) > 0){
            notFound <- prepNotFound(notFound, "entity" %in% colnames(toRet))
            toRet <- rbind(toRet, notFound)
        }
    }
    return(toRet)
}
