#!/bin/bash

wget http://10.5.5.9/gp/gpControl/execute?p1=gpStream&c1=restart
wget http://10.5.5.9/gp/gpControl/execute?p1=gpStream&c1=restart

python GoProStreamKeepAlive.py&

#To playback stream
ffplay -fflags nobuffer -f:v mpegts -probesize 8192 udp::8554

#To record stream
#ffmpeg  -f:v mpegts -probesize 8192 -i udp::8554 -r 20 -threads 8  -y -strict -2 recordC.mp4

exit 0
