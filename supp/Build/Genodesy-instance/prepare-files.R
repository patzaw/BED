
library(BED)

###############################################################################@
## Config ----

stopifnot(exists("config_file"))

config <- jsonlite::read_json(config_file)
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
wd <- config$BED_WORKING

###############################################################################@
## Uniprot ----

tois <- c(
   "9606"="human",
   "10090"="rodents",
   "10116"="rodents",
   "9823"="mammals",
   "7955"="vertebrates"
)

ftp <- "https://ftp.expasy.org/databases/uniprot/current_release/knowledgebase/taxonomic_divisions"
avRel <- readLines(file.path(ftp, "reldate.txt"), n=1)
avRel <- sub(
   "^UniProt Knowledgebase Release ", "",
   sub(" consists of:$", "", avRel)
)

for(i in 1:length(tois)){
   toi <- names(tois)[i]
   doi <- as.character(tois[i])
   message(toi, " ", doi)
   BED:::dumpUniprotDb(
      taxOfInt=toi,
      divOfInt=doi,
      release=avRel,
      ddir=wd,
      ftp='https://ftp.expasy.org/databases/uniprot',
      env=parent.frame(n=1)
   )
}

