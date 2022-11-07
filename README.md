README
================

-   <a href="#introduction" id="toc-introduction">Introduction</a>
-   <a href="#installation" id="toc-installation">Installation</a>
    -   <a href="#from-cran" id="toc-from-cran">From CRAN</a>
    -   <a href="#dependencies" id="toc-dependencies">Dependencies</a>
    -   <a href="#installation-from-github"
        id="toc-installation-from-github">Installation from github</a>
    -   <a href="#possible-issue-when-updating-from-releases--130"
        id="toc-possible-issue-when-updating-from-releases--130">Possible issue
        when updating from releases &lt;= 1.3.0</a>
-   <a href="#r-package-in-normal-use" id="toc-r-package-in-normal-use">R
    package in normal use</a>
-   <a href="#citing-bed" id="toc-citing-bed">Citing BED</a>
-   <a href="#docker_image" id="toc-docker_image">BED database instance
    available as a docker image</a>
-   <a href="#build-a-bed-database-instance"
    id="toc-build-a-bed-database-instance">Build a BED database instance</a>
    -   <a href="#run-a-neo4j-docker-images"
        id="toc-run-a-neo4j-docker-images">Run a neo4j docker images</a>
    -   <a href="#build-and-feed-bed" id="toc-build-and-feed-bed">Build and feed
        BED</a>
    -   <a href="#create-a-docker-image-with-bed-database"
        id="toc-create-a-docker-image-with-bed-database">Create a docker image
        with BED database</a>
    -   <a href="#push-the-image-on-docker-hub"
        id="toc-push-the-image-on-docker-hub">Push the image on docker hub</a>
    -   <a href="#run-the-new-image" id="toc-run-the-new-image">Run the new
        image</a>
-   <a href="#notes-about-docker" id="toc-notes-about-docker">Notes about
    Docker</a>
    -   <a href="#start-docker" id="toc-start-docker">Start docker</a>
    -   <a href="#building-a-docker-image"
        id="toc-building-a-docker-image">Building a Docker image</a>
    -   <a href="#saving-and-loading-an-image-archive"
        id="toc-saving-and-loading-an-image-archive">Saving and loading an image
        archive</a>
    -   <a href="#push-a-docker-image-on-docker-hub"
        id="toc-push-a-docker-image-on-docker-hub">Push a Docker image on docker
        hub</a>
    -   <a href="#run-a-docker-image" id="toc-run-a-docker-image">Run a docker
        image</a>
    -   <a href="#managing-containersimagesvolumes"
        id="toc-managing-containersimagesvolumes">Managing
        containers/images/volumes</a>

<img src="https://github.com/patzaw/BED/raw/master/supp/logo/BED.png" width="100px"/>

[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/BED)](https://cran.r-project.org/package=BED)
[![](http://cranlogs.r-pkg.org/badges/BED)](https://cran.r-project.org/package=BED)

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

# Introduction

The aim of the [BED](https://patzaw.github.io/BED/) (Biological Entity
Dictionary) R package is to get and explore mapping between identifiers
of biological entities (BE). This package provides a way to connect to a
BED Neo4j database in which the relationships between the identifiers
from different sources are recorded.

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

# Installation

## From CRAN

``` r
install.packages("BED")
```

## Dependencies

The following R packages available on CRAN are required:

-   [neo2R](https://CRAN.R-project.org/package=neo2R): Neo4j to R
-   [visNetwork](https://CRAN.R-project.org/package=visNetwork): Network
    Visualization using ‘vis.js’ Library
-   [dplyr](https://CRAN.R-project.org/package=dplyr): A Grammar of Data
    Manipulation
-   [readr](https://CRAN.R-project.org/package=readr): Read Rectangular
    Text Data
-   [stringr](https://CRAN.R-project.org/package=stringr): Simple,
    Consistent Wrappers for Common String Operations
-   [utils](https://CRAN.R-project.org/package=utils): The R Utils
    Package
-   [shiny](https://CRAN.R-project.org/package=shiny): Web Application
    Framework for R
-   [DT](https://CRAN.R-project.org/package=DT): A Wrapper of the
    JavaScript Library ‘DataTables’
-   [miniUI](https://CRAN.R-project.org/package=miniUI): Shiny UI
    Widgets for Small Screens
-   [rstudioapi](https://CRAN.R-project.org/package=rstudioapi): Safely
    Access the RStudio API

And those are suggested:

-   [knitr](https://CRAN.R-project.org/package=knitr): A General-Purpose
    Package for Dynamic Report Generation in R
-   [rmarkdown](https://CRAN.R-project.org/package=rmarkdown): Dynamic
    Documents for R
-   [biomaRt](https://CRAN.R-project.org/package=biomaRt): Interface to
    BioMart databases (i.e. Ensembl)
-   [GEOquery](https://CRAN.R-project.org/package=GEOquery): Get data
    from NCBI Gene Expression Omnibus (GEO)
-   [base64enc](https://CRAN.R-project.org/package=base64enc): Tools for
    base64 encoding
-   [htmltools](https://CRAN.R-project.org/package=htmltools): Tools for
    HTML
-   [webshot](https://CRAN.R-project.org/package=webshot): Take
    Screenshots of Web Pages

## Installation from github

``` r
devtools::install_github("patzaw/BED")
```

## Possible issue when updating from releases \<= 1.3.0

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

# R package in normal use

Documentation is provided in the
[BED](https://patzaw.github.io/BED/articles/BED.html) vignette.

A public instance of the [BED Neo4j database](#docker_image) is provided
for convenience and can be reached as follows:

``` r
library(BED)
connectToBed("https://genodesy.org/BED/", remember=TRUE, useCache=TRUE)
findBeids()
```

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

# Citing BED

This package and the underlying research has been published in this peer
reviewed article:

<a href="https://doi.org/10.12688/f1000research.13925.3" target="_blank">
Patrice Godard and Jonathan van Eyll (2018). BED: a Biological Entity
Dictionary based on a graph data model (version 3; peer review: 2
approved). F1000Research, 7:195. </a>

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

# BED database instance available as a docker image

An instance of the BED database (UCB-Human) has been built using the
script provided in the BED R package and made available in a Docker
image available here: <https://hub.docker.com/r/patzaw/bed-ucb-human/>

This instance is focused on *Homo sapiens*, *Mus musculus*, *Rattus
norvegicus*, *Sus scrofa* and *Danio rerio* organisms and it has been
built from the following resources:

-   Ensembl
-   NCBI
-   Uniprot
-   biomaRt
-   GEOquery
-   Clarivate Analytics MetaBase

The following commands can be adapted according to user needs and called
to get a running container with a BED database instance.

``` sh
export BED_HTTP_PORT=5454
export BED_BOLT_PORT=5687

docker run -d \
    --name bed \
    --publish=$BED_HTTP_PORT:7474 \
    --publish=$BED_BOLT_PORT:7687 \
    --env=NEO4J_dbms_memory_heap_initial__size=4G \
    --env=NEO4J_dbms_memory_heap_max__size=4G \
    --env=NEO4J_dbms_memory_pagecache_size=4G \
   --env=NEO4J_dbms_read__only=true \
    --env=NEO4J_AUTH=none \
   --restart=always \
    patzaw/bed-ucb-human
```

[Sergio Espeso-Gil](https://github.com/sespesogil) has reported
stability issues with this image running on Docker in Windows. It’s
mainly solved by checking the “Use the WSL2 based engine” options in
docker settings. More information are provided here:
<https://docs.docker.com/docker-for-windows/wsl/>

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

# Build a BED database instance

Building and feeding a BED database instance is achieved using scripts
available in the “supp/Build” folder.

## Run a neo4j docker images

<!------------------------->

Using the S01-NewBED-Container.sh script.

## Build and feed BED

<!------------------>

Using the S02-Rebuild-BED.sh script which compile the Rebuild-BED.Rmd
document.

## Create a docker image with BED database

<!--------------------------------------->

Using the S03-NewBED-image.sh script

## Push the image on docker hub

<!---------------------------->

Using the S04-Push-on-docker-hub.sh script

## Run the new image

<!------------------>

Using the S05-BED-Container.sh script

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->

# Notes about Docker

## Start docker

<!------------>

``` sh
sudo systemctl start docker
sudo systemctl enable docker
```

## Building a Docker image

<!----------------------->

-   <https://docs.docker.com/get-started/>
-   <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>

## Saving and loading an image archive

<!----------------------------------->

You can save the created image:

``` sh
docker save bed-ucb-human:$BED_VERSION > docker-bed-ucb-human-$BED_VERSION.tar
```

And the image archive can be loaded with the following command:

``` sh
cat docker-bed-ucb-human-$BED_VERSION.tar | docker load
```

## Push a Docker image on docker hub

<!--------------------------------->

-   <https://docs.docker.com/docker-cloud/builds/push-images/>

## Run a docker image

<!------------------>

-   <https://docs.docker.com/engine/reference/commandline/run/>

## Managing containers/images/volumes

<!---------------------------------->

### List created containers

``` sh
docker ps # list running containers
docker ps -a # list all containers
```

### Remove container

``` sh
docker rm CONTAINER
```

### Remove image

``` sh
docker rmi IMAGE # only if no corresponding container
```

### List volumes

``` sh
docker volume ls
```

### Remove unused volumes

``` sh
docker volume prune
```
