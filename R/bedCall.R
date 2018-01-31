#' Call a function on the BED graph
#'
#' @param f the function to call
#' @param ... params for f
#' @param bedCheck check if a connection to BED exists.
#'
#' @return The output of the called function.
#'
#' @examples \dontrun{
#' result <- bedCall(
#'    cypher,
#'    query=prepCql(
#'       'MATCH (n:BEID)',
#'       'WHERE n.value IN $values',
#'       'RETURN n.value AS value, n.labels, n.database'
#'    ),
#'    parameters=list(values=c("10", "100"))
#' )
#' }
#'
#' @seealso \code{\link{checkBedConn}}
#'
#' @export
#'
bedCall <- function(f, ..., bedCheck=TRUE){
    if(bedCheck) if(!checkBedConn()){
        stop("No connection")
    }
    do.call(f, list(graph=get("graph", bedEnv), ...))
}
