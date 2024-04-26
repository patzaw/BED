#/bin/bash

### usage: sh S02-Rebuild-BED.sh [instance_folder]
###
### Add quarto and pandoc to your path; for example add in your .bashrc:
###   export PATH=$PATH:/usr/lib/rstudio-server/bin/quarto/bin:/usr/lib/rstudio-server/bin/quarto/bin/tools

if test -z "$1"; then
   echo "Provide a directory with build_config.json and Rebuild-BED.Rmd files" >&2
   exit
fi

export CONFIG_FILE=$1/build_config.json

if ! test -e $CONFIG_FILE; then
   echo "Cannot find $CONFIG_FILE file" >&2
   exit
fi

export REBUILD_FILE=$1/Rebuild-BED.Rmd

if ! test -e $REBUILD_FILE; then
   echo "Cannot find $REBUILD_FILE file" >&2
   exit
fi

R -e "rmarkdown::render('$REBUILD_FILE')";
