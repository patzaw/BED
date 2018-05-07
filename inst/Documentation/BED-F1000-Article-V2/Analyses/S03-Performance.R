library(BED)
library(biomaRt)
hsEnsembl <- useMart("ensembl",dataset="hsapiens_gene_ensembl")
mmEnsembl <- useMart("ensembl",dataset="mmusculus_gene_ensembl")
library(mygene)
library(gProfileR)

nrep <- 10
resDir <- "Perf-Results"
dir.create(resDir, showWarnings=FALSE)

###############################################################################@
## Convert ensembl --> entrez human ----
scopes <- "Human-Genes-Ensembl-Entrez"

## * Conversion functions ----
bedConv <- function(ids){
   convBeIds(
      ids=ids, from="Gene", from.source="Ens_gene", from.org="human",
      to.source="EntrezGene", restricted=TRUE
   )
}
usedCache <- c(
   "getBeIdConvTable_Gene_Ens_gene_Gene_EntrezGene_9606_restricted",
   "convBeIds_Gene_Ens_gene_Gene_EntrezGene_9606_9606_restricted"
)
bmConv <- function(ids){
   getBM(
      values = ids,
      filters = 'ensembl_gene_id',
      attributes=c('ensembl_gene_id', 'entrezgene'),
      mart = hsEnsembl
   )
}
mgConv <- function(ids){
   queryMany(
      qterm=ids,
      scopes = "ensembl.gene",
      fields="entrezgene",
      species="human"
   )
}
gpConv <- function(ids){
   do.call(rbind, gconvert(
      query=ids,
      target="ENTREZGENE_ACC",
      organism="hsapiens",
      filter_na=FALSE,
      df=FALSE
   ))
}

## * IDs to convert ----
allIds <- getBeIds(
   be="Gene", source="Ens_gene", organism="human", restricted=TRUE
)

## * n=100 ----
nbid <- 100
message(scopes, ": ", nbid)
resFile <- file.path(resDir, paste0(scopes, "-", nbid, ".rda"))
if(file.exists(resFile)){
   message("   Results available ==> skip")
}else{
   message("   Results not available ==> computing...")
   bedTC <- bmTC <- mgTC <- gpTC <- c()
   for(r in 1:nrep){
      ids <- sample(unique(allIds$id), size=nbid, replace=FALSE)
      bedTC <- rbind(bedTC, system.time(bedConv(ids)))
      bmTC <- rbind(bmTC, system.time(bmConv(ids)))
      mgTC <- rbind(mgTC, system.time(mgConv(ids)))
      gpTC <- rbind(gpTC, system.time(gpConv(ids)))
      cat(paste(r, ""))
   }
   save(
      bedTC, bmTC, mgTC, gpTC,
      file=resFile
   )
   message("   Done")
}
cat("", fill=TRUE)

## * n=20000 ----
nbid <- 20000
message(scopes, ": ", nbid)
resFile <- file.path(resDir, paste0(scopes, "-", nbid, ".rda"))
if(file.exists(resFile)){
   message("   Results available ==> skip")
}else{
   message("   Results not available ==> computing...")
   bedTC <- bedcTC <- bmTC <- mgTC <- gpTC <- c()
   for(r in 1:nrep){
      ids <- sample(unique(allIds$id), size=nbid, replace=FALSE)
      clearBedCache(queries=usedCache)
      bedTC <- rbind(bedTC, system.time(bedConv(ids)))
      bedcTC <- rbind(bedcTC, system.time(bedConv(ids)))
      bmTC <- rbind(bmTC, system.time(bmConv(ids)))
      mgTC <- rbind(mgTC, system.time(mgConv(ids)))
      gpTC <- rbind(gpTC, system.time(gpConv(ids)))
      cat(paste(r, ""))
   }
   save(
      bedTC, bedcTC, bmTC, mgTC, gpTC,
      file=resFile
   )
   message("   Done")
}
cat("", fill=TRUE)


###############################################################################@
## Convert Uniprot peptides --> Ensembl transcript mouse ----
scopes <- "Mouse-Peptides-Uniprot-Transcript-Ensembl"

## * Conversion functions ----
bedConv <- function(ids){
   convBeIds(
      ids=ids, from="Peptide", from.source="Uniprot", from.org="mouse",
      to="Transcript", to.source="Ens_transcript", restricted=TRUE
   )
}
usedCache <- c(
   "getBeIdConvTable_Peptide_Uniprot_Transcript_Ens_transcript_10090_restricted",
   "convBeIds_Peptide_Uniprot_Transcript_Ens_transcript_10090_10090_restricted"
)
bmConv <- function(ids){
   tr <- getBM(
      values = ids,
      filters = c("uniprotsptrembl"),
      attributes=c("uniprotsptrembl", "ensembl_gene_id"),
      mart = mmEnsembl
   )
   sp <- getBM(
      values = ids,
      filters = c("uniprotswissprot"),
      attributes=c("uniprotswissprot", "ensembl_gene_id"),
      mart = mmEnsembl
   )
   colnames(tr) <- colnames(sp) <- c("uniprot", "ensembl_gene_id")
   return(rbind(tr, sp))
}
mgConv <- function(ids){
   queryMany(
      qterm=ids,
      scopes = "uniprot",
      fields="ensembl.gene",
      species="mouse"
   )
}
gpConv <- function(ids){
   do.call(rbind, gconvert(
      query=ids,
      target="ENSG",
      organism="mmusculus",
      filter_na=FALSE,
      df=FALSE
   ))
}

## * IDs to convert ----
allIds <- getBeIds(
   be="Peptide", source="Uniprot", organism="mouse", restricted=TRUE
)

## * n=100 ----
nbid <- 100
message(scopes, ": ", nbid)
resFile <- file.path(resDir, paste0(scopes, "-", nbid, ".rda"))
if(file.exists(resFile)){
   message("   Results available ==> skip")
}else{
   message("   Results not available ==> computing...")
   bedTC <- bmTC <- mgTC <- gpTC <- c()
   for(r in 1:nrep){
      ids <- sample(unique(allIds$id), size=nbid, replace=FALSE)
      bedTC <- rbind(bedTC, system.time(bedConv(ids)))
      bmTC <- rbind(bmTC, system.time(bmConv(ids)))
      mgTC <- rbind(mgTC, system.time(mgConv(ids)))
      gpTC <- rbind(gpTC, system.time(gpConv(ids)))
      cat(paste(r, ""))
   }
   save(
      bedTC, bmTC, mgTC, gpTC,
      file=resFile
   )
   message("   Done")
}
cat("", fill=TRUE)

## * n=20000 ----
nbid <- 20000
message(scopes, ": ", nbid)
resFile <- file.path(resDir, paste0(scopes, "-", nbid, ".rda"))
if(file.exists(resFile)){
   message("   Results available ==> skip")
}else{
   message("   Results not available ==> computing...")
   bedTC <- bedcTC <- bmTC <- mgTC <- gpTC <- c()
   for(r in 1:nrep){
      ids <- sample(unique(allIds$id), size=nbid, replace=FALSE)
      clearBedCache(queries=usedCache)
      bedTC <- rbind(bedTC, system.time(bedConv(ids)))
      bedcTC <- rbind(bedcTC, system.time(bedConv(ids)))
      bmTC <- rbind(bmTC, system.time(bmConv(ids)))
      mgTC <- rbind(mgTC, system.time(mgConv(ids)))
      gpTC <- rbind(gpTC, system.time(gpConv(ids)))
      cat(paste(r, ""))
   }
   save(
      bedTC, bedcTC, bmTC, mgTC, gpTC,
      file=resFile
   )
   message("   Done")
}
cat("", fill=TRUE)

###############################################################################@
## Convert Mouse Affy --> Peptide Ensembl ----
scopes <- "Mouse-Affy-Peptide-Ensembl"

## * Conversion functions ----
bedConv <- function(ids){
   convBeIds(
      ids=ids, from="Probe", from.source="GPL1261", from.org="mouse",
      to= "Peptide", to.source="Ens_translation", restricted=TRUE
   )
}
usedCache <- c(
   "getBeIdConvTable_Probe_GPL1261_Peptide_Ens_translation_10090_restricted",
   "convBeIds_Probe_GPL1261_Peptide_Ens_translation_10090_10090_restricted"
)
bmConv <- function(ids){
   getBM(
      values = ids,
      filters = "affy_mouse430a_2",
      attributes=c('affy_mouse430a_2', "ensembl_peptide_id"),
      mart = mmEnsembl
   )
}
mgConv <- function(ids){
   queryMany(
      qterm=ids,
      scopes = "reporter",
      fields="ensembl.protein",
      species="mouse"
   )
}
gpConv <- function(ids){
   do.call(rbind, gconvert(
      query=ids,
      target="ENSP",
      organism="mmusculus",
      filter_na=FALSE,
      df=FALSE
   ))
}

## * IDs to convert ----
allIds <- getBeIds(
   be="Probe", source="GPL1261", restricted=TRUE
)

## * n=100 ----
nbid <- 100
message(scopes, ": ", nbid)
resFile <- file.path(resDir, paste0(scopes, "-", nbid, ".rda"))
if(file.exists(resFile)){
   message("   Results available ==> skip")
}else{
   message("   Results not available ==> computing...")
   bedTC <- bmTC <- mgTC <- gpTC <- c()
   for(r in 1:nrep){
      ids <- sample(unique(allIds$id), size=nbid, replace=FALSE)
      bedTC <- rbind(bedTC, system.time(bedConv(ids)))
      bmTC <- rbind(bmTC, system.time(bmConv(ids)))
      mgTC <- rbind(mgTC, system.time(mgConv(ids)))
      gpTC <- rbind(gpTC, system.time(gpConv(ids)))
      cat(paste(r, ""))
   }
   save(
      bedTC, bmTC, mgTC, gpTC,
      file=resFile
   )
   message("   Done")
}
cat("", fill=TRUE)

## * n=20000 ----
nbid <- 20000
message(scopes, ": ", nbid)
resFile <- file.path(resDir, paste0(scopes, "-", nbid, ".rda"))
if(file.exists(resFile)){
   message("   Results available ==> skip")
}else{
   message("   Results not available ==> computing...")
   bedTC <- bedcTC <- bmTC <- mgTC <- gpTC <- c()
   for(r in 1:nrep){
      ids <- sample(unique(allIds$id), size=nbid, replace=FALSE)
      clearBedCache(queries=usedCache)
      bedTC <- rbind(bedTC, system.time(bedConv(ids)))
      bedcTC <- rbind(bedcTC, system.time(bedConv(ids)))
      bmTC <- rbind(bmTC, system.time(bmConv(ids)))
      mgTC <- rbind(mgTC, system.time(mgConv(ids)))
      gpTC <- rbind(gpTC, system.time(gpConv(ids)))
      cat(paste(r, ""))
   }
   save(
      bedTC, bedcTC, bmTC, mgTC, gpTC,
      file=resFile
   )
   message("   Done")
}
cat("", fill=TRUE)
