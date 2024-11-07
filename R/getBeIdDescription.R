#' Get description of Biological Entity identifiers
#'
#' This description can be used for annotating tables or graph based on BE IDs.
#'
#' @param ids list of identifiers
#' @param be one BE. **Guessed if not provided**
#' @param source the BE ID database. **Guessed if not provided**
#' @param organism organism name. **Guessed if not provided**
#' @param ... further arguments
#' for [getBeIdNames] and [getBeIdSymbols] functions
#'
#' @return a data.frame providing for each BE IDs
#' (row.names are provided BE IDs):
#'
#'  - **id**: the BE ID
#'  - **symbol**: the BE symbol
#'  - **name**: the corresponding name
#'
#' @examples \dontrun{
#' getBeIdDescription(
#'    ids=c("10", "100"),
#'    be="Gene",
#'    source="EntrezGene",
#'    organism="human"
#' )
#' }
#'
#' @seealso [getBeIdNames], [getBeIdSymbols]
#'
#' @export
#'
getBeIdDescription <- function(
   ids,
   be,
   source,
   organism,
   ...
){
   if(length(ids)==0){
      # stop("ids should be a character vector with at least one value")
      return(data.frame(
         "id"=character(),
         "symbol"=character(),
         "name"=character(),
         "preferred"=logical(),
         "db.version"=character(),
         "db.deprecated"=logical(),
         stringsAsFactors=FALSE
      ))
   }
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
   cnames <- getBeIdNames(
      ids=ids,
      be=be, source=source,
      organism=organism,
      restricted=FALSE,
      ...
   )
   cnames$canonical <- as.numeric(cnames$canonical)
   cnames$canonical <- ifelse(is.na(cnames$canonical), 0, cnames$canonical)
   cnames$preferred <- as.numeric(cnames$preferred)
   cnames$preferred <- ifelse(is.na(cnames$preferred), 0, cnames$preferred)
   cnames <- cnames[
      order(
         cnames$direct + cnames$preferred + 0.5*cnames$canonical, decreasing=T
      ),
      c("id", "name")
   ]
   cnames <- cnames[!duplicated(cnames$id),]
   if(!all(ids %in% cnames$id)){
      stop("Could not find all IDs for names")
   }
   csymb <- getBeIdSymbols(
      ids=ids,
      be=be, source=source,
      organism=organism,
      restricted=FALSE,
      ...
   )
   csymb$preferred <- as.numeric(csymb$preferred)
   csymb$preferred <- ifelse(is.na(csymb$preferred), 0, csymb$preferred)
   csymb <- csymb[
      order(csymb$direct + csymb$preferred + 0.5*csymb$canonical, decreasing=T),
      c("id", "symbol")
   ]
   csymb <- csymb[!duplicated(csymb$id),]
   if(!all(ids %in% csymb$id)){
      stop("Could not find all IDs for symbols")
   }
   toRet <- dplyr::inner_join(csymb, cnames, by="id")


   beidDesc <- getBeIds(
      be=be,
      source=source,
      organism=organism,
      restricted=FALSE,
      filter=ids
   )
   if(is.null(beidDesc)){
      beidDesc <- data.frame(
         id=ids,
         preferred=NA,
         db.version=NA,
         db.deprecated=NA,
         stringsAsFactors=FALSE
      )
   }
   beidDesc <- unique(beidDesc[
      ,
      c("id", "preferred", "db.version", "db.deprecated")
   ])
   toRet <- dplyr::full_join(toRet, beidDesc, by="id")

   rownames(toRet) <- toRet$id
   return(toRet[ids,])
}
