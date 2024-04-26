#!/bin/sh

### usage: sh S11-Push-on-Zenodo.sh [instance_folder]

if test -z "$1"; then
   echo "Provide a directory with build_config.json file" >&2
   exit
fi

export CONFIG_FILE=$1/build_config.json

if ! test -e $CONFIG_FILE; then
   echo "Cannot find $CONFIG_FILE file" >&2
   exit
fi

## Taken from https://github.com/jhpoelen/zenodo-upload
##
## Relies on https://jqlang.github.io/jq/:
##    wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -O ~/Downloads/jq-linux-amd64
##    chmod u+x ~/Downloads/jq-linux-amd64
##    ln -s ~/Downloads/jq-linux-amd64 ~/bin/jq
##

export BED_INSTANCE=$(jq -r '.BED_INSTANCE' $CONFIG_FILE)
export BED_VERSION=$(jq -r '.BED_VERSION' $CONFIG_FILE)

export WF_ROOT=`echo $(jq -r '.ROOT' $CONFIG_FILE) | sed s#___HOME___#$HOME#`
export BED_DUMPS=`echo $(jq -r '.BED_DUMPS' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`

export ZENODO_RECORD=$(jq -r '.ZENODO_RECORD' $CONFIG_FILE)

if test "$ZENODO_RECORD"=="null"; then
   echo "No Zenodo record in the $CONFIG_FILE file" >&2
   exit
fi

export ZENODO_TOKEN=$(cat ~/.zenodo.token)

if test -z "$ZENODO_TOKEN"; then
   echo "No Zenodo token: check ~/.zenodo.token file" >&2
   exit
fi

export DUMP_FILE=$BED_DUMPS/dump_bed_${BED_INSTANCE}_${BED_VERSION}.dump

if ! test -e $DUMP_FILE; then
   echo "Cannot find $DUMP_FILE file" >&2
   exit
fi

export H_DIR=$(dirname $0)/helpers

$H_DIR/zenodo_upload.sh $ZENODO_RECORD $DUMP_FILE -v

