#!/bin/bash

ADBAPP="adb"

cd DCIM/Camera

sudo $ADBAPP shell ls /sdcard/DCIM/Camera/*.mp4 | tr '\r' ' ' | xargs -n1 sudo $ADBAPP pull  
 sudo $ADBAPP shell ls /sdcard/DCIM/Camera/*.jpg | tr '\r' ' ' | xargs -n1 sudo $ADBAPP pull  


exit 0

exit 0
