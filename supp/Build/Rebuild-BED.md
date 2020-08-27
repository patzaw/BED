---
title: "Biological Entity Dictionary (BED): Feeding the DB"
author: "Patrice Godard"
date: "August 27 2020"
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
ensembl_release <- "101"
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
reDumpThr <- as.difftime(2, units="days")
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
## [1] "2020.08.27"
```

```r
BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
```

## Load Data model

**Start**: 2020-08-27 12:08:01


```r
BED:::loadBedModel()
```

**End**: 2020-08-27 12:08:06

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading taxonomy from NCBI

Information is downloaded if older than 2 days
according to the `reDumpThr` object.

**Start**: 2020-08-27 12:08:06


```r
BED:::loadNcbiTax(
    reDumpThr=reDumpThr,
    orgOfInt=c(
       "Homo sapiens", "Rattus norvegicus", "Mus musculus",
       "Sus scrofa", "Danio rerio"
      ),
    curDate=curDate
)
```

**End**: 2020-08-27 12:08:22

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
## [1] "101"
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

**Start**: 2020-08-27 12:08:22


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells  908537 48.6    4752441 253.9  5940551 317.3
## Vcells 3717586 28.4   39940320 304.8 51903427 396.0
```

**End**: 2020-08-27 12:11:05

### Transcripts

**Start**: 2020-08-27 12:11:05


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells  914570 48.9    4697096 250.9  5940551 317.3
## Vcells 3730552 28.5   46152048 352.2 57674486 440.1
```

**End**: 2020-08-27 12:13:43

### Peptides

**Start**: 2020-08-27 12:13:43


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##           used (Mb) gc trigger  (Mb) max used  (Mb)
## Ncells  919982 49.2    3757677 200.7  5940551 317.3
## Vcells 3742188 28.6   44369966 338.6 57674486 440.1
```

**End**: 2020-08-27 12:16:17

## Homo sapiens


```r
ensembl <- ensembl_Hsapiens
print(ensembl)
```

```
## $release
## [1] "101"
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

**Start**: 2020-08-27 12:16:17


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   920214 49.2   14091326 752.6  17614157  940.7
## Vcells 10034279 76.6  116518449 889.0 145639730 1111.2
```

**End**: 2020-08-27 12:20:15

### Transcripts

**Start**: 2020-08-27 12:20:15


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells   920566 49.2   12110329  646.8  17614157  940.7
## Vcells 10034876 76.6  134370052 1025.2 167952474 1281.4
```

**End**: 2020-08-27 12:25:51

### Peptides

**Start**: 2020-08-27 12:25:51


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   922284 49.3    9688264 517.5  17614157  940.7
## Vcells 10037800 76.6  129059250 984.7 167952474 1281.4
```

**End**: 2020-08-27 12:32:00

## Mus musculus


```r
ensembl <- ensembl_Mmusculus
print(ensembl)
```

```
## $release
## [1] "101"
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

**Start**: 2020-08-27 12:32:00


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   920508 49.2    7750612 414.0  17614157  940.7
## Vcells 10035090 76.6  103247400 787.8 167952474 1281.4
```

**End**: 2020-08-27 12:35:19

### Transcripts

**Start**: 2020-08-27 12:35:19


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   921037 49.2    7472588 399.1  17614157  940.7
## Vcells 10035982 76.6   99181504 756.7 167952474 1281.4
```

**End**: 2020-08-27 12:40:29

### Peptides

**Start**: 2020-08-27 12:40:29


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   920145 49.2    5978071 319.3  17614157  940.7
## Vcells 10034556 76.6   79345204 605.4 167952474 1281.4
```

**End**: 2020-08-27 12:44:40

## Rattus norvegicus


```r
ensembl <- ensembl_Rnorvegicus
print(ensembl)
```

```
## $release
## [1] "101"
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

**Start**: 2020-08-27 12:44:40


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   920658 49.2    4782457 255.5  17614157  940.7
## Vcells 10035662 76.6   63476164 484.3 167952474 1281.4
```

**End**: 2020-08-27 12:46:15

### Transcripts

**Start**: 2020-08-27 12:46:15


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   920656 49.2    4141295 221.2  17614157  940.7
## Vcells 10035669 76.6   50780932 387.5 167952474 1281.4
```

**End**: 2020-08-27 12:47:44

### Peptides

**Start**: 2020-08-27 12:47:44


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger (Mb)  max used   (Mb)
## Ncells   920481 49.2    3313036  177  17614157  940.7
## Vcells 10035438 76.6   40624746  310 167952474 1281.4
```

**End**: 2020-08-27 12:49:29

## Sus scrofa


```r
ensembl <- ensembl_Sscrofa
print(ensembl)
```

```
## $release
## [1] "101"
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

**Start**: 2020-08-27 12:49:29


```r
BED:::getEnsemblGeneIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$gdbCref,
    dbAss=ensembl$gdbAss,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   920232 49.2    6474882 345.8  17614157  940.7
## Vcells 10035267 76.6   46940508 358.2 167952474 1281.4
```

**End**: 2020-08-27 12:50:23

### Transcripts

**Start**: 2020-08-27 12:50:23


```r
BED:::getEnsemblTranscriptIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$tdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   920263 49.2    5179906 276.7  17614157  940.7
## Vcells 10035329 76.6   37552407 286.6 167952474 1281.4
```

**End**: 2020-08-27 12:51:44

### Peptides

**Start**: 2020-08-27 12:51:44


```r
BED:::getEnsemblPeptideIds(
    organism=ensembl$organism,
    release=ensembl$release,
    gv=ensembl$gv,
    dbCref=ensembl$pdbCref,
    canChromosomes=ensembl$canChromosomes
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   920232 49.2    4143925 221.4  17614157  940.7
## Vcells 10035338 76.6   43401172 331.2 167952474 1281.4
```

**End**: 2020-08-27 12:53:42

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading data from NCBI

Information is downloaded if older than 2 days
according to the `reDumpThr` object.

## Register NCBI DBs


```r
BED:::dumpNcbiDb(taxOfInt = c(), reDumpThr=reDumpThr, toLoad=c(), curDate=curDate)
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

**Start**: 2020-08-27 12:53:43


```r
BED:::getNcbiGeneTransPep(
    organism="Danio rerio", curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   933508 49.9    3315140 177.1  17614157  940.7
## Vcells 10062712 76.8   34722267 265.0 167952474 1281.4
```

**End**: 2020-08-27 12:57:01

## Homo sapiens data

**Start**: 2020-08-27 12:57:01


```r
BED:::getNcbiGeneTransPep(
    organism="Homo sapiens", curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   933435 49.9    3900365 208.4  17614157  940.7
## Vcells 10062637 76.8   50842544 387.9 167952474 1281.4
```

**End**: 2020-08-27 13:03:40

## Mus musculus data

**Start**: 2020-08-27 13:03:40


```r
BED:::getNcbiGeneTransPep(
    organism="Mus musculus", curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   933557 49.9    4563620 243.8  17614157  940.7
## Vcells 10062887 76.8   40679558 310.4 167952474 1281.4
```

**End**: 2020-08-27 13:09:38

## Rattus norvegicus data

**Start**: 2020-08-27 13:09:38


```r
BED:::getNcbiGeneTransPep(
    organism="Rattus norvegicus", curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   933199 49.9    3650896 195.0  17614157  940.7
## Vcells 10062339 76.8   32549188 248.4 167952474 1281.4
```

**End**: 2020-08-27 13:13:21

## Sus scrofa data

**Start**: 2020-08-27 13:13:21


```r
BED:::getNcbiGeneTransPep(
    organism="Sus scrofa", curDate=curDate
)
gc()
```

```
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells   933345 49.9    2920717 156.0  17614157  940.7
## Vcells 10062628 76.8   32549188 248.4 167952474 1281.4
```

**End**: 2020-08-27 13:16:22

## Direct cross-references with Uniprot

**Start**: 2020-08-27 13:16:22


```r
message("Direct cross-references with Uniprot")
BED:::dumpNcbiDb(
  taxOfInt="",
  reDumpThr=Inf,
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

**End**: 2020-08-27 13:21:45


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

**Start**: 2020-08-27 13:21:47


```r
BED:::getUniprot(
    organism="Danio rerio", release=avRel
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84345712 4504.6  143019118 7638.1 136625302 7296.6
## Vcells 311515058 2376.7  562931118 4294.9 475764224 3629.8
```

**End**: 2020-08-27 13:24:37

## Homo sapiens data

**Start**: 2020-08-27 13:24:37


```r
BED:::getUniprot(
    organism="Homo sapiens", release=avRel
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84345495 4504.6  143019118 7638.1 143019118 7638.1
## Vcells 311514743 2376.7  562931118 4294.9 475764224 3629.8
```

**End**: 2020-08-27 13:28:54

## Mus musculus data

**Start**: 2020-08-27 13:28:54


```r
BED:::getUniprot(
    organism="Mus musculus", release=avRel
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84345797 4504.6  143019118 7638.1 143019118 7638.1
## Vcells 311515294 2376.7  562931118 4294.9 475764224 3629.8
```

**End**: 2020-08-27 13:31:01

## Rattus norvegicus data

**Start**: 2020-08-27 13:31:01


```r
BED:::getUniprot(
    organism="Rattus norvegicus", release=avRel
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84345700 4504.6  143019118 7638.1 143019118 7638.1
## Vcells 311515190 2376.7  562931118 4294.9 475764224 3629.8
```

**End**: 2020-08-27 13:32:02

## Sus scrofa data

**Start**: 2020-08-27 13:32:02


```r
BED:::getUniprot(
    organism="Sus scrofa", release=avRel
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  84345615 4504.6  143019118 7638.1 143019118 7638.1
## Vcells 311515086 2376.7  562931118 4294.9 475764224 3629.8
```

**End**: 2020-08-27 13:35:46

## Indirect cross-references with EntrezGene

**Start**: 2020-08-27 13:35:46


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

**End**: 2020-08-27 13:44:14

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading Clarivate Analytics MetaBase objects

**Start**: 2020-08-27 13:44:14



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
## Ncells  85772249 4580.8  143019118 7638.1 143019118 7638.1
## Vcells 370167555 2824.2  562931118 4294.9 556261927 4244.0
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
## Ncells  85771488 4580.7  143019118 7638.1 143019118 7638.1
## Vcells 370166323 2824.2  562931118 4294.9 556261927 4244.0
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
## Ncells  85771489 4580.7  143019118 7638.1 143019118 7638.1
## Vcells 370166363 2824.2  562931118 4294.9 556261927 4244.0
```

**End**: 2020-08-27 13:48:51

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading homologs

## Orthologs from biomaRt

**Start**: 2020-08-27 13:48:51


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

**End**: 2020-08-27 13:58:34

## Orthologs from NCBI

**Start**: 2020-08-27 13:58:34


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
## Ncells  87442599 4670.0  143019118 7638.1 143019118 7638.1
## Vcells 374195146 2854.9  562931118 4294.9 556261927 4244.0
```

**End**: 2020-08-27 13:59:56

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading probes

## Probes from GEO


```r
library(GEOquery)
dir.create("geo", showWarnings=FALSE)
```

### GPL1708: 	Agilent-012391 Whole Human Genome Oligo Microarray G4112A (Feature Number version)

**Start**: 2020-08-27 13:59:56


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

**End**: 2020-08-27 14:00:28

### GPL6480: Agilent-014850 Whole Human Genome Microarray 4x44K G4112F (Probe Name version)

**Start**: 2020-08-27 14:00:28


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

**End**: 2020-08-27 14:00:57

### GPL570: Affymetrix Human Genome U133 Plus 2.0 Array

**Start**: 2020-08-27 14:00:57


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

**End**: 2020-08-27 14:01:59

### GPL571: Affymetrix Human Genome U133A 2.0 Array

**Start**: 2020-08-27 14:01:59


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

**End**: 2020-08-27 14:02:18

### GPL13158: Affymetrix HT HG-U133+ PM Array Plate

**Start**: 2020-08-27 14:02:18


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

**End**: 2020-08-27 14:03:00

### GPL96: Affymetrix Human Genome U133A Array

**Start**: 2020-08-27 14:03:00


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

**End**: 2020-08-27 14:03:50

### GPL1261: Affymetrix Mouse Genome 430 2.0 Array

**Start**: 2020-08-27 14:03:50


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

**End**: 2020-08-27 14:04:59

### GPL1355: Affymetrix Rat Genome 230 2.0 Array

**Start**: 2020-08-27 14:04:59


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

**End**: 2020-08-27 14:06:01

### GPL10558: Illumina HumanHT-12 V4.0 expression beadchip

**Start**: 2020-08-27 14:06:01


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

**End**: 2020-08-27 14:07:17

### GPL6947: Illumina HumanHT-12 V3.0 expression beadchip

**Start**: 2020-08-27 14:07:17


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

**End**: 2020-08-27 14:07:55

### GPL6885: Illumina MouseRef-8 v2.0 expression beadchip

**Start**: 2020-08-27 14:07:55


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

**End**: 2020-08-27 14:08:10

### GPL6887: Illumina MouseWG-6 v2.0 expression beadchip

**Start**: 2020-08-27 14:08:10


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

**End**: 2020-08-27 14:09:40

### GPL6101: Illumina ratRef-12 v1.0 expression beadchip

**Start**: 2020-08-27 14:09:40


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

**End**: 2020-08-27 14:09:52

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

<!-- **Start**: 2020-08-27 14:09:52 -->

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

<!-- **End**: 2020-08-27 14:09:52 -->

<!-- ### Mouse platforms -->

<!-- **Start**: 2020-08-27 14:09:52 -->

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

<!-- **End**: 2020-08-27 14:09:52 -->

<!-- ### Rat platforms -->

<!-- **Start**: 2020-08-27 14:09:52 -->

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

<!-- **End**: 2020-08-27 14:09:52 -->

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

**Start**: 2020-08-27 14:09:52


```r
BED:::loadLuceneIndexes()
```

**End**: 2020-08-27 14:09:53


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
##  [1] GEOquery_2.56.0     Biobase_2.48.0      BiocGenerics_0.34.0
##  [4] biomaRt_2.44.1      metabaser_4.7.0     igraph_1.2.5       
##  [7] BED_1.4.2           visNetwork_2.0.9    neo2R_2.1.0        
## [10] knitr_1.29         
## 
## loaded via a namespace (and not attached):
##  [1] Rcpp_1.0.5           tidyr_1.1.0          prettyunits_1.1.1   
##  [4] png_0.1-7            assertthat_0.2.1     digest_0.6.25       
##  [7] BiocFileCache_1.12.0 mime_0.9             R6_2.4.1            
## [10] plyr_1.8.6           stats4_4.0.2         RSQLite_2.2.0       
## [13] evaluate_0.14        httr_1.4.2           pillar_1.4.6        
## [16] rlang_0.4.7          progress_1.2.2       curl_4.3            
## [19] data.table_1.13.0    miniUI_0.1.1.1       blob_1.2.1          
## [22] S4Vectors_0.26.1     DT_0.14              rmarkdown_2.3       
## [25] readr_1.3.1          stringr_1.4.0        htmlwidgets_1.5.1   
## [28] RCurl_1.98-1.2       bit_4.0.4            shiny_1.5.0         
## [31] compiler_4.0.2       httpuv_1.5.4         xfun_0.16           
## [34] pkgconfig_2.0.3      askpass_1.1          base64enc_0.1-3     
## [37] htmltools_0.5.0      openssl_1.4.2        tidyselect_1.1.0    
## [40] tibble_3.0.3         IRanges_2.22.2       XML_3.99-0.5        
## [43] dbplyr_1.4.4         crayon_1.3.4         dplyr_1.0.1         
## [46] later_1.1.0.1        rappdirs_0.3.1       bitops_1.0-6        
## [49] jsonlite_1.7.0       xtable_1.8-4         lifecycle_0.2.0     
## [52] DBI_1.1.0            magrittr_1.5         RJDBC_0.2-8         
## [55] stringi_1.4.6        promises_1.1.1       limma_3.44.3        
## [58] xml2_1.3.2           ellipsis_0.3.1       generics_0.0.2      
## [61] vctrs_0.3.2          tools_4.0.2          bit64_4.0.2         
## [64] glue_1.4.1           purrr_0.3.4          hms_0.5.3           
## [67] fastmap_1.0.1        yaml_2.2.1           AnnotationDbi_1.50.3
## [70] memoise_1.1.0        rJava_0.9-13
```
