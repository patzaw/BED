#/bin/bash

export BED_VERSION=2023.02.11
export DOCKER_ID_USER="patzaw"

docker login
docker tag bed-ucb-human:$BED_VERSION $DOCKER_ID_USER/bed-ucb-human:$BED_VERSION
docker tag $DOCKER_ID_USER/bed-ucb-human:$BED_VERSION $DOCKER_ID_USER/bed-ucb-human:latest
docker push $DOCKER_ID_USER/bed-ucb-human:$BED_VERSION
docker push $DOCKER_ID_USER/bed-ucb-human:latest
