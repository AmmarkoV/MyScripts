#!/bin/bash

ffmpeg -i $1 -r 6 -pix_fmt rgb24 "$2-temp.gif" 
convert -layers Optimize "$2-temp.gif" "$2.gif"
rm "$2-temp.gif"


exit 0
