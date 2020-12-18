#' Clear the BED cache SQLite database
#'
#' @param queries a character vector of the names of queries to remove.
#' If NULL all queries are removed.
#' @param force if TRUE clear the BED cache table even if cache
#' file is not found
#' @param hard if TRUE remove everything in cache without checking file names
#' @param verbose display some information during the process
#'
#' @seealso [lsBedCache]
#'
#' @export
#'
clearBedCache <- function(
   queries=NULL, force=FALSE, hard=FALSE, verbose=FALSE
){
   if(!checkBedConn(verbose=FALSE)){
      stop("Unsuccessful connection")
   }
   ## Write cache in the user file space only if the "useCache" parameter
   ## is set to TRUE when calling `connectToBed()` (default: useCache=FALSE)
   if(!get("useCache", bedEnv)){
      warning("Cache is OFF: nothing is done")
      invisible(NULL)
   }else{
      if(hard){
         cachedbFile <- get("cachedbFile", bedEnv)
         cachedbDir <- dirname(cachedbFile)
         file.remove(list.files(path=cachedbDir, full.names=TRUE))
         cache <- data.frame(
            name=character(),
            file=character(),
            stringsAsFactors=FALSE
         )
         assign(
            "cache",
            cache,
            bedEnv
         )
         checkBedCache()
         invisible()
      }
      cache <- get("cache", bedEnv)
      cachedbFile <- get("cachedbFile", bedEnv)
      cachedbDir <- dirname(cachedbFile)
      if(is.null(queries)){
         queries <- cache
      }else{
         if(any(!queries %in% rownames(cache))){
            warning(sprintf(
               "%s not in cache",
               paste(setdiff(queries, rownames(cache)), collapse=", ")
            ))
         }
         queries <- cache[intersect(queries, rownames(cache)),]
      }
      for(tn in rownames(queries)){
         if(verbose){
            message(paste("Removing", tn, "from cache"))
         }
         if(file.remove(file.path(cachedbDir, queries[tn, "file"]))){
            cache <- cache[setdiff(rownames(cache), tn),]
            save(cache, file=cachedbFile)
            assign(
               "cache",
               cache,
               bedEnv
            )
         }else{
            if(!force){
               stop(paste(
                  "Could not remove the following file:",
                  file.path(cachedbDir, queries[tn, "file"]),
                  "\nCheck cache files and/or clear the whole-",
                  "cache using force=TRUE"
               ))
            }else{
               warning(paste(
                  "Could not remove the following file:",
                  file.path(cachedbDir, queries[tn, "file"]),
                  "\nClearing cache table anyway (force=TRUE)"
               ))
               cache <- cache[setdiff(rownames(cache), tn),]
               save(cache, file=cachedbFile)
               assign(
                  "cache",
                  cache,
                  bedEnv
               )
            }
         }
      }
      invisible(cache)
   }
}
