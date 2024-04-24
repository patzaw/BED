#/bin/bash

export BED_INSTANCE=$(jq -r '.BED_INSTANCE' build_config.json)
export BED_VERSION=$(jq -r '.BED_VERSION' build_config.json)

export NJ_VERSION=$(jq -r '.NJ_VERSION' build_config.json)
export NJ_HTTP_PORT=$(jq -r '.NJ_HTTP_PORT' build_config.json)
export NJ_BOLT_PORT=$(jq -r '.NJ_BOLT_PORT' build_config.json)

export NJ_INIT_HEAP=$(jq -r '.NJ_INIT_HEAP' build_config.json)
export NJ_MAX_HEAP=$(jq -r '.NJ_MAX_HEAP' build_config.json)
export NJ_PAGE_CACHE=$(jq -r '.NJ_PAGE_CACHE' build_config.json)
export NJ_QUERY_CACHE=$(jq -r '.NJ_QUERY_CACHE' build_config.json)
export NJ_REPLAN_INT=$(jq -r '.NJ_REPLAN_INT' build_config.json)
export NJ_DIV_THR=$(jq -r '.NJ_DIV_THR' build_config.json)

export CONTAINER=$(jq -r '.CONTAINER' build_config.json)

export WF_ROOT=`echo $(jq -r '.ROOT' build_config.json) | sed s#___HOME___#$HOME#`
export BED_DATA=`echo $(jq -r '.BED_DATA' build_config.json) | sed s#___ROOT___#$WF_ROOT#`
export BED_DUMPS=`echo $(jq -r '.BED_DUMPS' build_config.json) | sed s#___ROOT___#$WF_ROOT#`
export BED_BACKUPS=`echo $(jq -r '.BED_BACKUPS' build_config.json) | sed s#___ROOT___#$WF_ROOT#`

## Stop container
docker stop $CONTAINER

mkdir -p $BED_BACKUPS

## Create the backup
docker run --interactive --tty --rm \
   --volume=$BED_DATA/data:/data \
   --volume=$BED_BACKUPS:/backups \
   neo4j/neo4j-admin:$NJ_VERSION \
neo4j-admin database dump neo4j --to-path=/backups

## Copy and rename
cp $BED_BACKUPS/neo4j.dump $BED_DUMPS/dump_bed_${BED_INSTANCE}_${BED_VERSION}.dump
