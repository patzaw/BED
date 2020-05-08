#' List all the BED queries in cache and the total size of the cache
#'
#' @param verbose if TRUE (default) prints a message displaying the total
#' size of the cache
#'
#' @return A data.frame giving for each query (row names) its size in Bytes
#' (column "size") and in human readable format (column "hr"). The
#' attribute "Total" corresponds to the sum of all the file size.
#'
#' @seealso [clearBedCache]
#'
#' @export
#'
lsBedCache <- function(verbose=TRUE){
   ##
   sunits <- c("B", "KB", "MB", "GB", "TB")
   ##
   if(!checkBedConn()){
      stop("Unsuccessful connection")
   }
   if(!get("useCache", bedEnv)){
      warning("Cache is OFF: nothing to list")
      invisible(NULL)
   }else{
      cache <- get("cache", bedEnv)
      if(nrow(cache)==0){
         message("Empty cache")
         total <- data.frame(
            size=0,
            hr="0 B",
            stringsAsFactors=FALSE
         )
         rownames(total) <- "Total"
         toRet <- data.frame(
            size=numeric(),
            hr=character(),
            stringsAsFactors=FALSE
         )
         attr(toRet, "Total") <- total
         return(toRet)
      }
      cachedbDir <- dirname(get("cachedbFile", bedEnv))
      toRet <- file.size(file.path(cachedbDir, cache$file))
      names(toRet) <- cache$name
      total <- sum(toRet)
      toRetUnits <- log2(toRet)%/%10
      toRetHR <- lapply(
         1:length(toRet),
         function(i){
            format(
               toRet[i]/(2^(10*toRetUnits[i])),
               digit=1,
               nsmall=ifelse(toRetUnits[i]==0, 0, 1)
            )
         }
      )
      toRet <- data.frame(
         size=toRet,
         hr=paste(toRetHR, sunits[toRetUnits+1]),
         stringsAsFactors=FALSE
      )
      totalUnits <- log2(total)%/%10
      if(is.na(totalUnits)){
         totalUnits <- 0
      }
      totalHR <- format(
         total/(2^(10*totalUnits)),
         digit=1,
         nsmall=ifelse(totalUnits==0, 0, 1)
      )
      total <- data.frame(
         size=total,
         hr=paste(totalHR, sunits[totalUnits+1]),
         stringsAsFactors=FALSE
      )
      rownames(total) <- "Total"
      attr(toRet, "Total") <- total
      if(verbose){
         message(paste("Total cache size on disk:", total$hr))
      }
      return(toRet[order(toRet$size, decreasing=TRUE),])
   }
}
