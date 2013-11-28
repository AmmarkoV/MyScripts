#!/bin/bash

ADBAPP="adb"
sudo $ADBAPP shell ls /sdcard/DCIM/100ANDRO/*.mp4 | tr '\r' ' ' | xargs -n1 sudo $ADBAPP pull  


exit 0
