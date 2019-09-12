#' Check if two objects have the same BEID scope
#' 
#' @param x the object to test
#' @param y the object to test
#' 
#' @return A logical indicating if the 2 scopes are identical
#' 
#' @export
#' 
identicalScopes <- function(x, y){
   xs <- scope(x)
   ys <- scope(y)
   return(
      xs$be==ys$be &
      xs$source==ys$source &
      xs$organism==ys$organism
   )
}
