-   [BED](#bed)
-   [Installation](#installation)
    -   [Dependencies](#dependencies)
    -   [Installation from github](#installation-from-github)
-   [R package in normal use](#r-package-in-normal-use)
-   [Citing BED](#citing-bed)
-   [BED database instance available as a docker
    image](#bed-database-instance-available-as-a-docker-image)
-   [Build a BED database instance](#build-a-bed-database-instance)
    -   [Run a neo4j docker images](#run-a-neo4j-docker-images)
    -   [Build and feed BED](#build-and-feed-bed)
    -   [Create a docker image with BED
        database](#create-a-docker-image-with-bed-database)
    -   [Push the image on docker hub](#push-the-image-on-docker-hub)
    -   [Run the new image](#run-the-new-image)
-   [Notes about Docker](#notes-about-docker)
    -   [Start docker](#start-docker)
    -   [Building a Docker image](#building-a-docker-image)
    -   [Saving and loading an image
        archive](#saving-and-loading-an-image-archive)
    -   [Push a Docker image on docker
        hub](#push-a-docker-image-on-docker-hub)
    -   [Run a docker image](#run-a-docker-image)
    -   [Managing
        containers/images/volumes](#managing-containersimagesvolumes)

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
BED
===

The aim of the BED (Biological Entity Dictionary) R package is to get
and explore mapping between identifiers of biological entities (BE).
This package provides a way to connect to a BED Neo4j database in which
the relationships between the identifiers from different sources are
recorded.

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
Installation
============

Dependencies
------------

This package depends on the following R packages available in the CRAN
repository:

-   **neo2R**
-   **visNetwork**
-   **dplyr**
-   **readr**
-   **stringr**
-   **htmltools**
-   **DT**
-   **shiny**
-   **miniUI**
-   **rstudioapi**

They can be easily installed with the `install.packages()` function.

Installation from github
------------------------

``` r
devtools::install_github("patzaw/BED")
```

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
R package in normal use
=======================

It’s described in the [BED](https://patzaw.github.io/BED/BED.html)
vignette.

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
Citing BED
==========

This package and the underlying research has been published in this peer
reviewed article:

<p>
Godard P, van Eyll J (2018). “BED: a Biological Entity Dictionary based
on a graph data model.” <em>F1000Research</em>, <b>7</b>, 195. doi:
<a href="https://doi.org/10.12688/f1000research.13925.3">10.12688/f1000research.13925.3</a>,
<a href="https://doi.org/10.12688/f1000research.13925.3">https://doi.org/10.12688/f1000research.13925.3</a>.
</p>
<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
BED database instance available as a docker image
=================================================

An instance of the BED database (UCB-Human) has been built using the
script provided in the BED R package and made available in a Docker
image available here:
<a href="https://hub.docker.com/r/patzaw/bed-ucb-human/" class="uri">https://hub.docker.com/r/patzaw/bed-ucb-human/</a>

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
export BED_VERSION=2020.05.03

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
    patzaw/bed-ucb-human:$BED_VERSION
```

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
Build a BED database instance
=============================

Building and feeding a BED database instance is achieved using scripts
available in the “Build” folder.

Run a neo4j docker images
-------------------------

<!------------------------->
Using the S01-NewBED-Container.sh script.

Build and feed BED
------------------

<!------------------>
Using the S02-Rebuild-BED.sh script which compile the Rebuild-BED.Rmd
document.

Create a docker image with BED database
---------------------------------------

<!--------------------------------------->
Using the S03-NewBED-image.sh script

Push the image on docker hub
----------------------------

<!---------------------------->
Using the S04-Push-on-docker-hub.sh script

Run the new image
-----------------

<!------------------>
Using the S05-BED-Container.sh script

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
Notes about Docker
==================

Start docker
------------

<!------------>
``` sh
sudo systemctl start docker
sudo systemctl enable docker
```

Building a Docker image
-----------------------

<!----------------------->
-   <a href="https://docs.docker.com/get-started/" class="uri">https://docs.docker.com/get-started/</a>
-   <a href="https://docs.docker.com/develop/develop-images/dockerfile_best-practices/" class="uri">https://docs.docker.com/develop/develop-images/dockerfile_best-practices/</a>

Saving and loading an image archive
-----------------------------------

<!----------------------------------->
You can save the created image:

``` sh
docker save bed-ucb-human:$BED_VERSION > docker-bed-ucb-human-$BED_VERSION.tar
```

And the image archive can be loaded with the following command:

``` sh
cat docker-bed-ucb-human-$BED_VERSION.tar | docker load
```

Push a Docker image on docker hub
---------------------------------

<!--------------------------------->
-   <a href="https://docs.docker.com/docker-cloud/builds/push-images/" class="uri">https://docs.docker.com/docker-cloud/builds/push-images/</a>

Run a docker image
------------------

<!------------------>
-   <a href="https://docs.docker.com/engine/reference/commandline/run/" class="uri">https://docs.docker.com/engine/reference/commandline/run/</a>

Managing containers/images/volumes
----------------------------------

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
