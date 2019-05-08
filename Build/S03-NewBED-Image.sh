#/bin/bash

export BED_VERSION=2019.05.08
export NJ_VERSION=3.5.5
export BED_DATA=`pwd`/working/neo4jData

# Stop container
export CONTAINER=new_bed
docker stop $CONTAINER

# Remove neostore.transaction.db. ?
echo ""
echo "Do you want to remove Neo4j transaction files [y,n]"
read rmtf
if [ $rmtf = "y" ]; then
   echo ""
	echo "DELETE: transaction files are going to be deleted using sudo privileges"
   sudo rm $BED_DATA/data/databases/graph.db/neostore.transaction.db.*
	if [ $? -eq 0 ]; then
	      echo ""
        	echo "Files deleted"
        	echo ""
	else
	      echo ""
        	echo "Cannot delete files (exit)" >&2
        	echo ""
        	exit
	fi
else
	if [ $rmtf = "n" ]; then
	   echo ""
		echo "NOT DELETE: transaction files are going to be kept"
		echo ""
	else
      echo ""
      echo "Please chose between 'y' and 'n' (exit)" >&2
      echo ""
      exit
	fi
fi

# Create and save the image
echo "FROM neo4j:$NJ_VERSION" > $BED_DATA/Dockerfile
echo "COPY data /data" >> $BED_DATA/Dockerfile
cd $BED_DATA
docker build -t bed-ucb-human:$BED_VERSION .
cd -
mkdir -p BED-images
docker save bed-ucb-human:$BED_VERSION > BED-images/docker-bed-ucb-human-$BED_VERSION.tar
