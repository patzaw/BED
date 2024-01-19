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

