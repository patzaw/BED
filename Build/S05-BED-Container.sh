#!/bin/sh

export BED_HTTP_PORT=5454
export BED_BOLT_PORT=5687

export BED_VERSION=2020.01.24

# Stop and remove the former container
docker stop bed
docker rm bed

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
