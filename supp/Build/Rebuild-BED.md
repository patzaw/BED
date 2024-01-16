---
title: "Biological Entity Dictionary (BED): Feeding the DB"
author: "Patrice Godard"
date: "January 14 2024"
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
ensembl_release <- "111"
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
## [1] "2024.01.14"
```

```r
BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
```

## Load Data model

**Start**: 2024-01-14 11:47:01.757516


```r
BED:::loadBedModel()
```

**End**: 2024-01-14 11:47:06.863333

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading taxonomy from NCBI

Information is downloaded if older than 4 days
according to the `reDumpThr` object.

**Start**: 2024-01-14 11:47:06.864832


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

**End**: 2024-01-14 11:47:25.977368

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
## [1] "111"
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

**Start**: 2024-01-14 11:47:26.386705


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
##           used  (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells 2606111 139.2    8062171 430.6 10077713 538.3
## Vcells 8713004  66.5   43868404 334.7 68544379 523.0
```

**End**: 2024-01-14 11:50:31.316136

### Transcripts

**Start**: 2024-01-14 11:50:31.316714


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
##           used  (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells 2609321 139.4    8062171 430.6 10077713 538.3
## Vcells 8720097  66.6   50677200 386.7 68544379 523.0
```

**End**: 2024-01-14 11:53:01.396618

### Peptides

**Start**: 2024-01-14 11:53:01.398333


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
##           used  (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells 2612368 139.6    8062171 430.6 10077713 538.3
## Vcells 8726827  66.6   48714112 371.7 68544379 523.0
```

**End**: 2024-01-14 11:55:50.702204

## Homo sapiens


```r
ensembl <- ensembl_Hsapiens
print(ensembl)
```

```
## $release
## [1] "111"
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

**Start**: 2024-01-14 11:55:50.709869


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
##           used  (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells 2612305 139.6   10934034  584.0  13667542  730.0
## Vcells 8726965  66.6  131222916 1001.2 164014750 1251.4
```

**End**: 2024-01-14 12:00:39.969077

### Transcripts

**Start**: 2024-01-14 12:00:39.969501


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612771 139.6   10528672 562.3  13667542  730.0
## Vcells 8727763  66.6  126038000 961.6 164014750 1251.4
```

**End**: 2024-01-14 12:05:53.39851

### Peptides

**Start**: 2024-01-14 12:05:53.398962


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612629 139.6   10139525 541.6  13667542  730.0
## Vcells 8727589  66.6  121060480 923.7 164014750 1251.4
```

**End**: 2024-01-14 12:12:55.22442

## Mus musculus


```r
ensembl <- ensembl_Mmusculus
print(ensembl)
```

```
## $release
## [1] "111"
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

**Start**: 2024-01-14 12:12:55.232118


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612422 139.6    8477593 452.8  13667542  730.0
## Vcells 8727487  66.6   96848384 738.9 164014750 1251.4
```

**End**: 2024-01-14 12:16:01.442534

### Transcripts

**Start**: 2024-01-14 12:16:01.44326


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612501 139.6    8265491 441.5  13667542  730.0
## Vcells 8727639  66.6   77478708 591.2 164014750 1251.4
```

**End**: 2024-01-14 12:19:30.662379

### Peptides

**Start**: 2024-01-14 12:19:30.662823


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612590 139.6    8265491 441.5  13667542  730.0
## Vcells 8727850  66.6   74443560 568.0 164014750 1251.4
```

**End**: 2024-01-14 12:23:15.392183

## Rattus norvegicus


```r
ensembl <- ensembl_Rnorvegicus
print(ensembl)
```

```
## $release
## [1] "111"
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

**Start**: 2024-01-14 12:23:15.400541


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612437 139.6    8265491 441.5  13667542  730.0
## Vcells 8727839  66.6   59554848 454.4 164014750 1251.4
```

**End**: 2024-01-14 12:25:32.767507

### Transcripts

**Start**: 2024-01-14 12:25:32.767965


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612471 139.6    8265491 441.5  13667542  730.0
## Vcells 8727916  66.6   47643879 363.5 164014750 1251.4
```

**End**: 2024-01-14 12:27:05.667845

### Peptides

**Start**: 2024-01-14 12:27:05.668269


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612413 139.6    8265491 441.5  13667542  730.0
## Vcells 8727882  66.6   38115104 290.8 164014750 1251.4
```

**End**: 2024-01-14 12:29:09.788619

## Sus scrofa


```r
ensembl <- ensembl_Sscrofa
print(ensembl)
```

```
## $release
## [1] "111"
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

**Start**: 2024-01-14 12:29:09.796041


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612437 139.6    8265491 441.5  13667542  730.0
## Vcells 8728160  66.6   36654500 279.7 164014750 1251.4
```

**End**: 2024-01-14 12:30:00.176693

### Transcripts

**Start**: 2024-01-14 12:30:00.177154


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612363 139.6    8265491 441.5  13667542  730.0
## Vcells 8728057  66.6   35252320 269.0 164014750 1251.4
```

**End**: 2024-01-14 12:31:08.373983

### Peptides

**Start**: 2024-01-14 12:31:08.374404


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
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2612371 139.6    8265491 441.5  13667542  730.0
## Vcells 8728133  66.6   33906228 258.7 164014750 1251.4
```

**End**: 2024-01-14 12:33:23.738484

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

**Start**: 2024-01-14 12:33:23.952307


```r
BED:::getNcbiGeneTransPep(
    organism="Danio rerio",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2618928 139.9    8265491 441.5  13667542  730.0
## Vcells 8742202  66.7   33942068 259.0 164014750 1251.4
```

**End**: 2024-01-14 12:36:09.404121

## Homo sapiens data

**Start**: 2024-01-14 12:36:09.404555


```r
BED:::getNcbiGeneTransPep(
    organism="Homo sapiens",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2619002 139.9   13489241 720.5  16861551  900.6
## Vcells 8742375  66.7   94990661 724.8 164014750 1251.4
```

**End**: 2024-01-14 12:44:13.060746

## Mus musculus data

**Start**: 2024-01-14 12:44:13.06117


```r
BED:::getNcbiGeneTransPep(
    organism="Mus musculus",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2618965 139.9   10791393 576.4  16861551  900.6
## Vcells 8742363  66.7   75992529 579.8 164014750 1251.4
```

**End**: 2024-01-14 12:49:08.567864

## Rattus norvegicus data

**Start**: 2024-01-14 12:49:08.568286


```r
BED:::getNcbiGeneTransPep(
    organism="Rattus norvegicus",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2618991 139.9    8633115 461.1  16861551  900.6
## Vcells 8742456  66.7   60794024 463.9 164014750 1251.4
```

**End**: 2024-01-14 12:52:37.196582

## Sus scrofa data

**Start**: 2024-01-14 12:52:37.197022


```r
BED:::getNcbiGeneTransPep(
    organism="Sus scrofa",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##           used  (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells 2618939 139.9    8633115 461.1  16861551  900.6
## Vcells 8742419  66.7   38908176 296.9 164014750 1251.4
```

**End**: 2024-01-14 12:54:38.571459

## Direct cross-references with Uniprot

**Start**: 2024-01-14 12:54:38.571967


```r
message("Direct cross-references with Uniprot")
BED:::dumpNcbiDb(
  taxOfInt="",
  reDumpThr=Inf,
  ddir=".",
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

**End**: 2024-01-14 13:26:02.061278


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

**Start**: 2024-01-14 13:26:05.317015


```r
BED:::getUniprot(
    organism="Danio rerio", release=avRel, ddir="."
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  226060423 12073.0  542148864 28953.9  542148864 28953.9
## Vcells 1255117686  9575.8 2413975841 18417.2 2413843464 18416.2
```

**End**: 2024-01-14 13:29:13.713659

## Homo sapiens data

**Start**: 2024-01-14 13:29:13.714174


```r
BED:::getUniprot(
    organism="Homo sapiens", release=avRel, ddir="."
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  226060350 12073.0  542148864 28953.9  542148864 28953.9
## Vcells 1255117615  9575.8 2413975841 18417.2 2413843464 18416.2
```

**End**: 2024-01-14 13:34:04.992427

## Mus musculus data

**Start**: 2024-01-14 13:34:04.993228


```r
BED:::getUniprot(
    organism="Mus musculus", release=avRel, ddir="."
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  226060307 12073.0  542148864 28953.9  542148864 28953.9
## Vcells 1255117594  9575.8 2413975841 18417.2 2413843464 18416.2
```

**End**: 2024-01-14 13:36:43.992773

## Rattus norvegicus data

**Start**: 2024-01-14 13:36:43.993324


```r
BED:::getUniprot(
    organism="Rattus norvegicus", release=avRel, ddir="."
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  226060282 12073.0  542148864 28953.9  542148864 28953.9
## Vcells 1255117603  9575.8 2413975841 18417.2 2413843464 18416.2
```

**End**: 2024-01-14 13:39:14.783914

## Sus scrofa data

**Start**: 2024-01-14 13:39:14.784573


```r
BED:::getUniprot(
    organism="Sus scrofa", release=avRel, ddir="."
)
gc()
```

```
##              used    (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  226060200 12073.0  542148864 28953.9  542148864 28953.9
## Vcells 1255117517  9575.8 2413975841 18417.2 2413843464 18416.2
```

**End**: 2024-01-14 13:53:43.462274

## Indirect cross-references with EntrezGene

**Start**: 2024-01-14 13:53:43.462833


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

**End**: 2024-01-14 14:14:25.28842

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading Clarivate Analytics MetaBase objects from TKCat

**Start**: 2024-01-14 14:14:25.289829


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
## Ncells  226200939 12080.5  542148864 28953.9  542148864 28953.9
## Vcells 1282928352  9788.0 2413975841 18417.2 2413843464 18416.2
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
## Ncells  226193680 12080.1  542148864 28953.9  542148864 28953.9
## Vcells 1282386179  9783.9 2413975841 18417.2 2413843464 18416.2
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
## Ncells  226193681 12080.1  542148864 28953.9  542148864 28953.9
## Vcells 1282386219  9783.9 2413975841 18417.2 2413843464 18416.2
```

**End**: 2024-01-14 14:19:30.118291

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading homologs

## Orthologs from biomaRt

**Start**: 2024-01-14 14:19:30.118892


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

**End**: 2024-01-14 14:23:56.647594

## Orthologs from NCBI

**Start**: 2024-01-14 14:23:56.648806


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
## Ncells  229414415 12252.1  542148864 28953.9  542148864 28953.9
## Vcells 1263917544  9643.0 2413975841 18417.2 2413843464 18416.2
```

**End**: 2024-01-14 14:26:10.311735

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading probes

## Probes from GEO


```r
library(GEOquery)
dir.create("geo", showWarnings=FALSE)
```

### GPL1708: 	Agilent-012391 Whole Human Genome Oligo Microarray G4112A (Feature Number version)

**Start**: 2024-01-14 14:26:10.586352


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

**End**: 2024-01-14 14:26:19.093677

### GPL6480: Agilent-014850 Whole Human Genome Microarray 4x44K G4112F (Probe Name version)

**Start**: 2024-01-14 14:26:19.094476


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

**End**: 2024-01-14 14:26:28.678242

### GPL570: Affymetrix Human Genome U133 Plus 2.0 Array

**Start**: 2024-01-14 14:26:28.679068


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

**End**: 2024-01-14 14:26:45.047439

### GPL571: Affymetrix Human Genome U133A 2.0 Array

**Start**: 2024-01-14 14:26:45.048921


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

**End**: 2024-01-14 14:26:53.111189

### GPL13158: Affymetrix HT HG-U133+ PM Array Plate

**Start**: 2024-01-14 14:26:53.112198


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

**End**: 2024-01-14 14:27:06.255659

### GPL96: Affymetrix Human Genome U133A Array

**Start**: 2024-01-14 14:27:06.256824


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

**End**: 2024-01-14 14:27:15.260589

### GPL1261: Affymetrix Mouse Genome 430 2.0 Array

**Start**: 2024-01-14 14:27:15.26153


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

**End**: 2024-01-14 14:27:30.303245

### GPL1355: Affymetrix Rat Genome 230 2.0 Array

**Start**: 2024-01-14 14:27:30.304478


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

**End**: 2024-01-14 14:27:42.796712

### GPL10558: Illumina HumanHT-12 V4.0 expression beadchip

**Start**: 2024-01-14 14:27:42.79785


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

**End**: 2024-01-14 14:28:00.285635

### GPL6947: Illumina HumanHT-12 V3.0 expression beadchip

**Start**: 2024-01-14 14:28:00.286885


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

**End**: 2024-01-14 14:28:12.228395

### GPL6885: Illumina MouseRef-8 v2.0 expression beadchip

**Start**: 2024-01-14 14:28:12.229644


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

**End**: 2024-01-14 14:28:20.738121

### GPL6887: Illumina MouseWG-6 v2.0 expression beadchip

**Start**: 2024-01-14 14:28:20.739532


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

**End**: 2024-01-14 14:28:33.174355

### GPL6101: Illumina ratRef-12 v1.0 expression beadchip

**Start**: 2024-01-14 14:28:33.175525


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

**End**: 2024-01-14 14:28:39.874118

## Probes from biomaRt


**Start**: 2024-01-14 14:28:39.875085


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

**End**: 2024-01-14 15:22:02.818444

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

**Start**: 2024-01-14 15:22:03.355202


```r
BED:::loadLuceneIndexes()
```

**End**: 2024-01-14 15:22:03.590014


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
##  [1] GEOquery_2.70.0     Biobase_2.62.0      BiocGenerics_0.48.1
##  [4] biomaRt_2.58.0      TKCat_1.1.3         DBI_1.2.0          
##  [7] ReDaMoR_0.7.2       magrittr_2.0.3      dplyr_1.1.4        
## [10] BED_1.5.0           visNetwork_2.1.2    neo2R_2.4.2        
## [13] knitr_1.45         
## 
## loaded via a namespace (and not attached):
##   [1] rstudioapi_0.15.0       jsonlite_1.8.8          rmarkdown_2.25         
##   [4] zlibbioc_1.48.0         vctrs_0.6.5             memoise_2.0.1          
##   [7] RCurl_1.98-1.13         askpass_1.2.0           base64enc_0.1-3        
##  [10] htmltools_0.5.7         progress_1.2.3          curl_5.2.0             
##  [13] sass_0.4.8              parallelly_1.36.0       bslib_0.6.1            
##  [16] htmlwidgets_1.6.4       cachem_1.0.8            uuid_1.1-1             
##  [19] ClickHouseHTTP_0.3.2    mime_0.12               lifecycle_1.0.4        
##  [22] pkgconfig_2.0.3         colourpicker_1.3.0      Matrix_1.6-5           
##  [25] R6_2.5.1                fastmap_1.1.1           GenomeInfoDbData_1.2.11
##  [28] future_1.33.1           shiny_1.8.0             digest_0.6.34          
##  [31] AzureAuth_1.3.3         AnnotationDbi_1.64.1    S4Vectors_0.40.2       
##  [34] RSQLite_2.3.4           filelock_1.0.3          fansi_1.0.6            
##  [37] httr_1.4.7              compiler_4.3.0          bit64_4.0.5            
##  [40] withr_2.5.2             R.utils_2.12.3          openssl_2.1.1          
##  [43] rappdirs_0.3.3          tools_4.3.0             httpuv_1.6.13          
##  [46] jsonvalidate_1.3.2      R.oo_1.25.0             glue_1.7.0             
##  [49] promises_1.2.1          grid_4.3.0              getPass_0.2-4          
##  [52] generics_0.1.3          tzdb_0.4.0              R.methodsS3_1.8.2      
##  [55] tidyr_1.3.0             data.table_1.14.10      hms_1.1.3              
##  [58] xml2_1.3.6              utf8_1.2.4              XVector_0.42.0         
##  [61] pillar_1.9.0            markdown_1.12           stringr_1.5.1          
##  [64] limma_3.58.1            later_1.3.2             rintrojs_0.3.4         
##  [67] BiocFileCache_2.10.1    lattice_0.22-5          bit_4.0.5              
##  [70] tidyselect_1.2.0        jose_1.2.0              Biostrings_2.70.1      
##  [73] miniUI_0.1.1.1          V8_4.4.1                IRanges_2.36.0         
##  [76] stats4_4.3.0            xfun_0.41               shinydashboard_0.7.2   
##  [79] statmod_1.5.0           DT_0.31                 stringi_1.8.3          
##  [82] yaml_2.3.8              evaluate_0.23           codetools_0.2-19       
##  [85] tibble_3.2.1            cli_3.6.2               arrow_14.0.0.2         
##  [88] xtable_1.8-4            jquerylib_0.1.4         roxygen2_7.3.0         
##  [91] Rcpp_1.0.12             GenomeInfoDb_1.38.5     globals_0.16.2         
##  [94] dbplyr_2.4.0            png_0.1-8               XML_3.99-0.16          
##  [97] parallel_4.3.0          ellipsis_0.3.2          readr_2.1.5            
## [100] assertthat_0.2.1        blob_1.2.4              prettyunits_1.2.0      
## [103] bitops_1.0-7            listenv_0.9.0           purrr_1.0.2            
## [106] crayon_1.5.2            rlang_1.1.3             KEGGREST_1.42.0        
## [109] shinyjs_2.1.0
```
