#' Get symbols of Biological Entity identifiers
#'
#' @param ids list of identifiers
#' @param be one BE. **Guessed if not provided**
#' @param source the BE ID database. **Guessed if not provided**
#' @param organism organism name. **Guessed if not provided**
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
    be,
    source,
    organism,
    limForCache=4000,
    ...
){
    ids <- setdiff(ids, NA)
    ##
    if(missing(be) || missing(source) || missing(organism)){
        toWarn <- TRUE
    }else{
        toWarn <- FALSE
    }
    guess <- guessIdScope(ids=ids, be=be, source=source, organism=organism)
    if(is.null(guess)){
        warning("Could not find the provided ids")
        if(missing(be) || missing(source) || missing(organism)){
            stop("Missing be, source or organism information")
        }
    }else{
        if(is.na(guess$be)){
            warning(
                "The provided ids does not match the provided scope",
                " (be, source or organism)"
            )
            if(missing(be) || missing(source) || missing(organism)){
                stop("Missing be, source or organism information")
            }
        }else{
            be <- guess$be
            source <- guess$source
            organism <- guess$organism
        }
    }
    if(toWarn){
        warning(
            "Guessing ID scope:",
            sprintf("\n   - be: %s", be),
            sprintf("\n   - source: %s", source),
            sprintf("\n   - organism: %s", organism)
        )
    }
    ##
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
        toRet <- getBeIdSymbolTable(
            be=be, source=source, organism=organism,
            ...
        )
    }else{
        toRet <- getBeIdSymbolTable(
            be=be, source=source, organism=organism,
            filter=ids,
            ...
        )
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
