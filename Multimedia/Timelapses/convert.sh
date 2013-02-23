#!/bin/bash
echo "This will resize all jpg images in INPUT_IMAGES directory to CONVERTED directory and rename them according to their input order..!"

if [ -d "INPUT_IMAGES" ]; then
  echo "Found INPUT_IMAGES directory"
  #remove placeholder file :P
  rm INPUT_IMAGES/placeholder
else
  echo "Error : Could not find INPUT_IMAGES directory" 
  exit 1
fi


if [ -d "CONVERTED" ]; then
  echo "Found CONVERTED directory"
  #remove placeholder file :P
  rm CONVERTED/placeholder
else
  echo "Error : Could not find CONVERTED directory" 
  exit 1
fi

  
count=1
for i in INPUT_IMAGES/*; do  
  outname="CONVERTED/`printf image_%05d.jpg $count`"
  echo "Processing image $i output is $outname " ; 

  convert -size 1631x1080 $i -resize 1631x1080 $outname;
  count=$((count + 1))
done 

echo "Done .."

exit 0

