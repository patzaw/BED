###############################################################################@
#' Connect to a neo4j BED database
#'
#' @param url a character string. The host and the port are sufficient
#' (e.g: "localhost:5454")
#' @param username a character string
#' @param password a character string
#' @param connection the id of the connection already registered to use. By
#' default the first registered connection is used.
#' @param remember if TRUE connection information is saved localy in a file
#' and used to automatically connect the next time.
#' The default is set to FALSE.
#' All the connections that have been saved can be listed
#' with [lsBedConnections] and any of
#' them can be forgotten with [forgetBedConnection].
#' @param useCache if TRUE the results of large queries can be saved locally
#' in a file. The default is FALSE for policy reasons.
#' But it is recommended to set it to TRUE to improve the speed
#' of recurrent queries.
#' If NA (default parameter) the value is taken from former connection if
#' it exists or it is set to FALSE.
#' @param importPath the path to the import folder for loading information
#' in BED (used only when feeding the database ==> default: NULL)
#' @param .opts a named list or CURLOptions object identifying the curl
#' options for the handle (see [RCurl::curlPerform()]).
#' (for example: `.opts = list(ssl.verifypeer = FALSE)`)
#'
#' @return This function does not return any value. It prepares the BED
#' environment to allow transparent DB calls.
#'
#' @details Be careful that you should reconnect to BED database each time
#' the environment is reloaded. It is done automatically if `remember` is
#' set to TRUE.
#'
#' Information about how to get an instance of the BED 'Neo4j' database is
#' provided here:
#' - <https://github.com/patzaw/BED#bed-database-instance-available-as-a-docker-image>
#' - <https://github.com/patzaw/BED#build-a-bed-database-instance>
#'
#' @seealso [checkBedConn], [lsBedConnections], [forgetBedConnection]
#'
#' @export
#'
connectToBed <- function(
   url=NULL, username=NULL, password=NULL, connection=1,
   remember=FALSE, useCache=NA,
   importPath=NULL,
   .opts=list()
){
   stopifnot(
      is.logical(remember), length(remember)==1, !is.na(remember),
      is.logical(useCache), length(useCache)==1
   )
   bedDir <- file.path(Sys.getenv("HOME"), "R", "BED")
   if(remember){
      dir.create(bedDir, showWarnings=FALSE, recursive=TRUE)
   }
   conFile <- file.path(bedDir, "BED-Connections.rda")
   connections <- list()
   if(file.exists(conFile)){
      load(conFile)
   }
   if(length(url)==0 && length(username)==0 && length(password)==0){
      if(length(connections)==0){
         checkBedConn()
         return(FALSE)
      }else{
         url <- connections[[connection]][["url"]]
         username <- connections[[connection]][["username"]]
         password <- connections[[connection]][["password"]]
         useCache <- ifelse(
            is.na(useCache),
            connections[[connection]][["cache"]],
            useCache
         )
         .opts <- c(
            .opts,
            connections[[connection]][[".opts"]]
         )
      }
      connections <- c(connections[connection], connections[-connection])
   }else{
      if(length(username)==0 && length(password)==0){
         username <- password <- NA
      }
      url <- sub("^https?://", "", url)
      if(is.na(useCache)){
         useCache <- FALSE
      }
      connections <- c(
         list(list(
            url=url, username=username, password=password, cache=useCache,
            .opts=.opts
         )),
         connections
      )
   }
   ## The graph DB
   e1 <- try(assign(
      "graph",
      neo2R::startGraph(
         url=paste0("https://", url),
         username=username,
         password=password,
         importPath=importPath,
         .opts=.opts
      ),
      bedEnv
   ), silent=TRUE)
   if(inherits(e1, "try-error")){
      e2 <- try(assign(
         "graph",
         neo2R::startGraph(
            url=paste0("http://", url),
            username=username,
            password=password,
            importPath=importPath,
            .opts=.opts
         ),
         bedEnv
      ), silent=TRUE)
      if(inherits(e2, "try-error")){
         message(e1)
         message(e2)
      }
   }
   assign("useCache", useCache, bedEnv)
   corrConn <- checkBedConn(verbose=TRUE)
   if(!corrConn){
      rm("graph", envir=bedEnv)
      return(FALSE)
   }else{
      connections[[1]][colnames(attr(corrConn, "dbVersion")[1,])] <-
         as.character(attr(checkBedConn(), "dbVersion")[1,])
      connections[[1]]["cache"] <- useCache
   }
   ##
   if(remember){
      connections <- connections[which(
         !duplicated(unlist(lapply(
            connections,
            function(x){
               x["url"]
            }
         )))
      )]
      save(connections, file=conFile)
   }
   ## File system cache
   if(useCache){
      dir.create(bedDir, showWarnings=FALSE, recursive=TRUE)
      cachedbDir <- file.path(
         bedDir,
         paste(
            sub(
               "[:]", "..",
               sub(
                  "[/].*$", "",
                  sub("^https{0,1}[:][/]{2}", "", url)
               )
            ),
            username,
            sep=".."
         )
      )
      dir.create(cachedbDir, showWarnings=FALSE, recursive=TRUE)
      cachedbFile <- file.path(cachedbDir, "0000-BED-cache.rda")
      assign(
         "cachedbFile",
         cachedbFile,
         bedEnv
      )
      if(file.exists(cachedbFile)){
         load(cachedbFile)
      }else{
         cache <- data.frame(
            name=character(),
            file=character(),
            stringsAsFactors=FALSE
         )
      }
      assign(
         "cache",
         cache,
         bedEnv
      )
      ## Managing cache vs DB version
      checkBedCache(newCon=TRUE)
   }
}

###############################################################################@
#' List all registered BED connection
#'
#' @seealso [connectToBed], [forgetBedConnection], [checkBedConn]
#'
#' @export
#'
lsBedConnections <- function(){
   conFile <- file.path(
      Sys.getenv("HOME"), "R", "BED", "BED-Connections.rda"
   )
   connections <- list()
   if(file.exists(conFile)){
      load(conFile)
   }
   return(connections)
}

###############################################################################@
#' Forget a BED connection
#'
#' @param connection the id of the connection to forget.
#' @param save a logical. Should be set to TRUE to save the updated list of
#' connections in the file space (default to FALSE to comply with CRAN
#' policies).
#'
#' @seealso [lsBedConnections], [checkBedConn], [connectToBed]
#'
#' @export
#'
forgetBedConnection <- function(connection, save=FALSE){
   conFile <- file.path(
      Sys.getenv("HOME"), "R", "BED", "BED-Connections.rda"
   )
   connections <- list()
   if(file.exists(conFile)){
      load(conFile)
   }
   connections <- connections[-connection]
   if(save){
      save(connections, file=conFile)
   }
}

###############################################################################@
bedEnv <- new.env(hash=TRUE, parent=emptyenv())
.onLoad <- function(libname, pkgname){
   connectToBed()
}
