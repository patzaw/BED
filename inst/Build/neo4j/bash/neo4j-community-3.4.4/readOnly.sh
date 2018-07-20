#/bin/bash

export NP=$1

$NP/bin/neo4j stop
echo 'dbms.read_only=true' >> $NP/conf/neo4j.conf
$NP/bin/neo4j start
sleep 20
