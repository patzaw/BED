###############################################################################@
#' Create a BEIDList
#'
#' @param l a named list of BEID vectors
#' @param metadata a data.frame with rownames or
#' a column "**.lname**" all in names of l.
#' If missing, the metadata is constructed with **.lname** being the names
#' of l.
#' @param scope a list with 3 character vectors of length one named "be",
#' "source" and "organism".
#' If missing, it is guessed from l.
#'
#' @return A BEIDList object which is a list of BEID vectors with 2 additional
#' attributes:
#'
#' - **metadata**: a data.frame with metadata about list elements.
#' The "**.lname**" column correspond to the names of the BEIDList.
#' - **scope**: the BEID scope ("be", "source" and "organism")
#'
#' @examples \dontrun{
#' bel <- BEIDList(
#'    l=list(
#'       kinases=c("117283", "3706", "3707", "51447", "80271", "9807"),
#'       phosphatases=c(
#'          "130367", "249", "283871", "493911", "57026", "5723", "81537"
#'       )
#'    ),
#'    scope=list(be="Gene", source="EntrezGene", organism="Homo sapiens")
#' )
#' scope(bel)
#' metadata(bel)
#' metadata(bel) <- dplyr::mutate(
#'    metadata(bel),
#'    "description"=c("A few kinases", "A few phosphatases")
#' )
#' metadata(bel)
#' }
#'
#' @export
#'
BEIDList <- function(
   l,
   metadata,
   scope
){

   if(missing(metadata)){
      metadata <- data.frame(.lname=names(l), stringsAsFactors=FALSE)
   }
   if(missing(scope)){
      scope <- BED::guessIdScope(unlist(l))
      warning(
         "Guessing ID scope:",
         sprintf("\n   - be: %s", scope$be),
         sprintf("\n   - source: %s", scope$source),
         sprintf("\n   - organism: %s", scope$organism)
      )
   }

   ## Checks ----
   stopifnot(is.data.frame(metadata))
   if(!".lname" %in% colnames(metadata)){
      metadata <- dplyr::mutate(metadata, .lname=rownames(!!metadata))
   }
   metadata$.lname <- as.character(metadata$.lname)
   stopifnot(
      is.list(l),
      all(names(l) %in% metadata$.lname),
      all(metadata$.lname %in% names(l)),
      is.list(scope),
      length(scope)==3,
      all(c("be", "source", "organism") %in% names(scope)),
      all(unlist(lapply(scope, length))==1),
      all(unlist(lapply(scope, is.character)))
   )

   ## BEIDList object ----
   toRet <- l
   attr(toRet, "metadata") <- metadata[
      match(names(l), metadata$.lname),,
      drop=FALSE
   ]
   attr(toRet, "scope") <- scope
   class(toRet) <- c("BEIDList", class(toRet))
   return(toRet)

}

###############################################################################@
#' @export
#'
scope.BEIDList <- function(x, ...){
   attr(x, "scope")
}


###############################################################################@
#' @export
#'
metadata.BEIDList <- function(x, ...){
   attr(x, "metadata")
}

###############################################################################@
#' @export
#'
`metadata<-.BEIDList` <- function(x, value){
   return(BEIDList(x, scope=scope(x), metadata=value))
}

###############################################################################@
#' Check if the provided object is a [BEIDList]
#'
#' @param x the object to check
#'
#' @return A logical value
#'
#' @export
#'
is.BEIDList <- function(x){
   inherits(x, "BEIDList")
}

###############################################################################@
#' @export
#'
length.BEIDList <- function(x){
   y <- x
   class(y) <- "list"
   length(y)
}

###############################################################################@
#' @export
#'
stack.BEIDList <- function(x, ...){
   class(x) <- "list"
   return(stack(x))
}

###############################################################################@
#' @export
#'
format.BEIDList <- function(x, ...){
   toRet <- sprintf(
      'BEIDList of %s elements gathering %s BEIDs in total',
      length(x), length(unique(unlist(x)))
   )
   toRet <- paste(
      toRet,
      sprintf(
         '   - Scope: be="%s", source="%s", organism="%s"',
         scope(x)$be, scope(x)$source, scope(x)$organism
      ),
      sep="\n"
   )
   toRet <- paste(
      toRet,
      sprintf(
         '   - Metadata fields: "%s"',
         paste(colnames(metadata(x)), collapse='", "')
      ),
      sep="\n"
   )
   return(toRet)
}

###############################################################################@
#' @export
#'
print.BEIDList <- function(x, ...) cat(format(x, ...), "\n")

###############################################################################@
#' @export
#'
'[.BEIDList' <- function(x, i){
   l <- x
   class(l) <- "list"
   l <- l[i]
   metadata <- metadata(x)
   metadata <- metadata[
      match(names(l), metadata$.lname),,
      drop=FALSE
   ]
   return(BEIDList(
      l=l,
      metadata=metadata,
      scope=scope(x)
   ))
}

###############################################################################@
#' @export
#'
'[<-.BEIDList' <- function(x, i, value){
   stop("'[<-' is not supported for BEIDList: use 'c' instead")
}

###############################################################################@
#' @export
#'
'[[<-.BEIDList' <- function(x, i, value){
   stop("'[[<-' is not supported for BEIDList: use 'c' instead")
}

###############################################################################@
#' @export
#'
'names<-.BEIDList' <- function(x, value){
   value <- unique(as.character(value))
   stopifnot(length(x)==length(value))
   metadata <- metadata(x)
   scope <- scope(x)
   l <- x
   class(l) <- "list"
   names(l) <- value
   metadata <- dplyr::mutate(metadata, .lname=!!value)
   return(BEIDList(
      l=l,
      metadata=metadata,
      scope=scope
   ))
}

###############################################################################@
#' @export
#'
c.BEIDList <- function(...){
   inputs <- list(...)
   il <- lapply(inputs, function(x){class(x) <- "list"; return(x)})
   imd <- do.call(dplyr::bind_rows, lapply(inputs, attr, which="metadata"))
   l <- do.call(c, il)
   stopifnot(
      all(unlist(lapply(inputs, is.BEIDList))),
      all(unlist(lapply(inputs, identicalScopes, inputs[[1]]))),
      sum(duplicated(names(l)))==0
   )

   return(BEIDList(
      l=l,
      metadata=imd[
         match(names(l), imd$.lname),,
         drop=FALSE
      ],
      scope=scope(inputs[[1]])
   ))
}

###############################################################################@
#' Convert a BEIDList object in a specific identifier (BEID) scope
#'
#' @param x the BEIDList to be converted
#' @param be the type of biological entity to focus on.
#' If NULL (default), it's taken from `scope(x)`.
#' Used if `is.null(scope)`
#' @param source the source of BEID to focus on.
#' If NULL (default), it's taken from `scope(x)`.
#' Used if `is.null(scope)`
#' @param organism the organism of BEID to focus on.
#' If NULL (default), it's taken from `scope(x)`.
#' Used if `is.null(scope)`
#' @param scope a list with the following element:
#' - **be**
#' - **source**
#' - **organism**
#'
#' @param force if TRUE the conversion is done even between identical scopes
#' (default: FALSE)
#' @param restricted if TRUE (default) the BEID are limited to current version
#' of the source
#' @param prefFilter if TRUE (default) the BEID are limited to prefered
#' identifiers when they exist
#' @param ... additional parameters to the BEID conversion function
#'
#' @return A BEIDList
#'
#' @export
#'
focusOnScope.BEIDList <- function(
   x, be=NULL, source=NULL, organism=NULL,
   scope=NULL,
   force=FALSE,
   restricted=TRUE, prefFilter=TRUE,
   ...
){
   if(is.null(be)){
      be <- scope(x)$be
   }
   if(is.null(source)){
      source <- scope(x)$source
   }
   if(is.null(organism)){
      organism <- scope(x)$organism
   }
   if(!is.null(scope)){
      be <- scope$be
      source <- scope$source
      organism <- scope$organism
   }
   taxid <- getTaxId(organism)
   stopifnot(length(taxid)==1)
   orgsn <- getOrgNames(taxid)
   orgsn <- orgsn$name[which(orgsn$nameClass=="scientific name")]
   stopifnot(length(orgsn)==1)

   ##
   if(
      !force &&
      scope(x)$be==be &&
      scope(x)$source==source &&
      getTaxId(scope(x)$organism)==taxid
   ){
      return(x)
   }else{
      l <- x
      class(l) <- "list"
      md <- metadata(x)
      fscope <- scope(x)
      fscope$organism <- ifelse(
         fscope$organism=="any", organism, fscope$organism
      )

      toRet <- convBeIdLists(
         l,
         from=fscope$be, from.source=fscope$source, from.org=fscope$organism,
         to=be, to.source=source, to.org=organism,
         restricted=restricted, prefFilter=prefFilter,
         ...
      )

      toRet <- BEIDList(
         l=toRet[md$.lname],
         metadata=md,
         scope=list(
            be=be, source=source, organism=orgsn
         )
      )
      return(toRet)
   }
}

###############################################################################@
#' @export
#'
filterByBEID.BEIDList <- function(
   x,
   toKeep,
   ...
){
   l <- lapply(
      x,
      intersect,
      toKeep
   )
   l <- l[which(unlist(lapply(l, length))>0)]
   metadata <- metadata(x)
   metadata <- metadata[
      match(names(l), metadata$.lname),,
      drop=FALSE
   ]
   return(BEIDList(
      l=l,
      metadata=metadata,
      scope=scope(x)
   ))
}
