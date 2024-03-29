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

#ffmpeg -y -i argaleios.mp4 -r 5 -vf scale="720:-1" -ss 00:00:10  -t 00:00:23 -pix_fmt rgb8 argaleios.gif
#    rescale            start       duration 
#-vf scale="720:-1" -ss 00:00:10 -t 00:00:23
ffmpeg -i $1  -y -r 6 -pix_fmt rgb8 "$2-temp.gif"  
convert -limit memory 4GiB -layers Optimize "$2-temp.gif" "$2.gif"
rm "$2-temp.gif"


exit 0
