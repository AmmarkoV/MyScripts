#!/bin/bash
 
#adb tcpip 5555
#adb connect OCULUS_IP_HERE

adb shell ls /mnt/sdcard/Oculus/VideoShots/*.mp4 | tr '\r' ' ' | xargs -n1 adb pull  


exit 0
