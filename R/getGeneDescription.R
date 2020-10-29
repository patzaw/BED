#' Get description of genes corresponding to Biological Entity identifiers
#'
#' This description can be used for annotating tables or graph based on BE IDs.
#'
#' @param ids list of identifiers
#' @param be one BE. **Guessed if not provided**
#' @param source the BE ID database. **Guessed if not provided**
#' @param organism organism name. **Guessed if not provided**
#' @param gsource the source of the gene IDs to use. It's chosen automatically
#' by default.
#' @param limForCache The number of ids above which the description
#' is gathered for all be IDs and cached for  futur queries.
#'
#' @return a data.frame providing for each BE IDs
#' (row.names are provided BE IDs):
#'
#'  - **id**: the BE ID
#'  - **gsource**: the Gene ID the column name provides the source of the
#'  used identifier
#'  - **symbol**: the associated gene symbols
#'  - **name**: the associated gene names
#'
#' @examples \dontrun{
#' getGeneDescription(
#'    ids=c("1438_at", "1552335_at"),
#'    be="Probe",
#'    source="GPL570",
#'    organism="human"
#' )
#' }
#'
#' @seealso [getBeIdDescription], [getBeIdNames], [getBeIdSymbols]
#'
#' @export
#'
getGeneDescription <- function(
   ids,
   be,
   source,
   organism,
   gsource=largestBeSource(
      be="Gene", organism=organism, rel="is_known_as", restricted=TRUE
   ),
   limForCache=2000
){
   ##
   from <- to <- symbol <- name <- NULL # for passing R check
   ##
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
   if(be=="Gene"){
      return(getBeIdDescription(
         ids=ids,
         be="Gene",
         source=source,
         organism=organism,
         limForCache=limForCache
      ))
   }

   ##
   gids <- unique(convBeIds(
      ids=ids,
      from=be,
      from.source=source,
      from.org=organism,
      to="Gene",
      to.source=gsource,
      restricted=TRUE,
      limForCache=limForCache
   )[, c("from", "to")])
   gDesc <- getBeIdDescription(
      ids=setdiff(gids$to, NA),
      be="Gene",
      source=gsource,
      organism=organism
   )
   tDesc <- dplyr::full_join(
      gids,
      gDesc,
      by=c("to"="id")
   )
   tDesc <- dplyr::group_by(tDesc, from)
   ##
   gidSum <- function(x){
      x <- setdiff(x, NA)
      if(length(x)==0){
         return(as.character(NA))
      }else{
         return(paste(x, collapse=" || "))
      }
   }
   snSum <- function(x, y){
      x <- x[which(!is.na(y))]
      y <- y[which(!is.na(y))]
      if(length(x)==0){
         return(as.character(NA))
      }else{
         return(paste(
            paste0(y, " (", x, ")"),
            collapse=" || "
         ))
      }
   }
   toRet <- dplyr::summarise(
      tDesc,
      gene=gidSum(to),
      symbol=gidSum(symbol),
      name=gidSum(name)
      # symbol=snSum(to, symbol),
      # name=snSum(to, name)
   )
   toRet <- as.data.frame(toRet)
   colnames(toRet) <- c("id", gsource, "symbol", "name")
   rownames(toRet) <- toRet$id
   return(toRet[ids,])
}
