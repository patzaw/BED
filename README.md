README
================

# Biological Entity Dictionary <img src="man/figures/BED.png" align="right" alt="" width="120" />

[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/BED)](https://cran.r-project.org/package=BED)
[![](http://cranlogs.r-pkg.org/badges/BED)](https://cran.r-project.org/package=BED)

Render SVG as interactive figures to display contextual information,
with selectable and clickable user interface elements. These figures can
be seamlessly integrated into ‘rmarkdown’ and ‘Quarto’ documents, as
well as ‘shiny’ applications, allowing manipulation of elements and
reporting actions performed on them. Additional features include pan,
zoom in/out functionality, and the ability to export the figures in SVG
or PNG formats.

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
- [webshot](https://CRAN.R-project.org/package=webshot): Take
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

A public instance of the [BED Neo4j database](#bed_db) is provided for
convenience and can be reached as follows:

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
- Clarivate Analytics MetaBase

The following shell commands can be adapted according to user needs and
called to get a running container with a BED database instance.

``` sh
#!/bin/sh

####################################################@
## Config ----
export BED_VERSION=2024.01.14
export NJ_VERSION=5.15.0
export BED_HTTP_PORT=5454
export BED_BOLT_PORT=5687
export CONTAINER=bed

export BED_REP_URL=https://zenodo.org/records/10521413/files/

export BED_DUMPS=~/.cache/BED/neo4jDump
export BED_DATA=~/.cache/BED/neo4jData

####################################################@
## Check folders ----
if test -e $BED_DATA; then
   echo "$BED_DATA directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
mkdir -p $BED_DATA

if test -e $BED_DUMPS; then
   echo "$BED_DUMPS directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
mkdir -p $BED_DUMPS

####################################################@
## Download data ----
wget $BED_REP_URL/dump-bed-ucb-human-$BED_VERSION.dump -O $BED_DUMPS/neo4j.dump

####################################################@
## Import data ----
docker run --interactive --tty --rm \
   --volume=$BED_DATA/data:/data \
   --volume=$BED_DUMPS:/backups \
    neo4j/neo4j-admin:$NJ_VERSION \
neo4j-admin database load neo4j --from-path=/backups

####################################################@
## Start neo4j ----
docker run -d \
   --name $CONTAINER \
   --publish=$BED_HTTP_PORT:7474 \
   --publish=$BED_BOLT_PORT:7687 \
   --env=NEO4J_dbms_memory_heap_initial__size=4G \
   --env=NEO4J_dbms_memory_heap_max__size=4G \
   --env=NEO4J_dbms_memory_pagecache_size=4G \
   --env=NEO4J_dbms_read__only=true \
   --env=NEO4J_AUTH=none \
   --volume $BED_DATA/data:/data \
   --restart=always \
   neo4j:$NJ_VERSION
```

[Sergio Espeso-Gil](https://github.com/sespesogil) has reported
stability issues with Docker images in Windows. It’s mainly solved by
checking the “Use the WSL2 based engine” options in docker settings.
More information is provided here:
<https://docs.docker.com/docker-for-windows/wsl/>

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
