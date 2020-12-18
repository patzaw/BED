---
title: "Biological Entity Dictionary (BED): Feeding the DB"
author: "Patrice Godard"
date: "December 18 2020"
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
if("metabaser" %in% rownames(installed.packages())){
   source("helpers/loadMBObjects.R")
}else{
   stop("The Clarivate analytics metabaser package is not installed.")
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
ensembl_release <- "102"
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
    gv="38",                        # genome version
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
    gv="6",                         # genome version
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
reDumpThr <- as.difftime(200, units="days")
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
## [1] "2020.12.18"
```

```r
BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
```

## Load Data model

**Start**: 2020-12-18 15:57:03


```r
BED:::loadBedModel()
```

**End**: 2020-12-18 15:57:10

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading taxonomy from NCBI

Information is downloaded if older than 200 days
according to the `reDumpThr` object.

**Start**: 2020-12-18 15:57:10


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

**End**: 2020-12-18 15:57:25

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
## [1] "102"
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

**Start**: 2020-12-18 15:57:26


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
##           used (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells  894985 47.8    5056102 270.1  6320127 337.6
## Vcells 5785557 44.2   45420935 346.6 56770622 433.2
```

**End**: 2020-12-18 16:00:19

### Transcripts

**Start**: 2020-12-18 16:00:19


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
##           used (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells  898309 48.0    4044882 216.1  6320127 337.6
## Vcells 5792842 44.2   43668098 333.2 56770622 433.2
```

**End**: 2020-12-18 16:02:56

### Peptides

**Start**: 2020-12-18 16:02:56


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
##           used (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells  901301 48.2    3915087 209.1  6320127 337.6
## Vcells 5799483 44.3   41985374 320.4 56770622 433.2
```

**End**: 2020-12-18 16:05:35

## Homo sapiens


```r
ensembl <- ensembl_Hsapiens
print(ensembl)
```

```
## $release
## [1] "102"
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

**Start**: 2020-12-18 16:05:35


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  903338 48.3   14486628 773.7  18108285  967.1
## Vcells 9997420 76.3  121632911 928.0 152032980 1160.0
```

**End**: 2020-12-18 16:09:29

### Transcripts

**Start**: 2020-12-18 16:09:29


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901221 48.2   11589303 619.0  18108285  967.1
## Vcells 9993912 76.3  116831595 891.4 152032980 1160.0
```

**End**: 2020-12-18 16:15:04

### Peptides

**Start**: 2020-12-18 16:15:04


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901589 48.2    9271443 495.2  18108285  967.1
## Vcells 9994587 76.3  112222332 856.2 152032980 1160.0
```

**End**: 2020-12-18 16:21:16

## Mus musculus


```r
ensembl <- ensembl_Mmusculus
print(ensembl)
```

```
## $release
## [1] "102"
## 
## $organism
## [1] "Mus musculus"
## 
## $gv
## [1] "38"
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

**Start**: 2020-12-18 16:21:16


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  902069 48.2    7417155 396.2  18108285  967.1
## Vcells 9995630 76.3  107797439 822.5 152032980 1160.0
```

**End**: 2020-12-18 16:24:36

### Transcripts

**Start**: 2020-12-18 16:24:36


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901500 48.2    7272692 388.5  18108285  967.1
## Vcells 9994702 76.3   86237952 658.0 152032980 1160.0
```

**End**: 2020-12-18 16:29:57

### Peptides

**Start**: 2020-12-18 16:29:57


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901502 48.2    7013784 374.6  18108285  967.1
## Vcells 9994767 76.3   82852434 632.2 152032980 1160.0
```

**End**: 2020-12-18 16:34:08

## Rattus norvegicus


```r
ensembl <- ensembl_Rnorvegicus
print(ensembl)
```

```
## $release
## [1] "102"
## 
## $organism
## [1] "Rattus norvegicus"
## 
## $gv
## [1] "6"
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

**Start**: 2020-12-18 16:34:08


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901727 48.2    5611028 299.7  18108285  967.1
## Vcells 9995386 76.3   66281948 505.7 152032980 1160.0
```

**End**: 2020-12-18 16:35:43

### Transcripts

**Start**: 2020-12-18 16:35:43


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901392 48.2    4568522 244.0  18108285  967.1
## Vcells 9994848 76.3   53025559 404.6 152032980 1160.0
```

**End**: 2020-12-18 16:37:11

### Peptides

**Start**: 2020-12-18 16:37:11


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901550 48.2    3654818 195.2  18108285  967.1
## Vcells 9995173 76.3   42420448 323.7 152032980 1160.0
```

**End**: 2020-12-18 16:38:53

## Sus scrofa


```r
ensembl <- ensembl_Sscrofa
print(ensembl)
```

```
## $release
## [1] "102"
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

**Start**: 2020-12-18 16:38:53


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901361 48.2    4098340 218.9  18108285  967.1
## Vcells 9995096 76.3   40787630 311.2 152032980 1160.0
```

**End**: 2020-12-18 16:39:50

### Transcripts

**Start**: 2020-12-18 16:39:50


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901329 48.2    3730336 199.3  18108285  967.1
## Vcells 9995063 76.3   39220125 299.3 152032980 1160.0
```

**End**: 2020-12-18 16:41:22

### Peptides

**Start**: 2020-12-18 16:41:22


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
##           used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  901319 48.2    3613123 193.0  18108285  967.1
## Vcells 9995108 76.3   37715320 287.8 152032980 1160.0
```

**End**: 2020-12-18 16:43:35

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading data from NCBI

Information is downloaded if older than 200 days
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

**Start**: 2020-12-18 16:43:35


```r
BED:::getNcbiGeneTransPep(
    organism="Danio rerio",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   907831 48.5    2890499 154.4  18108285  967.1
## Vcells 10009023 76.4   37724864 287.9 152032980 1160.0
```

**End**: 2020-12-18 16:47:05

## Homo sapiens data

**Start**: 2020-12-18 16:47:05


```r
BED:::getNcbiGeneTransPep(
    organism="Homo sapiens",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   907911 48.5    4940470 263.9  18108285  967.1
## Vcells 10009200 76.4   52548944 401.0 152032980 1160.0
```

**End**: 2020-12-18 16:53:53

## Mus musculus data

**Start**: 2020-12-18 16:53:53


```r
BED:::getNcbiGeneTransPep(
    organism="Mus musculus",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   908087 48.5    4799665 256.4  18108285  967.1
## Vcells 10009543 76.4   42045417 320.8 152032980 1160.0
```

**End**: 2020-12-18 17:00:10

## Rattus norvegicus data

**Start**: 2020-12-18 17:00:10


```r
BED:::getNcbiGeneTransPep(
    organism="Rattus norvegicus",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   907894 48.5    3839732 205.1  18108285  967.1
## Vcells 10009273 76.4   33636334 256.7 152032980 1160.0
```

**End**: 2020-12-18 17:04:10

## Sus scrofa data

**Start**: 2020-12-18 17:04:10


```r
BED:::getNcbiGeneTransPep(
    organism="Sus scrofa",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   907872 48.5    3071786 164.1  18108285  967.1
## Vcells 10009284 76.4   33636334 256.7 152032980 1160.0
```

**End**: 2020-12-18 17:07:13

## Direct cross-references with Uniprot

**Start**: 2020-12-18 17:07:13


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

**End**: 2020-12-18 17:13:24


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

**Start**: 2020-12-18 17:13:26


```r
BED:::getUniprot(
    organism="Danio rerio", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84315091 4503.0  142949137 7634.4 138920272 7419.2
## Vcells 311452197 2376.2  562836035 4294.1 492868338 3760.3
```

**End**: 2020-12-18 17:16:16

## Homo sapiens data

**Start**: 2020-12-18 17:16:16


```r
BED:::getUniprot(
    organism="Homo sapiens", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84314874 4503.0  142949137 7634.4 142949137 7634.4
## Vcells 311451884 2376.2  562836035 4294.1 492868338 3760.3
```

**End**: 2020-12-18 17:21:09

## Mus musculus data

**Start**: 2020-12-18 17:21:09


```r
BED:::getUniprot(
    organism="Mus musculus", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84315224 4503.0  142949137 7634.4 142949137 7634.4
## Vcells 311452516 2376.2  562836035 4294.1 492868338 3760.3
```

**End**: 2020-12-18 17:23:25

## Rattus norvegicus data

**Start**: 2020-12-18 17:23:25


```r
BED:::getUniprot(
    organism="Rattus norvegicus", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84315079 4503.0  142949137 7634.4 142949137 7634.4
## Vcells 311452325 2376.2  562836035 4294.1 492868338 3760.3
```

**End**: 2020-12-18 17:24:35

## Sus scrofa data

**Start**: 2020-12-18 17:24:35


```r
BED:::getUniprot(
    organism="Sus scrofa", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84314994 4503.0  142949137 7634.4 142949137 7634.4
## Vcells 311452230 2376.2  562836035 4294.1 492868338 3760.3
```

**End**: 2020-12-18 17:28:28

## Indirect cross-references with EntrezGene

**Start**: 2020-12-18 17:28:28


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

**End**: 2020-12-18 17:38:09

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading Clarivate Analytics MetaBase objects

**Start**: 2020-12-18 17:38:09



The following chunk should be adapted to fit MetaBase installation.


```r
library(metabaser)
metabase.connect(
    driver = "jdbc",
    jdbc.url ="jdbc:oracle:thin:@//HOSTURL",
    uid = "USER", pwd = "PASSWORD"
)
```

## Register MetaBase DB


```r
mbInfo <- mbquery("select * from zzz_System")
BED:::registerBEDB(
    name="MetaBase_gene",
    description="Clarivate Analytics MetaBase",
    currentVersion=mbInfo$VERSION,
    idURL='https://portal.genego.com/cgi/entity_page.cgi?term=20&id=%s'
)
BED:::registerBEDB(
    name="MetaBase_object",
    description="Clarivate Analytics MetaBase",
    currentVersion=mbInfo$VERSION,
    idURL='https://portal.genego.com/cgi/entity_page.cgi?term=100&id=%s'
)
```

## Homo sapiens data


```r
loadMBObjects(
    orgOfInt=c("Homo sapiens")
)
```

```
## Metabase connection OK
```

```r
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  85729140 4578.5  142949137 7634.4 142949137 7634.4
## Vcells 371052650 2831.0  562836035 4294.1 554862818 4233.3
```

## Mus musculus data


```r
loadMBObjects(
    orgOfInt=c("Mus musculus")
)
```

```
## Metabase connection OK
```

```r
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  85728232 4578.4  142949137 7634.4 142949137 7634.4
## Vcells 371051173 2830.9  562836035 4294.1 554862818 4233.3
```

## Rattus norvegicus data


```r
loadMBObjects(
    orgOfInt=c("Rattus norvegicus")
)
```

```
## Metabase connection OK
```

```r
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  85728233 4578.4  142949137 7634.4 142949137 7634.4
## Vcells 371051213 2830.9  562836035 4294.1 554862818 4233.3
```

**End**: 2020-12-18 17:41:31

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading homologs

## Orthologs from biomaRt

**Start**: 2020-12-18 17:41:31


```r
library(biomaRt)
loadBmHomologs <- function(org1, org2, version){

    #########################################
    ## The mart
    bm <- "ENSEMBL_MART_ENSEMBL"
    marts <-listMarts()
    if(
        grep(
            sprintf(" %s$", version),
            marts[which(marts$biomart==bm), "version"]
        )==1
    ){
        version <- NULL
    }
    mart <- useEnsembl(
        biomart=bm,
        dataset=paste0(org1, "_gene_ensembl"),
        version=version
    )
    #mattr <- listAttributes(mart)
    
    toImport <- getBM(
        mart=mart,
        attributes=c(
            "ensembl_gene_id",
            paste0(org2, "_homolog_ensembl_gene")
        )
    )
    colnames(toImport) <- c("id1", "id2")
    toImport <- unique(toImport[
        which(toImport$id1 != "" & toImport$id2 != ""),
    ])
    
    BED:::loadIsHomologOf(
        d=toImport,
        db1="Ens_gene", db2="Ens_gene",
        be="Gene"
    )

}

#########################################
orgOfInt <- c("hsapiens", "mmusculus", "rnorvegicus", "sscrofa", "drerio")
for(i in 1:(length(orgOfInt)-1)){
  for(j in (i+1):length(orgOfInt)){
    loadBmHomologs(
      org1=orgOfInt[i],
      org2=orgOfInt[j],
      version=ensembl_release
    )
  }
}
```

**End**: 2020-12-18 17:48:19

## Orthologs from NCBI

**Start**: 2020-12-18 17:48:19


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
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  87385995 4667.0  142949137 7634.4 142949137 7634.4
## Vcells 375047915 2861.4  562836035 4294.1 554862818 4233.3
```

**End**: 2020-12-18 17:49:37

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading probes

## Probes from GEO


```r
library(GEOquery)
dir.create("geo", showWarnings=FALSE)
```

### GPL1708: 	Agilent-012391 Whole Human Genome Oligo Microarray G4112A (Feature Number version)

**Start**: 2020-12-18 17:49:37


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

**End**: 2020-12-18 17:49:45

### GPL6480: Agilent-014850 Whole Human Genome Microarray 4x44K G4112F (Probe Name version)

**Start**: 2020-12-18 17:49:45


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

**End**: 2020-12-18 17:49:54

### GPL570: Affymetrix Human Genome U133 Plus 2.0 Array

**Start**: 2020-12-18 17:49:54


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

**End**: 2020-12-18 17:50:10

### GPL571: Affymetrix Human Genome U133A 2.0 Array

**Start**: 2020-12-18 17:50:10


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

**End**: 2020-12-18 17:50:18

### GPL13158: Affymetrix HT HG-U133+ PM Array Plate

**Start**: 2020-12-18 17:50:18


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

**End**: 2020-12-18 17:50:30

### GPL96: Affymetrix Human Genome U133A Array

**Start**: 2020-12-18 17:50:30


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

**End**: 2020-12-18 17:50:38

### GPL1261: Affymetrix Mouse Genome 430 2.0 Array

**Start**: 2020-12-18 17:50:38


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

**End**: 2020-12-18 17:50:49

### GPL1355: Affymetrix Rat Genome 230 2.0 Array

**Start**: 2020-12-18 17:50:49


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

**End**: 2020-12-18 17:50:57

### GPL10558: Illumina HumanHT-12 V4.0 expression beadchip

**Start**: 2020-12-18 17:50:57


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

**End**: 2020-12-18 17:51:14

### GPL6947: Illumina HumanHT-12 V3.0 expression beadchip

**Start**: 2020-12-18 17:51:14


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

**End**: 2020-12-18 17:51:25

### GPL6885: Illumina MouseRef-8 v2.0 expression beadchip

**Start**: 2020-12-18 17:51:25


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

**End**: 2020-12-18 17:51:32

### GPL6887: Illumina MouseWG-6 v2.0 expression beadchip

**Start**: 2020-12-18 17:51:32


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

**End**: 2020-12-18 17:51:48

### GPL6101: Illumina ratRef-12 v1.0 expression beadchip

**Start**: 2020-12-18 17:51:48


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

**End**: 2020-12-18 17:51:54

<!-- ## Probes from biomaRt -->

<!-- ```{r biomartProbes, message=FALSE} -->
<!-- library(biomaRt) -->
<!-- loadBmProbes <- function(dataset, platName, trDb, version){ -->

<!--     ######################################### -->
<!--     ## The platform -->
<!--     bm <- "ENSEMBL_MART_ENSEMBL" -->
<!--     marts <-listMarts() -->
<!--     if( -->
<!--         grep( -->
<!--             sprintf(" %s$", version), -->
<!--             marts[which(marts$biomart==bm), "version"] -->
<!--         )==1 -->
<!--     ){ -->
<!--         version <- NULL -->
<!--     } -->
<!--     mart <- useEnsembl(biomart=bm, dataset=dataset, version=version) -->
<!--     mattr <- listAttributes(mart) -->

<!--     ######################################### -->
<!--     ## The platform -->
<!--     message("Loading the platform") -->
<!--     description <- mattr[which(mattr$name==platName),"description"] -->
<!--     BED:::loadPlf(name=platName, description=description, be="Transcript") -->

<!--     ######################################### -->
<!--     ## The probes -->
<!--     message("Getting the biomaRt data") -->
<!--     toImport <- getBM( -->
<!--         mart=mart, attributes=c("ensembl_transcript_id", platName) -->
<!--     ) -->
<!--     toImport <- unique(toImport[which(toImport[,platName]!=""),]) -->
<!--     colnames(toImport) <- c("id", "probeID") -->
<!--     message("Loading the probes") -->
<!--     BED:::loadProbes( -->
<!--         d=toImport, -->
<!--         be="Transcript", -->
<!--         platform=platName, -->
<!--         dbname=trDb -->
<!--     ) -->

<!-- } -->
<!-- ``` -->

<!-- ### Human platforms -->

<!-- **Start**: 2020-12-18 17:51:54 -->

<!-- ```{r illumina_humanht_12_v4, message=FALSE} -->
<!-- message(Sys.time()) -->
<!-- loadBmProbes( -->
<!--     dataset="hsapiens_gene_ensembl", -->
<!--     platName="illumina_humanht_12_v4", -->
<!--     trDb="Ens_transcript", -->
<!--     version=ensembl_release -->
<!-- ) -->
<!-- ``` -->

<!-- ```{r affy_hg_u133_plus_2, message=FALSE} -->
<!-- message(Sys.time()) -->
<!-- loadBmProbes( -->
<!--     dataset="hsapiens_gene_ensembl", -->
<!--     platName="affy_hg_u133_plus_2", -->
<!--     trDb="Ens_transcript", -->
<!--     version=ensembl_release -->
<!-- ) -->
<!-- ``` -->

<!-- **End**: 2020-12-18 17:51:54 -->

<!-- ### Mouse platforms -->

<!-- **Start**: 2020-12-18 17:51:54 -->

<!-- ```{r illumina_mouseref_8_v2, message=FALSE} -->
<!-- message(Sys.time()) -->
<!-- loadBmProbes( -->
<!--     dataset="mmusculus_gene_ensembl", -->
<!--     platName="illumina_mouseref_8_v2", -->
<!--     trDb="Ens_transcript", -->
<!--     version=ensembl_release -->
<!-- ) -->
<!-- ``` -->

<!-- ```{r affy_mouse430_2, message=FALSE} -->
<!-- message(Sys.time()) -->
<!-- loadBmProbes( -->
<!--     dataset="mmusculus_gene_ensembl", -->
<!--     platName="affy_mouse430_2", -->
<!--     trDb="Ens_transcript", -->
<!--     version=ensembl_release -->
<!-- ) -->
<!-- ``` -->

<!-- **End**: 2020-12-18 17:51:54 -->

<!-- ### Rat platforms -->

<!-- **Start**: 2020-12-18 17:51:54 -->

<!-- ```{r illumina_ratref_12_v1, message=FALSE} -->
<!-- message(Sys.time()) -->
<!-- loadBmProbes( -->
<!--     dataset="rnorvegicus_gene_ensembl", -->
<!--     platName="illumina_ratref_12_v1", -->
<!--     trDb="Ens_transcript", -->
<!--     version=ensembl_release -->
<!-- ) -->
<!-- ``` -->

<!-- ```{r affy_rat230_2, message=FALSE} -->
<!-- message(Sys.time()) -->
<!-- loadBmProbes( -->
<!--     dataset="rnorvegicus_gene_ensembl", -->
<!--     platName="affy_rat230_2", -->
<!--     trDb="Ens_transcript", -->
<!--     version=ensembl_release -->
<!-- ) -->
<!-- ``` -->

<!-- **End**: 2020-12-18 17:51:54 -->

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

**Start**: 2020-12-18 17:51:55


```r
BED:::loadLuceneIndexes()
```

**End**: 2020-12-18 17:51:56


<!----------------------------------------------------------------->
<!----------------------------------------------------------------->
# Session info


```
## R version 4.0.2 (2020-06-22)
## Platform: x86_64-pc-linux-gnu (64-bit)
## Running under: Red Hat Enterprise Linux
## 
## Matrix products: default
## BLAS/LAPACK: /usr/lib64/libopenblasp-r0.3.3.so
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8          LC_NUMERIC=C                 
##  [3] LC_TIME=en_US.UTF-8           LC_COLLATE=en_US.UTF-8       
##  [5] LC_MONETARY=en_US.UTF-8       LC_MESSAGES=en_US.UTF-8      
##  [7] LC_PAPER=en_US.UTF-8          LC_NAME=en_US.UTF-8          
##  [9] LC_ADDRESS=en_US.UTF-8        LC_TELEPHONE=en_US.UTF-8     
## [11] LC_MEASUREMENT=en_US.UTF-8    LC_IDENTIFICATION=en_US.UTF-8
## 
## attached base packages:
## [1] parallel  stats     graphics  grDevices utils     datasets  methods  
## [8] base     
## 
## other attached packages:
##  [1] GEOquery_2.58.0     Biobase_2.50.0      BiocGenerics_0.36.0
##  [4] biomaRt_2.46.0      metabaser_4.7.1     igraph_1.2.6       
##  [7] BED_1.4.3           visNetwork_2.0.9    neo2R_2.1.0        
## [10] knitr_1.30         
## 
## loaded via a namespace (and not attached):
##  [1] Rcpp_1.0.5           tidyr_1.1.2          prettyunits_1.1.1   
##  [4] png_0.1-7            assertthat_0.2.1     digest_0.6.27       
##  [7] BiocFileCache_1.14.0 mime_0.9             R6_2.5.0            
## [10] plyr_1.8.6           stats4_4.0.2         RSQLite_2.2.1       
## [13] evaluate_0.14        httr_1.4.2           pillar_1.4.7        
## [16] rlang_0.4.8          progress_1.2.2       curl_4.3            
## [19] data.table_1.13.2    miniUI_0.1.1.1       blob_1.2.1          
## [22] S4Vectors_0.28.0     DT_0.16              rmarkdown_2.5       
## [25] readr_1.4.0          stringr_1.4.0        htmlwidgets_1.5.2   
## [28] RCurl_1.98-1.2       bit_4.0.4            shiny_1.5.0         
## [31] compiler_4.0.2       httpuv_1.5.4         xfun_0.19           
## [34] askpass_1.1          pkgconfig_2.0.3      base64enc_0.1-3     
## [37] htmltools_0.5.0      openssl_1.4.3        tidyselect_1.1.0    
## [40] tibble_3.0.4         IRanges_2.24.0       XML_3.99-0.5        
## [43] withr_2.3.0          dbplyr_2.0.0         crayon_1.3.4        
## [46] dplyr_1.0.2          later_1.1.0.1        rappdirs_0.3.1      
## [49] bitops_1.0-6         jsonlite_1.7.1       xtable_1.8-4        
## [52] lifecycle_0.2.0      DBI_1.1.0            magrittr_2.0.1      
## [55] RJDBC_0.2-8          stringi_1.5.3        promises_1.1.1      
## [58] limma_3.46.0         xml2_1.3.2           ellipsis_0.3.1      
## [61] generics_0.1.0       vctrs_0.3.5          tools_4.0.2         
## [64] bit64_4.0.5          glue_1.4.2           purrr_0.3.4         
## [67] hms_0.5.3            fastmap_1.0.1        yaml_2.2.1          
## [70] AnnotationDbi_1.52.0 memoise_1.1.0        rJava_0.9-13
```
