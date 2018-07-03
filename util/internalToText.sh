#!/usr/bin/env bash

error=$1

if [[ ${#error} != 7 ]] ; then
  echo "Argument should be 7 characters long"
  exit 1
fi

filepart=`echo $error | cut -c1-3`
linepart=`echo $error | cut -c4-7`

for match in `find $CHPL_HOME/compiler -iname "$filepart*.*"` ; do
  sed -e "${linepart}q;d" $match | grep INT | sed -e "s;^ *;`basename $match`:$linepart: ;"
done
