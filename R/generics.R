###############################################################################@
#' Focus a BE related object on a specific identifier (BEID) scope
#'
#' @param x the object to be focused
#' @param be the type of biological entity to focus on
#' @param source the source of BEID to focus on
#' @param organism the organism of BEID to focus on
#' @param restricted if TRUE (default) the BEID are limited to current version
#' of the source
#' @param prefFilter if TRUE (default) the BEID are limited to prefered
#' identifiers when they exist
#' @param ... additional parameters to the BEID conversion function
#'
#' @return Depends on the class of x
#'
#' @export
#'
focusOnScope <- function(x, ...){
   UseMethod("focusOnScope", x)
}


###############################################################################@
#' Get the BEID scope of an object
#'
#' @export
#'
scope <- function(x, ...){
   UseMethod("scope", x)
}

###############################################################################@
#' Get the BEID scopes of an object
#'
#' @return A tibble with 4 columns:
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
#' @export
#'
metadata <- function(x, ...){
   UseMethod("metadata", x)
}

###############################################################################@
#' Get the BEIDs from an object
#'
#' @return A tibble with at least 4 columns:
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
#' @param x the object to filter
#' @param toKeep a vector of elements to keep
#' @param ... method specific parameters
#'
#' @export
#'
filterByBEID <- function(x, toKeep, ...){
   UseMethod("filterByBEID", x)
}
