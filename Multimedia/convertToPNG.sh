#!/bin/bash

mkdir png 

FILES=./*
COUNTER=0
for f in $FILES
do
 FILENAMENOEXT=`
     FULL_FILENAME=$f 
     FILENAME=${FULL_FILENAME##*/}
     echo ${FILENAME%%.*}`

     echo "Processing $FILENAMENOEXT file..." 

     convert $FILENAMENOEXT.pnm  png/$FILENAMENOEXT.png
done
 
exit 0
