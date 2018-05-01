---
title: "Biological Entity Dictionary (BED): Feeding the DB"
author: "Patrice Godard"
date: "April 30 2018"
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

BED is based on [Neo4j](https://neo4j.com/). The following chunk is used
to config Neo4j. The automation of the installation has been done for Linux
and according to current needs. It should be adapted for other operating
systems and according to specific needs.

Also, because the import functions use massively the `LOAD CSV` Neo4j query, 
the feeding of the BED database can only be down from the
computer hosting the Neo4j relevant instance.


```r
## neo4j config
neov <- "neo4j-community-3.3.5"
neo.config <- list(
    url="http://localhost:7474",
    username="neo4j", password="1234"
)
bedPath <- sprintf("./bed-dev-%s", neov)
bash <- file.path("neo4j/bash", neov)
```

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
opts_chunk$set(eval=TRUE, message=FALSE)
## Specific config
bedInstance <- "UCB-Human"
bedVersion <- format(Sys.Date(), "%Y.%m.%d")
ensembl_release <- "92"
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
## General config
reDumpThr <- as.difftime(2, units="days")
curDate <- Sys.Date()
```

# BED initialization

<a name="reset"></a>

## Neo4j installation

Again, this part has been automated according to current needs and on a Linux
computer.

### Backup and removing existing former build


```r
if(file.exists(bedPath)){
    system(paste("sh", file.path(bash, "bedBckClean.sh"), bedPath))
}
```

### Neo4j installation


```r
system(paste("sh", file.path(bash, "installNeo4j.sh"), neov, bedPath))
```

### Start Neo4j


```r
system(paste("sh", file.path(bash, "startNeo4j.sh"), bedPath))
```

## Starting BED

### Connect to BED


```r
do.call(connectToBed, neo.config)
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

Do not go further if your BED DB is not empty.
Check the procedure described [above](#reset).


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

### Set BED Version


```r
print(bedVersion)
```

```
## [1] "2018.04.30"
```

```r
BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
```

```
## Warning in checkBedConn(): BED DB is empty !
```

### Load Data model

**Start**: 2018-04-30 12:53:32


```r
BED:::loadBedModel()
```

**End**: 2018-04-30 12:53:39

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading taxonomy from NCBI

Information is downloaded if older than 2 days
according to the `reDumpThr` object.

**Start**: 2018-04-30 12:53:39


```r
BED:::loadNcbiTax(
    reDumpThr=reDumpThr,
    orgOfInt=c("Homo sapiens", "Rattus norvegicus", "Mus musculus"),
    curDate=curDate
)
```

**End**: 2018-04-30 12:53:54

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
## [1] "92"
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

**Start**: 2018-04-30 12:53:55


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
## Ncells  678889 36.3    7715856 412.1   9644821 515.1
## Vcells 5673596 43.3   96067041 733.0 120078752 916.2
```

**End**: 2018-04-30 12:58:41

### Transcripts

**Start**: 2018-04-30 12:58:41


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
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  685235 36.6    7439221 397.3   9644821 515.1
## Vcells 5686327 43.4   92288359 704.2 120078752 916.2
```

**End**: 2018-04-30 13:07:53

### Peptides

**Start**: 2018-04-30 13:07:53


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
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  686543 36.7    7173652 383.2   9644821 515.1
## Vcells 5686305 43.4   88660824 676.5 120078752 916.2
```

**End**: 2018-04-30 13:16:46

## Mus musculus


```r
ensembl <- ensembl_Mmusculus
print(ensembl)
```

```
## $release
## [1] "92"
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

**Start**: 2018-04-30 13:16:46


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
## Ncells  688332 36.8    5738921 306.5   9644821 515.1
## Vcells 5695875 43.5   70928659 541.2 120078752 916.2
```

**End**: 2018-04-30 13:20:29

### Transcripts

**Start**: 2018-04-30 13:20:29


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
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  689508 36.9    4591136 245.2   9644821 515.1
## Vcells 5703216 43.6   68155512 520.0 120078752 916.2
```

**End**: 2018-04-30 13:25:27

### Peptides

**Start**: 2018-04-30 13:25:27


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
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  690150 36.9    4439490 237.1   9644821 515.1
## Vcells 5709031 43.6   65493291 499.7 120078752 916.2
```

**End**: 2018-04-30 13:30:27

## Rattus norvegicus


```r
ensembl <- ensembl_Rnorvegicus
print(ensembl)
```

```
## $release
## [1] "92"
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

**Start**: 2018-04-30 13:30:27


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
## Ncells  690342 36.9    3551592 189.7   9644821 515.1
## Vcells 5709601 43.6   52394632 399.8 120078752 916.2
```

**End**: 2018-04-30 13:32:36

### Transcripts

**Start**: 2018-04-30 13:32:36


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
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  690349 36.9    2841273 151.8   9644821 515.1
## Vcells 5709623 43.6   41915705 319.8 120078752 916.2
```

**End**: 2018-04-30 13:35:03

### Peptides

**Start**: 2018-04-30 13:35:03


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
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  690135 36.9    2759621 147.4   9644821 515.1
## Vcells 5709326 43.6   33532564 255.9 120078752 916.2
```

**End**: 2018-04-30 13:37:50

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

**Start**: 2018-04-30 13:37:51


```r
BED:::getNcbiGeneTransPep(
    organism="Homo sapiens", curDate=curDate
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  697391 37.3    4749654 253.7   9644821 515.1
## Vcells 5718173 43.7   38770312 295.8 120078752 916.2
```

```r
BED:::loadNCBIEntrezGOFunctions(
    organism="Homo sapiens", curDate=curDate
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  699114 37.4    3799723 203.0   9644821 515.1
## Vcells 5721155 43.7   31016249 236.7 120078752 916.2
```

**End**: 2018-04-30 13:48:51

## Mus musculus data

**Start**: 2018-04-30 13:48:51


```r
BED:::getNcbiGeneTransPep(
    organism="Mus musculus", curDate=curDate
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  701447 37.5    4447680 237.6   9644821 515.1
## Vcells 5737132 43.8   24812999 189.4 120078752 916.2
```

```r
BED:::loadNCBIEntrezGOFunctions(
    organism="Mus musculus", curDate=curDate
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  701665 37.5    3558144 190.1   9644821 515.1
## Vcells 5738297 43.8   19850399 151.5 120078752 916.2
```

**End**: 2018-04-30 13:57:36

## Rattus norvegicus data

**Start**: 2018-04-30 13:57:36


```r
BED:::getNcbiGeneTransPep(
    organism="Rattus norvegicus", curDate=curDate
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  701635 37.5    3447817 184.2   9644821 515.1
## Vcells 5738323 43.8   19120382 145.9 120078752 916.2
```

```r
BED:::loadNCBIEntrezGOFunctions(
    organism="Rattus norvegicus", curDate=curDate
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  701667 37.5    2758253 147.4   9644821 515.1
## Vcells 5738383 43.8   19120382 145.9 120078752 916.2
```

**End**: 2018-04-30 14:02:39

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

**Start**: 2018-04-30 14:02:41


```r
BED:::getUniprot(
    organism="Homo sapiens", release=avRel
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  704452 37.7    2679922 143.2   9644821 515.1
## Vcells 5740270 43.8   19120382 145.9 120078752 916.2
```

**End**: 2018-04-30 14:07:27

## Mus musculus data

**Start**: 2018-04-30 14:07:27


```r
BED:::getUniprot(
    organism="Mus musculus", release=avRel
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  706069 37.8    2143937 114.5   9644821 515.1
## Vcells 5750278 43.9   19120382 145.9 120078752 916.2
```

**End**: 2018-04-30 14:10:03

## Rattus norvegicus data

**Start**: 2018-04-30 14:10:03


```r
BED:::getUniprot(
    organism="Rattus norvegicus", release=avRel
)
gc()
```

```
##           used (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  706071 37.8    2143937 114.5   9644821 515.1
## Vcells 5750336 43.9   19120382 145.9 120078752 916.2
```

**End**: 2018-04-30 14:11:11

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading Clarivate Analytics MetaBase objects

**Start**: 2018-04-30 14:11:11



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
##            used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  2366518 126.4    4660385 248.9   9644821 515.1
## Vcells 49008992 374.0   71151756 542.9 120078752 916.2
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
##            used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  2367074 126.5    4660385 248.9   9644821 515.1
## Vcells 49012999 374.0   85462107 652.1 120078752 916.2
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
##            used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  2367816 126.5    4660385 248.9   9644821 515.1
## Vcells 49014274 374.0   85462107 652.1 120078752 916.2
```

**End**: 2018-04-30 14:13:15

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading homologs

## Orthologs from biomaRt

**Start**: 2018-04-30 14:13:15


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
##            used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  3201925 171.1    5632462 300.9   9644821 515.1
## Vcells 49784039 379.9   85462107 652.1 120078752 916.2
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
##            used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  3205320 171.2    5632462 300.9   9644821 515.1
## Vcells 49894713 380.7   85462107 652.1 120078752 916.2
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
##            used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  3205379 171.2    5632462 300.9   9644821 515.1
## Vcells 49974218 381.3   85462107 652.1 120078752 916.2
```

**End**: 2018-04-30 14:16:35

## Orthologs from NCBI

**Start**: 2018-04-30 14:16:35


```r
#####################################
gdbname <- "EntrezGene"
taxOfInt <- unlist(lapply(
    c("Homo sapiens", "Mus musculus", "Rattus norvegicus"),
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
##            used  (Mb) gc trigger  (Mb)  max used  (Mb)
## Ncells  3205976 171.3    5632462 300.9   9644821 515.1
## Vcells 49976529 381.3  102634528 783.1 120078752 916.2
```

**End**: 2018-04-30 14:17:14

<!----------------------------------------------------------------->
<!----------------------------------------------------------------->

# Loading probes

## Probes from GEO


```r
library(GEOquery)
dir.create("geo", showWarnings=FALSE)
```

### GPL6480: Agilent-014850 Whole Human Genome Microarray 4x44K G4112F (Probe Name version)

**Start**: 2018-04-30 14:17:14


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

**End**: 2018-04-30 14:17:36

### GPL570: Affymetrix Human Genome U133 Plus 2.0 Array

**Start**: 2018-04-30 14:17:36


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

**End**: 2018-04-30 14:18:07

### GPL571: Affymetrix Human Genome U133A 2.0 Array

**Start**: 2018-04-30 14:18:07


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

**End**: 2018-04-30 14:18:23

### GPL13158: Affymetrix HT HG-U133+ PM Array Plate

**Start**: 2018-04-30 14:18:23


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

**End**: 2018-04-30 14:18:44

### GPL96: Affymetrix Human Genome U133A Array

**Start**: 2018-04-30 14:18:44


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

**End**: 2018-04-30 14:18:59

### GPL1261: Affymetrix Mouse Genome 430 2.0 Array

**Start**: 2018-04-30 14:18:59


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

**End**: 2018-04-30 14:19:24

### GPL1355: Affymetrix Rat Genome 230 2.0 Array

**Start**: 2018-04-30 14:19:24


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

**End**: 2018-04-30 14:19:40

### GPL10558: Illumina HumanHT-12 V4.0 expression beadchip

**Start**: 2018-04-30 14:19:40


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

**End**: 2018-04-30 14:20:08

### GPL6947: Illumina HumanHT-12 V3.0 expression beadchip

**Start**: 2018-04-30 14:20:08


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

**End**: 2018-04-30 14:20:26

### GPL6885: Illumina MouseRef-8 v2.0 expression beadchip

**Start**: 2018-04-30 14:20:26


```r
## Import plateform
platName <- "GPL6885"
gds <- getGEO(platName, destdir="geo")
platDesc <- Meta(gds)$title
be <- "Transcript"
##
BED:::loadPlf(name=platName, description=platDesc, be=be)
## Import mapping
d <- Table(gds)
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

**End**: 2018-04-30 14:20:36

### GPL6101: Illumina ratRef-12 v1.0 expression beadchip

**Start**: 2018-04-30 14:20:36


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

**End**: 2018-04-30 14:20:46

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

<!-- **Start**: 2018-04-30 14:20:46 -->

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

<!-- **End**: 2018-04-30 14:20:46 -->

<!-- ### Mouse platforms -->

<!-- **Start**: 2018-04-30 14:20:46 -->

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

<!-- **End**: 2018-04-30 14:20:46 -->

<!-- ### Rat platforms -->

<!-- **Start**: 2018-04-30 14:20:46 -->

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

<!-- **End**: 2018-04-30 14:20:46 -->

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

# Final procedure

## Shift to read only mode

Shifting to read only mode will avoid unintended modification of the BED
database.


```r
system(paste("sh", file.path(bash, "readOnly.sh"), bedPath), intern = FALSE)
```

# Session info


```
## R version 3.4.4 (2018-03-15)
## Platform: x86_64-redhat-linux-gnu (64-bit)
## Running under: Red Hat Enterprise Linux Workstation 7.4 (Maipo)
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
##  [1] GEOquery_2.46.15    Biobase_2.38.0      BiocGenerics_0.24.0
##  [4] biomaRt_2.34.2      metabaser_4.2.3     igraph_1.2.1       
##  [7] BED_1.1.0           visNetwork_2.0.3    neo2R_0.1.0        
## [10] knitr_1.20         
## 
## loaded via a namespace (and not attached):
##  [1] Rcpp_0.12.16         lattice_0.20-35      tidyr_0.8.0         
##  [4] prettyunits_1.0.2    png_0.1-7            utf8_1.1.3          
##  [7] assertthat_0.2.0     rprojroot_1.3-2      digest_0.6.15       
## [10] mime_0.5             R6_2.2.2             plyr_1.8.4          
## [13] backports_1.1.2      stats4_3.4.4         RSQLite_2.1.0       
## [16] evaluate_0.10.1      httr_1.3.1           pillar_1.2.1        
## [19] rlang_0.2.0.9001     progress_1.1.2       curl_3.2            
## [22] rstudioapi_0.7       miniUI_0.1.1         blob_1.1.1          
## [25] S4Vectors_0.16.0     Matrix_1.2-14        DT_0.4              
## [28] rmarkdown_1.9        readr_1.1.1          stringr_1.3.0       
## [31] htmlwidgets_1.2      RCurl_1.95-4.10      bit_1.1-12          
## [34] shiny_1.0.5          compiler_3.4.4       httpuv_1.4.0        
## [37] pkgconfig_2.0.1      base64enc_0.1-3      htmltools_0.3.6     
## [40] tibble_1.4.2         IRanges_2.12.0       XML_3.98-1.11       
## [43] crayon_1.3.4         dplyr_0.7.4          later_0.7.1         
## [46] bitops_1.0-6         grid_3.4.4           jsonlite_1.5        
## [49] xtable_1.8-2         DBI_0.8              magrittr_1.5        
## [52] RJDBC_0.2-7.1        cli_1.0.0            stringi_1.1.7       
## [55] promises_1.0.1       bindrcpp_0.2.2       limma_3.34.9        
## [58] xml2_1.2.0           tools_3.4.4          bit64_0.9-7         
## [61] glue_1.2.0           purrr_0.2.4          hms_0.4.2           
## [64] yaml_2.1.18          AnnotationDbi_1.40.0 memoise_1.1.0       
## [67] rJava_0.9-9          bindr_0.1.1
```
