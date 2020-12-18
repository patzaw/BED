#' Put a BED query result in cache
#'
#' Internal use
#'
#' @param value the result to cache
#' @param name the name of the query
#'
#' @seealso [cacheBedCall], [loadBedResult]
#'
cacheBedResult <- function(
   value,
   name
){
   ## Write cache in the user file space only if the "useCache" parameter
   ## is set to TRUE when calling `connectToBed()` (default: useCache=FALSE)
   if(!get("useCache", bedEnv)){
      invisible(NULL)
   }else{
      if(length(grep("^0000-", name))>0){
         stop('names starting by "0000-" are reserved')
      }
      cache <- get("cache", bedEnv)
      cachedbFile <- get("cachedbFile", bedEnv)
      cachedbDir <- dirname(cachedbFile)
      file <- paste0(name, ".rda")
      save(value, file=file.path(cachedbDir, file))
      cache[name, ] <- data.frame(name=name, file=file, stringsAsFactors=FALSE)
      save(cache, file=cachedbFile)
      assign(
         "cache",
         cache,
         bedEnv
      )
   }
}

#' Get a BED query result from cache
#'
#' Internal use
#'
#' @param name the name of the query
#'
#' @seealso [cacheBedCall], [cacheBedResult]
#'
loadBedResult <- function(name){
   value <- NULL
   cache <- get("cache", bedEnv)
   cachedbFile <- get("cachedbFile", bedEnv)
   cachedbDir <- dirname(cachedbFile)
   if(!name %in% rownames(cache)){
      stop(sprintf("%s not in cache", name))
   }
   load(file.path(cachedbDir, cache[name, "file"]))
   return(value)
}
