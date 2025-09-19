---
title: "Biological Entity Dictionary (BED): Feeding the DB"
author: "Patrice Godard"
date: "September 19 2025"
abstract: "Dump source identifiers related information and integrate content in BED"
output:
  html_document:
      fig_width: 9
      fig_height: 5
      keep_md: yes
      number_sections: yes
      theme: cerulean
      toc: yes
      toc_float: yes
editor_options: 
  chunk_output_type: console
---

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Introduction

This document shows how to feed the Biological Entity Dictionary (BED).
It can be adapted according to specific needs and DB access.
The BED functions used to feed the DB are not exported to avoid
unintended modifications of the DB. To call them, they are preceded
by `BED:::`.

In this example several source databases are dumped and their content
is integrated in BED.
Some helper functions are provided to get information from famous databases.
The following chunk is used to configure source versions.
The `reDumpThr` object is used to define time intervals during which some
data sources should not be re-downloaded.


``` r
##
library(knitr)
library(BED)
library(jsonlite)
library(rvest)
library(dplyr)
library(readr)
library(stringr)
options(timeout = 36000)
##
config <- jsonlite::read_json("build_config.json")
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
##
wd <- config$BED_WORKING

##
# opts_knit$set(root.dir=wd)
opts_chunk$set(
   eval=TRUE,
   message=FALSE
   # root.dir=wd
)
## Specific config
bedInstance <- config$BED_INSTANCE
bedVersion <- config$BED_VERSION

## Identify the latest ensembl release here: https://www.ensembl.org/
ensembl_org_dir <- grep(
  "_core_",
  rvest::html_table(
    rvest::read_html("https://ftp.ensembl.org/pub/current_mysql/")
  )[[1]]$Name,
  value=TRUE
)
ensembl_org_table <- do.call(rbind, lapply(
  strsplit(ensembl_org_dir, split="_"),
  function(x){
    gv <- sub("/", "", x[length(x)])
    e <- x[length(x)-1]
    core <- which(x=="core")
    org <- paste(x[1:(core-1)], collapse=" ")
    substr(org, 1, 1) <- toupper(substr(org, 1,1))
    return(data.frame(
       organism=org,
       release=e,
       genome_version=gv
    ))
  }
))
ensembl_org_table <- ensembl_org_table[
  order(as.numeric(ensembl_org_table$genome_version), decreasing=T),
]
ensembl_org_table <- ensembl_org_table[
  which(!duplicated(ensembl_org_table$organism)),
]

ensembl_release <- unique(ensembl_org_table$release)
stopifnot(length(ensembl_release)==1)

org <-"Homo sapiens"
ensembl_Hsapiens <- list(
    release=ensembl_release,
    organism=org,
    gv=ensembl_org_table$genome_version[which(ensembl_org_table$organism==org)],
    gdbCref=c(                      # Gene cross-references DBs
        "HGNC"="HGNC",
        "EntrezGene"="EntrezGene",
        "Vega_gene"="Vega_gene",
        "Ens_Hs_gene"="Ens_gene"
    ),
    gdbAss=c(                       # Gene associated IDs (DB)
        "miRBase"="miRBase",
        "MIM_GENE"="MIM_GENE",
        "UniGene"="UniGene"
    ),
    tdbCref=c(                      # Transcript cross-references DBs
        "RefSeq_mRNA"="RefSeq",
        "RefSeq_ncRNA"="RefSeq",
        "RefSeq_mRNA_predicted"="RefSeq",
        "RefSeq_ncRNA_predicted"="RefSeq",
        "Vega_transcript"="Vega_transcript",
        "Ens_Hs_transcript"="Ens_transcript"
    ),
    pdbCref=c(                      # Peptide cross-references DBs
        "RefSeq_peptide"="RefSeq_peptide",
        "RefSeq_peptide_predicted"="RefSeq_peptide",
        "Uniprot/SPTREMBL"="Uniprot",
        "Uniprot/SWISSPROT"="Uniprot",
        "Vega_translation"="Vega_translation",
        "Ens_Hs_translation"="Ens_translation"
    ),
    canChromosomes=c(1:22, "X", "Y", "MT")
)
org <- "Mus musculus"
ensembl_Mmusculus <- list(
    release=ensembl_release,
    organism=org,
    gv=ensembl_org_table$genome_version[which(ensembl_org_table$organism==org)],
    gdbCref=c(                      # Gene cross-references DBs
        "MGI"="MGI",
        "EntrezGene"="EntrezGene",
        "Vega_gene"="Vega_gene",
        "Ens_Mm_gene"="Ens_gene"
    ),
    gdbAss=c(                       # Gene associated IDs (DB)
        "miRBase"="miRBase",
        "UniGene"="UniGene"
    ),
    tdbCref=c(                      # Transcript cross-references DBs
        "RefSeq_mRNA"="RefSeq",
        "RefSeq_ncRNA"="RefSeq",
        "RefSeq_mRNA_predicted"="RefSeq",
        "RefSeq_ncRNA_predicted"="RefSeq",
        "Vega_transcript"="Vega_transcript",
        "Ens_Mm_transcript"="Ens_transcript"
    ),
    pdbCref=c(                      # Peptide cross-references DBs
        "RefSeq_peptide"="RefSeq_peptide",
        "RefSeq_peptide_predicted"="RefSeq_peptide",
        "Uniprot/SPTREMBL"="Uniprot",
        "Uniprot/SWISSPROT"="Uniprot",
        "Vega_translation"="Vega_translation",
        "Ens_Mm_translation"="Ens_translation"
    ),
    canChromosomes=c(1:19, "X", "Y", "MT")
)
org <- "Rattus norvegicus"
ensembl_Rnorvegicus <- list(
    release=ensembl_release,
    organism=org,
    gv=ensembl_org_table$genome_version[which(ensembl_org_table$organism==org)],
    gdbCref=c(                      # Gene cross-references DBs
        "RGD"="RGD",
        "EntrezGene"="EntrezGene",
        "Vega_gene"="Vega_gene",
        "Ens_Rn_gene"="Ens_gene"
    ),
    gdbAss=c(                       # Gene associated IDs (DB)
        "miRBase"="miRBase",
        "UniGene"="UniGene"
    ),
    tdbCref=c(                      # Transcript cross-references DBs
        "RefSeq_mRNA"="RefSeq",
        "RefSeq_ncRNA"="RefSeq",
        "RefSeq_mRNA_predicted"="RefSeq",
        "RefSeq_ncRNA_predicted"="RefSeq",
        "Vega_transcript"="Vega_transcript",
        "Ens_Rn_transcript"="Ens_transcript"
    ),
    pdbCref=c(                      # Peptide cross-references DBs
        "RefSeq_peptide"="RefSeq_peptide",
        "RefSeq_peptide_predicted"="RefSeq_peptide",
        "Uniprot/SPTREMBL"="Uniprot",
        "Uniprot/SWISSPROT"="Uniprot",
        "Vega_translation"="Vega_translation",
        "Ens_Rn_translation"="Ens_translation"
    ),
    canChromosomes=c(1:20, "X", "Y", "MT")
)
org <- "Sus scrofa"
ensembl_Sscrofa <- list(
    release=ensembl_release,
    organism=org,
    gv=ensembl_org_table$genome_version[which(ensembl_org_table$organism==org)],
    gdbCref=c(                      # Gene cross-references DBs
        "EntrezGene"="EntrezGene",
        "Vega_gene"="Vega_gene",
        "Ens_Ss_gene"="Ens_gene"
    ),
    gdbAss=c(                       # Gene associated IDs (DB)
        "miRBase"="miRBase",
        "UniGene"="UniGene"
    ),
    tdbCref=c(                      # Transcript cross-references DBs
        "RefSeq_mRNA"="RefSeq",
        "RefSeq_ncRNA"="RefSeq",
        "RefSeq_mRNA_predicted"="RefSeq",
        "RefSeq_ncRNA_predicted"="RefSeq",
        "Vega_transcript"="Vega_transcript",
        "Ens_Ss_transcript"="Ens_transcript"
    ),
    pdbCref=c(                      # Peptide cross-references DBs
        "RefSeq_peptide"="RefSeq_peptide",
        "RefSeq_peptide_predicted"="RefSeq_peptide",
        "Uniprot/SPTREMBL"="Uniprot",
        "Uniprot/SWISSPROT"="Uniprot",
        "Vega_translation"="Vega_translation",
        "Ens_Ss_translation"="Ens_translation"
    ),
    canChromosomes=c(1:18, "X", "Y", "MT")
)
org <- "Danio rerio"
ensembl_Drerio <- list(
    release=ensembl_release,
    organism=org,
    gv=ensembl_org_table$genome_version[which(ensembl_org_table$organism==org)],
    gdbCref=c(                      # Gene cross-references DBs
        "EntrezGene"="EntrezGene",
        "ZFIN_ID"="ZFIN_gene",
        "Vega_gene"="Vega_gene",
        "Ens_Dr_gene"="Ens_gene"
    ),
    gdbAss=c(                       # Gene associated IDs (DB)
        "miRBase"="miRBase",
        "UniGene"="UniGene"
    ),
    tdbCref=c(                      # Transcript cross-references DBs
        "RefSeq_mRNA"="RefSeq",
        "RefSeq_ncRNA"="RefSeq",
        "RefSeq_mRNA_predicted"="RefSeq",
        "RefSeq_ncRNA_predicted"="RefSeq",
        "Vega_transcript"="Vega_transcript",
        "Ens_Dr_transcript"="Ens_transcript"
    ),
    pdbCref=c(                      # Peptide cross-references DBs
        "RefSeq_peptide"="RefSeq_peptide",
        "RefSeq_peptide_predicted"="RefSeq_peptide",
        "Uniprot/SPTREMBL"="Uniprot",
        "Uniprot/SWISSPROT"="Uniprot",
        "Vega_translation"="Vega_translation",
        "Ens_Dr_translation"="Ens_translation"
    ),
    canChromosomes=c(1:25, "MT")
)
## General config
reDumpThr <- as.difftime(config$SOURCE_REDUMP_THR, units="days")
curDate <- Sys.Date()
```

# BED initialization

BED is based on [Neo4j](https://neo4j.com/).

The S01-NewBED-Container.sh shows how to run it in
a [docker](https://www.docker.com/) container.

Because the import functions use massively the `LOAD CSV` Neo4j query, 
the feeding of the BED database can only be down from the
computer hosting the Neo4j relevant instance.

The chunk below shows how to connect to BED. In this example,
neo4j authentication is disabled.


``` r
connectToBed(
   url=sprintf("localhost:%s", config$NJ_HTTP_PORT),
   remember=FALSE,
   useCache=TRUE,
   importPath=config$BED_IMPORT
)
```

```
## Warning in checkBedConn(verbose = TRUE): BED DB is empty !
```

```
## Warning in checkBedConn(): BED DB is empty !
## Warning in checkBedConn(): BED DB is empty !
```

```
## Warning in checkBedCache(newCon = TRUE): Clearing cache
```

```
## Warning in checkBedConn(verbose = FALSE): BED DB is empty !
```

``` r
clearBedCache(force = TRUE, hard = TRUE)
```

```
## Warning in checkBedConn(verbose = FALSE): BED DB is empty !
```

```
## Warning in checkBedConn(): BED DB is empty !
```

```
## Warning in checkBedCache(): Clearing cache
```

```
## Warning in checkBedConn(verbose = FALSE): BED DB is empty !
```

## Check empty DB

Do not go further if your BED DB is not empty.


``` r
dbSize <- bedCall(cypher, 'MATCH (n) RETURN count(n)')[,1]
if(dbSize!=0){
    stop("BED DB is not empty ==> clean it before loading the content below")
}
```

## Set BED instance and version


``` r
print(bedInstance)
```

```
## [1] "Genodesy-Human"
```

``` r
print(bedVersion)
```

```
## [1] "2025.09.18"
```

``` r
BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
```

## Load Data model

**Start**: 2025-09-19 06:23:26.731567


``` r
BED:::loadBedModel()
```

**End**: 2025-09-19 06:23:27.920911

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading taxonomy from NCBI

Information is downloaded if older than 4 days
according to the `reDumpThr` object.

**Start**: 2025-09-19 06:23:27.921342


``` r
BED:::loadNcbiTax(
    reDumpThr=reDumpThr,
    ddir=wd,
    orgOfInt=c(
       "Homo sapiens", "Rattus norvegicus", "Mus musculus",
       "Sus scrofa", "Danio rerio"
      ),
    curDate=curDate
)
```

**End**: 2025-09-19 06:23:37.953289

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading data from Ensembl

## Register Ensembl DBs

### Genes


``` r
BED:::registerBEDB(
    name="Ens_gene",
    description="Ensembl gene",
    currentVersion=ensembl_release,
    idURL='http://www.ensembl.org/id/%s'
)
```

### Transcripts


``` r
BED:::registerBEDB(
    name="Ens_transcript",
    description="Ensembl transcript",
    currentVersion=ensembl_release,
    idURL='http://www.ensembl.org/id/%s'
)
```

### Peptides


``` r
BED:::registerBEDB(
    name="Ens_translation",
    description="Ensembl peptides",
    currentVersion=ensembl_release,
    idURL='http://www.ensembl.org/id/%s'
)
```

## Danio rerio


``` r
ensembl <- ensembl_Drerio
print(ensembl)
```

```
## $release
## [1] "115"
## 
## $organism
## [1] "Danio rerio"
## 
## $gv
## [1] "11"
## 
## $gdbCref
##   EntrezGene      ZFIN_ID    Vega_gene  Ens_Dr_gene 
## "EntrezGene"  "ZFIN_gene"  "Vega_gene"   "Ens_gene" 
## 
## $gdbAss
##   miRBase   UniGene 
## "miRBase" "UniGene" 
## 
## $tdbCref
##            RefSeq_mRNA           RefSeq_ncRNA  RefSeq_mRNA_predicted 
##               "RefSeq"               "RefSeq"               "RefSeq" 
## RefSeq_ncRNA_predicted        Vega_transcript      Ens_Dr_transcript 
##               "RefSeq"      "Vega_transcript"       "Ens_transcript" 
## 
## $pdbCref
##           RefSeq_peptide RefSeq_peptide_predicted         Uniprot/SPTREMBL 
##         "RefSeq_peptide"         "RefSeq_peptide"                "Uniprot" 
##        Uniprot/SWISSPROT         Vega_translation       Ens_Dr_translation 
##                "Uniprot"       "Vega_translation"        "Ens_translation" 
## 
## $canChromosomes
##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14" "15"
## [16] "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "MT"
```

### Genes

**Start**: 2025-09-19 06:23:38.148739


``` r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells 1055227 56.4    5705820 304.8  7132274 381.0
## Vcells 6029649 46.1   49837951 380.3 77871795 594.2
```

**End**: 2025-09-19 06:24:37.558486

### Transcripts

**Start**: 2025-09-19 06:24:37.558883


``` r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells 1061350 56.7    4704629 251.3  7132274 381.0
## Vcells 6042817 46.2   47908433 365.6 77871795 594.2
```

**End**: 2025-09-19 06:25:33.324749

### Peptides

**Start**: 2025-09-19 06:25:33.324998


``` r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells 1066856 57.0    3763704 201.1  7132274 381.0
## Vcells 6054611 46.2   46056096 351.4 77871795 594.2
```

**End**: 2025-09-19 06:26:30.062519

## Homo sapiens


``` r
ensembl <- ensembl_Hsapiens
print(ensembl)
```

```
## $release
## [1] "115"
## 
## $organism
## [1] "Homo sapiens"
## 
## $gv
## [1] "38"
## 
## $gdbCref
##         HGNC   EntrezGene    Vega_gene  Ens_Hs_gene 
##       "HGNC" "EntrezGene"  "Vega_gene"   "Ens_gene" 
## 
## $gdbAss
##    miRBase   MIM_GENE    UniGene 
##  "miRBase" "MIM_GENE"  "UniGene" 
## 
## $tdbCref
##            RefSeq_mRNA           RefSeq_ncRNA  RefSeq_mRNA_predicted 
##               "RefSeq"               "RefSeq"               "RefSeq" 
## RefSeq_ncRNA_predicted        Vega_transcript      Ens_Hs_transcript 
##               "RefSeq"      "Vega_transcript"       "Ens_transcript" 
## 
## $pdbCref
##           RefSeq_peptide RefSeq_peptide_predicted         Uniprot/SPTREMBL 
##         "RefSeq_peptide"         "RefSeq_peptide"                "Uniprot" 
##        Uniprot/SWISSPROT         Vega_translation       Ens_Hs_translation 
##                "Uniprot"       "Vega_translation"        "Ens_translation" 
## 
## $canChromosomes
##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14" "15"
## [16] "16" "17" "18" "19" "20" "21" "22" "X"  "Y"  "MT"
```

### Genes

**Start**: 2025-09-19 06:26:30.070141


``` r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 1066940 57.0    9313801 497.5  11642251  621.8
## Vcells 6054946 46.2  129167663 985.5 161393578 1231.4
```

**End**: 2025-09-19 06:28:40.71756

### Transcripts

**Start**: 2025-09-19 06:28:40.717952


``` r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1067088 57.0   10951796 584.9  13689745  731.2
## Vcells 10249570 78.2  124064956 946.6 161393578 1231.4
```

**End**: 2025-09-19 06:31:45.432877

### Peptides

**Start**: 2025-09-19 06:31:45.433279


``` r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1067135 57.0    8761437 468.0  13689745  731.2
## Vcells 10249710 78.2  119166358 909.2 161393578 1231.4
```

**End**: 2025-09-19 06:36:36.038563

## Mus musculus


``` r
ensembl <- ensembl_Mmusculus
print(ensembl)
```

```
## $release
## [1] "115"
## 
## $organism
## [1] "Mus musculus"
## 
## $gv
## [1] "39"
## 
## $gdbCref
##          MGI   EntrezGene    Vega_gene  Ens_Mm_gene 
##        "MGI" "EntrezGene"  "Vega_gene"   "Ens_gene" 
## 
## $gdbAss
##   miRBase   UniGene 
## "miRBase" "UniGene" 
## 
## $tdbCref
##            RefSeq_mRNA           RefSeq_ncRNA  RefSeq_mRNA_predicted 
##               "RefSeq"               "RefSeq"               "RefSeq" 
## RefSeq_ncRNA_predicted        Vega_transcript      Ens_Mm_transcript 
##               "RefSeq"      "Vega_transcript"       "Ens_transcript" 
## 
## $pdbCref
##           RefSeq_peptide RefSeq_peptide_predicted         Uniprot/SPTREMBL 
##         "RefSeq_peptide"         "RefSeq_peptide"                "Uniprot" 
##        Uniprot/SWISSPROT         Vega_translation       Ens_Mm_translation 
##                "Uniprot"       "Vega_translation"        "Ens_translation" 
## 
## $canChromosomes
##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14" "15"
## [16] "16" "17" "18" "19" "X"  "Y"  "MT"
```

### Genes

**Start**: 2025-09-19 06:36:36.046328


``` r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1067141 57.0    7788776 416.0  13689745  731.2
## Vcells 10249911 78.3   95385577 727.8 161393578 1231.4
```

**End**: 2025-09-19 06:38:09.768564

### Transcripts

**Start**: 2025-09-19 06:38:09.768958


``` r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1067022 57.0    7509225 401.1  13689745  731.2
## Vcells 10249786 78.2   91634154 699.2 161393578 1231.4
```

**End**: 2025-09-19 06:40:07.760922

### Peptides

**Start**: 2025-09-19 06:40:07.761339


``` r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1067120 57.0    7240856 386.8  13689745  731.2
## Vcells 10250011 78.3   88032788 671.7 161393578 1231.4
```

**End**: 2025-09-19 06:41:44.65815

## Rattus norvegicus


``` r
ensembl <- ensembl_Rnorvegicus
print(ensembl)
```

```
## $release
## [1] "115"
## 
## $organism
## [1] "Rattus norvegicus"
## 
## $gv
## [1] "1"
## 
## $gdbCref
##          RGD   EntrezGene    Vega_gene  Ens_Rn_gene 
##        "RGD" "EntrezGene"  "Vega_gene"   "Ens_gene" 
## 
## $gdbAss
##   miRBase   UniGene 
## "miRBase" "UniGene" 
## 
## $tdbCref
##            RefSeq_mRNA           RefSeq_ncRNA  RefSeq_mRNA_predicted 
##               "RefSeq"               "RefSeq"               "RefSeq" 
## RefSeq_ncRNA_predicted        Vega_transcript      Ens_Rn_transcript 
##               "RefSeq"      "Vega_transcript"       "Ens_transcript" 
## 
## $pdbCref
##           RefSeq_peptide RefSeq_peptide_predicted         Uniprot/SPTREMBL 
##         "RefSeq_peptide"         "RefSeq_peptide"                "Uniprot" 
##        Uniprot/SWISSPROT         Vega_translation       Ens_Rn_translation 
##                "Uniprot"       "Vega_translation"        "Ens_translation" 
## 
## $canChromosomes
##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14" "15"
## [16] "16" "17" "18" "19" "20" "X"  "Y"  "MT"
```

### Genes

**Start**: 2025-09-19 06:41:44.665748


``` r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1066937 57.0    6231968 332.9  13689745  731.2
## Vcells 10249898 78.3   70426231 537.4 161393578 1231.4
```

**End**: 2025-09-19 06:42:32.287002

### Transcripts

**Start**: 2025-09-19 06:42:32.287241


``` r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1066974 57.0    4985575 266.3  13689745  731.2
## Vcells 10250033 78.3   56340985 429.9 161393578 1231.4
```

**End**: 2025-09-19 06:43:20.651809

### Peptides

**Start**: 2025-09-19 06:43:20.652232


``` r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1066853 57.0    3988460 213.1  13689745  731.2
## Vcells 10249893 78.3   54151346 413.2 161393578 1231.4
```

**End**: 2025-09-19 06:44:24.492727

## Sus scrofa


``` r
ensembl <- ensembl_Sscrofa
print(ensembl)
```

```
## $release
## [1] "115"
## 
## $organism
## [1] "Sus scrofa"
## 
## $gv
## [1] "111"
## 
## $gdbCref
##   EntrezGene    Vega_gene  Ens_Ss_gene 
## "EntrezGene"  "Vega_gene"   "Ens_gene" 
## 
## $gdbAss
##   miRBase   UniGene 
## "miRBase" "UniGene" 
## 
## $tdbCref
##            RefSeq_mRNA           RefSeq_ncRNA  RefSeq_mRNA_predicted 
##               "RefSeq"               "RefSeq"               "RefSeq" 
## RefSeq_ncRNA_predicted        Vega_transcript      Ens_Ss_transcript 
##               "RefSeq"      "Vega_transcript"       "Ens_transcript" 
## 
## $pdbCref
##           RefSeq_peptide RefSeq_peptide_predicted         Uniprot/SPTREMBL 
##         "RefSeq_peptide"         "RefSeq_peptide"                "Uniprot" 
##        Uniprot/SWISSPROT         Vega_translation       Ens_Ss_translation 
##                "Uniprot"       "Vega_translation"        "Ens_translation" 
## 
## $canChromosomes
##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14" "15"
## [16] "16" "17" "18" "X"  "Y"  "MT"
```

### Genes

**Start**: 2025-09-19 06:44:24.497774


``` r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1066967 57.0    4071235 217.5  13689745  731.2
## Vcells 10250270 78.3   43321077 330.6 161393578 1231.4
```

**End**: 2025-09-19 06:44:50.147656

### Transcripts

**Start**: 2025-09-19 06:44:50.147917


``` r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1066860 57.0    3640810 194.5  13689745  731.2
## Vcells 10250165 78.3   41652234 317.8 161393578 1231.4
```

**End**: 2025-09-19 06:45:20.659141

### Peptides

**Start**: 2025-09-19 06:45:20.659369


``` r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=wd,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1066907 57.0    3527178 188.4  13689745  731.2
## Vcells 10250305 78.3   40050144 305.6 161393578 1231.4
```

**End**: 2025-09-19 06:46:17.438371

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading data from NCBI

Information is downloaded if older than 4 days
according to the `reDumpThr` object.

## Register NCBI DBs


``` r
BED:::dumpNcbiDb(
  taxOfInt = c(), reDumpThr=reDumpThr,
  ddir=wd,
  toLoad=c(), curDate=curDate
)
```

### Genes


``` r
BED:::registerBEDB(
    name="EntrezGene",
    description="NCBI gene",
    currentVersion=format(dumpDate, "%Y%m%d"),
    idURL='https://www.ncbi.nlm.nih.gov/gene/%s'
)
```

### Transcripts


``` r
BED:::registerBEDB(
    name="RefSeq",
    description="NCBI nucleotide",
    currentVersion=format(dumpDate, "%Y%m%d"),
    idURL='https://www.ncbi.nlm.nih.gov/nuccore/%s'
)
```

### Peptides


``` r
BED:::registerBEDB(
    name="RefSeq_peptide",
    description="NCBI protein",
    currentVersion=format(dumpDate, "%Y%m%d"),
    idURL='https://www.ncbi.nlm.nih.gov/protein/%s'
)
```

## Danio rerio data

**Start**: 2025-09-19 06:46:17.532163


``` r
BED:::getNcbiGeneTransPep(
    organism="Danio rerio",
    ddir=wd,
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1081512 57.8    3418091 182.6  13689745  731.2
## Vcells 10280822 78.5   32040294 244.5 161393578 1231.4
```

**End**: 2025-09-19 06:47:47.865452

## Homo sapiens data

**Start**: 2025-09-19 06:47:47.865687


``` r
BED:::getNcbiGeneTransPep(
    organism="Homo sapiens",
    ddir=wd,
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1081682 57.8   11533236 616.0  14416545  770.0
## Vcells 10281155 78.5  106018934 808.9 161393578 1231.4
```

**End**: 2025-09-19 06:52:22.28276

## Mus musculus data

**Start**: 2025-09-19 06:52:22.283153


``` r
BED:::getNcbiGeneTransPep(
    organism="Mus musculus",
    ddir=wd,
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1081579 57.8    9226589 492.8  14416545  770.0
## Vcells 10281033 78.5   84815148 647.1 161393578 1231.4
```

**End**: 2025-09-19 06:55:15.778641

## Rattus norvegicus data

**Start**: 2025-09-19 06:55:15.779041


``` r
BED:::getNcbiGeneTransPep(
    organism="Rattus norvegicus",
    ddir=wd,
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1081488 57.8    7381272 394.3  14416545  770.0
## Vcells 10280931 78.5   54281696 414.2 161393578 1231.4
```

**End**: 2025-09-19 06:58:15.345602

## Sus scrofa data

**Start**: 2025-09-19 06:58:15.345898


``` r
BED:::getNcbiGeneTransPep(
    organism="Sus scrofa",
    ddir=wd,
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1081547 57.8    5905018 315.4  14416545  770.0
## Vcells 10281088 78.5   43425357 331.4 161393578 1231.4
```

**End**: 2025-09-19 06:59:47.314815

## Direct cross-references with Uniprot

**Start**: 2025-09-19 06:59:47.315226


``` r
message("Direct cross-references with Uniprot")
BED:::dumpNcbiDb(
  taxOfInt="",
  reDumpThr=Inf,
  ddir=wd,
  toLoad="gene_refseq_uniprotkb_collab",
  curDate=Sys.Date()
)
gene_refseq_uniprotkb_collab <- gene_refseq_uniprotkb_collab[
   gene_refseq_uniprotkb_collab$method %in% c("uniprot", "identical"),
]
gene_refseq_uniprotkb_collab$NCBI_protein_accession <- sub(
   "[.].*$", "", gene_refseq_uniprotkb_collab$NCBI_protein_accession
)
for(org in listOrganisms()){
  message("   ", org)
  curRS <- getBeIds(
    be="Peptide", source="RefSeq_peptide", organism=org,
    restricted=TRUE
  )
  toAdd <- gene_refseq_uniprotkb_collab[
      which(
         gene_refseq_uniprotkb_collab$NCBI_protein_accession %in% curRS$id
      ),
  ]
  ## External DB IDs
  toImport <- unique(toAdd[, "UniProtKB_protein_accession", drop=F])
  colnames(toImport) <- "id"
  BED:::loadBE(
      d=toImport, be="Peptide",
      dbname="Uniprot",
      taxId=NA
  )
  ## The cross references
  toImport <- toAdd[
    , c("NCBI_protein_accession", "UniProtKB_protein_accession")
  ]
  colnames(toImport) <- c("id1", "id2")
  BED:::loadCorrespondsTo(
      d=toImport,
      db1="RefSeq_peptide",
      db2="Uniprot",
      be="Peptide"
  )
}
```

**End**: 2025-09-19 07:16:42.367898


<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading data from HGNC

## DB information


``` r
dbname <- "HGNC"
hgnc_date <- jsonlite::read_json(
   "https://www.genenames.org/cgi-bin/statistics/db-last-updated"
)$date
BED:::registerBEDB(
    name=dbname,
    description="HUGO Gene Nomenclature Committee",
    currentVersion=hgnc_date,
    idURL='https://www.genenames.org/data/gene-symbol-report/#!/hgnc_id/HGNC:%s'
)
```



``` r
hgnc <- read_tsv(
   file="https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt",
   col_types = "ccccccccccccccDDDDcccccccccccccccccccccccccccccccccccc"
)
hgnc_genes <- hgnc |>
  select(
    hgnc_id, symbol, name, locus_group, locus_type, status,
    location #, location_sortable
  ) |>
  mutate(id = str_remove(hgnc_id, "^HGNC:")) |>
  relocate(id, .after = "hgnc_id") |>
  distinct()

get_hgnc_xref <- function(colname){
  toRet <- hgnc |>
    select(all_of(c("hgnc_id", colname)))
  values <- toRet |> pull(colname) |> strsplit("[|]")
  toRet <- tibble(
    hgnc_id=rep(toRet$hgnc_id, lengths(values)),
    value = unlist(values)
  )
  return(toRet)
}

hgnc_alias_symbols <- get_hgnc_xref("alias_symbol") |>
  filter(!is.na(value)) |>
  rename("symbol"="value") |> 
  mutate(id = str_remove(hgnc_id, "^HGNC:"))
hgnc_alias_names <- get_hgnc_xref("alias_name") |>
  filter(!is.na(value)) |>
  rename("name"="value") |> 
  mutate(id = str_remove(hgnc_id, "^HGNC:"))
hgnc_previous_symbols <- get_hgnc_xref("prev_symbol") |>
  filter(!is.na(value)) |>
  rename("symbol"="value") |> 
  mutate(id = str_remove(hgnc_id, "^HGNC:"))
hgnc_previous_names <- get_hgnc_xref("prev_name") |>
  filter(!is.na(value)) |>
  rename("name"="value") |> 
  mutate(id = str_remove(hgnc_id, "^HGNC:"))
hgnc_entrez <- get_hgnc_xref("entrez_id") |>
  filter(!is.na(value)) |>
  rename("entrez"="value") |> 
  mutate(id = str_remove(hgnc_id, "^HGNC:"))
hgnc_ensembl <- get_hgnc_xref("ensembl_gene_id") |>
  filter(!is.na(value)) |>
  rename("ensembl"="value") |> 
  mutate(id = str_remove(hgnc_id, "^HGNC:"))
hgnc_omim <- get_hgnc_xref("omim_id") |>
  filter(!is.na(value)) |>
  rename("omim"="value") |> 
  mutate(id = str_remove(hgnc_id, "^HGNC:"))
hgnc_orphanet <- get_hgnc_xref("orphanet") |>
  filter(!is.na(value)) |>
  rename("orphanet"="value") |> 
  mutate(id = str_remove(hgnc_id, "^HGNC:"))
# hgnc_mgd <- get_hgnc_xref("mgd_id") |>
#   filter(!is.na(value)) |>
#   rename("mgd_id"="value") |>
#   mutate("mgd" = str_remove(mgd_id, "MGI:"))
# hgnc_rgd <- get_hgnc_xref("rgd_id") |>
#   filter(!is.na(value)) |>
#   rename("rgd_id"="value") |>
#   mutate("rgd" = str_remove(rgd_id, "RGD:"))
```

## Identifiers


``` r
toLoad <- hgnc_genes |> select(id)
BED:::loadBE(
   toLoad, be = "Gene",
   dbname = dbname, version = hgnc_date,
   taxId = "9606"
)
```

## Symbols


``` r
toLoad <- dplyr::bind_rows(
   hgnc_genes |> 
      dplyr::select(id, symbol) |> 
      dplyr::mutate(canonical = TRUE),
   hgnc_alias_symbols |> 
      dplyr::select(id, symbol) |> 
      dplyr::mutate(canonical = FALSE),
   hgnc_previous_symbols |> 
      dplyr::select(id, symbol) |> 
      dplyr::mutate(canonical = FALSE)
)|>
   dplyr::distinct(id, symbol, .keep_all = TRUE)
BED:::loadBESymbols(toLoad, be = "Gene", dbname = dbname)
```

## Names


``` r
toLoad <- dplyr::bind_rows(
   hgnc_genes |> 
      dplyr::select(id, name) |> 
      dplyr::mutate(canonical = TRUE),
   hgnc_alias_names |> 
      dplyr::select(id, name) |> 
      dplyr::mutate(canonical = FALSE),
   hgnc_previous_names |> 
      dplyr::select(id, name) |> 
      dplyr::mutate(canonical = FALSE)
)|>
   dplyr::distinct(id, name, .keep_all = TRUE)
BED:::loadBENames(toLoad, be = "Gene", dbname = dbname)
```

## Cross references

### EntrezGene


``` r
crdb <- "EntrezGene"
toLoad <- hgnc_entrez |> 
   dplyr::select(id = entrez) |> 
   dplyr::distinct()
BED:::loadBE(
   d=toLoad, be="Gene",
   dbname=crdb,
   taxId=NA
)
## The cross references
toLoad <- hgnc_entrez |> 
   dplyr::select(id1 = entrez, id2 = id) |> 
   dplyr::distinct()
BED:::loadCorrespondsTo(
   d=as.data.frame(toLoad),
   db1=crdb,
   db2=dbname,
   be="Gene"
)
```

### Ens_gene


``` r
crdb <- "Ens_gene"
toLoad <- hgnc_ensembl |> 
   dplyr::select(id = ensembl) |> 
   dplyr::distinct()
BED:::loadBE(
   d=toLoad, be="Gene",
   dbname=crdb,
   taxId=NA
)
## The cross references
toLoad <- hgnc_ensembl |> 
   dplyr::select(id1 = ensembl, id2 = id) |> 
   dplyr::distinct()
BED:::loadCorrespondsTo(
   d=as.data.frame(toLoad),
   db1=crdb,
   db2=dbname,
   be="Gene"
)
```

### MIM_GENE


``` r
crdb <- "MIM_GENE"
toLoad <- hgnc_omim |> 
   dplyr::select(id = omim) |> 
   dplyr::distinct()
BED:::loadBE(
   d=toLoad, be="Gene",
   dbname=crdb,
   taxId=NA
)
## The cross references (associations)
toLoad <- hgnc_omim |> 
   dplyr::select(id1 = omim, id2 = id) |> 
   dplyr::distinct()
BED:::loadIsAssociatedTo(
   d=as.data.frame(toLoad),
   db1=crdb,
   db2=dbname,
   be="Gene"
)
```


<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading data from Uniprot

Release is defined according to the *reldate.txt* file on the Uniprot FTP
and data is downloaded only if not already done for the current release.


``` r
ftp <- "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions"
avRel <- readLines(file.path(ftp, "reldate.txt"), n=1)
avRel <- sub(
    "^UniProt Knowledgebase Release ", "",
    sub(" consists of:$", "", avRel)
)
if(is.na(as.Date(paste0(avRel, "_01"), format="%Y_%m_%d"))){
    print(avRel)
    stop(sprintf("Check reldate.txt file on %s", ftp))
}
BED:::registerBEDB(
    name="Uniprot",
    description="Uniprot",
    currentVersion=avRel,
    idURL='http://www.uniprot.org/uniprot/%s'
)
```

## Danio rerio data

**Start**: 2025-09-19 07:17:16.071511


``` r
BED:::getUniprot(
    organism="Danio rerio", taxDiv="vertebrates", release=avRel, ddir=wd
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  220816418 11792.9  513676991 27433.4  513676991 27433.4
## Vcells 1235261819  9424.3 2373430763 18107.9 2373430763 18107.9
```

**End**: 2025-09-19 07:20:21.677263

## Homo sapiens data

**Start**: 2025-09-19 07:20:21.67759


``` r
BED:::getUniprot(
    organism="Homo sapiens", taxDiv="human", release=avRel, ddir=wd
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  220816575 11792.9  513676991 27433.4  513676991 27433.4
## Vcells 1235262133  9424.4 2373430763 18107.9 2373430763 18107.9
```

**End**: 2025-09-19 07:22:47.251084

## Mus musculus data

**Start**: 2025-09-19 07:22:47.251506


``` r
BED:::getUniprot(
    organism="Mus musculus", taxDiv="rodents", release=avRel, ddir=wd
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  220816560 11792.9  513676991 27433.4  513676991 27433.4
## Vcells 1235262160  9424.4 2373430763 18107.9 2373430763 18107.9
```

**End**: 2025-09-19 07:24:09.775775

## Rattus norvegicus data

**Start**: 2025-09-19 07:24:09.776121


``` r
BED:::getUniprot(
    organism="Rattus norvegicus", taxDiv="rodents", release=avRel, ddir=wd
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  220816544 11792.9  513676991 27433.4  513676991 27433.4
## Vcells 1235262186  9424.4 2373430763 18107.9 2373430763 18107.9
```

**End**: 2025-09-19 07:25:36.856315

## Sus scrofa data

**Start**: 2025-09-19 07:25:36.856647


``` r
BED:::getUniprot(
    organism="Sus scrofa", taxDiv="mammals", release=avRel, ddir=wd
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  220816462 11792.9  513676991 27433.4  513676991 27433.4
## Vcells 1235262103  9424.4 2373430763 18107.9 2373430763 18107.9
```

**End**: 2025-09-19 07:32:40.152278

## Indirect cross-references with EntrezGene

**Start**: 2025-09-19 07:32:40.152626


``` r
message("Indirect cross-references with Uniprot")
dumpDir <- file.path(wd, "NCBI-gene-DATA")
f <- "gene2accession.gz"
if(file.exists(dumpDir)){
  load(file.path(dumpDir, "dumpDate.rda"))
  message("Last download: ", dumpDate)
  if(curDate - dumpDate > reDumpThr | !file.exists(file.path(dumpDir, f))){
    toDownload <- TRUE
  }else{
    toDownload <- FALSE
  }
}else{
  message("Not downloaded yet")
  toDownload <- TRUE
}
if(toDownload){
  ftp <- "ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/"
  dlok <- try(download.file(
    url=paste0(ftp, f),
    destfile=file.path(dumpDir, f),
    method="wget",
    quiet=T
  ), silent=T)
}else{
  message("Existing data are going to be used")
}
cn <- readLines(file.path(dumpDir, f), n=1)
cn <- sub("^#", "", cn)
cn <- unlist(strsplit(cn, split="[ \t]"))
for(org in listOrganisms()){
  message("   ", org)
  tid <- getTaxId(org)
  toAdd <- read.table(
    text=system(
      sprintf("zgrep ^%s %s", tid, file.path(dumpDir, f)),
      intern=TRUE
    ),
    sep="\t",
    header=F,
    stringsAsFactors=F,
    quote="", comment.char=""
  )
  colnames(toAdd) <- cn
  toAdd <- toAdd[
    which(toAdd$tax_id==tid),
    c("tax_id", "GeneID", "protein_accession.version")
  ]
  toAdd$pacc <- sub("[.].*$", "", toAdd$protein_accession.version)
  curUP <- getBeIdConvTable(
    from="Gene", from.source="BEDTech_gene", organism=org,
    to="Peptide", to.source="Uniprot",
    restricted=TRUE
  )
  toAdd <- merge(
    toAdd[,c("GeneID", "pacc")],
    curUP[,c("from", "to")],
    by.x="pacc", by.y="to",
    all=FALSE
  )
  toAdd <- toAdd[,c("from", "GeneID")]
  toAdd$from <- as.character(toAdd$from)
  toAdd$GeneID <- as.character(toAdd$GeneID)
  colnames(toAdd) <- c("id1", "id2")
  BED:::loadIsAssociatedTo(
    d=toAdd,
    db1="BEDTech_gene", db2="EntrezGene",
    be="Gene"
  )
}
```

**End**: 2025-09-19 07:44:34.989133


<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading orthologs

<!-- ## Orthologs from biomaRt -->

<!-- **Start**: 2025-09-19 07:44:34.989443 -->

<!-- ```{r homolog_biomart, message=FALSE} -->
<!-- # library(biomaRt) -->
<!-- # loadBmHomologs <- function(mart, org2){ -->
<!-- #  -->
<!-- #     #mattr <- listAttributes(mart) -->
<!-- #      -->
<!-- #     toImport <- getBM( -->
<!-- #         mart=mart, -->
<!-- #         attributes=c( -->
<!-- #             "ensembl_gene_id", -->
<!-- #             paste0( -->
<!-- #               org2, -->
<!-- #               c("_homolog_ensembl_gene", "_homolog_orthology_confidence") -->
<!-- #             ) -->
<!-- #         ) -->
<!-- #     ) -->
<!-- #     colnames(toImport) <- c("id1", "id2", "cs") -->
<!-- #     toImport <- unique(toImport[ -->
<!-- #         which(toImport$id1 != "" & toImport$id2 != "" & toImport$cs==1), -->
<!-- #         c("id1", "id2") -->
<!-- #     ]) -->
<!-- #      -->
<!-- #     BED:::loadIsHomologOf( -->
<!-- #         d=toImport, -->
<!-- #         db1="Ens_gene", db2="Ens_gene", -->
<!-- #         be="Gene" -->
<!-- #     ) -->
<!-- #  -->
<!-- # } -->
<!-- #  -->
<!-- # ######################################### -->
<!-- # orgOfInt <- c("hsapiens", "mmusculus", "rnorvegicus", "sscrofa", "drerio") -->
<!-- # marts <-listMarts() -->
<!-- # bm <- "ENSEMBL_MART_ENSEMBL" -->
<!-- # version <- ensembl_release -->
<!-- # if( -->
<!-- #   grep( -->
<!-- #     sprintf(" %s$", version), -->
<!-- #     marts[which(marts$biomart==bm), "version"] -->
<!-- #   )==1 -->
<!-- # ){ -->
<!-- #     version <- NULL -->
<!-- # } -->
<!-- # for(i in 1:(length(orgOfInt)-1)){ -->
<!-- #   ######################################### -->
<!-- #   ## The mart -->
<!-- #   org1 <- orgOfInt[i] -->
<!-- #   mart <- useEnsembl( -->
<!-- #       biomart=bm, -->
<!-- #       dataset=paste0(org1, "_gene_ensembl"), -->
<!-- #       version=version -->
<!-- #   ) -->
<!-- #   for(j in (i+1):length(orgOfInt)){ -->
<!-- #     loadBmHomologs( -->
<!-- #       mart=mart, -->
<!-- #       org2=orgOfInt[j] -->
<!-- #     ) -->
<!-- #   } -->
<!-- # } -->
<!-- ``` -->

<!-- **End**: 2025-09-19 07:44:34.989629 -->

## Orthologs from Ensembl

**Start**: 2025-09-19 07:44:34.98979


``` r
## Dump data from ensembl
orgOfInt <- c(
   "homo_sapiens", "mus_musculus", "rattus_norvegicus", "sus_scrofa",
   "danio_rerio"
)
data_dir <- file.path(wd, "ensembl_homologies")
dir.create(data_dir, showWarnings = FALSE)
ensembl_homologies <- c()
for(org in orgOfInt){
   ## Proteins
   f_url <- sprintf(
      "https://ftp.ensembl.org/pub/release-%s/tsv/ensembl-compara/homologies/%s/Compara.%s.protein_default.homologies.tsv.gz",
      ensembl_release, org, ensembl_release
   )
   f_name <- sprintf(
      "%s.Compara.%s.protein_default.homologies.tsv.gz",
      org, ensembl_release
   )
   f_path <- file.path(data_dir, f_name)
   if(!file.exists(f_path)){
      download.file(url = f_url, destfile = f_path)
   }
   to_add <- readr::read_tsv(
      f_path, col_types = "c"
   )
   to_add <- to_add |> 
      filter(
         is_high_confidence == "1",
         species %in% orgOfInt,
         homology_species %in% orgOfInt,
         species != homology_species
      ) |> 
      select(gene_stable_id, homology_gene_stable_id, species, homology_species)
   ensembl_homologies <- bind_rows(
      ensembl_homologies,
      to_add
   )
   ## ncRNA
   f_url <- sprintf(
      "https://ftp.ensembl.org/pub/release-%s/tsv/ensembl-compara/homologies/%s/Compara.%s.ncrna_default.homologies.tsv.gz",
      ensembl_release, org, ensembl_release
   )
   f_name <- sprintf(
      "%s.Compara.%s.ncrna_default.homologies.tsv.gz",
      org, ensembl_release
   )
   f_path <- file.path(data_dir, f_name)
   if(!file.exists(f_path)){
      download.file(url = f_url, destfile = f_path)
   }
   to_add <- readr::read_tsv(
      f_path, col_types = "c"
   )
   to_add <- to_add |> 
      filter(
         is_high_confidence == "1",
         species %in% orgOfInt,
         homology_species %in% orgOfInt,
         species != homology_species
      ) |> 
      select(gene_stable_id, homology_gene_stable_id, species, homology_species)
   ensembl_homologies <- bind_rows(
      ensembl_homologies,
      to_add
   )
   
}
toImport <- ensembl_homologies |> 
   dplyr::select(id1 = gene_stable_id, id2 = homology_gene_stable_id) |> 
   as.data.frame()
BED:::loadIsHomologOf(
   d=toImport,
   db1="Ens_gene", db2="Ens_gene",
   be="Gene"
)
```

**End**: 2025-09-19 07:46:29.047236

## Orthologs from NCBI

**Start**: 2025-09-19 07:46:29.047667


``` r
#####################################
gdbname <- "EntrezGene"
taxOfInt <- unlist(lapply(
    c(
       "Homo sapiens", "Mus musculus", "Rattus norvegicus",
       "Sus scrofa", "Danio rerio"
    ),
    getTaxId
))
for(i in 1:length(taxOfInt)){
   BED:::dumpNcbiDb(
       taxOfInt=taxOfInt[i],
       reDumpThr=reDumpThr,
       ddir=wd,
       toLoad=c("gene_orthologs"),
       curDate=curDate
   )
   toImport <- gene_orthologs[
       which(
           gene_orthologs$tax_id %in% taxOfInt &
           gene_orthologs$Other_tax_id %in% taxOfInt &
           gene_orthologs$relationship == "Ortholog"
       ),
       c("GeneID", "Other_GeneID")
   ]
   if(nrow(toImport)>0){
      colnames(toImport) <- c("id1", "id2")
      toImport <- dplyr::mutate_all(toImport, as.character)
      BED:::loadIsHomologOf(
          d=toImport,
          db1=gdbname, db2=gdbname,
          be="Gene"
      )
   }
}
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  220968791 11801.1  513676991 27433.4  513676991 27433.4
## Vcells 1240825072  9466.8 2373430763 18107.9 2373430763 18107.9
```

**End**: 2025-09-19 07:47:37.191609

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading probes

## Probes from GEO


``` r
library(GEOquery)
geoPath <- file.path(wd, "geo")
dir.create(geoPath, showWarnings=FALSE)
```

### GPL1708: 	Agilent-012391 Whole Human Genome Oligo Microarray G4112A (Feature Number version)

**Start**: 2025-09-19 07:47:39.784726


``` r
## Import plateform
platName <- "GPL1708"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping with Entrez
d <- Table(gds)
toImport <- d[which(!is.na(d$SPOT_ID)), c("SPOT_ID", "GENE")]
colnames(toImport) <- c("probeID", "id")
toImport$probeID <- as.character(toImport$probeID)
toImport$id <- as.character(toImport$id)
toImport <- toImport[which(!is.na(toImport$id)),]
toImport <- unique(toImport)
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
# ## Import mapping with UniGene
# toImport <- d[which(!is.na(d$SPOT_ID)), c("SPOT_ID", "UNIGENE_ID")]
# colnames(toImport) <- c("probeID", "id")
# toImport$probeID <- as.character(toImport$probeID)
# toImport$id <- as.character(toImport$id)
# toImport <- toImport[which(!is.na(toImport$id) & toImport$id!=""),]
# dbname <- "UniGene"
# ##
# BED:::loadProbes(
#     d=toImport,
#     be=be,
#     platform=platName,
#     dbname=dbname
# )
```

**End**: 2025-09-19 07:47:43.24239

### GPL6480: Agilent-014850 Whole Human Genome Microarray 4x44K G4112F (Probe Name version)

**Start**: 2025-09-19 07:47:43.242706


``` r
## Import plateform
platName <- "GPL6480"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping with Entrez
d <- Table(gds)
toImport <- d[which(!is.na(d$ID)), c("ID", "GENE")]
colnames(toImport) <- c("probeID", "id")
toImport$probeID <- as.character(toImport$probeID)
toImport$id <- as.character(toImport$id)
toImport <- toImport[which(!is.na(toImport$id)),]
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
# ## Import mapping with UniGene
# toImport <- d[which(!is.na(d$ID)), c("ID", "UNIGENE_ID")]
# colnames(toImport) <- c("probeID", "id")
# toImport$probeID <- as.character(toImport$probeID)
# toImport$id <- as.character(toImport$id)
# toImport <- toImport[which(!is.na(toImport$id)),]
# dbname <- "UniGene"
# ##
# BED:::loadProbes(
#     d=toImport,
#     be=be,
#     platform=platName,
#     dbname=dbname
# )
```

**End**: 2025-09-19 07:47:46.751936

### GPL570: Affymetrix Human Genome U133 Plus 2.0 Array

**Start**: 2025-09-19 07:47:46.752232


``` r
## Import plateform
platName <- "GPL570"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
toImport <- strsplit(
    as.character(d$ENTREZ_GENE_ID),
    split=" /// "
)
names(toImport) <- d$ID
toImport <- stack(toImport)
toImport[,1] <- as.character(toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:47:52.920343

### GPL571: Affymetrix Human Genome U133A 2.0 Array

**Start**: 2025-09-19 07:47:52.92076


``` r
## Import plateform
platName <- "GPL571"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
toImport <- strsplit(
    as.character(d$ENTREZ_GENE_ID),
    split=" /// "
)
names(toImport) <- d$ID
toImport <- stack(toImport)
toImport[,1] <- as.character(toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:47:55.500594

### GPL13158: Affymetrix HT HG-U133+ PM Array Plate

**Start**: 2025-09-19 07:47:55.501014


``` r
## Import plateform
platName <- "GPL13158"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
toImport <- strsplit(
    as.character(d$ENTREZ_GENE_ID),
    split=" /// "
)
names(toImport) <- d$ID
toImport <- stack(toImport)
toImport[,1] <- as.character(toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:47:59.583792

### GPL96: Affymetrix Human Genome U133A Array

**Start**: 2025-09-19 07:47:59.584221


``` r
## Import plateform
platName <- "GPL96"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
toImport <- strsplit(
    as.character(d$ENTREZ_GENE_ID),
    split=" /// "
)
names(toImport) <- d$ID
toImport <- stack(toImport)
toImport[,1] <- as.character(toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:48:02.318593

### GPL1261: Affymetrix Mouse Genome 430 2.0 Array

**Start**: 2025-09-19 07:48:02.319012


``` r
## Import plateform
platName <- "GPL1261"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
toImport <- strsplit(
    as.character(d$ENTREZ_GENE_ID),
    split=" /// "
)
names(toImport) <- d$ID
toImport <- stack(toImport)
toImport[,1] <- as.character(toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:48:06.642607

### GPL1355: Affymetrix Rat Genome 230 2.0 Array

**Start**: 2025-09-19 07:48:06.643029


``` r
## Import plateform
platName <- "GPL1355"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
toImport <- strsplit(
    as.character(d$ENTREZ_GENE_ID),
    split=" /// "
)
names(toImport) <- d$ID
toImport <- stack(toImport)
toImport[,1] <- as.character(toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:48:09.161557

### GPL10558: Illumina HumanHT-12 V4.0 expression beadchip

**Start**: 2025-09-19 07:48:09.16196


``` r
## Import plateform
platName <- "GPL10558"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
toImport <- d[,c("Entrez_Gene_ID", "ID")]
toImport[,1] <- as.character(toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
toImport <- toImport[which(!is.na(toImport$id) & toImport$id != ""),]
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:48:13.845788

### GPL6947: Illumina HumanHT-12 V3.0 expression beadchip

**Start**: 2025-09-19 07:48:13.846208


``` r
## Import plateform
platName <- "GPL6947"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
toImport <- d[,c("Entrez_Gene_ID", "ID")]
toImport[,1] <- as.character(toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
toImport <- toImport[which(!is.na(toImport$id) & toImport$id != ""),]
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:48:18.078715

### GPL6885: Illumina MouseRef-8 v2.0 expression beadchip

**Start**: 2025-09-19 07:48:18.07914


``` r
## Import plateform
platName <- "GPL6885"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
d <- Table(gds)
# e <- getBeIds(
#    be="Gene", source="EntrezGene", organism="mouse", restricted=FALSE
# )
# sum(d$Entrez_Gene_ID %in% e$id) < sum(sub("[.].*$", "", d$RefSeq_ID) %in% f$id)
be <- "Transcript"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
toImport <- d[,c("RefSeq_ID", "ID")]
toImport[,1] <- as.character(toImport[,1])
toImport[,1] <- sub("[.].*$", "", toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
toImport <- toImport[which(!is.na(toImport$id) & toImport$id != ""),]
dbname <- "RefSeq"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:48:20.848793

### GPL6887: Illumina MouseWG-6 v2.0 expression beadchip

**Start**: 2025-09-19 07:48:20.849228


``` r
## Import plateform
platName <- "GPL6887"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
d <- Table(gds)
# e <- getBeIds(
#    be="Gene", source="EntrezGene", organism="mouse", restricted=FALSE
# )
# sum(d$Entrez_Gene_ID %in% e$id) > sum(sub("[.].*$", "", d$RefSeq_ID) %in% f$id)
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
toImport <- d[,c("Entrez_Gene_ID", "ID")]
toImport[,1] <- as.character(toImport[,1])
# toImport[,1] <- sub("[.].*$", "", toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
toImport <- toImport[which(!is.na(toImport$id) & toImport$id != ""),]
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:48:25.053942

### GPL6101: Illumina ratRef-12 v1.0 expression beadchip

**Start**: 2025-09-19 07:48:25.054374


``` r
## Import plateform
platName <- "GPL6101"
gds <- getGEO(platName, destdir=geoPath)
platDesc <- Meta(gds)$title
be <- "Gene"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
toImport <- d[,c("Entrez_Gene_ID", "ID")]
toImport[,1] <- as.character(toImport[,1])
toImport[,2] <- as.character(toImport[,2])
colnames(toImport) <- c("id", "probeID")
toImport <- toImport[which(!is.na(toImport$id) & toImport$id != ""),]
dbname <- "EntrezGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2025-09-19 07:48:27.137969

<!-- ## Probes from biomaRt -->


<!-- **Start**: 2025-09-19 07:48:27.138388 -->

<!-- ```{r} -->
<!-- library(biomaRt) -->
<!-- bm <- "ENSEMBL_MART_ENSEMBL" -->
<!-- marts <-listMarts() -->
<!-- version <- ensembl_release -->
<!-- if(grep( -->
<!--    sprintf(" %s$", version), -->
<!--    marts[which(marts$biomart==bm), "version"] -->
<!-- ) == 1) { -->
<!--    version <- NULL -->
<!-- } -->
<!-- orgOfInt <- c("hsapiens", "mmusculus", "rnorvegicus", "sscrofa", "drerio") -->
<!-- for(org in orgOfInt){ -->
<!--    message(org) -->
<!--    mart <- useEnsembl( -->
<!--       biomart = bm, -->
<!--       dataset = paste0(org, "_gene_ensembl"), -->
<!--       version = version -->
<!--    ) -->
<!--    at <- listAttributes(mart) %>% -->
<!--       dplyr::filter( -->
<!--          stringr::str_detect( -->
<!--             description, stringr::regex("probe", ignore_case=TRUE) -->
<!--          ) -->
<!--       ) %>% -->
<!--       dplyr::filter( -->
<!--          !name %in% -->
<!--             c( -->
<!--                "affy_huex_1_0_st_v2", -->
<!--                "affy_moex_1_0_st_v1", -->
<!--                "affy_raex_1_0_st_v1" -->
<!--             ) -->
<!--       ) -->
<!--    for(i in 1:nrow(at)){ -->
<!--       message("   ", i, "/", nrow(at), " platforms") -->
<!--       message("      ", Sys.time()) -->
<!--       platName <- at$name[i] -->
<!--       platDesc <- paste(at$description[i], "(Ensembl BioMart mapping)") -->
<!--       be <- "Transcript" -->
<!--       ## -->
<!--       BED:::loadPlf(name=platName, description=platDesc, be=be) -->
<!--       ## Import mapping with Ens_transcript -->
<!--       toImport <- getBM( -->
<!--          mart=mart, -->
<!--          attributes=c( -->
<!--             "ensembl_transcript_id", -->
<!--             platName -->
<!--          ) -->
<!--       ) %>% -->
<!--          dplyr::as_tibble() %>% -->
<!--          magrittr::set_colnames(c("id", "probeID")) %>% -->
<!--          dplyr::filter(!is.na(probeID) & probeID!="" & !is.na(id) & id!="") %>% -->
<!--          dplyr::select(probeID, id) %>% -->
<!--          dplyr::distinct() -->
<!--       dbname <- "Ens_transcript" -->
<!--       ## -->
<!--       BED:::loadProbes( -->
<!--          d=toImport, -->
<!--          be=be, -->
<!--          platform=platName, -->
<!--          dbname=dbname -->
<!--       ) -->
<!--    } -->
<!-- } -->
<!-- ``` -->

<!-- **End**: 2025-09-19 07:48:27.138665 -->

## Probes from Ensembl

**Start**: 2025-09-19 07:48:27.138904


``` r
to_exclude <- c(
   "affy_huex_1_0_st_v2",
   "affy_moex_1_0_st_v1",
   "affy_raex_1_0_st_v1"
)
dump_ensembl_func <- function(ens_def){
   base_url <- sprintf(
      "https://ftp.ensembl.org/pub/current_mysql/%s_funcgen_%s_%s",
      stringr::str_replace(tolower(ens_def$organism), " ", "_"),
      ens_def$release, ens_def$gv
   )
   data_dir <- file.path(
      wd,
      sprintf(
         "%s_funcgen_%s_%s",
         stringr::str_replace(tolower(ens_def$organism), " ", "_"),
         ens_def$release, ens_def$gv
      )
   )
   dir.create(data_dir, showWarnings = FALSE)
   to_download <- c(
      "array.txt.gz",
      "probe.txt.gz",
      "probe_set.txt.gz",
      "probe_transcript.txt.gz",
      "probe_set_transcript.txt.gz"
   )
   for(f in to_download){
      fp <- file.path(data_dir, f)
      if(!file.exists(fp)){
         download.file(file.path(base_url, f), fp)
      }
   }
}
load_ensembl_probes <- function(ens_def){
   data_dir <- file.path(
      wd,
      sprintf(
         "%s_funcgen_%s_%s",
         stringr::str_replace(tolower(ens_def$organism), " ", "_"),
         ens_def$release, ens_def$gv
      )
   )
   array <- readr::read_tsv(
      file.path(data_dir, "array.txt.gz"),
      col_names = c(
         "array_id",
         "name",
         "format",
         "vendor",
         "description",
         "type",
         "class",
         "is_probeset_array",
         "is_linked_array",
         "has_sense_interrogation"
      ),
      col_types = "ccccccclll",
      na = "\\N"
   )
   array <- array |>
      dplyr::filter(
         format %in% c("EXPRESSION"),
         !.data$name %in% to_exclude
      )
   probe_arrays <- array |> filter(!is_probeset_array) |> pull(array_id)
   probe <- readr::read_tsv(
      file.path(data_dir, "probe.txt.gz"),
      col_names = c(
         "probe_id",
         "probe_set_id",
         "name",
         "length",
         "array_chip_id",
         "class",
         "description",
         "probe_seq_id"
      ),
      col_types = "cccnccccc",
      na = "\\N"
   )
   probe <- probe |> filter(array_chip_id %in% probe_arrays)
   probe_set <- readr::read_tsv(
      file.path(data_dir, "probe_set.txt.gz"),
      col_names = c(
         "probe_set_id",
         "name",
         "size",
         "family",
         "array_chip_id"
      ),
      col_types = "cccncc",
      na = "\\N"
   )
   probe_transcript <- readr::read_tsv(
      file.path(data_dir, "probe_transcript.txt.gz"),
      col_names = c(
         "probe_transcript_id",
         "probe_id",
         "stable_id",
         "description"
      ),
      col_types = "cccc",
      na = "\\N"
   )
   probe_transcript <- probe_transcript |> 
      filter(probe_id %in% probe$probe_id)
   probe_set_transcript <- readr::read_tsv(
      file.path(data_dir, "probe_set_transcript.txt.gz"),
      col_names = c(
         "probe_set_transcript_id",
         "probe_set_id",
         "stable_id",
         "description"
      ),
      col_types = "cccc",
      na = "\\N"
   )
   be <- "Transcript"
   dbname <- "Ens_transcript"
   for(i in 1:nrow(array)){
      message("   ", i, "/", nrow(array), " platforms")
      message("      ", Sys.time())
      platName <- tolower(paste(
         str_replace(ens_def$organism, " ", "_"),
         array$vendor[i], array$name[i], sep = "_"
      ))
      is_probe_set <- array$is_probeset_array[i]
      platDesc <- paste(
         array$vendor[i],
         array$name[i],
         array$type[i],
         ifelse(is_probe_set, "probe set", "probe"),
         ens_def$organism,
         "(Ensembl mapping)"
      )
      array_id <- array$array_id[i]
      if(is_probe_set){
         toImport <- probe_set |>
            dplyr::filter(.data$array_chip_id==!!array_id) |> 
            dplyr::select("probe_set_id", "name") |> 
            dplyr::inner_join(
               probe_set_transcript |>
                  dplyr::select("probe_set_id", "stable_id"),
               by = "probe_set_id"
            ) |> 
            dplyr::select("probeID" = "name", "id" = "stable_id") |> 
            dplyr::distinct()
      }else{
         toImport <- probe |>
            dplyr::filter(.data$array_chip_id==!!array_id) |> 
            dplyr::select("probe_id", "name") |> 
            dplyr::inner_join(
               probe_transcript |> dplyr::select("probe_id", "stable_id"),
               by = "probe_id"
            ) |> 
            dplyr::select("probeID" = "name", "id" = "stable_id") |> 
            dplyr::distinct()
      }
      if(nrow(toImport) > 0){
         ## Platform description
         BED:::loadPlf(name=platName, description=platDesc, be=be)
         ## Import mapping with Ens_transcript
         BED:::loadProbes(
            d=toImport,
            be=be,
            platform=platName,
            dbname=dbname
         )
      }
   }
}

message("Ensembl probes for Drerio")
dump_ensembl_func(ensembl_Drerio)
load_ensembl_probes(ensembl_Drerio)
message("Ensembl probes for Hsapiens")
dump_ensembl_func(ensembl_Hsapiens)
load_ensembl_probes(ensembl_Hsapiens)
message("Ensembl probes for Mmusculus")
dump_ensembl_func(ensembl_Mmusculus)
load_ensembl_probes(ensembl_Mmusculus)
message("Ensembl probes for Rnorvegicus")
dump_ensembl_func(ensembl_Rnorvegicus)
load_ensembl_probes(ensembl_Rnorvegicus)
message("Ensembl probes for Sscrofa")
dump_ensembl_func(ensembl_Sscrofa)
load_ensembl_probes(ensembl_Sscrofa)
```

**End**: 2025-09-19 08:23:56.279008

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Other information

## Databases ID URL


``` r
otherIdURL <- list(
    # "HGNC"='http://www.genenames.org/cgi-bin/gene_symbol_report?hgnc_id=%s',
    # "HGNC"='https://www.genenames.org/data/gene-symbol-report/#!/hgnc_id/HGNC:%s',
    "miRBase"='http://www.mirbase.org/cgi-bin/mirna_entry.pl?acc=%s',
    "Vega_gene"='http://vega.sanger.ac.uk/id/%s',
    "UniGene"='https://www.ncbi.nlm.nih.gov/unigene?term=%s',
    "Vega_transcript"='http://vega.sanger.ac.uk/id/%s',
    "MGI"='http://www.informatics.jax.org/marker/MGI:%s',
    "Vega_translation"='http://vega.sanger.ac.uk/id/%s',
    "RGD"='https://rgd.mcw.edu/rgdweb/report/gene/main.html?id=%s',
    "MIM_GENE"='http://www.omim.org/entry/%s',
    "ZFIN_gene"='http://zfin.org/%s'
)
for(db in names(otherIdURL)){
    BED:::registerBEDB(
        name=db,
        idURL=otherIdURL[[db]]
    )   
}
```

# Load Lucene Indexes

**Start**: 2025-09-19 08:23:56.452258


``` r
BED:::loadLuceneIndexes()
```

**End**: 2025-09-19 08:23:56.54837


<!----------------------------------------------------------------->
<!----------------------------------------------------------------->
# Session info


```
## R version 4.5.0 (2025-04-11)
## Platform: x86_64-pc-linux-gnu
## Running under: Ubuntu 24.04.3 LTS
## 
## Matrix products: default
## BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
## LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=en_GB.UTF-8        LC_COLLATE=en_US.UTF-8    
##  [5] LC_MONETARY=en_GB.UTF-8    LC_MESSAGES=en_US.UTF-8   
##  [7] LC_PAPER=en_GB.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=en_GB.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: Europe/Rome
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
##  [1] GEOquery_2.76.0     Biobase_2.68.0      BiocGenerics_0.54.0
##  [4] generics_0.1.4      stringr_1.5.2       readr_2.1.5        
##  [7] dplyr_1.1.4         rvest_1.0.5         jsonlite_2.0.0     
## [10] BED_1.6.3           visNetwork_2.1.4    neo2R_2.4.2        
## [13] knitr_1.50         
## 
## loaded via a namespace (and not attached):
##  [1] tidyselect_1.2.1            R.utils_2.13.0             
##  [3] fastmap_1.2.0               promises_1.3.3             
##  [5] XML_3.99-0.19               digest_0.6.37              
##  [7] mime_0.13                   lifecycle_1.0.4            
##  [9] statmod_1.5.0               processx_3.8.6             
## [11] magrittr_2.0.4              compiler_4.5.0             
## [13] rlang_1.1.6                 sass_0.4.10                
## [15] tools_4.5.0                 yaml_2.3.10                
## [17] data.table_1.17.8           S4Arrays_1.8.1             
## [19] htmlwidgets_1.6.4           bit_4.6.0                  
## [21] curl_7.0.0                  DelayedArray_0.34.1        
## [23] xml2_1.4.0                  abind_1.4-8                
## [25] websocket_1.4.4             miniUI_0.1.2               
## [27] withr_3.0.2                 purrr_1.1.0                
## [29] R.oo_1.27.1                 grid_4.5.0                 
## [31] stats4_4.5.0                xtable_1.8-4               
## [33] SummarizedExperiment_1.38.1 cli_3.6.5                  
## [35] rmarkdown_2.29              crayon_1.5.3               
## [37] rstudioapi_0.17.1           httr_1.4.7                 
## [39] tzdb_0.5.0                  cachem_1.1.0               
## [41] chromote_0.5.1              parallel_4.5.0             
## [43] XVector_0.48.0              matrixStats_1.5.0          
## [45] base64enc_0.1-3             vctrs_0.6.5                
## [47] Matrix_1.7-4                IRanges_2.42.0             
## [49] hms_1.1.3                   S4Vectors_0.46.0           
## [51] bit64_4.6.0-1               limma_3.64.3               
## [53] jquerylib_0.1.4             tidyr_1.3.1                
## [55] glue_1.8.0                  ps_1.9.1                   
## [57] DT_0.34.0                   stringi_1.8.7              
## [59] later_1.4.4                 GenomeInfoDb_1.44.2        
## [61] GenomicRanges_1.60.0        UCSC.utils_1.4.0           
## [63] tibble_3.3.0                pillar_1.11.1              
## [65] htmltools_0.5.8.1           GenomeInfoDbData_1.2.14    
## [67] R6_2.6.1                    vroom_1.6.5                
## [69] evaluate_1.0.5              shiny_1.11.1               
## [71] lattice_0.22-7              rentrez_1.2.4              
## [73] R.methodsS3_1.8.2           httpuv_1.6.16              
## [75] bslib_0.9.0                 Rcpp_1.1.0                 
## [77] SparseArray_1.8.1           xfun_0.53                  
## [79] MatrixGenerics_1.20.0       pkgconfig_2.0.3
```
