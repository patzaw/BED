<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
# BED

The aim of the BED (Biological Entity Dictionary) R package is to get
and explore mapping between identifiers of biological entities (BE).
This package provides a way to connect to a BED Neo4j database in which the
relationships between the identifiers from different sources are recorded.

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
# Installation

## Dependencies

This package depends on the following R packages available in the
CRAN repository:

   - visNetwork
   - dplyr
   - htmltools
   - DT
   - shiny
   - miniUI
   - rstudioapi
   
They can be easily installed with the `install.packages()` function.
   
BED also depends on the neo2R package (https://github.com/patzaw/neo2R)
co-developped with this project.
It can be installed from github: `devtools::install_github("patzaw/neo2R")`

## Installation from github

```
devtools::install_github("patzaw/BED")
```
<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
# R package in normal use

It's described in the [BED](inst/doc/BED.html) vignette.

<!----------------------------------------------------------------------------->
<!----------------------------------------------------------------------------->
# BED database instance available as a docker image

An instance of the BED database (UCB-Human)
has been built using the script provided
in the BED R package and made available in a Docker
image available here:
https://hub.docker.com/r/patzaw/bed-ucb-human/

This instance
is focused on *Homo sapiens*, *Mus musculus* and *Rattus norvegicus* organisms
and it has been built from the following resources:

   - Ensembl
   - NCBI
   - Uniprot
   - biomaRt
   - GEOquery
   - Clarivate Analytics MetaBase
   
The following commands can be adapted according to user needs and called to
get a running container with a BED database instance.

```
export BED_HTTP_PORT=5454
export BED_BOLT_PORT=5687
export BED_VERSION=2020.01.24

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
# Build a BED database instance

Building and feeding a BED database instance is achieved using scripts
available in the "Build" folder.

## Run a neo4j docker images
<!------------------------->

Using the S01-NewBED-Container.sh script.

## Build and feed BED
<!------------------>

Using the S02-Rebuild-BED.sh script which compile the Rebuild-BED.Rmd document.

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

```
sudo systemctl start docker
sudo systemctl enable docker
```

## Building a Docker image
<!----------------------->

- https://docs.docker.com/get-started/
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/

## Saving and loading an image archive
<!----------------------------------->

You can save the created image:

```
docker save bed-ucb-human:$BED_VERSION > docker-bed-ucb-human-$BED_VERSION.tar
```

And the image archive can be loaded with the following command:

```
cat docker-bed-ucb-human-$BED_VERSION.tar | docker load
```

## Push a Docker image on docker hub
<!--------------------------------->

- https://docs.docker.com/docker-cloud/builds/push-images/

## Run a docker image
<!------------------>

- https://docs.docker.com/engine/reference/commandline/run/

## Managing containers/images/volumes
<!---------------------------------->

### List created containers

```
docker ps # list running containers
docker ps -a # list all containers
```

### Remove container

```
docker rm CONTAINER
```

### Remove image

```
docker rmi IMAGE # only if no corresponding container
```

### List volumes

```
docker volume ls
```

### Remove unused volumes

```
docker volume prune
```
