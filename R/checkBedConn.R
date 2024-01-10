#' Check if there is a connection to a BED database
#'
#' @param verbose if TRUE print information about the BED connection
#' (default: FALSE).
#'
#' @return
#'
#'  - TRUE if the connection can be established
#'  - Or FALSE if the connection cannot be established or the "System" node
#'  does not exist or does not have "BED" as name or any version recorded.
#'
#' @seealso [connectToBed]
#'
#' @export
#'
checkBedConn <- function(verbose=FALSE){
   if(!exists("graph", bedEnv)){
      message(
         "BED is not connected.\n",
         "You can connect to a BED database instance using the connectToBed",
         " function."
      )
      return(FALSE)
   }
   nmv <- bedEnv$graph$version[1]
   if(! nmv %in% c("3", "5")){
      message(sprintf("The version %s of Neo4j is not supported", nmv))
      return(FALSE)
   }
   if(verbose) message(get("graph", bedEnv)$url)
   dbVersion <- try(bedCall(
      f=neo2R::cypher,
      query=neo2R::prepCql(c(
         'MATCH (n:System) RETURN',
         'n.name as name, n.instance as instance, n.version as version'
      )),
      bedCheck=FALSE
   ))
   if(inherits(dbVersion, "try-error")){
      return(FALSE)
   }
   if(is.null(dbVersion)){
      dbSize <- bedCall(
         f=neo2R::cypher,
         query='MATCH (n) WITH n LIMIT 1 RETURN count(n);',
         bedCheck=FALSE
      )[,1]
      if(is.null(dbSize)){
         warning("No connection")
         return(FALSE)
      }
      if(dbSize==0){
         warning("BED DB is empty !")
         return(TRUE)
      }else{
         warning("DB is not empty but without any System node. Check url.")
         return(FALSE)
      }
   }
   if(verbose){
      message(dbVersion$name)
      message(dbVersion$instance)
      message(dbVersion$version)
      if(get("useCache", bedEnv)){
         message("Cache ON")
      }else{
         message("Cache OFF")
      }
   }
   if(
      is.null(dbVersion$name) || dbVersion$name!="BED" ||
      is.null(dbVersion$instance) ||
      is.null(dbVersion$version)
   ){
      warning("Wrong system. Check url.")
      print(get("graph", bedEnv)$url)
      return(FALSE)
   }
   toRet <- TRUE
   attr(toRet, "dbVersion") <- dbVersion
   return(toRet)
}
