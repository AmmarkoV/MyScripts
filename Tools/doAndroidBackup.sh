#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

ADBAPP="adb"

#mkdir -p DCIM/Camera
#cd DCIM/Camera
#sudo $ADBAPP shell ls /sdcard/DCIM/Camera/*.mp4 | tr '\r' ' ' | xargs -n1 sudo $ADBAPP pull  
#sudo $ADBAPP shell ls /sdcard/DCIM/Camera/*.jpg | tr '\r' ' ' | xargs -n1 sudo $ADBAPP pull  
#cd "$DIR"
#sudo chown ammar:ammar -R DCIM/Camera/

#We will sync all this directories from the android device to the local file system
TASKLIST="Download/X Download DCIM/Camera DCIM/100ANDRO DCIM/Facebook Plumble Pictures/Instagram Pictures/Messenger Pictures/Screenshots Pictures/mydlink Pictures/panoramas Pictures/workplace_chat bluetooth Videos Documents"
for TASK in $TASKLIST
do
  cd "$DIR"
  mkdir -p $TASK
  cd $TASK
  sudo $ADBAPP shell ls /sdcard/$TASK/* | tr '\r' ' ' | xargs -n1 sudo $ADBAPP pull  
  cd "$DIR"
  sudo chown ammar:ammar -R $TASK/
done


exit 0
