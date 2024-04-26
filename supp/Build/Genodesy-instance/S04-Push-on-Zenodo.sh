#!/bin/sh

## Taken from https://github.com/jhpoelen/zenodo-upload
##
## Relies on https://jqlang.github.io/jq/:
##    wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -O ~/Downloads/jq-linux-amd64
##    chmod u+x ~/Downloads/jq-linux-amd64
##    ln -s ~/Downloads/jq-linux-amd64 ~/bin/jq
##

export BED_INSTANCE=$(jq -r '.BED_INSTANCE' build_config.json)
export BED_VERSION=$(jq -r '.BED_VERSION' build_config.json)

export WF_ROOT=`echo $(jq -r '.ROOT' build_config.json) | sed s#___HOME___#$HOME#`
export BED_DUMPS=`echo $(jq -r '.BED_DUMPS' build_config.json) | sed s#___ROOT___#$WF_ROOT#`

export ZENODO_RECORD=$(jq -r '.ZENODO_RECORD' build_config.json)
export ZENODO_TOKEN=$(cat ~/.zenodo.token)

export H_DIR=$(dirname $0)/../helpers
$H_DIR/zenodo_upload.sh $ZENODO_RECORD $BED_DUMPS/dump_bed_${BED_INSTANCE}_${BED_VERSION}.dump -v

