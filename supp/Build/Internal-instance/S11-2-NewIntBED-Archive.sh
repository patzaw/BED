#!/bin/sh

export BED_VERSION=2023.08.09
export BED_DATA=`pwd`/../../../../working/neo4jDataInt
export ARCHIVE=bed_ucb_human_internal-$BED_VERSION.zip
if test -e $BED_DATA/$ARCHIVE; then
   echo "$BED_DATA/$ARCHIVE already exists ==> abort" >&2
   exit
fi
if (docker ps | grep new_int_bed) ; then
   echo "Docker container is still running ==> abort" >&2
   exit
fi
echo "$ARCHIVE will be created"

sudo rm $BED_DATA/data/databases/graph.db/neostore.transaction.db.*
cd $BED_DATA
zip -r $ARCHIVE data
cd -
