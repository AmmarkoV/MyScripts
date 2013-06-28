#!/bin/bash

mkdir pnm 

FILES=./*
COLORCOUNTER=0
DEPTHCOUNTER=0
for f in $FILES
do
 FILENAMENOEXT=`
     FULL_FILENAME=$f 
     FILENAME=${FULL_FILENAME##*/}
     echo ${FILENAME%%.*}`

     echo "Processing $FILENAMENOEXT file..." 


    ISITACOLORFRAME=`echo $f | grep "8492037-01"` 
     if [ -n "$ISITACOLORFRAME" ] 
      then
       file2=${FILENAMENOEXT/"8492037-01"/"colorFrame_0"}
       convert $FILENAMENOEXT.png  pnm/$file2.pnm
       COLORCOUNTER=$[$COLORCOUNTER +1] 
     fi

    ISITADEPTHFRAME=`echo $f | grep "8492037-00"` 
     if [ -n "$ISITADEPTHFRAME" ] 
      then
       file2=${FILENAMENOEXT/"8492037-00"/"depthFrame_0"}
       convert $FILENAMENOEXT.png  pnm/$file2.pnm
       DEPTHCOUNTER=$[$DEPTHCOUNTER +1] 
     fi


done
 
exit 0
