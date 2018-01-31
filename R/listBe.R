#' Lists all the biological entities (BE) available in the BED database
#'
#' @return A character vector of biological entities (BE)
#'
#' @seealso \code{\link{listPlatforms}}, \code{\link{listBeIdSources}},
#' \code{\link{listOrganisms}}
#'
#'
#' @importFrom neo2R prepCql cypher
#' @export
#'
listBe <- function(){
    toRet <- bedCall(cypher, query='MATCH (n:BEType) return n.value as be')
    return(toRet$be)
}
