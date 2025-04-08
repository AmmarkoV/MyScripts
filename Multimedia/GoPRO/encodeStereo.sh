#!/bin/bash

#sudo apt install mkvtoolnix ffmpeg


FILE="GX010005.MP4"
VERTICALCROP="40"

ffmpeg -i left/$FILE -i right/$FILE -filter_complex "\
[0:v]transpose=1,hqdn3d=0:0:8:8,eq=contrast=1.2:brightness=-0.05:saturation=1.25,\
     crop=in_w:in_h-$VERTICALCROP:0:$VERTICALCROP[l]; \
[1:v]transpose=1,hqdn3d=0:0:8:8,eq=contrast=1.2:brightness=-0.05:saturation=1.25,\
     crop=in_w:in_h-$VERTICALCROP:0:$VERTICALCROP[r]; \
[l][r]hstack=inputs=2,format=yuv420p[v]" \
-map "[v]" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=left_right -y -threads 0 c$FILE.mkv


mkvmerge --output y2bVR.mkv \
  --projection-type 0:0 \
  --projection-private 0:0x000000000x000000000x000000000x3fffffff0x3fffffff \
  --stereo-mode 0:side_by_side_left_first \
  c$FILE.mkv


exit 0
