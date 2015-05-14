#!/bin/bash

ffmpeg -i $1  -r 30 colorFrame_0_%05d.jpg
 
exit 0
