library(rvest)
library(tibble)
get_ensembl_release_ref <- function(){
   eftp <- rvest::read_html("https://ftp.ensembl.org/pub/current/mysql/")
   ftable <- rvest::html_table(eftp)[[1]]
   org_dir <- grep("_core_", ftable$Name, value=TRUE)
   org_table <- do.call(rbind, lapply(strsplit(org_dir, split="_"), function(x){
      gv <- sub("/", "", x[length(x)])
      e <- x[length(x)-1]
      core <- which(x=="core")
      org <- paste(x[1:(core-1)], collapse=" ")
      substr(org, 1, 1) <- toupper(substr(org, 1,1))
      return(tibble::tibble(
         organism=org,
         release=e,
         genome_version=gv
      ))
   }))
   return(org_table)
}

