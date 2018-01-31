#' Get description of Biological Entity identifiers
#'
#' This description can be used for annotating tables or graph based on BE IDs.
#'
#' @param ids list of identifiers
#' @param be one BE
#' @param source the BE ID database
#' @param organism organism name
#' @param ... further arguments for
#' \code{\link{getBeIdNames}} and \code{\link{getBeIdSymbols}} functions
#'
#' @return a data.frame providing for each BE IDs
#' (row.names are provided BE IDs):
#' \describe{
#'  \item{id}{the BE ID}
#'  \item{symbol}{the BE symbol}
#'  \item{name}{the corresponding name}
#' }
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
#' @seealso \code{\link{getBeIdNames}},
#' \code{\link{getBeIdSymbols}}
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
   cnames <- getBeIdNames(
      ids=ids,
      be=be, source=source,
      organism=organism,
      restricted=FALSE,
      ...
   )
   cnames$preferred <- as.numeric(cnames$preferred)
   cnames$preferred <- ifelse(is.na(cnames$preferred), 0, cnames$preferred)
   cnames <- cnames[
      order(cnames$direct + cnames$preferred, decreasing=T),
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
   toRet <- merge(csymb, cnames, by="id")


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
   toRet <- merge(toRet, beidDesc, by="id", all=TRUE)

   rownames(toRet) <- toRet$id
   return(toRet[ids,])
}
