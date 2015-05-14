#!/bin/bash

ffmpeg -i $1  -r 30 colorFrame%05d.jpg
 
exit 0
