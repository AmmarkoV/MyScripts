#!/bin/bash

ffmpeg -f pulse -i default -f x11grab -framerate 30 -video_size 1680x1050 -i :0.0+0,0 -c:v libx264 -preset veryfast -maxrate 3000k -bufsize 3000k -vf "scale=1280:-1,format=yuv420p" -g 60 -c:a libvo_aacenc -b:a 128k -ar 44100 -f flv rtmp://a.rtmp.youtube.com/live2/


exit 0
