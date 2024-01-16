#/bin/bash

export BED_VERSION=2024.01.14
export NJ_VERSION=5.15.0
export BED_DATA=`pwd`/../../../working/neo4jData
export BED_DUMPS=`pwd`/../../../BED-dumps

# Stop container
export CONTAINER=new_bed
docker stop $CONTAINER

export BED_BACKUPS=`pwd`/../../../working/neo4jDump
mkdir -p $BED_BACKUPS

docker run --interactive --tty --rm \
   --volume=$BED_DATA/data:/data \
   --volume=$BED_BACKUPS:/backups \
   neo4j/neo4j-admin:$NJ_VERSION \
neo4j-admin database dump neo4j --to-path=/backups

# sudo chown -R pgodard:pgodard ../../../working/neo4jDump/
cp ../../../working/neo4jDump/neo4j.dump $BED_DUMPS/dump-bed-ucb-human-$BED_VERSION.dump
