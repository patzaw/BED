#' Lists all the biological entities (BE) available in the BED database
#'
#' @return A character vector of biological entities (BE)
#'
#' @seealso [listPlatforms], [listBeIdSources],
#' [listOrganisms]
#'
#' @export
#'
listBe <- function(){
   toRet <- bedCall(
   neo2R::cypher,
   query='MATCH (n:BEType) return n.value as be'
   )
   return(toRet$be)
}
