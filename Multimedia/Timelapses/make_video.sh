#!/bin/bash 

  avconv -i CONVERTED/image_%05d.jpg -r 15 -threads 8 -b 30000k -s 1631x1080  outHD.mp4 

exit 0

