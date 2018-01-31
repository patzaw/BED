#/bin/bash

export NV=$1
export NP=$2

cp -R neo4j/install/$NV $NP
cp neo4j/files/$NV/neo4j.conf $NP/conf/
mkdir -p $NP/data/dbms/
cp neo4j/files/$NV/auth $NP/data/dbms/
