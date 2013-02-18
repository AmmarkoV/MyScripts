#!/bin/bash  
for infile in "$@"; do 
  convert "$infile" -resize "1024x768>^" "$infile-resized.jpg"& 
done 
exit 0
