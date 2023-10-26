#!/bin/bash

#sudo pluma /etc/ImageMagick-6/policy.xml
#increase 
#   <policy domain="resource" name="memory" value="4256MiB"/>
# <!-- <policy domain="system" name="max-memory-request" value="4256MiB"/> -->
 #-vf scale="720:-1" -t 00:00:23
ffmpeg -i $1  -r 6 -pix_fmt rgb24 "$2-temp.gif"  
convert -limit memory 4GiB -layers Optimize "$2-temp.gif" "$2.gif"
rm "$2-temp.gif"


exit 0
