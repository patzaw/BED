#' Converts lists of BE IDs
#'
#' @param idList a list of IDs lists
#' @param ... params for the \code{\link{convBeIds}} function
#'
#' @return a list of \code{\link{convBeIds}} ouput ids
#'
#' @examples \dontrun{
#' convBeIdLists(
#'    idList=list(a=c("10", "100"), b=c("1000")),
#'    from="Gene",
#'    from.source="EntrezGene",
#'    from.org="human",
#'    to.source="Ens_gene"
#' )
#' }
#'
#' @seealso \code{\link{convBeIds}}, \code{\link{convDfBeIds}}
#'
#' @export
#'
convBeIdLists <- function(
    idList,
    ...
){
    ct <- convBeIds(unique(unlist(idList)), ...)
    return(lapply(
        idList,
        function(x) setdiff(unique(ct$to[which(ct$from %in% x)]), NA)
    ))
}
