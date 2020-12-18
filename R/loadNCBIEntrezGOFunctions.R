#' Feeding BED: Load in BED GO functions associated to Entrez gene IDs
#' from NCBI
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param organism character vector of 1 element corresponding to the organism
#' of interest (e.g. "Homo sapiens")
#' @param reDumpThr time difference threshold between 2 downloads
#' @param ddir path to the directory where the data should be saved
#' @param curDate current date as given by [Sys.Date]
#'
loadNCBIEntrezGOFunctions <- function(
   organism,
   reDumpThr=100000,
   ddir,
   curDate
){

   ################################################
   ## Organism
   taxId <- getTaxId(organism)

   ################################################
   ## Dump ----
   dumpNcbiDb(
      taxOfInt=taxId,
      reDumpThr=reDumpThr,
      ddir=ddir,
      toLoad="gene2go",
      curDate=curDate
   )
   gene2go <- gene2go[which(
      gene2go$Category == "Function" & gene2go$Evidence != "ND" &
         !gene2go$Qualifier %in% c("NOT", "NOT contributes_to")
   ),]

   ################################################
   ## DB information ----
   gdbname <- "EntrezGene"
   odbname <- "GO_function"

   ################################################
   ## Add objects
   message(Sys.time(), " --> Importing GO functions")
   toImport <- unique(gene2go[, "GO_ID", drop=F])
   colnames(toImport) <- "id"
   loadBE(
      d=toImport, be="Object",
      dbname=odbname,
      version=NA,
      taxId=NA
   )

   ################################################
   ## Add GO term as symbols
   message(Sys.time(), " --> Importing GO function terms as symbols")
   toImport <- unique(gene2go[, c("GO_ID", "GO_term")])
   colnames(toImport) <- c("id", "symbol")
   if(any(table(toImport$symbol)>1)){
      stop("Verify object symbol for NA or blank values")
   }
   toImport$canonical <- TRUE
   loadBESymbols(d=toImport, be="Object", dbname=odbname)

   ################################################
   ## Add "codes_for" edges
   toImport <- unique(gene2go[,
      c("GeneID", "GO_ID")
   ])
   colnames(toImport) <- c("gid", "oid")
   loadCodesFor(
      d=toImport,
      gdb=gdbname,
      odb=odbname
   )

}
