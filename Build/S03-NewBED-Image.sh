#/bin/bash

export BED_VERSION=2018.10.07
export NJ_VERSION=3.4.7
export CONTAINER=new_bed
export BED_DATA=`pwd`/working/neo4jData

# Stop container
docker stop $CONTAINER

# Create and save the image
echo "FROM neo4j:$NJ_VERSION" > $BED_DATA/Dockerfile
echo "COPY data /data" >> $BED_DATA/Dockerfile
cd $BED_DATA
docker build -t bed-ucb-human:$BED_VERSION .
cd -
mkdir -p BED-images
docker save bed-ucb-human:$BED_VERSION > BED-images/docker-bed-ucb-human-$BED_VERSION.tar
