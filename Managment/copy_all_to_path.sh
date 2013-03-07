#!/bin/bash
 
CURDIR=`pwd` 
 
files=`ls | grep "$1"`
while read -r everyfile; do
   ln -s "$CURDIR/$everyfile" "$2/$everyfile"
   #echo "$CURDIR/$everyfile $2/$everyfile" 
done <<< "$files"



exit 0

#files=(*$1)
#for everyfile in "${files[@]}"; do 
   #ln -s "$CURDIR/$everyfile" "$2/$everyfile"
#  echo "$CURDIR/$everyfile $2/$everyfile" 
#done
  

#exit 0
