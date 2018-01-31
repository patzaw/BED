#/bin/bash

export NP=$1

$NP/bin/neo4j stop
zip -r $NP-`date +%Y-%m-%d-%s`.zip $NP
rm -rf $NP
