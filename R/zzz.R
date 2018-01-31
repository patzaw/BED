#' Connect to a neo4j BED database
#'
#' @param url a character string. The host and the port are sufficient
#' (e.g: "localhost:7474")
#' @param username a character string
#' @param password a character string
#' @param connection the id of the connection already registered to use. By
#' default the first registered connection is used.
#' @param remember if TRUE the connection is registered. All the registered
#' connections can be listed with \code{\link{lsBedConnections}} and any of
#' them can be forgotten with \code{\link{forgetBedConnection}}.
#'
#' @return This function does not return any value. It prepares the BED
#' environment to allow transparent DB calls.
#'
#' @details Be carefull that you should reconnect to BED database each time
#' the environment is reloaded.
#'
#' @seealso \code{\link{checkBedConn}}, \code{\link{lsBedConnections}},
#' \code{\link{forgetBedConnection}}
#'
#' @importFrom neo2R startGraph
#' @export
#'
connectToBed <- function(
   url=NULL, username=NULL, password=NULL, connection=1,
   remember=TRUE
){
   bedDir <- file.path(
      Sys.getenv("HOME"), "R", "BED"
   )
   dir.create(bedDir, showWarnings=FALSE, recursive=TRUE)
   conFile <- file.path(
      bedDir, "BED-Connections.rda"
   )
   connections <- list()
   if(file.exists(conFile)){
      load(conFile)
   }
   if(length(url)==0 && length(username)==0 && length(password)==0){
      if(length(connections)==0){
         checkBedConn()
         return(FALSE)
      }else{
         url <- connections[[connection]]["url"]
         username <- connections[[connection]]["username"]
         password <- connections[[connection]]["password"]
      }
      connections <- c(connections[connection], connections[-connection])
   }else{
      connections <- c(
         list(c(url=url, username=username, password=password)),
         connections
      )
   }
   ## The graph DB
   assign(
      "graph",
      startGraph(
         url=url,
         username=username,
         password=password
      ),
      bedEnv
   )
   if(!checkBedConn(verbose=TRUE)){
      rm("graph", envir=bedEnv)
      return(FALSE)
   }
   ##
   if(remember){
      connections <- unique(connections)
      save(connections, file=conFile)
   }
   ## The SQLite cache
   cachedbDir <- file.path(
      Sys.getenv("HOME"), "R",
      "BED",
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

##########################
#' List all registered BED connection
#'
#' @seealso \code{\link{connectToBed}},
#' \code{\link{forgetBedConnection}}, \code{\link{checkBedConn}}
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

##########################
#' Forget a BED connection
#'
#' @param connection the id of the connection to forget.
#'
#' @seealso \code{\link{lsBedConnections}},
#' \code{\link{checkBedConn}}, \code{\link{connectToBed}}
#'
#'
#' @export
#'
forgetBedConnection <- function(connection){
   conFile <- file.path(
      Sys.getenv("HOME"), "R", "BED", "BED-Connections.rda"
   )
   connections <- list()
   if(file.exists(conFile)){
      load(conFile)
   }
   connections <- connections[-connection]
   save(connections, file=conFile)
}

##########################
bedEnv <- new.env(hash=TRUE, parent=emptyenv())
.onLoad <- function(libname, pkgname){
   connectToBed()
}
