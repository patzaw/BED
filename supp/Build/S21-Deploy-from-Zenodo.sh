#!/bin/sh

### usage: sh S12-Deploy-from-Zenodo.sh [instance_folder]

####################################################@
## Config ----

if test -z "$1"; then
   echo "Provide a directory with deploy_config.json file" >&2
   exit
fi

export CONFIG_FILE=$1/deploy_config.json

if ! test -e $CONFIG_FILE; then
   echo "Cannot find $CONFIG_FILE file" >&2
   exit
fi

export NJ_VERSION=$(jq -r '.NJ_VERSION' $CONFIG_FILE)
export NJ_HTTP_PORT=$(jq -r '.NJ_HTTP_PORT' $CONFIG_FILE)
export NJ_BOLT_PORT=$(jq -r '.NJ_BOLT_PORT' $CONFIG_FILE)

export BED_INSTANCE=$(jq -r '.BED_INSTANCE' $CONFIG_FILE)
export BED_VERSION=$(jq -r '.BED_VERSION' $CONFIG_FILE)
export BED_NEW_INSTANCE=$(jq -r '.BED_NEW_INSTANCE' $CONFIG_FILE)

export NJ_INIT_HEAP=$(jq -r '.NJ_INIT_HEAP' $CONFIG_FILE)
export NJ_MAX_HEAP=$(jq -r '.NJ_MAX_HEAP' $CONFIG_FILE)
export NJ_PAGE_CACHE=$(jq -r '.NJ_PAGE_CACHE' $CONFIG_FILE)

export CONTAINER=$(jq -r '.CONTAINER' $CONFIG_FILE)

export ZENODO_RECORD=$(jq -r '.ZENODO_RECORD' $CONFIG_FILE)

if test "$ZENODO_RECORD" = "null"; then
   echo "No Zenodo record in the $CONFIG_FILE file" >&2
   exit
fi

export WF_ROOT=`echo $(jq -r '.ROOT' $CONFIG_FILE) | sed s#___HOME___#$HOME#`
export BED_DUMPS=`echo $(jq -r '.BED_DUMPS' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`
export BED_DATA=`echo $(jq -r '.BED_DATA' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`

export BED_IMPORT=`echo $(jq -r '.BED_IMPORT' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`

####################################################@
## Check folders ----
if test -e $BED_DATA; then
   echo "$BED_DATA directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
mkdir -p $BED_DATA

if test "$2" != "--use-existing-dump" && test -e $BED_DUMPS; then
   echo "$BED_DUMPS directory exists ==> abort - Remove it before proceeding" >&2
   exit
fi
mkdir -p $BED_DUMPS

####################################################@
## Download data ----
export BED_REP_URL=https://zenodo.org/records/$ZENODO_RECORD/files/
if ! test -e $BED_DUMPS/neo4j.dump; then
   wget $BED_REP_URL/dump_bed_${BED_INSTANCE}_${BED_VERSION}.dump -O $BED_DUMPS/neo4j.dump
fi

####################################################@
## Import data ----
docker run --interactive --tty --rm \
   --volume=$BED_DATA/data:/data \
   --volume=$BED_DUMPS:/backups \
    neo4j:$NJ_VERSION \
neo4j-admin database load neo4j --from-path=/backups

####################################################@
## Additional data ----
if test "$BED_NEW_INSTANCE" != "null" && test "$BED_IMPORT" != "null"; then

   docker run -d \
      --name ${CONTAINER}_${BED_VERSION} \
      --publish=$NJ_HTTP_PORT:7474 \
      --publish=$NJ_BOLT_PORT:7687 \
      --env=NEO4J_dbms_memory_heap_initial__size=$NJ_INIT_HEAP \
      --env=NEO4J_dbms_memory_heap_max__size=$NJ_MAX_HEAP \
      --env=NEO4J_dbms_memory_pagecache_size=$NJ_PAGE_CACHE \
      --env=NEO4J_dbms_read__only=false \
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

   cd $1

   R -e '
      library(BED)
      library(jsonlite)
      config <- jsonlite::read_json("deploy_config.json")
      connectToBed(
         url=sprintf("localhost:%s", config$NJ_HTTP_PORT),
         remember=FALSE,
         useCache=TRUE,
         importPath=config$BED_IMPORT
      )
      bedInstance <- config$BED_NEW_INSTANCE
      bedVersion <- config$BED_VERSION
      BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
   '

   if test -e additional-data.R ; then
      Rscript additional-data.R
   fi

   cd -

   docker stop ${CONTAINER}_${BED_VERSION}
   docker rm ${CONTAINER}_${BED_VERSION}

fi


####################################################@
## Start neo4j ----
docker run -d \
   --name ${CONTAINER}_${BED_VERSION} \
   --publish=$NJ_HTTP_PORT:7474 \
   --publish=$NJ_BOLT_PORT:7687 \
   --env=NEO4J_dbms_memory_heap_initial__size=$NJ_INIT_HEAP \
   --env=NEO4J_dbms_memory_heap_max__size=$NJ_MAX_HEAP \
   --env=NEO4J_dbms_memory_pagecache_size=$NJ_PAGE_CACHE \
   --env=NEO4J_dbms_read__only=true \
   --env=NEO4J_AUTH=none \
   --volume $BED_DATA/data:/data \
   --volume $BED_DATA/logs:/var/lib/neo4j/logs \
   --restart=always \
   neo4j:$NJ_VERSION

