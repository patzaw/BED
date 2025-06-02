library(BED)
library(jsonlite)
library(dplyr)
library(BDSTools)

source("helpers/loadMBObjects_fromTKCat.R")

## Config ----
config <- jsonlite::read_json("deploy_config.json")
config <- lapply(
   config, function(x){
      if(!is.character(x)){
         return(x)
      }else{
         sub(pattern="___HOME___", replacement=Sys.getenv("HOME"), x = x)
      }
   }
)
config <- lapply(
   config, function(x){
      if(!is.character(x)){
         return(x)
      }else{
         sub(pattern="___ROOT___", replacement=config$ROOT, x = x)
      }
   }
)

## Connection ----
connectToBed(
   url=sprintf("localhost:%s", config$NJ_HTTP_PORT),
   remember=FALSE,
   useCache=TRUE,
   importPath=config$BED_IMPORT
)
clearBedCache(force = TRUE, hard = TRUE)

## Add MetaBase identifiers ----
mb <- get_MDB(ap_rd_tkcat(), "MetaBase", check = FALSE)
loadMBObjects_fromTKCat(
   orgOfInt = c("Homo sapiens", "Mus musculus", "Rattus norvegicus"),
   tkmb = mb
)

