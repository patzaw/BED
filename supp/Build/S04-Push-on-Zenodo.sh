#!/bin/sh

## Taken from https://github.com/jhpoelen/zenodo-upload
##
## Relies on https://jqlang.github.io/jq/:
##    wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -O ~/Downloads/jq-linux-amd64
##    chmod u+x ~/Downloads/jq-linux-amd64
##    ln -s ~/Downloads/jq-linux-amd64 ~/bin/jq
##

export BED_VERSION=2024.01.14

ZENODO_RECORD=10521413

export ZENODO_TOKEN=$(cat ~/.zenodo.token)
./helpers/zenodo_upload.sh $ZENODO_RECORD ../../../BED-dumps/dump-bed-ucb-human-$BED_VERSION.dump -v

