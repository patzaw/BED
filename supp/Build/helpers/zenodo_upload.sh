#!/bin/bash
##
## Taken from https://github.com/jhpoelen/zenodo-upload
##
## Upload big files to Zenodo.
##
## Relies on https://jqlang.github.io/jq/:
##    apt-get install jq
##
## OR:
##    wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -O ~/Downloads/jq-linux-amd64
##    chmod u+x ~/Downloads/jq-linux-amd64
##    ln -s ~/Downloads/jq-linux-amd64 ~/bin/jq
##
##
## usage: ./zenodo_upload.sh [deposition id] [filename] [--verbose|-v]
##

set -e

VERBOSE=0
if [ "$3" == "--verbose" ] || [ "$3" == "-v" ]; then
    VERBOSE=1
fi

# strip deposition url prefix if provided; see https://github.com/jhpoelen/zenodo-upload/issues/2#issuecomment-797657717
DEPOSITION=$( echo $1 | sed 's+^http[s]*://zenodo.org/deposit/++g' )
FILEPATH="$2"
FILENAME=$(echo $FILEPATH | sed 's+.*/++g')
FILENAME=${FILENAME// /%20}

BUCKET=$(curl https://zenodo.org/api/deposit/depositions/"$DEPOSITION"?access_token="$ZENODO_TOKEN" | jq --raw-output .links.bucket)

if [ "$VERBOSE" -eq 1 ]; then
    echo "Deposition ID: $DEPOSITION"
    echo "File path: $FILEPATH"
    echo "File name: $FILENAME"
    echo "Bucket URL: $BUCKET"
    echo "Uploading file..."
fi

curl --progress-bar \
    --retry 5 \
    --retry-delay 5 \
    -o /dev/null \
    --upload-file "$FILEPATH" \
    $BUCKET/"$FILENAME"?access_token="$ZENODO_TOKEN"
