---
title: "Biological Entity Dictionary (BED): Feeding the DB"
author: "Patrice Godard"
date: "December 16 2021"
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
library(TKCat)
k <- chTKCat("bel040344", password="")
if("MetaBase" %in% list_MDBs(k)$name){
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
ensembl_release <- "105"
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
## [1] "2021.12.16"
```

```r
BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
```

## Load Data model

**Start**: 2021-12-16 14:44:41


```r
BED:::loadBedModel()
```

**End**: 2021-12-16 14:44:46

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading taxonomy from NCBI

Information is downloaded if older than 4 days
according to the `reDumpThr` object.

**Start**: 2021-12-16 14:44:46


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

**End**: 2021-12-16 14:45:02

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
## [1] "105"
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

**Start**: 2021-12-16 14:45:03


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
## Ncells 1245660 66.6    6664223 356.0  8330278 444.9
## Vcells 6364401 48.6   54403833 415.1 68004788 518.9
```

**End**: 2021-12-16 14:47:35

### Transcripts

**Start**: 2021-12-16 14:47:35


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
## Ncells 1251795 66.9    5331379 284.8  8330278 444.9
## Vcells 6377548 48.7   52291680 399.0 68004788 518.9
```

**End**: 2021-12-16 14:49:52

### Peptides

**Start**: 2021-12-16 14:49:52


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
## Ncells 1257031 67.2    4265104 227.8  8330278 444.9
## Vcells 6388893 48.8   50264013 383.5 68004788 518.9
```

**End**: 2021-12-16 14:52:17

## Homo sapiens


```r
ensembl <- ensembl_Hsapiens
print(ensembl)
```

```
## $release
## [1] "105"
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

**Start**: 2021-12-16 14:52:17


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
##            used (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  1271832 68.0   12330100  658.5  15412624  823.2
## Vcells 10623212 81.1  178185569 1359.5 222731961 1699.4
```

**End**: 2021-12-16 15:00:18

### Transcripts

**Start**: 2021-12-16 15:00:18


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
##            used (Mb) gc trigger   (Mb)  max used   (Mb)
## Ncells  1273801 68.1   10215351  545.6  15412624  823.2
## Vcells 10626515 81.1  142548456 1087.6 222731961 1699.4
```

**End**: 2021-12-16 15:05:12

### Peptides

**Start**: 2021-12-16 15:05:12


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1272267 68.0    8172281 436.5  15412624  823.2
## Vcells 10624021 81.1  114038765 870.1 222731961 1699.4
```

**End**: 2021-12-16 15:10:51

## Mus musculus


```r
ensembl <- ensembl_Mmusculus
print(ensembl)
```

```
## $release
## [1] "105"
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

**Start**: 2021-12-16 15:10:51


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1271259 67.9    7877390 420.7  15412624  823.2
## Vcells 10622584 81.1  109541215 835.8 222731961 1699.4
```

**End**: 2021-12-16 15:16:21

### Transcripts

**Start**: 2021-12-16 15:16:21


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1271599 68.0    6316299 337.4  15412624  823.2
## Vcells 10623171 81.1   87632972 668.6 222731961 1699.4
```

**End**: 2021-12-16 15:19:34

### Peptides

**Start**: 2021-12-16 15:19:34


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1271121 67.9    5085527 271.6  15412624  823.2
## Vcells 10622437 81.1   70106378 534.9 222731961 1699.4
```

**End**: 2021-12-16 15:22:34

## Rattus norvegicus


```r
ensembl <- ensembl_Rnorvegicus
print(ensembl)
```

```
## $release
## [1] "105"
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

**Start**: 2021-12-16 15:22:34


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1271868 68.0    4914106 262.5  15412624  823.2
## Vcells 10623913 81.1   67366123 514.0 222731961 1699.4
```

**End**: 2021-12-16 15:26:04

### Transcripts

**Start**: 2021-12-16 15:26:04


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1271884 68.0    3931285 210.0  15412624  823.2
## Vcells 10623960 81.1   53892899 411.2 222731961 1699.4
```

**End**: 2021-12-16 15:27:40

### Peptides

**Start**: 2021-12-16 15:27:40


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1271709 68.0    3848847 205.6  15412624  823.2
## Vcells 10623731 81.1   43114320 329.0 222731961 1699.4
```

**End**: 2021-12-16 15:29:14

## Sus scrofa


```r
ensembl <- ensembl_Sscrofa
print(ensembl)
```

```
## $release
## [1] "105"
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

**Start**: 2021-12-16 15:29:15


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1271385 67.9    4581597 244.7  15412624  823.2
## Vcells 10623429 81.1   59834196 456.5 222731961 1699.4
```

**End**: 2021-12-16 15:31:20

### Transcripts

**Start**: 2021-12-16 15:31:20


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1271410 68.0    3705208 197.9  15412624  823.2
## Vcells 10623491 81.1   47867357 365.2 222731961 1699.4
```

**End**: 2021-12-16 15:32:32

### Peptides

**Start**: 2021-12-16 15:32:32


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
##            used (Mb) gc trigger  (Mb)  max used   (Mb)
## Ncells  1271382 67.9    3589000 191.7  15412624  823.2
## Vcells 10623507 81.1   38293886 292.2 222731961 1699.4
```

**End**: 2021-12-16 15:34:24

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

**Start**: 2021-12-16 15:34:24


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
## Ncells   1285164   68.7  407611527 21768.9  318868944 17029.5
## Vcells 136480868 1041.3 1968457354 15018.2 2460555498 18772.6
```

**End**: 2021-12-16 16:36:16

## Homo sapiens data

**Start**: 2021-12-16 16:36:16


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
## Ncells   1285565   68.7  326089222 17415.1  394701204 21079.4
## Vcells 270699316 2065.3 1574765884 12014.6 2460555498 18772.6
```

**End**: 2021-12-16 16:56:04

## Mus musculus data

**Start**: 2021-12-16 16:56:04


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
## Ncells   1285021   68.7  208697103 11145.7  394701204 21079.4
## Vcells 270698461 2065.3 1209471399  9227.6 2460555498 18772.6
```

**End**: 2021-12-16 17:17:37

## Rattus norvegicus data

**Start**: 2021-12-16 17:17:37


```r
BED:::getNcbiGeneTransPep(
    organism="Rattus norvegicus",
    ddir=".",
    curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   1286877   68.8  160304976 8561.3  394701204 21079.4
## Vcells 270701608 2065.3 1116049972 8514.8 2460555498 18772.6
```

**End**: 2021-12-16 17:36:42

## Sus scrofa data

**Start**: 2021-12-16 17:36:42


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
## Ncells   1285325   68.7  205263512 10962.3  394701204 21079.4
## Vcells 270699072 2065.3 1028664295  7848.1 2460555498 18772.6
```

**End**: 2021-12-16 17:55:12

## Direct cross-references with Uniprot

**Start**: 2021-12-16 17:55:12


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

**End**: 2021-12-16 18:01:46


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

**Start**: 2021-12-16 18:01:48


```r
BED:::getUniprot(
    organism="Danio rerio", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  84715551 4524.3  205263512 10962.3  394701204 21079.4
## Vcells 513476178 3917.6 1422258480 10851.0 2460555498 18772.6
```

**End**: 2021-12-16 22:27:01

## Homo sapiens data

**Start**: 2021-12-16 22:27:01


```r
BED:::getUniprot(
    organism="Homo sapiens", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  84715862 4524.4  205263512 10962.3  394701204 21079.4
## Vcells 513476746 3917.6 1422258480 10851.0 2460555498 18772.6
```

**End**: 2021-12-16 22:31:06

## Mus musculus data

**Start**: 2021-12-16 22:31:06


```r
BED:::getUniprot(
    organism="Mus musculus", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  84715837 4524.4  205263512 10962.3  394701204 21079.4
## Vcells 513476754 3917.6 1422258480 10851.0 2460555498 18772.6
```

**End**: 2021-12-16 22:33:00

## Rattus norvegicus data

**Start**: 2021-12-16 22:33:00


```r
BED:::getUniprot(
    organism="Rattus norvegicus", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  84715794 4524.4  205263512 10962.3  394701204 21079.4
## Vcells 513476734 3917.6 1422258480 10851.0 2460555498 18772.6
```

**End**: 2021-12-16 22:34:11

## Sus scrofa data

**Start**: 2021-12-16 22:34:11


```r
BED:::getUniprot(
    organism="Sus scrofa", release=avRel, ddir="."
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  84715820 4524.4  205263512 10962.3  394701204 21079.4
## Vcells 513476826 3917.6 1422258480 10851.0 2460555498 18772.6
```

**End**: 2021-12-16 22:37:12

## Indirect cross-references with EntrezGene

**Start**: 2021-12-16 22:37:12


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

**End**: 2021-12-16 22:51:56

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading Clarivate Analytics MetaBase objects from TKCat

**Start**: 2021-12-16 22:51:56


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
db_reconnect(k)
tkmb <- get_MDB(k, "MetaBase")
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
db_reconnect(tkmb)
loadMBObjects_fromTKCat(
    orgOfInt=c("Homo sapiens"),
    tkmb=tkmb
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  84796408 4528.7  205263512 10962.3  394701204 21079.4
## Vcells 513669179 3919.0 1422258480 10851.0 2460555498 18772.6
```

## Mus musculus data


```r
db_reconnect(tkmb)
loadMBObjects_fromTKCat(
    orgOfInt=c("Mus musculus"),
    tkmb=tkmb
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  84795772 4528.6  205263512 10962.3  394701204 21079.4
## Vcells 513668613 3919.0 1422258480 10851.0 2460555498 18772.6
```

## Rattus norvegicus data


```r
db_reconnect(tkmb)
loadMBObjects_fromTKCat(
    orgOfInt=c("Rattus norvegicus"),
    tkmb=tkmb
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  84795777 4528.6  205263512 10962.3  394701204 21079.4
## Vcells 513668654 3919.0 1422258480 10851.0 2460555498 18772.6
```

**End**: 2021-12-16 22:55:14

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading homologs

## Orthologs from biomaRt

**Start**: 2021-12-16 22:55:14


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

**End**: 2021-12-16 22:59:05

## Orthologs from NCBI

**Start**: 2021-12-16 22:59:05


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
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells  87584348 4677.6  205263512 10962.3  394701204 21079.4
## Vcells 520554976 3971.6 1422258480 10851.0 2460555498 18772.6
```

**End**: 2021-12-16 23:00:18

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading probes

## Probes from GEO


```r
library(GEOquery)
dir.create("geo", showWarnings=FALSE)
```

### GPL1708: 	Agilent-012391 Whole Human Genome Oligo Microarray G4112A (Feature Number version)

**Start**: 2021-12-16 23:00:18


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

**End**: 2021-12-16 23:00:28

### GPL6480: Agilent-014850 Whole Human Genome Microarray 4x44K G4112F (Probe Name version)

**Start**: 2021-12-16 23:00:28


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

**End**: 2021-12-16 23:00:38

### GPL570: Affymetrix Human Genome U133 Plus 2.0 Array

**Start**: 2021-12-16 23:00:38


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

**End**: 2021-12-16 23:00:59

### GPL571: Affymetrix Human Genome U133A 2.0 Array

**Start**: 2021-12-16 23:00:59


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

**End**: 2021-12-16 23:01:09

### GPL13158: Affymetrix HT HG-U133+ PM Array Plate

**Start**: 2021-12-16 23:01:09


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

**End**: 2021-12-16 23:01:24

### GPL96: Affymetrix Human Genome U133A Array

**Start**: 2021-12-16 23:01:24


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

**End**: 2021-12-16 23:01:33

### GPL1261: Affymetrix Mouse Genome 430 2.0 Array

**Start**: 2021-12-16 23:01:33


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

**End**: 2021-12-16 23:01:47

### GPL1355: Affymetrix Rat Genome 230 2.0 Array

**Start**: 2021-12-16 23:01:47


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

**End**: 2021-12-16 23:02:00

### GPL10558: Illumina HumanHT-12 V4.0 expression beadchip

**Start**: 2021-12-16 23:02:00


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

**End**: 2021-12-16 23:02:22

### GPL6947: Illumina HumanHT-12 V3.0 expression beadchip

**Start**: 2021-12-16 23:02:22


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

**End**: 2021-12-16 23:02:34

### GPL6885: Illumina MouseRef-8 v2.0 expression beadchip

**Start**: 2021-12-16 23:02:34


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

**End**: 2021-12-16 23:02:42

### GPL6887: Illumina MouseWG-6 v2.0 expression beadchip

**Start**: 2021-12-16 23:02:42


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

**End**: 2021-12-16 23:02:58

### GPL6101: Illumina ratRef-12 v1.0 expression beadchip

**Start**: 2021-12-16 23:02:58


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

**End**: 2021-12-16 23:03:05

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

<!-- **Start**: 2021-12-16 23:03:05 -->

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

<!-- **End**: 2021-12-16 23:03:05 -->

<!-- ### Mouse platforms -->

<!-- **Start**: 2021-12-16 23:03:05 -->

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

<!-- **End**: 2021-12-16 23:03:05 -->

<!-- ### Rat platforms -->

<!-- **Start**: 2021-12-16 23:03:05 -->

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

<!-- **End**: 2021-12-16 23:03:05 -->

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

**Start**: 2021-12-16 23:03:06


```r
BED:::loadLuceneIndexes()
```

**End**: 2021-12-16 23:03:07


<!----------------------------------------------------------------->
<!----------------------------------------------------------------->
# Session info


```
## R version 4.1.1 (2021-08-10)
## Platform: x86_64-pc-linux-gnu (64-bit)
## Running under: Red Hat Enterprise Linux
## 
## Matrix products: default
## BLAS/LAPACK: /usr/lib64/libopenblasp-r0.3.3.so
## 
## locale:
##  [1] LC_CTYPE=en_GB.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=en_GB.UTF-8        LC_COLLATE=en_GB.UTF-8    
##  [5] LC_MONETARY=en_GB.UTF-8    LC_MESSAGES=en_GB.UTF-8   
##  [7] LC_PAPER=en_GB.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=en_GB.UTF-8 LC_IDENTIFICATION=C       
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
##  [1] GEOquery_2.62.1     Biobase_2.54.0      BiocGenerics_0.40.0
##  [4] biomaRt_2.50.1      TKCat_0.7.1         RClickhouse_0.6.0  
##  [7] DBI_1.1.1           ReDaMoR_0.5.2       magrittr_2.0.1     
## [10] dplyr_1.0.7         BED_1.4.7           visNetwork_2.1.0   
## [13] neo2R_2.1.0         knitr_1.36         
## 
## loaded via a namespace (and not attached):
##  [1] bitops_1.0-7           bit64_4.0.5            filelock_1.0.2        
##  [4] progress_1.2.2         httr_1.4.2             GenomeInfoDb_1.30.0   
##  [7] tools_4.1.1            bslib_0.3.1            utf8_1.2.2            
## [10] R6_2.5.1               DT_0.20                withr_2.4.3           
## [13] tidyselect_1.1.1       prettyunits_1.1.1      bit_4.0.4             
## [16] curl_4.3.2             compiler_4.1.1         xml2_1.3.3            
## [19] shinyjs_2.0.0          colourpicker_1.1.1     sass_0.4.0            
## [22] readr_2.1.1            rappdirs_0.3.3         stringr_1.4.0         
## [25] digest_0.6.29          R.utils_2.11.0         rmarkdown_2.11        
## [28] XVector_0.34.0         base64enc_0.1-3        pkgconfig_2.0.3       
## [31] htmltools_0.5.2        parallelly_1.29.0      limma_3.50.0          
## [34] dbplyr_2.1.1           fastmap_1.1.0          jsonvalidate_1.3.2    
## [37] htmlwidgets_1.5.4      rlang_0.4.12           rstudioapi_0.13       
## [40] RSQLite_2.2.9          shiny_1.7.1            jquerylib_0.1.4       
## [43] generics_0.1.1         jsonlite_1.7.2         R.oo_1.24.0           
## [46] RCurl_1.98-1.5         GenomeInfoDbData_1.2.7 Rcpp_1.0.7            
## [49] S4Vectors_0.32.3       fansi_0.5.0            R.methodsS3_1.8.1     
## [52] lifecycle_1.0.1        stringi_1.7.6          yaml_2.2.1            
## [55] rintrojs_0.3.0         zlibbioc_1.40.0        BiocFileCache_2.2.0   
## [58] blob_1.2.2             parallel_4.1.1         listenv_0.8.0         
## [61] promises_1.2.0.1       shinydashboard_0.7.2   crayon_1.4.2          
## [64] miniUI_0.1.1.1         Biostrings_2.62.0      hms_1.1.1             
## [67] KEGGREST_1.34.0        pillar_1.6.4           uuid_1.0-3            
## [70] markdown_1.1           codetools_0.2-18       stats4_4.1.1          
## [73] XML_3.99-0.8           glue_1.5.1             evaluate_0.14         
## [76] getPass_0.2-2          V8_3.5.0               data.table_1.14.2     
## [79] vctrs_0.3.8            png_0.1-7              tzdb_0.2.0            
## [82] httpuv_1.6.3           tidyr_1.1.4            purrr_0.3.4           
## [85] future_1.23.0          assertthat_0.2.1       cachem_1.0.6          
## [88] xfun_0.28              mime_0.12              xtable_1.8-4          
## [91] later_1.3.0            tibble_3.1.6           AnnotationDbi_1.56.2  
## [94] memoise_2.0.1          IRanges_2.28.0         globals_0.14.0        
## [97] ellipsis_0.3.2
```
