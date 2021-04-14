#!/bin/bash
 
adb shell ls /mnt/sdcard/Oculus/VideoShots/*.mp4 | tr '\r' ' ' | xargs -n1 adb pull  


exit 0
