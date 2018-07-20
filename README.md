# BED

The aim of the BED (Biological Entity Dictionary) R package is to get
and explore mapping between identifiers of biological entities (BE).
This package provides a way to connect to a BED Neo4j database in which the
relationships between the identifiers from different sources are recorded.

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

# R package in normal use

It's described in the [BED](inst/doc/BED.html) vignette.

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
docker pull patzaw/bed-ucb-human:2018.07.20
docker run -d \
   --name bed \
   --publish=5454:7474 --publish=5687:7687 \
   --env=NEO4J_dbms_memory_heap_initial__size=2g \
   --env=NEO4J_dbms_memory_heap_max__size=2G \
   --env=NEO4J_dbms_memory_pagecache_size=2g \
   --env=NEO4J_dbms_read__only=true \
   --env=NEO4J_dbms_security_procedures_unrestricted=apoc.* \
   --restart=always \
   patzaw/bed-ucb-human:2018.07.20
```

# Build a BED database instance

It's described in the [Rebuild-BED](inst/Build/Rebuild-BED.html) vignette.

First, copy the Rebuild-BED.Rmd file and the neo4j directory found
in the Build sub-directory of BED package in a new directory.
Then, copy the installation directory of neo4j in
*neo4j/install/* sub-directory of the new directory.
Finally run Rebuild-BED.sh script.
**Do not forget to change the neo4j access mode into read only** as
explained in the Rebuild-BED.html compiled file
(it's done automatically at the end of the procedure).

# Create and run a Docker image with the BED database.

## Prepare neo4j folder

1. Stop neo4j
2. Remove all *neostore.transaction.db.XX* files
in the *data/databases/graph.db/* directory to make the DB lighter

## Start docker

```
sudo systemctl start docker
sudo systemctl enable docker
```

## Building a Docker image

- https://docs.docker.com/engine/getstarted/step_four/
- https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#add-or-copy

Put in a **Dockerfile** the following lines:

```
FROM neo4j:3.4.4
COPY bed-dev-neo4j-community-3.4.4/data /data
COPY bed-dev-neo4j-community-3.4.4/plugins /plugins
# COPY bed-dev-neo4j-community-3.4.4/conf/neo4j.conf /var/lib/neo4j/conf/
```

Be careful that the *bed-dev-neo4j-community-3.3.5* directory (neo4j
installation directory with a BED database) is located in the directory
containing the *Dockerfile*.

Run the following command in the directory containing the *Dockerfile*:

```
docker build -t bed-ucb-human:2018.07.20 .
```

You can then save the created image:

```
docker save bed-ucb-human:2018.07.20 > docker-bed-ucb-human-2018.07.20.tar
```

And the image archive can be loaded with the following command:

```
cat docker-bed-ucb-human-2018.07.20.tar | docker load
```

## Run the BED Docker image

- https://docs.docker.com/engine/reference/commandline/run/

```
docker run -d \
   --name bed_test \
   --publish=7474:7474 --publish=7687:7687 \
   --env=NEO4J_dbms_memory_heap_initial__size=2g \
   --env=NEO4J_dbms_memory_heap_max__size=2G \
   --env=NEO4J_dbms_memory_pagecache_size=2g \
   --env=NEO4J_dbms_read__only=true \
   --env=NEO4J_dbms_security_procedures_unrestricted=apoc.* \
   --restart=always \
   bed-ucb-human:2018.07.20
# --publish=hostport:containerport
# --restart=always ==> start when the docker daemon starts
# --env=NEO4J_dbms_memory_heap_maxSize --> http://neo4j.com/docs/operations-manual/current/installation/docker/
```

## Push the BED Docker image

- https://docs.docker.com/docker-cloud/builds/push-images/

```
export DOCKER_ID_USER="username"
docker login
docker tag bed-ucb-human:2018.07.20 $DOCKER_ID_USER/bed-ucb-human:2018.07.20
docker tag $DOCKER_ID_USER/bed-ucb-human:2018.07.20 $DOCKER_ID_USER/bed-ucb-human:latest
docker push $DOCKER_ID_USER/bed-ucb-human:2018.07.20
docker push $DOCKER_ID_USER/bed-ucb-human:latest
```

## Managing containers/images/volumes

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
