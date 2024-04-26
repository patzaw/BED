#!/bin/sh

### usage: sh S01-NewBED-Container.sh [instance_folder]

if test -z "$1"; then
   echo "Provide a directory with build_config.json file" >&2
   exit
fi

export CONFIG_FILE=$1/build_config.json

if ! test -e $CONFIG_FILE; then
   echo "Cannot find $CONFIG_FILE file" >&2
   exit
fi

export NJ_VERSION=$(jq -r '.NJ_VERSION' $CONFIG_FILE)
export NJ_HTTP_PORT=$(jq -r '.NJ_HTTP_PORT' $CONFIG_FILE)
export NJ_BOLT_PORT=$(jq -r '.NJ_BOLT_PORT' $CONFIG_FILE)

export NJ_INIT_HEAP=$(jq -r '.NJ_INIT_HEAP' $CONFIG_FILE)
export NJ_MAX_HEAP=$(jq -r '.NJ_MAX_HEAP' $CONFIG_FILE)
export NJ_PAGE_CACHE=$(jq -r '.NJ_PAGE_CACHE' $CONFIG_FILE)
export NJ_QUERY_CACHE=$(jq -r '.NJ_QUERY_CACHE' $CONFIG_FILE)
export NJ_REPLAN_INT=$(jq -r '.NJ_REPLAN_INT' $CONFIG_FILE)
export NJ_DIV_THR=$(jq -r '.NJ_DIV_THR' $CONFIG_FILE)

export CONTAINER=$(jq -r '.CONTAINER' $CONFIG_FILE)

export WF_ROOT=`echo $(jq -r '.ROOT' $CONFIG_FILE) | sed s#___HOME___#$HOME#`
export BED_IMPORT=`echo $(jq -r '.BED_IMPORT' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`
export BED_DATA=`echo $(jq -r '.BED_DATA' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`

mkdir -p $BED_IMPORT
if test -e $BED_DATA; then
   echo "$BED_DATA directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
mkdir $BED_DATA

docker run -d \
	--name $CONTAINER \
	--publish=$NJ_HTTP_PORT:7474 \
	--publish=$NJ_BOLT_PORT:7687 \
   --env=NEO4J_dbms_memory_heap_initial__size=$NJ_INIT_HEAP \
   --env=NEO4J_dbms_memory_heap_max__size=$NJ_MAX_HEAP \
   --env=NEO4J_dbms_memory_pagecache_size=$NJ_PAGE_CACHE \
   --env=NEO4J_dbms_query__cache__size=$NJ_QUERY_CACHE \
   --env=NEO4J_cypher_min__replan__interval=$NJ_REPLAN_INT \
   --env=NEO4J_cypher_statistics__divergence__threshold=$NJ_DIV_THR \
	--env=NEO4J_AUTH=none \
	--env=NEO4J_dbms_directories_import=import \
	--volume $BED_IMPORT:/var/lib/neo4j/import \
	--volume $BED_DATA/data:/data \
   --volume $BED_DATA/logs:/var/lib/neo4j/logs \
	neo4j:$NJ_VERSION

sleep 20
uid=`id -u`
gid=`id -g`
sudo chown $uid:$gid $BED_IMPORT
chmod a+rx $BED_IMPORT
