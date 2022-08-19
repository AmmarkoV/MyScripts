#!/bin/bash

#ffmpeg -i left.avi -i right.avi -filter_complex hstack -c:v ffv1 output.avi
#stereo_mode=1


#ffmpeg -i left.mp4 -vf "lenscorrection=0.5:0.5:-0.335:0.097" -c:v libx264 -crf 18 -y leftC.mp4
#ffmpeg -i right.mp4 -vf "lenscorrection=0.5:0.5:-0.335:0.097" -c:v libx264 -crf 18 -y rightC.mp4

#ffmpeg -i left.mp4 -i right.mp4 -filter_complex "vstack,format=yuv420p" -c:v libx264 -crf 18  -vcodec libx264 -x264opts "frame-packing=3" vr180.mp4



#ffmpeg -i leftC.mp4 -i rightC.mp4 -filter_complex "hstack,format=yuv420p" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=left_right -y vr180.mkv
#https://github.com/Vargol/spatial-media

#sudo apt install mkvtoolnix

ffmpeg -i lMOVI0007.avi -i rMOVI0007.avi -filter_complex "hstack,format=yuv420p" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=left_right -y vr180.mkv

mkvmerge --output y2bVR.mkv  --projection-type 0:1 --projection-private 0:0x000000000x000000000x000000000x3fffffff0x3fffffff  --stereo-mode 0:side_by_side_left_first vr180.mkv 


#ffmpeg -i leftC.mp4 -i rightC.mp4 -filter_complex "vstack,format=yuv420p" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=top_bottom -y vr180.mkv


exit 0
