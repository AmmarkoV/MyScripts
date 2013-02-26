#!/bin/bash

CURRENTDIR=`pwd`
echo "Switching to $1 dir"
cd $1
find -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.jpeg" -o -exec 7z x "{}" -o/tmp/ \;
cd $CURRENTDIR


exit 0
