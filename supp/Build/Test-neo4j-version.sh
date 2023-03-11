#!/bin/sh

export NJ_VERSION=3.5.32

export BED_HTTP_PORT=5410
export BED_BOLT_PORT=5610

export BED_DATA=`pwd`/../../../working/tmpDataInt

export CONTAINER=torm

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
	--volume $BED_DATA/data:/data \
	neo4j:$NJ_VERSION

sleep 10


