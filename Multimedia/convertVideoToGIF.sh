#!/bin/bash

#sudo pluma /etc/ImageMagick-6/policy.xml
#increase 
#   <policy domain="resource" name="memory" value="4256MiB"/>
# <!-- <policy domain="system" name="max-memory-request" value="4256MiB"/> -->
 #
ffmpeg -i $1 -r 6  -filter:v "crop=1920:400:0:0" -vf scale="640:-1" -ss 00:00:0 -t 00:00:39   -pix_fmt rgb24 "$2-temp.gif"  
#convert -limit memory 4GiB -layers Optimize "$2-temp.gif" "$2.gif"
#rm "$2-temp.gif"


exit 0
