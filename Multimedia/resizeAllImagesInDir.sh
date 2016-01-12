#!/bin/bash
echo "This will resize all jpg images in INPUT_IMAGES directory to CONVERTED directory and rename them according to their input order..!"
 
RESIZEDDIR="resized"
INDIR=`pwd`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"
 

if [ -d "$RESIZEDDIR/" ]; then
  echo "Found Resized directory"
else
  echo "Error : Could not find CONVERTED directory" 
  mkdir  $RESIZEDDIR
fi

echo "DIR IS : "
pwd
rm $RESIZEDDIR/*.jpg
   
totalCount=`ls | grep JPG | wc -l` 
FILES_TO_CONVERT=`ls | grep JPG`
count=1
for i in $FILES_TO_CONVERT
do  
  #outname="$RESIZEDDIR/`printf image_%05d.jpg $count`"
  basename=`basename $i .JPG`
  outname="$RESIZEDDIR/$basename.JPG"
  echo "Processing image $i output is $outname $count / $totalCount" ; 

  convert -size 1920x1080 $i -resize 1920x1080 $outname;
  count=$((count + 1))
done 

echo "Compressing"
zip -r $RESIZEDDIR.zip $RESIZEDDIR 

echo "Done .."

cd $INDIR

exit 0

