#!/bin/sh

export NJ_VERSION=3.5.21

export BED_HTTP_PORT=5420
export BED_BOLT_PORT=5620

export BED_IMPORT=`pwd`/../../../../working/neo4jImport
mkdir -p $BED_IMPORT
export BED_PUB_DATA=`pwd`/../../../../working/neo4jData
export BED_DATA=`pwd`/../../../../working/neo4jDataInt
if test -e $BED_DATA; then
   echo "$BED_DATA directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
if test -e $BED_PUB_DATA; then
   cp -R $BED_PUB_DATA $BED_DATA
else
   echo "$BED_PUB_DATA directory does not exist ==> abort - Create public instance before proceeding with internal" >&2
   # exit
fi

export CONTAINER=new_int_bed

docker run -d \
	--name $CONTAINER \
	--publish=$BED_HTTP_PORT:7474 \
	--publish=$BED_BOLT_PORT:7687 \
	--env=NEO4J_dbms_memory_heap_initial__size=16G \
	--env=NEO4J_dbms_memory_heap_max__size=16G \
	--env=NEO4J_dbms_memory_pagecache_size=8G \
	--env=NEO4J_dbms_query__cache__size=0 \
   --env=NEO4J_cypher_min__replan__interval=100000000ms \
   --env=NEO4J_cypher_statistics__divergence__threshold=1 \
	--env=NEO4J_AUTH=none \
	--env=NEO4J_dbms_directories_import=import \
	--volume $BED_IMPORT:/var/lib/neo4j/import \
	--volume $BED_DATA/data:/data \
	neo4j:$NJ_VERSION

sleep 10
uid=`id -u`
gid=`id -g`
sudo chown $uid:$gid $BED_IMPORT
chmod a+rx $BED_IMPORT


