#!/bin/bash

ffmpeg -i GOPR3976.MP4 -ss 00:01:22 -t 00:04:00 -async 1 -strict -2 -vf vidstabdetect=stepsize=32:shakiness=10:accuracy=10:result=transforms.trf -f null -
ffmpeg -y -i GOPR3976.MP4 -ss 00:01:22 -t 00:04:00 -async 1 -strict -2 -vf vidstabtransform=input=transforms.trf:zoom=0:smoothing=10,unsharp=5:5:0.8:3:3:0.4 -vcodec libx264 -tune film -acodec copy -preset slow -vf "transpose=2"  output.mp4

ffmpeg -i $1 -ss 00:01:22 -t 00:04:00 -async 1 -strict -2  -vf vidstabtransform,unsharp=5:5:0.8:3:3:0.4 -vf "transpose=2"  out-$1

#For the transpose parameter you can pass:

#0 = 90CounterCLockwise and Vertical Flip (default)
#1 = 90Clockwise
#2 = 90CounterClockwise
#3 = 90Clockwise and Vertical Flip

exit 0
