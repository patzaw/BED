#/bin/bash

### usage: sh S03-Dump-BED.sh [instance_folder]

if test -z "$1"; then
   echo "Provide a directory with build_config.json file" >&2
   exit
fi

export CONFIG_FILE=$1/build_config.json

if ! test -e $CONFIG_FILE; then
   echo "Cannot find $CONFIG_FILE file" >&2
   exit
fi

export BED_INSTANCE=$(jq -r '.BED_INSTANCE' $CONFIG_FILE)
export BED_VERSION=$(jq -r '.BED_VERSION' $CONFIG_FILE)

export NJ_VERSION=$(jq -r '.NJ_VERSION' $CONFIG_FILE)

export CONTAINER=$(jq -r '.CONTAINER' $CONFIG_FILE)

export WF_ROOT=`echo $(jq -r '.ROOT' $CONFIG_FILE) | sed s#___HOME___#$HOME#`
export BED_DATA=`echo $(jq -r '.BED_DATA' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`
export BED_DUMPS=`echo $(jq -r '.BED_DUMPS' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`
export BED_BACKUPS=`echo $(jq -r '.BED_BACKUPS' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`

## Stop container
docker stop $CONTAINER

mkdir -p $BED_BACKUPS
chmod a+w $BED_BACKUPS

## Create the backup
docker run --interactive --tty --rm \
   --volume=$BED_DATA/data:/data \
   --volume=$BED_BACKUPS:/backups \
   neo4j:$NJ_VERSION \
neo4j-admin database dump neo4j --to-path=/backups

## Copy and rename
mkdir -p $BED_DUMPS
cp $BED_BACKUPS/neo4j.dump $BED_DUMPS/dump_bed_${BED_INSTANCE}_${BED_VERSION}.dump
