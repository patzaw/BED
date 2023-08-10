---
title: "Biological Entity Dictionary (BED): Feeding the DB"
author: "Patrice Godard"
date: "August 09 2023"
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


```r
##
library(knitr)
library(BED)
##
# if("metabaser" %in% rownames(installed.packages())){
#    source("helpers/loadMBObjects.R")
# }else{
#    stop("The Clarivate analytics metabaser package is not installed.")
# }
# library(TKCat)
# k <- chTKCat("bel040344", password="")
.get_tk_headers <- do.call(function(){
   ## Choose the relevant credentials
   credentials <- readRDS("~/etc/kmt_authorization.rds")
   credentials$refresh()
   return(function(){
      if(!credentials$validate()){
         credentials$refresh()
      }
      list(
         "Authorization"=paste("Bearer", credentials$credentials$access_token)
      )
   })
}, list())
library(TKCat)
.tkcon <- chTKCat(
   "tkcat.ucb.com",
   password="",
   port=443, https=TRUE,
   extended_headers=.get_tk_headers()
)
.db_reconnect <- function(x){
   xn <- deparse(substitute(x))
   nv <- db_reconnect(x, extended_headers=.get_tk_headers())
   assign(xn, nv, envir=parent.frame(n=1))
   invisible(nv)
}
if("MetaBase" %in% list_MDBs(.tkcon)$name){
   source("helpers/loadMBObjects_fromTKCat.R")
}else{
   stop("MetaBase is not available in this TKCat instance.")
}
##
workingDirectory <- "../../../working"
##
opts_knit$set(root.dir=workingDirectory)
opts_chunk$set(
   eval=TRUE,
   message=FALSE,
   root.dir=workingDirectory
)
## Specific config
bedInstance <- "UCB-Human"
bedVersion <- format(Sys.Date(), "%Y.%m.%d")
ensembl_release <- "110"
ensembl_Hsapiens <- list(
    release=ensembl_release,
    organism="Homo sapiens",
    gv="38",                        # genome version
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
ensembl_Mmusculus <- list(
    release=ensembl_release,
    organism="Mus musculus",
    gv="39",                        # genome version
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
ensembl_Rnorvegicus <- list(
    release=ensembl_release,
    organism="Rattus norvegicus",
    gv="72",                         # genome version
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
ensembl_Sscrofa <- list(
    release=ensembl_release,
    organism="Sus scrofa",
    gv="111",                         # genome version
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
ensembl_Drerio <- list(
    release=ensembl_release,
    organism="Danio rerio",
    gv="11",                         # genome version
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
reDumpThr <- as.difftime(4, units="days")
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


```r
connectToBed(
   url="localhost:5410",
   remember=FALSE,
   useCache=TRUE,
   importPath=file.path(getwd(), "neo4jImport")
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

## Check empty DB

Do not go further if your BED DB is not empty.


```r
dbSize <- bedCall(cypher, 'MATCH (n) RETURN count(n)')[,1]
if(dbSize!=0){
    stop("BED DB is not empty ==> clean it before loading the content below")
}
```

## Set BED instance and version


```r
print(bedInstance)
```

```
## [1] "UCB-Human"
```

```r
print(bedVersion)
```

```
## [1] "2023.08.09"
```

```r
BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
```

## Load Data model

**Start**: 2023-08-09 16:54:18.232244


```r
BED:::loadBedModel()
```

**End**: 2023-08-09 16:54:26.723324

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading taxonomy from NCBI

Information is downloaded if older than 4 days
according to the `reDumpThr` object.

**Start**: 2023-08-09 16:54:26.724561


```r
BED:::loadNcbiTax(
    reDumpThr=reDumpThr,
    ddir=".",
    orgOfInt=c(
       "Homo sapiens", "Rattus norvegicus", "Mus musculus",
       "Sus scrofa", "Danio rerio"
      ),
    curDate=curDate
)
```

**End**: 2023-08-09 16:55:17.213482

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading data from Ensembl

## Register Ensembl DBs

### Genes


```r
BED:::registerBEDB(
    name="Ens_gene",
    description="Ensembl gene",
    currentVersion=ensembl_release,
    idURL='http://www.ensembl.org/id/%s'
)
```

### Transcripts


```r
BED:::registerBEDB(
    name="Ens_transcript",
    description="Ensembl transcript",
    currentVersion=ensembl_release,
    idURL='http://www.ensembl.org/id/%s'
)
```

### Peptides


```r
BED:::registerBEDB(
    name="Ens_translation",
    description="Ensembl peptides",
    currentVersion=ensembl_release,
    idURL='http://www.ensembl.org/id/%s'
)
```

## Danio rerio


```r
ensembl <- ensembl_Drerio
print(ensembl)
```

```
## $release
## [1] "110"
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

**Start**: 2023-08-09 16:55:17.489155


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells 2675368 142.9   14240172 760.6  17800214 950.7
## Vcells 8807724  67.2   81973800 625.5 128081948 977.2
```

**End**: 2023-08-09 16:59:18.44798

### Transcripts

**Start**: 2023-08-09 16:59:18.448443


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells 2678707 143.1   11392138 608.5  17800214 950.7
## Vcells 8815033  67.3   65579040 500.4 128081948 977.2
```

**End**: 2023-08-09 17:01:58.144515

### Peptides

**Start**: 2023-08-09 17:01:58.14496


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells 2681694 143.3    9113711 486.8  17800214 950.7
## Vcells 8821663  67.4   52463232 400.3 128081948 977.2
```

**End**: 2023-08-09 17:04:42.648849

## Homo sapiens


```r
ensembl <- ensembl_Hsapiens
print(ensembl)
```

```
## $release
## [1] "110"
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

**Start**: 2023-08-09 17:04:42.657035


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  2681835 143.3   14597024  779.6  18246279  974.5
## Vcells 13016445  99.4  212754936 1623.2 265740570 2027.5
```

**End**: 2023-08-09 17:14:09.033694

### Transcripts

**Start**: 2023-08-09 17:14:09.034201


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  2681899 143.3   12481296  666.6  18246279  974.5
## Vcells 13016573  99.4  170203949 1298.6 265740570 2027.5
```

**End**: 2023-08-09 17:19:56.655175

### Peptides

**Start**: 2023-08-09 17:19:56.65571


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  2681718 143.3    9985037  533.3  18246279  974.5
## Vcells 13016334  99.4  136163160 1038.9 265740570 2027.5
```

**End**: 2023-08-09 17:27:03.348397

## Mus musculus


```r
ensembl <- ensembl_Mmusculus
print(ensembl)
```

```
## $release
## [1] "110"
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

**Start**: 2023-08-09 17:27:03.356942


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  2681949 143.3    9617636  513.7  18246279  974.5
## Vcells 13016963  99.4  157000760 1197.9 265740570 2027.5
```

**End**: 2023-08-09 17:33:05.56222

### Transcripts

**Start**: 2023-08-09 17:33:05.562761


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  2681713 143.3    7694109 411.0  18246279  974.5
## Vcells 13016591  99.4  125600608 958.3 265740570 2027.5
```

**End**: 2023-08-09 17:36:24.561842

### Peptides

**Start**: 2023-08-09 17:36:24.562372


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  2681766 143.3    7418344 396.2  18246279  974.5
## Vcells 13016742  99.4  100480487 766.7 265740570 2027.5
```

**End**: 2023-08-09 17:39:27.578029

## Rattus norvegicus


```r
ensembl <- ensembl_Rnorvegicus
print(ensembl)
```

```
## $release
## [1] "110"
## 
## $organism
## [1] "Rattus norvegicus"
## 
## $gv
## [1] "72"
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

**Start**: 2023-08-09 17:39:27.585655


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  2681664 143.3    7418344 396.2  18246279  974.5
## Vcells 13016804  99.4   80384390 613.3 265740570 2027.5
```

**End**: 2023-08-09 17:42:53.341053

### Transcripts

**Start**: 2023-08-09 17:42:53.341566


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  2681644 143.3    7418344 396.2  18246279  974.5
## Vcells 13016792  99.4   64307512 490.7 265740570 2027.5
```

**End**: 2023-08-09 17:44:25.003394

### Peptides

**Start**: 2023-08-09 17:44:25.003982


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  2681691 143.3    7418344 396.2  18246279  974.5
## Vcells 13016933  99.4   51446010 392.6 265740570 2027.5
```

**End**: 2023-08-09 17:46:15.73512

## Sus scrofa


```r
ensembl <- ensembl_Sscrofa
print(ensembl)
```

```
## $release
## [1] "110"
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

**Start**: 2023-08-09 17:46:15.742546


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  2681688 143.3    7418344 396.2  18246279  974.5
## Vcells 13017167  99.4   59406604 453.3 265740570 2027.5
```

**End**: 2023-08-09 17:48:15.562748

### Transcripts

**Start**: 2023-08-09 17:48:15.563196


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  2681617 143.3    7418344 396.2  18246279  974.5
## Vcells 13017070  99.4   47525284 362.6 265740570 2027.5
```

**End**: 2023-08-09 17:49:23.884223

### Peptides

**Start**: 2023-08-09 17:49:23.884698


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    ddir=".",
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  2681658 143.3    7418344 396.2  18246279  974.5
## Vcells 13017201  99.4   45688272 348.6 265740570 2027.5
```

**End**: 2023-08-09 17:50:55.922581

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading data from NCBI

Information is downloaded if older than 4 days
according to the `reDumpThr` object.

## Register NCBI DBs


```r
BED:::dumpNcbiDb(
  taxOfInt = c(), reDumpThr=reDumpThr,
  ddir=".",
  toLoad=c(), curDate=curDate
)
```

### Genes


```r
BED:::registerBEDB(
    name="EntrezGene",
    description="NCBI gene",
    currentVersion=format(dumpDate, "%Y%m%d"),
    idURL='https://www.ncbi.nlm.nih.gov/gene/%s'
)
```

### Transcripts


```r
BED:::registerBEDB(
    name="RefSeq",
    description="NCBI nucleotide",
    currentVersion=format(dumpDate, "%Y%m%d"),
    idURL='https://www.ncbi.nlm.nih.gov/nuccore/%s'
)
```

### Peptides


```r
BED:::registerBEDB(
    name="RefSeq_peptide",
    description="NCBI protein",
    currentVersion=format(dumpDate, "%Y%m%d"),
    idURL='https://www.ncbi.nlm.nih.gov/protein/%s'
)
```

## Danio rerio data

**Start**: 2023-08-09 17:50:56.075854


```r
BED:::getNcbiGeneTransPep(
    organism="Danio rerio",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells   2688857  143.7  453949054 24243.5  445391260 23786.5
## Vcells 273079189 2083.5 3396819172 25915.7 4233038320 32295.6
```

**End**: 2023-08-09 19:09:42.726727

## Homo sapiens data

**Start**: 2023-08-09 19:09:42.727325


```r
BED:::getNcbiGeneTransPep(
    organism="Homo sapiens",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells   2688562  143.6  363159244 19394.8  453949054 24243.5
## Vcells 273078749 2083.5 2758820610 21048.2 4233038320 32295.6
```

**End**: 2023-08-09 19:35:39.88117

## Mus musculus data

**Start**: 2023-08-09 19:35:39.881632


```r
BED:::getNcbiGeneTransPep(
    organism="Mus musculus",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells   2688678  143.6  232421917 12412.7  453949054 24243.5
## Vcells 273078994 2083.5 1765645191 13470.9 4233038320 32295.6
```

**End**: 2023-08-09 19:56:53.935304

## Rattus norvegicus data

**Start**: 2023-08-09 19:56:53.935843


```r
BED:::getNcbiGeneTransPep(
    organism="Rattus norvegicus",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells   2688464  143.6  401350628 21434.5  453949054 24243.5
## Vcells 273078689 2083.5 1702083957 12985.9 4233038320 32295.6
```

**End**: 2023-08-09 20:19:53.221418

## Sus scrofa data

**Start**: 2023-08-09 20:19:53.221975


```r
BED:::getNcbiGeneTransPep(
    organism="Sus scrofa",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells   2688646  143.6  422959348 22588.5  453949054 24243.5
## Vcells 273079045 2083.5 1972792330 15051.3 4233038320 32295.6
```

**End**: 2023-08-09 20:41:36.105746

## Direct cross-references with Uniprot

**Start**: 2023-08-09 20:41:36.106295


```r
message("Direct cross-references with Uniprot")
BED:::dumpNcbiDb(
  taxOfInt="",
  reDumpThr=Inf,
  ddir=".",
  toLoad="gene_refseq_uniprotkb_collab",
  curDate=Sys.Date()
)
for(org in listOrganisms()){
  message("   ", org)
  curRS <- getBeIds(
    be="Peptide", source="RefSeq_peptide", organism=org,
    restricted=TRUE
  )
  toAdd <- gene_refseq_uniprotkb_collab[
    which(gene_refseq_uniprotkb_collab$NCBI_protein_accession %in% curRS$id),
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
  toImport <- toAdd
  colnames(toImport) <- c("id1", "id2")
  BED:::loadCorrespondsTo(
      d=toImport,
      db1="RefSeq_peptide",
      db2="Uniprot",
      be="Peptide"
  )
}
```

**End**: 2023-08-09 20:59:00.060223


<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading data from Uniprot

Release is defined according to the *reldate.txt* file on the Uniprot FTP
and data is downloaded only if not already done for the current release.


```r
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

**Start**: 2023-08-09 20:59:04.803069


```r
BED:::getUniprot(
    organism="Danio rerio", release=avRel, ddir="."
)
gc()
```

```
##              used  (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  254034955 13567  422959348 22588.5  453949054 24243.5
## Vcells 1068885129  8155 1972792330 15051.3 4233038320 32295.6
```

**End**: 2023-08-09 21:02:39.226946

## Homo sapiens data

**Start**: 2023-08-09 21:02:39.227428


```r
BED:::getUniprot(
    organism="Homo sapiens", release=avRel, ddir="."
)
gc()
```

```
##              used  (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  254034936 13567  422959348 22588.5  453949054 24243.5
## Vcells 1068885147  8155 1972792330 15051.3 4233038320 32295.6
```

**End**: 2023-08-09 21:06:57.985456

## Mus musculus data

**Start**: 2023-08-09 21:06:57.985965


```r
BED:::getUniprot(
    organism="Mus musculus", release=avRel, ddir="."
)
gc()
```

```
##              used  (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  254034902 13567  422959348 22588.5  453949054 24243.5
## Vcells 1068885140  8155 1972792330 15051.3 4233038320 32295.6
```

**End**: 2023-08-09 21:09:14.990926

## Rattus norvegicus data

**Start**: 2023-08-09 21:09:14.991794


```r
BED:::getUniprot(
    organism="Rattus norvegicus", release=avRel, ddir="."
)
gc()
```

```
##              used  (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  254034895 13567  422959348 22588.5  453949054 24243.5
## Vcells 1068885178  8155 1972792330 15051.3 4233038320 32295.6
```

**End**: 2023-08-09 21:11:34.041939

## Sus scrofa data

**Start**: 2023-08-09 21:11:34.042398


```r
BED:::getUniprot(
    organism="Sus scrofa", release=avRel, ddir="."
)
gc()
```

```
##              used  (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  254034867 13567  422959348 22588.5  453949054 24243.5
## Vcells 1068885182  8155 1972792330 15051.3 4233038320 32295.6
```

**End**: 2023-08-09 21:23:19.799993

## Indirect cross-references with EntrezGene

**Start**: 2023-08-09 21:23:19.800496


```r
message("Indirect cross-references with Uniprot")
dumpDir <- "NCBI-gene-DATA"
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

**End**: 2023-08-09 21:43:06.291949

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading Clarivate Analytics MetaBase objects from TKCat

**Start**: 2023-08-09 21:43:06.292837


<!-- ```{r, echo=FALSE} -->
<!-- options(java.parameters="-Xmx16g") -->
<!-- source("~/opt/MetaBase/metabaseConnection.R") -->
<!-- ``` -->

<!-- The following chunk should be adapted to fit MetaBase installation. -->

<!-- ```{r MetaBaseConnection, eval=FALSE} -->
<!-- library(metabaser) -->
<!-- metabase.connect( -->
<!--     driver = "jdbc", -->
<!--     jdbc.url ="jdbc:oracle:thin:@//HOSTURL", -->
<!--     uid = "USER", pwd = "PASSWORD" -->
<!-- ) -->
<!-- ``` -->


```r
.db_reconnect(.tkcon)
tkmb <- get_MDB(.tkcon, "MetaBase")
```


## Register MetaBase DB


```r
# mbInfo <- mbquery("select * from zzz_System")
BED:::registerBEDB(
    name="MetaBase_gene",
    description="Clarivate Analytics MetaBase",
    currentVersion=tkmb$MetaBase_sourceDatabases$current,
    idURL='https://portal.genego.com/cgi/entity_page.cgi?term=20&id=%s'
)
BED:::registerBEDB(
    name="MetaBase_object",
    description="Clarivate Analytics MetaBase",
    currentVersion=tkmb$MetaBase_sourceDatabases$current,
    idURL='https://portal.genego.com/cgi/entity_page.cgi?term=100&id=%s'
)
```

## Homo sapiens data


```r
.db_reconnect(tkmb)
loadMBObjects_fromTKCat(
    orgOfInt=c("Homo sapiens"),
    tkmb=tkmb
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  254205880 13576.1  422959348 22588.5  453949054 24243.5
## Vcells 1095861975  8360.8 1972792330 15051.3 4233038320 32295.6
```

## Mus musculus data


```r
.db_reconnect(tkmb)
loadMBObjects_fromTKCat(
    orgOfInt=c("Mus musculus"),
    tkmb=tkmb
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  254200162 13575.8  422959348 22588.5  453949054 24243.5
## Vcells 1095292593  8356.5 1972792330 15051.3 4233038320 32295.6
```

## Rattus norvegicus data


```r
.db_reconnect(tkmb)
loadMBObjects_fromTKCat(
    orgOfInt=c("Rattus norvegicus"),
    tkmb=tkmb
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  254200163 13575.8  422959348 22588.5  453949054 24243.5
## Vcells 1095292633  8356.5 1972792330 15051.3 4233038320 32295.6
```

**End**: 2023-08-09 21:48:05.90633

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading homologs

## Orthologs from biomaRt

**Start**: 2023-08-09 21:48:05.907005


```r
library(biomaRt)
loadBmHomologs <- function(mart, org2){

    #mattr <- listAttributes(mart)
    
    toImport <- getBM(
        mart=mart,
        attributes=c(
            "ensembl_gene_id",
            paste0(
              org2,
              c("_homolog_ensembl_gene", "_homolog_orthology_confidence")
            )
        )
    )
    colnames(toImport) <- c("id1", "id2", "cs")
    toImport <- unique(toImport[
        which(toImport$id1 != "" & toImport$id2 != "" & toImport$cs==1),
        c("id1", "id2")
    ])
    
    BED:::loadIsHomologOf(
        d=toImport,
        db1="Ens_gene", db2="Ens_gene",
        be="Gene"
    )

}

#########################################
orgOfInt <- c("hsapiens", "mmusculus", "rnorvegicus", "sscrofa", "drerio")
marts <-listMarts()
bm <- "ENSEMBL_MART_ENSEMBL"
version <- ensembl_release
if(
  grep(
    sprintf(" %s$", version),
    marts[which(marts$biomart==bm), "version"]
  )==1
){
    version <- NULL
}
for(i in 1:(length(orgOfInt)-1)){
  #########################################
  ## The mart
  org1 <- orgOfInt[i]
  mart <- useEnsembl(
      biomart=bm,
      dataset=paste0(org1, "_gene_ensembl"),
      version=version
  )
  for(j in (i+1):length(orgOfInt)){
    loadBmHomologs(
      mart=mart,
      org2=orgOfInt[j]
    )
  }
}
```

**End**: 2023-08-09 21:52:31.50735

## Orthologs from NCBI

**Start**: 2023-08-09 21:52:31.50861


```r
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
       ddir=".",
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
## Ncells  257237437 13738.0  422959348 22588.5  453949054 24243.5
## Vcells 1077557647  8221.2 1972792330 15051.3 4233038320 32295.6
```

**End**: 2023-08-09 21:54:39.971296

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading probes

## Probes from GEO


```r
library(GEOquery)
dir.create("geo", showWarnings=FALSE)
```

### GPL1708: 	Agilent-012391 Whole Human Genome Oligo Microarray G4112A (Feature Number version)

**Start**: 2023-08-09 21:54:40.425633


```r
## Import plateform
platName <- "GPL1708"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:54:51.049109

### GPL6480: Agilent-014850 Whole Human Genome Microarray 4x44K G4112F (Probe Name version)

**Start**: 2023-08-09 21:54:51.050111


```r
## Import plateform
platName <- "GPL6480"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:55:00.803126

### GPL570: Affymetrix Human Genome U133 Plus 2.0 Array

**Start**: 2023-08-09 21:55:00.804045


```r
## Import plateform
platName <- "GPL570"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:55:18.130326

### GPL571: Affymetrix Human Genome U133A 2.0 Array

**Start**: 2023-08-09 21:55:18.130943


```r
## Import plateform
platName <- "GPL571"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:55:27.391098

### GPL13158: Affymetrix HT HG-U133+ PM Array Plate

**Start**: 2023-08-09 21:55:27.392382


```r
## Import plateform
platName <- "GPL13158"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:55:43.246305

### GPL96: Affymetrix Human Genome U133A Array

**Start**: 2023-08-09 21:55:43.247053


```r
## Import plateform
platName <- "GPL96"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:55:52.172971

### GPL1261: Affymetrix Mouse Genome 430 2.0 Array

**Start**: 2023-08-09 21:55:52.173522


```r
## Import plateform
platName <- "GPL1261"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:56:09.566804

### GPL1355: Affymetrix Rat Genome 230 2.0 Array

**Start**: 2023-08-09 21:56:09.567395


```r
## Import plateform
platName <- "GPL1355"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:56:18.467928

### GPL10558: Illumina HumanHT-12 V4.0 expression beadchip

**Start**: 2023-08-09 21:56:18.469008


```r
## Import plateform
platName <- "GPL10558"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:56:34.187848

### GPL6947: Illumina HumanHT-12 V3.0 expression beadchip

**Start**: 2023-08-09 21:56:34.188923


```r
## Import plateform
platName <- "GPL6947"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:56:45.169499

### GPL6885: Illumina MouseRef-8 v2.0 expression beadchip

**Start**: 2023-08-09 21:56:45.170087


```r
## Import plateform
platName <- "GPL6885"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:56:52.69024

### GPL6887: Illumina MouseWG-6 v2.0 expression beadchip

**Start**: 2023-08-09 21:56:52.691792


```r
## Import plateform
platName <- "GPL6887"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:57:07.172913

### GPL6101: Illumina ratRef-12 v1.0 expression beadchip

**Start**: 2023-08-09 21:57:07.173792


```r
## Import plateform
platName <- "GPL6101"
gds <- getGEO(platName, destdir="geo")
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

**End**: 2023-08-09 21:57:14.369364

## Probes from biomaRt


**Start**: 2023-08-09 21:57:14.370009


```r
library(biomaRt)
bm <- "ENSEMBL_MART_ENSEMBL"
marts <-listMarts()
version <- ensembl_release
if(grep(
   sprintf(" %s$", version),
   marts[which(marts$biomart==bm), "version"]
) == 1) {
   version <- NULL
}
orgOfInt <- c("hsapiens", "mmusculus", "rnorvegicus", "sscrofa", "drerio")
for(org in orgOfInt){
   message(org)
   mart <- useEnsembl(
      biomart = bm,
      dataset = paste0(org, "_gene_ensembl"),
      version = version
   )
   at <- listAttributes(mart) %>%
      dplyr::filter(
         stringr::str_detect(
            description, stringr::regex("probe", ignore_case=TRUE)
         )
      ) %>%
      dplyr::filter(
         !name %in%
            c(
               "affy_huex_1_0_st_v2",
               "affy_moex_1_0_st_v1",
               "affy_raex_1_0_st_v1"
            )
      )
   for(i in 1:nrow(at)){
      message("   ", i, "/", nrow(at), " platforms")
      message("      ", Sys.time())
      platName <- at$name[i]
      platDesc <- paste(at$description[i], "(Ensembl BioMart mapping)")
      be <- "Transcript"
      ##
      BED:::loadPlf(name=platName, description=platDesc, be=be)
      ## Import mapping with Ens_transcript
      toImport <- getBM(
         mart=mart,
         attributes=c(
            "ensembl_transcript_id",
            platName
         )
      ) %>%
         dplyr::as_tibble() %>%
         magrittr::set_colnames(c("id", "probeID")) %>%
         dplyr::filter(!is.na(probeID) & probeID!="" & !is.na(id) & id!="") %>%
         dplyr::select(probeID, id) %>%
         dplyr::distinct()
      dbname <- "Ens_transcript"
      ##
      BED:::loadProbes(
         d=toImport,
         be=be,
         platform=platName,
         dbname=dbname
      )
   }
}
```

**End**: 2023-08-09 23:42:29.187714

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Other information

## Databases ID URL


```r
otherIdURL <- list(
    "HGNC"='http://www.genenames.org/cgi-bin/gene_symbol_report?hgnc_id=%s',
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

**Start**: 2023-08-09 23:42:29.730429


```r
BED:::loadLuceneIndexes()
```

**End**: 2023-08-09 23:42:30.773977


<!----------------------------------------------------------------->
<!----------------------------------------------------------------->
# Session info


```
## R version 4.3.0 (2023-04-21)
## Platform: x86_64-pc-linux-gnu (64-bit)
## Running under: Red Hat Enterprise Linux
## 
## Matrix products: default
## BLAS/LAPACK: /usr/lib64/libopenblasp-r0.3.3.so;  LAPACK version 3.8.0
## 
## locale:
##  [1] LC_CTYPE=en_GB.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=en_GB.UTF-8        LC_COLLATE=en_GB.UTF-8    
##  [5] LC_MONETARY=en_GB.UTF-8    LC_MESSAGES=en_GB.UTF-8   
##  [7] LC_PAPER=en_GB.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=en_GB.UTF-8 LC_IDENTIFICATION=C       
## 
## time zone: Europe/Brussels
## tzcode source: system (glibc)
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
##  [1] GEOquery_2.68.0     Biobase_2.60.0      BiocGenerics_0.46.0
##  [4] biomaRt_2.56.1      TKCat_1.1.2         DBI_1.1.3          
##  [7] ReDaMoR_0.7.2       magrittr_2.0.3      dplyr_1.1.2        
## [10] BED_1.4.13          visNetwork_2.1.2    neo2R_2.4.1        
## [13] knitr_1.43         
## 
## loaded via a namespace (and not attached):
##   [1] bitops_1.0-7            rlang_1.1.1             shinydashboard_0.7.2   
##   [4] compiler_4.3.0          RSQLite_2.3.1           getPass_0.2-2          
##   [7] roxygen2_7.2.3          png_0.1-8               vctrs_0.6.3            
##  [10] stringr_1.5.0           pkgconfig_2.0.3         crayon_1.5.2           
##  [13] fastmap_1.1.1           dbplyr_2.3.3            XVector_0.40.0         
##  [16] ellipsis_0.3.2          utf8_1.2.3              promises_1.2.0.1       
##  [19] rmarkdown_2.23          markdown_1.7            tzdb_0.4.0             
##  [22] ClickHouseHTTP_0.3.2    purrr_1.0.1             bit_4.0.5              
##  [25] xfun_0.39               zlibbioc_1.46.0         cachem_1.0.8           
##  [28] GenomeInfoDb_1.36.1     jsonlite_1.8.7          progress_1.2.2         
##  [31] blob_1.2.4              later_1.3.1             uuid_1.1-0             
##  [34] prettyunits_1.1.1       parallel_4.3.0          R6_2.5.1               
##  [37] bslib_0.5.0             stringi_1.7.12          limma_3.56.2           
##  [40] parallelly_1.36.0       jquerylib_0.1.4         Rcpp_1.0.11            
##  [43] assertthat_0.2.1        R.utils_2.12.2          base64enc_0.1-3        
##  [46] readr_2.1.4             IRanges_2.34.1          httpuv_1.6.11          
##  [49] Matrix_1.6-0            tidyselect_1.2.0        rstudioapi_0.15.0      
##  [52] yaml_2.3.7              codetools_0.2-19        miniUI_0.1.1.1         
##  [55] curl_5.0.1              listenv_0.9.0           lattice_0.21-8         
##  [58] tibble_3.2.1            KEGGREST_1.40.0         shiny_1.7.4.1          
##  [61] withr_2.5.0             askpass_1.1             evaluate_0.21          
##  [64] future_1.33.0           BiocFileCache_2.8.0     xml2_1.3.5             
##  [67] Biostrings_2.68.1       filelock_1.0.2          pillar_1.9.0           
##  [70] DT_0.28                 stats4_4.3.0            shinyjs_2.1.0          
##  [73] generics_0.1.3          RCurl_1.98-1.12         hms_1.1.3              
##  [76] S4Vectors_0.38.1        globals_0.16.2          xtable_1.8-4           
##  [79] glue_1.6.2              tools_4.3.0             data.table_1.14.8      
##  [82] colourpicker_1.2.0      XML_3.99-0.14           grid_4.3.0             
##  [85] jsonvalidate_1.3.2      tidyr_1.3.0             AnnotationDbi_1.62.2   
##  [88] GenomeInfoDbData_1.2.10 cli_3.6.1               rappdirs_0.3.3         
##  [91] AzureAuth_1.3.3         fansi_1.0.4             arrow_12.0.1.1         
##  [94] V8_4.3.3                R.methodsS3_1.8.2       rintrojs_0.3.2         
##  [97] sass_0.4.7              digest_0.6.33           htmlwidgets_1.6.2      
## [100] R.oo_1.25.0             memoise_2.0.1           htmltools_0.5.5        
## [103] lifecycle_1.0.3         httr_1.4.6              jose_1.2.0             
## [106] mime_0.12               openssl_2.1.0           bit64_4.0.5
```
