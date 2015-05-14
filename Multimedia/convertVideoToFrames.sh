#!/bin/bash

ffmpeg -i $1  -r 30 -q:v 1 colorFrame_0_%05d.jpg
 
exit 0
