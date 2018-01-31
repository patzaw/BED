#' Get description of genes corresponding to Biological Entity identifiers
#'
#' This description can be used for annotating tables or graph based on BE IDs.
#'
#' @param ids list of identifiers
#' @param be one BE
#' @param source the BE ID database
#' @param organism organism name
#' @param gsource the source of the gene IDs to use. It's chosen automatically
#' by default.
#' @param limForCache The number of ids above which the description
#' is gathered for all be IDs and cached for  futur queries.
#'
#' @return a data.frame providing for each BE IDs
#' (row.names are provided BE IDs):
#' \describe{
#'  \item{id}{the BE ID}
#'  \item{gsource}{the Gene ID the column name provides the source of the
#'  used identifier}
#'  \item{symbol}{the associated gene symbols}
#'  \item{name}{the associated gene names}
#' }
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
#' @seealso \code{\link{getBeIdDescription}},
#' \code{\link{getBeIdNames}},
#' \code{\link{getBeIdSymbols}}
#'
#' @importFrom dplyr group_by summarise
#' @export
#'
getGeneDescription <- function(
   ids,
   be=c(listBe(), "Probe"),
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
   be <- match.arg(be)
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
   tDesc <- merge(
      gids,
      gDesc,
      by.x="to",
      by.y="id",
      all=TRUE
   )
   tDesc <- group_by(tDesc, from)
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
   toRet <- summarise(
      tDesc,
      gene=gidSum(to),
      symbol=snSum(to, symbol),
      name=snSum(to, name)
   )
   toRet <- as.data.frame(toRet)
   colnames(toRet) <- c("id", gsource, "symbol", "name")
   rownames(toRet) <- toRet$id
   return(toRet[ids,])
}
