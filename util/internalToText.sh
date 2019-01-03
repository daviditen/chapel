#!/usr/bin/env bash

error=$1
#PAS-NOR-IZE-0141
if [[ ${#error} != 16 ]] ; then
  echo "Argument should be 16 characters long"
  exit 1
fi

dirpart=`echo $error | cut -c1-3 | tr '[:upper:]' '[:lower:]'`
filepart1=`echo $error | cut -c5-7`
filepart2=`echo $error | cut -c9-11`
linepart=`echo $error | cut -c13-16`

for match in `find $CHPL_HOME/compiler/$dirpart* -depth 1 -iname "$filepart1*$filepart2.*"` ; do
  sed -e "${linepart}q;d" $match | grep INT | sed -e "s;^ *;`basename $match`:$linepart: ;"
done
