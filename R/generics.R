###############################################################################@
#' Focus a BE related object on a specific identifier (BEID) scope
#'
#' @param x an object representing a collection of BEID (e.g. BEIDList)
#' @param be the type of biological entity to focus on.
#' Used if `is.null(scope)`
#' @param source the source of BEID to focus on.
#' Used if `is.null(scope)`
#' @param organism the organism of BEID to focus on.
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
#' @param ... method specific parameters for BEID conversion
#'
#' @return Depends on the class of x
#'
#' @export
#'
focusOnScope <- function(
   x,
   be, source, organism,
   scope,
   force,
   restricted, prefFilter,
   ...
){
   UseMethod("focusOnScope", x)
}


###############################################################################@
#' Get the BEID scope of an object
#'
#' @param x an object representing a collection of BEID (e.g. BEIDList)
#' @param ... method specific parameters
#'
#' @export
#'
scope <- function(x, ...){
   UseMethod("scope", x)
}

###############################################################################@
#' Get the BEID scopes of an object
#'
#' @param x an object representing a collection of BEID (e.g. BEIDList)
#' @param ... method specific parameters
#'
#' @return A tibble with 4 columns:
#'
#' - be
#' - source
#' - organism
#' - Freq
#'
#' @export
#'
scopes <- function(x, ...){
   UseMethod("scopes", x)
}

###############################################################################@
#' Get object metadata
#'
#' @param x an object representing a collection of BEID (e.g. BEIDList)
#' @param ... method specific parameters
#'
#' @export
#'
metadata <- function(x, ...){
   UseMethod("metadata", x)
}

###############################################################################@
#' Set object metadata
#'
#' @param x an object representing a collection of BEID (e.g. BEIDList)
#' @param value a data.frame with rownames or
#' a column "**.lname**" all in names of l.
#'
#' @export
#'
`metadata<-` <- function(x, value){
   UseMethod("metadata<-", x)
}

###############################################################################@
#' Get the BEIDs from an object
#'
#' @param x an object representing a collection of BEID (e.g. BEIDList)
#' @param ... method specific parameters
#'
#' @return A tibble with at least 4 columns:
#'
#' - value
#' - be
#' - source
#' - organism
#' - ...
#'
#' @export
#'
BEIDs <- function(x, ...){
   UseMethod("BEIDs", x)
}

###############################################################################@
#' Filter an object to keep only a set of BEIDs
#'
#' @param x an object representing a collection of BEID (e.g. BEIDList)
#' @param toKeep a vector of elements to keep
#' @param ... method specific parameters
#'
#' @export
#'
filterByBEID <- function(x, toKeep, ...){
   UseMethod("filterByBEID", x)
}
