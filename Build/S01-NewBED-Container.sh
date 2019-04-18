#!/bin/sh

export NJ_VERSION=3.4.12

export BED_HTTP_PORT=5410
export BED_BOLT_PORT=5610

export BED_IMPORT=`pwd`/working/neo4jImport
mkdir -p $BED_IMPORT
export BED_DATA=`pwd`/working/neo4jData
if test -e $BED_DATA; then
   echo "$BED_DATA directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
mkdir $BED_DATA

export CONTAINER=new_bed

docker run -d \
	--name $CONTAINER \
	--publish=$BED_HTTP_PORT:7474 \
	--publish=$BED_BOLT_PORT:7687 \
	--env=NEO4J_dbms_memory_heap_initial__size=16G \
	--env=NEO4J_dbms_memory_heap_max__size=16G \
	--env=NEO4J_dbms_query__cache__size=0 \
	--env=NEO4J_AUTH=none \
	--env=NEO4J_dbms_directories_import=import \
	--volume $BED_IMPORT:/var/lib/neo4j/import \
	--volume $BED_DATA/data:/data \
	neo4j:$NJ_VERSION
