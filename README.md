README
================

# Biological Entity Dictionary <img src="man/figures/BED.png" align="right" alt="" width="120" />

[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/BED)](https://cran.r-project.org/package=BED)
[![](https://cranlogs.r-pkg.org/badges/BED)](https://cran.r-project.org/package=BED)

An interface for the ‘Neo4j’ database providing mapping between
different identifiers of biological entities. This Biological Entity
Dictionary (BED) has been developed to address three main challenges.
The first one is related to the completeness of identifier mappings.
Indeed, direct mapping information provided by the different systems are
not always complete and can be enriched by mappings provided by other
resources. More interestingly, direct mappings not identified by any of
these resources can be indirectly inferred by using mappings to a third
reference. For example, many human Ensembl gene ID are not directly
mapped to any Entrez gene ID but such mappings can be inferred using
respective mappings to HGNC ID. The second challenge is related to the
mapping of deprecated identifiers. Indeed, entity identifiers can change
from one resource release to another. The identifier history is provided
by some resources, such as Ensembl or the NCBI, but it is generally not
used by mapping tools. The third challenge is related to the automation
of the mapping process according to the relationships between the
biological entities of interest. Indeed, mapping between gene and
protein ID scopes should not be done the same way than between two
scopes regarding gene ID. Also, converting identifiers from different
organisms should be possible using gene orthologs information. The
method has been published by Godard and van Eyll (2018)
<doi:10.12688/f1000research.13925.3>.

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

## Installation

### From CRAN

``` r
install.packages("BED")
```

### Dependencies

The following R packages available on CRAN are required:

- [neo2R](https://CRAN.R-project.org/package=neo2R): Neo4j to R
- [visNetwork](https://CRAN.R-project.org/package=visNetwork): Network
  Visualization using ‘vis.js’ Library
- [dplyr](https://CRAN.R-project.org/package=dplyr): A Grammar of Data
  Manipulation
- [readr](https://CRAN.R-project.org/package=readr): Read Rectangular
  Text Data
- [stringr](https://CRAN.R-project.org/package=stringr): Simple,
  Consistent Wrappers for Common String Operations
- [utils](https://CRAN.R-project.org/package=utils): The R Utils Package
- [shiny](https://CRAN.R-project.org/package=shiny): Web Application
  Framework for R
- [DT](https://CRAN.R-project.org/package=DT): A Wrapper of the
  JavaScript Library ‘DataTables’
- [miniUI](https://CRAN.R-project.org/package=miniUI): Shiny UI Widgets
  for Small Screens
- [rstudioapi](https://CRAN.R-project.org/package=rstudioapi): Safely
  Access the RStudio API

And those are suggested:

- [knitr](https://CRAN.R-project.org/package=knitr): A General-Purpose
  Package for Dynamic Report Generation in R
- [rmarkdown](https://CRAN.R-project.org/package=rmarkdown): Dynamic
  Documents for R
- [biomaRt](https://CRAN.R-project.org/package=biomaRt): Interface to
  BioMart databases (i.e. Ensembl)
- [GEOquery](https://CRAN.R-project.org/package=GEOquery): Get data from
  NCBI Gene Expression Omnibus (GEO)
- [base64enc](https://CRAN.R-project.org/package=base64enc): Tools for
  base64 encoding
- [htmltools](https://CRAN.R-project.org/package=htmltools): Tools for
  HTML
- [webshot2](https://CRAN.R-project.org/package=webshot2): Take
  Screenshots of Web Pages
- [RCurl](https://CRAN.R-project.org/package=RCurl): General Network
  (HTTP/FTP/…) Client Interface for R

### Installation from github

``` r
devtools::install_github("patzaw/BED")
```

### Possible issue when updating from releases \<= 1.3.0

If you get an error like the following…

    Error: package or namespace load failed for ‘BED’:
     .onLoad failed in loadNamespace() for 'BED', details:
      call: connections[[connection]][["cache"]]
      error: subscript out of bounds

… remove the BED folder located here:

``` r
file.exists(file.path(Sys.getenv("HOME"), "R", "BED"))
```

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

## Documentation

Documentation is provided in the
[BED](https://patzaw.github.io/BED/articles/BED.html) vignette.

A public instance of the [BED Neo4j
database](#available-bed-database-instance) is provided for convenience
and can be reached as follows:

``` r
library(BED)
connectToBed("https://genodesy.org/BED/", remember=TRUE, useCache=TRUE)
findBeids()
```

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

## Citing BED

This package and the underlying research has been published in this peer
reviewed article:

<a href="https://doi.org/10.12688/f1000research.13925.3" target="_blank">
Patrice Godard and Jonathan van Eyll (2018). BED: a Biological Entity
Dictionary based on a graph data model (version 3; peer review: 2
approved). F1000Research, 7:195. </a>

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

## Available BED database instance

An instance of the BED database (UCB-Human) has been built using the
script provided in the BED R package.

This instance is focused on *Homo sapiens*, *Mus musculus*, *Rattus
norvegicus*, *Sus scrofa* and *Danio rerio* organisms. It has been built
from the following resources:

- Ensembl
- NCBI
- Uniprot
- biomaRt
- GEOquery

The Neo4j graph database is available as a dump file shared in
[Zenodo](https://zenodo.org/records/11196534).

The following shell commands can be adapted according to user needs and
called to get a running Neo4j container with a BED database instance.

``` sh
#!/bin/sh

####################################################@
## Check folders ----
if test -e ~/.cache/BED/neo4jData; then
   echo "~/.cache/BED/neo4jData directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
mkdir -p ~/.cache/BED/neo4jData

if test -e ~/.cache/BED/neo4jDump; then
   echo "~/.cache/BED/neo4jDump directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
mkdir -p ~/.cache/BED/neo4jDump

####################################################@
## Download data ----
export BED_REP_URL=https://zenodo.org/records/11196534/files/
wget $BED_REP_URL/dump_bed_Genodesy-Human_2024.05.15.dump -O ~/.cache/BED/neo4jDump/neo4j.dump

####################################################@
## Import data ----
docker run --interactive --tty --rm \
   --volume=~/.cache/BED/neo4jData/data:/data \
   --volume=~/.cache/BED/neo4jDump:/backups \
    neo4j:5.19.0 \
neo4j-admin database load neo4j --from-path=/backups

####################################################@
## Start neo4j ----
docker run -d \
   --name bed_2024.05.15 \
   --publish=5454:7474 \
   --publish=5687:7687 \
   --env=NEO4J_dbms_memory_heap_initial__size=4G \
   --env=NEO4J_dbms_memory_heap_max__size=4G \
   --env=NEO4J_dbms_memory_pagecache_size=4G \
   --env=NEO4J_dbms_read__only=true \
   --env=NEO4J_AUTH=none \
   --volume ~/.cache/BED/neo4jData/data:/data \
   --volume ~/.cache/BED/neo4jData/logs:/var/lib/neo4j/logs \
   --restart=always \
   neo4j:5.19.0
```

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

## Build a BED database instance

Building and feeding a BED database instance is achieved using scripts
available in the “supp/Build” folder.

### Run a neo4j docker images

Using the S01-NewBED-Container.sh script.

### Build and feed BED

Using the S02-Rebuild-BED.sh script which compile the Rebuild-BED.Rmd
document.

## Dump the graph DB content for sharing

Using the S03-Dump-BED.sh script

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

## Docker notes

[Sergio Espeso-Gil](https://github.com/sespesogil) has reported
stability issues with Docker images in Windows. It’s mainly solved by
checking the “Use the WSL2 based engine” options in docker settings.
More information is provided here:
<https://docs.docker.com/docker-for-windows/wsl/>
