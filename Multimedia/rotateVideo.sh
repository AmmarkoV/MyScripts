#!/bin/bash

ffmpeg -i $1 -vf "transpose=1" $2

#For the transpose parameter you can pass:

#0 = 90CounterCLockwise and Vertical Flip (default)
#1 = 90Clockwise
#2 = 90CounterClockwise
#3 = 90Clockwise and Vertical Flip

exit 0
