#/bin/bash

export NP=$1

$NP/bin/neo4j stop
echo 'read_only=true' >> $NP/conf/neo4j.properties
$NP/bin/neo4j start
sleep 10
