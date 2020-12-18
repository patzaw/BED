#' Check BED cache
#'
#' This function checks information recorded into BED cache
#' and resets it if not relevant.
#'
#' Internal use.
#'
#' @param newCon if TRUE for the loading of the system information file
#'
#' @seealso [clearBedCache], [lsBedCache]
#'
checkBedCache <- function(newCon=FALSE){
   if(!checkBedConn()){
      stop("Not connected to BED")
   }
   ## Write cache in the user file space only if the "useCache" parameter
   ## is set to TRUE when calling `connectToBed()` (default: useCache=FALSE)
   if(!get("useCache", bedEnv)){
      invisible(NULL)
   }else{
      dbSize <- bedCall(
         neo2R::cypher,
         'MATCH (n) WITH n LIMIT 1 RETURN count(n);'
      )[,1]
      if(dbSize==0){
         warning("Clearing cache")
         cache <- clearBedCache()
      }else{
         dbVersion <- bedCall(
            neo2R::cypher,
            query=neo2R::prepCql(c(
               'MATCH (n:System) RETURN',
               'n.name as name, n.instance as instance, n.version as version'
            ))
         )
         dbVersion$rbed <- utils::packageDescription(
            utils::packageName()
         )$Version
         ##
         cachedbFile <- get("cachedbFile", bedEnv)
         cachedbDir <- dirname(cachedbFile)
         sysFile <- file.path(cachedbDir, "0000-BED-system.rda")
         if(file.exists(sysFile)){
            if(!exists("system", envir=bedEnv) | newCon){
               load(file.path(cachedbDir, "0000-BED-system.rda"), envir=bedEnv)
            }
            system <- get("system", envir=bedEnv)
            if(
               any(!names(dbVersion) %in% names(system)) ||
               dbVersion$name != system$name ||
               dbVersion$instance != system$instance ||
               dbVersion$version != system$version ||
               dbVersion$rbed != system$rbed
            ){
               message("Inconsitent cache == > clearing cache")
               cache <- clearBedCache()
               system <- dbVersion
               save(system, file=sysFile)
               assign(
                  "system",
                  system,
                  bedEnv
               )
            }else{
               cache <- get("cache", bedEnv)
            }
         }else{
            message("No recorded version ==> clearing cache")
            cache <- clearBedCache()
            system <- dbVersion
            save(system, file=sysFile)
            assign(
               "system",
               system,
               bedEnv
            )
         }
      }
      invisible(cache)
   }
}
