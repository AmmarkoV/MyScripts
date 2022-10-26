#!/bin/bash

ffmpeg -i $1 -ss 00:01:22 -t 00:04:00 -async 1 -strict -2  -vf vidstabtransform,unsharp=5:5:0.8:3:3:0.4 -vf "transpose=1"  out-$1

#For the transpose parameter you can pass:

#0 = 90CounterCLockwise and Vertical Flip (default)
#1 = 90Clockwise
#2 = 90CounterClockwise
#3 = 90Clockwise and Vertical Flip

exit 0
