---
title: "Biological Entity Dictionary (BED): Feeding the DB"
author: "Patrice Godard"
date: "April 23 2019"
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
```

```
## Warning in checkBedConn(verbose = TRUE): BED DB is empty !
```

```
## Warning in checkBedConn(): BED DB is empty !

## Warning in checkBedConn(): BED DB is empty !

## Warning in checkBedConn(): BED DB is empty !
```

```
## Warning in checkBedCache(newCon = TRUE): Clearing cache
```

```
## Warning in checkBedConn(verbose = FALSE): BED DB is empty !
```

```r
##
workingDirectory <- "working"
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
ensembl_release <- "96"
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
    canChromosomes=c(1:18, "X", "Y", "MT")
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
   url="http://localhost:5410",
   importPath=file.path(getwd(), "neo4jImport")
)
```

```
## Warning in checkBedConn(verbose = TRUE): BED DB is empty !
```

```
## Warning in checkBedConn(): BED DB is empty !

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
```

```
## Warning in checkBedConn(): BED DB is empty !
```

```r
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
## [1] "2019.04.23"
```

```r
BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
```

```
## Warning in checkBedConn(): BED DB is empty !
```

## Load Data model

**Start**: 2019-04-23 09:45:30


```r
BED:::loadBedModel()
```

**End**: 2019-04-23 09:45:37

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading taxonomy from NCBI

Information is downloaded if older than 2 days
according to the `reDumpThr` object.

**Start**: 2019-04-23 09:45:37


```r
BED:::loadNcbiTax(
    reDumpThr=reDumpThr,
    orgOfInt=c(
       "Homo sapiens", "Rattus norvegicus", "Mus musculus",
       "Sus scrofa"
      ),
    curDate=curDate
)
```

**End**: 2019-04-23 09:45:50

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

## Homo sapiens


```r
ensembl <- ensembl_Hsapiens
print(ensembl)
```

```
## $release
## [1] "96"
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
##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14"
## [15] "15" "16" "17" "18" "19" "20" "21" "22" "X"  "Y"  "MT"
```

### Genes

**Start**: 2019-04-23 09:45:51


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
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  719107 38.5    8379534 447.6  10474418 559.4
## Vcells 5858343 44.7   89653246 684.0 112052790 854.9
```

**End**: 2019-04-23 09:50:22

### Transcripts

**Start**: 2019-04-23 09:50:22


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   725385 38.8    9562022 510.7  11952528 638.4
## Vcells 10065946 76.8  103421339 789.1 129221452 985.9
```

**End**: 2019-04-23 09:59:06

### Peptides

**Start**: 2019-04-23 09:59:06


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   729629 39.0    7747911 413.8  11952528 638.4
## Vcells 10075535 76.9   99348484 758.0 129221452 985.9
```

**End**: 2019-04-23 10:07:22

## Mus musculus


```r
ensembl <- ensembl_Mmusculus
print(ensembl)
```

```
## $release
## [1] "96"
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
##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14"
## [15] "15" "16" "17" "18" "19" "X"  "Y"  "MT"
```

### Genes

**Start**: 2019-04-23 10:07:22


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   729296 39.0    6225667 332.5  11952528 638.4
## Vcells 10075229 76.9   79478787 606.4 129221452 985.9
```

**End**: 2019-04-23 10:10:46

### Transcripts

**Start**: 2019-04-23 10:10:46


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   730386 39.1    4980533 266.0  11952528 638.4
## Vcells 10077056 76.9   76363635 582.7 129221452 985.9
```

**End**: 2019-04-23 10:15:30

### Peptides

**Start**: 2019-04-23 10:15:30


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   729323 39.0    4814942 257.2  11952528 638.4
## Vcells 10075345 76.9   73373089 559.8 129221452 985.9
```

**End**: 2019-04-23 10:20:21

## Rattus norvegicus


```r
ensembl <- ensembl_Rnorvegicus
print(ensembl)
```

```
## $release
## [1] "96"
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
##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14"
## [15] "15" "16" "17" "18" "19" "20" "X"  "Y"  "MT"
```

### Genes

**Start**: 2019-04-23 10:20:21


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   729893 39.0    3851953 205.8  11952528 638.4
## Vcells 10076545 76.9   58698471 447.9 129221452 985.9
```

**End**: 2019-04-23 10:22:12

### Transcripts

**Start**: 2019-04-23 10:22:12


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   729474 39.0    3729874 199.2  11952528 638.4
## Vcells 10075857 76.9   46958776 358.3 129221452 985.9
```

**End**: 2019-04-23 10:24:19

### Peptides

**Start**: 2019-04-23 10:24:19


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   729689 39.0    2983899 159.4  11952528 638.4
## Vcells 10076276 76.9   37567020 286.7 129221452 985.9
```

**End**: 2019-04-23 10:26:46

## Sus scrofa


```r
ensembl <- ensembl_Sscrofa
print(ensembl)
```

```
## $release
## [1] "96"
## 
## $organism
## [1] "Sus scrofa"
## 
## $gv
## [1] "111"
## 
## $gdbCref
##   EntrezGene    Vega_gene  Ens_Rn_gene 
## "EntrezGene"  "Vega_gene"   "Ens_gene" 
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
##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14"
## [15] "15" "16" "17" "18" "X"  "Y"  "MT"
```

### Genes

**Start**: 2019-04-23 10:26:46


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   729449 39.0    3171783 169.4  11952528 638.4
## Vcells 10076120 76.9   56415232 430.5 129221452 985.9
```

**End**: 2019-04-23 10:27:53

### Transcripts

**Start**: 2019-04-23 10:27:53


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   729567 39.0    2665971 142.4  11952528 638.4
## Vcells 10076327 76.9   45132185 344.4 129221452 985.9
```

**End**: 2019-04-23 10:29:52

### Peptides

**Start**: 2019-04-23 10:29:52


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
##            used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells   729551 39.0    2591332 138.4  11952528 638.4
## Vcells 10076361 76.9   36105748 275.5 129221452 985.9
```

**End**: 2019-04-23 10:32:24

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

## Homo sapiens data

**Start**: 2019-04-23 10:32:25


```r
BED:::getNcbiGeneTransPep(
    organism="Homo sapiens", curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells    748462   40.0  239094744 12769.1  298868431 15961.3
## Vcells 135945655 1037.2 1289631257  9839.2 1611982806 12298.5
```

```r
BED:::loadNCBIEntrezGOFunctions(
    organism="Homo sapiens", curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells    749987   40.1  191275795 10215.3  298868431 15961.3
## Vcells 135949407 1037.3 1031705005  7871.3 1611982806 12298.5
```

**End**: 2019-04-23 11:22:45

## Mus musculus data

**Start**: 2019-04-23 11:22:45


```r
BED:::getNcbiGeneTransPep(
    organism="Mus musculus", curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells    749894   40.1  183656763 9808.4  298868431 15961.3
## Vcells 135949328 1037.3 1001596121 7641.6 1611982806 12298.5
```

```r
BED:::loadNCBIEntrezGOFunctions(
    organism="Mus musculus", curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells    749986   40.1  146925410 7846.7  298868431 15961.3
## Vcells 135949491 1037.3  801276896 6113.3 1611982806 12298.5
```

**End**: 2019-04-23 11:39:13

## Rattus norvegicus data

**Start**: 2019-04-23 11:39:13


```r
BED:::getNcbiGeneTransPep(
    organism="Rattus norvegicus", curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger    (Mb)   max used    (Mb)
## Ncells    750826   40.1  188479976 10066.0  298868431 15961.3
## Vcells 135950970 1037.3  944348776  7204.9 1611982806 12298.5
```

```r
BED:::loadNCBIEntrezGOFunctions(
    organism="Rattus norvegicus", curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells    749988   40.1  150783980 8052.8  298868431 15961.3
## Vcells 135949584 1037.3  755479020 5763.9 1611982806 12298.5
```

**End**: 2019-04-23 11:54:16

## Sus scrofa data

**Start**: 2019-04-23 11:54:16


```r
BED:::getNcbiGeneTransPep(
    organism="Sus scrofa", curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells    751206   40.2  186208888 9944.7  298868431 15961.3
## Vcells 135951685 1037.3  872063244 6653.4 1611982806 12298.5
```

```r
BED:::loadNCBIEntrezGOFunctions(
    organism="Sus scrofa", curDate=curDate
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells    749990   40.1  148967110 7955.8  298868431 15961.3
## Vcells 135949668 1037.3  697650595 5322.7 1611982806 12298.5
```

**End**: 2019-04-23 12:07:45

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

## Homo sapiens data

**Start**: 2019-04-23 12:07:47


```r
BED:::getUniprot(
    organism="Homo sapiens", release=avRel
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells    757908   40.5  119173688 6364.6  298868431 15961.3
## Vcells 135965804 1037.4  558120476 4258.2 1611982806 12298.5
```

**End**: 2019-04-23 12:12:16

## Mus musculus data

**Start**: 2019-04-23 12:12:16


```r
BED:::getUniprot(
    organism="Mus musculus", release=avRel
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells    757781   40.5   95338950 5091.7  298868431 15961.3
## Vcells 135965640 1037.4  446496380 3406.5 1611982806 12298.5
```

**End**: 2019-04-23 12:14:32

## Rattus norvegicus data

**Start**: 2019-04-23 12:14:32


```r
BED:::getUniprot(
    organism="Rattus norvegicus", release=avRel
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells    757612   40.5   76271160 4073.4  298868431 15961.3
## Vcells 135965416 1037.4  446496380 3406.5 1611982806 12298.5
```

**End**: 2019-04-23 12:15:34

## Sus scrofa data

**Start**: 2019-04-23 12:15:34


```r
BED:::getUniprot(
    organism="Sus scrofa", release=avRel
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells    757536   40.5   61016928 3258.7  298868431 15961.3
## Vcells 135965328 1037.4  446496380 3406.5 1611982806 12298.5
```

**End**: 2019-04-23 12:16:49

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading Clarivate Analytics MetaBase objects

**Start**: 2019-04-23 12:16:49



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
BED:::loadMBObjects(
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
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   1995812  106.6   48813542 2607.0  298868431 15961.3
## Vcells 185090008 1412.2  446496380 3406.5 1611982806 12298.5
```

## Mus musculus data


```r
BED:::loadMBObjects(
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
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   1994943  106.6   39050833 2085.6  298868431 15961.3
## Vcells 185088598 1412.2  446496380 3406.5 1611982806 12298.5
```

## Rattus norvegicus data


```r
BED:::loadMBObjects(
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
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   1994944  106.6   31240666 1668.5  298868431 15961.3
## Vcells 185088640 1412.2  446496380 3406.5 1611982806 12298.5
```

**End**: 2019-04-23 12:19:12

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading homologs

## Orthologs from biomaRt

**Start**: 2019-04-23 12:19:12


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
loadBmHomologs(
    org1="hsapiens",
    org2="mmusculus",
    version=ensembl_release
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   3234570  172.8   24992532 1334.8  298868431 15961.3
## Vcells 187270411 1428.8  446496380 3406.5 1611982806 12298.5
```


```r
loadBmHomologs(
    org1="hsapiens",
    org2="rnorvegicus",
    version=ensembl_release
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   3235691  172.9   19994025 1067.8  298868431 15961.3
## Vcells 187393873 1429.8  446496380 3406.5 1611982806 12298.5
```


```r
loadBmHomologs(
    org1="hsapiens",
    org2="sscrofa",
    version=ensembl_release
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   3235110  172.8   15995220  854.3  298868431 15961.3
## Vcells 187509641 1430.6  446496380 3406.5 1611982806 12298.5
```


```r
loadBmHomologs(
    org1="mmusculus",
    org2="rnorvegicus",
    version=ensembl_release
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   3236342  172.9   12796176  683.4  298868431 15961.3
## Vcells 187624414 1431.5  446496380 3406.5 1611982806 12298.5
```


```r
loadBmHomologs(
    org1="mmusculus",
    org2="sscrofa",
    version=ensembl_release
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   3236307  172.9   10236940  546.8  298868431 15961.3
## Vcells 187733801 1432.3  446496380 3406.5 1611982806 12298.5
```


```r
loadBmHomologs(
    org1="rnorvegicus",
    org2="sscrofa",
    version=ensembl_release
)
gc()
```

```
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   3236481  172.9   10236940  546.8  298868431 15961.3
## Vcells 187820485 1433.0  446496380 3406.5 1611982806 12298.5
```

**End**: 2019-04-23 12:24:03

## Orthologs from NCBI

**Start**: 2019-04-23 12:24:03


```r
#####################################
gdbname <- "EntrezGene"
taxOfInt <- unlist(lapply(
    c(
       "Homo sapiens", "Mus musculus", "Rattus norvegicus",
       "Sus scrofa"
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
##             used   (Mb) gc trigger   (Mb)   max used    (Mb)
## Ncells   3236612  172.9   10236940  546.8  298868431 15961.3
## Vcells 187822039 1433.0  446496380 3406.5 1611982806 12298.5
```

**End**: 2019-04-23 12:25:10

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading probes

## Probes from GEO


```r
library(GEOquery)
dir.create("geo", showWarnings=FALSE)
```

### GPL6480: Agilent-014850 Whole Human Genome Microarray 4x44K G4112F (Probe Name version)

**Start**: 2019-04-23 12:25:10


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
## Import mapping with UniGene
toImport <- d[which(!is.na(d$ID)), c("ID", "UNIGENE_ID")]
colnames(toImport) <- c("probeID", "id")
toImport$probeID <- as.character(toImport$probeID)
toImport$id <- as.character(toImport$id)
toImport <- toImport[which(!is.na(toImport$id)),]
dbname <- "UniGene"
##
BED:::loadProbes(
    d=toImport,
    be=be,
    platform=platName,
    dbname=dbname
)
```

**End**: 2019-04-23 12:25:28

### GPL570: Affymetrix Human Genome U133 Plus 2.0 Array

**Start**: 2019-04-23 12:25:28


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

**End**: 2019-04-23 12:25:45

### GPL571: Affymetrix Human Genome U133A 2.0 Array

**Start**: 2019-04-23 12:25:45


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

**End**: 2019-04-23 12:25:54

### GPL13158: Affymetrix HT HG-U133+ PM Array Plate

**Start**: 2019-04-23 12:25:54


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

**End**: 2019-04-23 12:26:09

### GPL96: Affymetrix Human Genome U133A Array

**Start**: 2019-04-23 12:26:09


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

**End**: 2019-04-23 12:26:19

### GPL1261: Affymetrix Mouse Genome 430 2.0 Array

**Start**: 2019-04-23 12:26:19


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

**End**: 2019-04-23 12:26:34

### GPL1355: Affymetrix Rat Genome 230 2.0 Array

**Start**: 2019-04-23 12:26:34


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

**End**: 2019-04-23 12:26:43

### GPL10558: Illumina HumanHT-12 V4.0 expression beadchip

**Start**: 2019-04-23 12:26:43


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

**End**: 2019-04-23 12:26:58

### GPL6947: Illumina HumanHT-12 V3.0 expression beadchip

**Start**: 2019-04-23 12:26:58


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

**End**: 2019-04-23 12:27:10

### GPL6885: Illumina MouseRef-8 v2.0 expression beadchip

**Start**: 2019-04-23 12:27:10


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

**End**: 2019-04-23 12:27:17

### GPL6887: Illumina MouseWG-6 v2.0 expression beadchip

**Start**: 2019-04-23 12:27:17


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

**End**: 2019-04-23 12:27:31

### GPL6101: Illumina ratRef-12 v1.0 expression beadchip

**Start**: 2019-04-23 12:27:31


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

**End**: 2019-04-23 12:27:39

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

<!-- **Start**: 2019-04-23 12:27:39 -->

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

<!-- **End**: 2019-04-23 12:27:39 -->

<!-- ### Mouse platforms -->

<!-- **Start**: 2019-04-23 12:27:39 -->

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

<!-- **End**: 2019-04-23 12:27:39 -->

<!-- ### Rat platforms -->

<!-- **Start**: 2019-04-23 12:27:39 -->

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

<!-- **End**: 2019-04-23 12:27:39 -->

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
    "GO_function"='http://amigo.geneontology.org/amigo/term/%s'
)
for(db in names(otherIdURL)){
    BED:::registerBEDB(
        name=db,
        idURL=otherIdURL[[db]]
    )   
}
```


<!----------------------------------------------------------------->
<!----------------------------------------------------------------->
# Session info


```
## R version 3.5.2 (2018-12-20)
## Platform: x86_64-redhat-linux-gnu (64-bit)
## Running under: Red Hat Enterprise Linux
## 
## Matrix products: default
## BLAS/LAPACK: /usr/lib64/R/lib/libRblas.so
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
##  [1] GEOquery_2.50.5     Biobase_2.42.0      BiocGenerics_0.28.0
##  [4] biomaRt_2.38.0      metabaser_4.3.0     igraph_1.2.4       
##  [7] BED_1.1.6           visNetwork_2.0.5    neo2R_1.1.1        
## [10] knitr_1.22         
## 
## loaded via a namespace (and not attached):
##  [1] Rcpp_1.0.0           tidyr_0.8.3          prettyunits_1.0.2   
##  [4] png_0.1-7            assertthat_0.2.0     digest_0.6.18       
##  [7] mime_0.6             R6_2.4.0             plyr_1.8.4          
## [10] stats4_3.5.2         RSQLite_2.1.1        evaluate_0.13       
## [13] httr_1.4.0           pillar_1.3.1         rlang_0.3.1         
## [16] progress_1.2.0       curl_3.3             rstudioapi_0.9.0    
## [19] data.table_1.12.0    miniUI_0.1.1.1       blob_1.1.1          
## [22] S4Vectors_0.20.1     DT_0.5               rmarkdown_1.12      
## [25] readr_1.3.1          stringr_1.4.0        htmlwidgets_1.3     
## [28] RCurl_1.95-4.12      bit_1.1-14           shiny_1.2.0         
## [31] compiler_3.5.2       httpuv_1.4.5.1       xfun_0.5            
## [34] pkgconfig_2.0.2      base64enc_0.1-3      htmltools_0.3.6     
## [37] tidyselect_0.2.5     tibble_2.0.1         IRanges_2.16.0      
## [40] XML_3.98-1.19        crayon_1.3.4         dplyr_0.8.0.1       
## [43] later_0.8.0          bitops_1.0-6         jsonlite_1.6        
## [46] xtable_1.8-3         DBI_1.0.0            magrittr_1.5        
## [49] RJDBC_0.2-7.1        stringi_1.4.3        promises_1.0.1      
## [52] limma_3.38.3         xml2_1.2.0           tools_3.5.2         
## [55] bit64_0.9-7          glue_1.3.1           purrr_0.3.1         
## [58] hms_0.4.2            yaml_2.2.0           AnnotationDbi_1.44.0
## [61] memoise_1.1.0        rJava_0.9-10
```
