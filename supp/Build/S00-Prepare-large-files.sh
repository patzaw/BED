#/bin/bash

### usage: sh S02-Rebuild-BED.sh [instance_folder]

if test -z "$1"; then
   echo "Provide a directory with build_config.json and prepare-files.R files" >&2
   exit
fi

export CONFIG_FILE=$1/build_config.json

if ! test -e $CONFIG_FILE; then
   echo "Cannot find build_config.json file" >&2
   exit
fi

export PREPARE_FILE=$1/prepare-files.R

if ! test -e $PREPARE_FILE; then
   echo "Cannot find $PREPARE_FILE file" >&2
   exit
fi

export WF_ROOT=`echo $(jq -r '.ROOT' $CONFIG_FILE) | sed s#___HOME___#$HOME#`
export BED_WORKING=`echo $(jq -r '.BED_WORKING' $CONFIG_FILE) | sed s#___ROOT___#$WF_ROOT#`
mkdir -p $BED_WORKING

R -e "config_file='$CONFIG_FILE'; source('$PREPARE_FILE')";
