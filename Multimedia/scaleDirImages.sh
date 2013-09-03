#!/bin/bash

mkdir small 

FILES=./*
COUNTER=0
for f in $FILES
do
 FILENAMENOEXT=`
     FULL_FILENAME=$f 
     FILENAME=${FULL_FILENAME##*/}
     echo ${FILENAME%%.*}`

     echo "Processing $FILENAMENOEXT file..." 

     convert $f -resize "1024x768>^"  small/$FILENAMENOEXT.jpg
done
 
exit 0
