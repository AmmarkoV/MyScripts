#!/bin/bash

#ffmpeg -i left.avi -i right.avi -filter_complex hstack -c:v ffv1 output.avi
#stereo_mode=1


#ffmpeg -i left.mp4 -vf "lenscorrection=0.5:0.5:-0.335:0.097" -c:v libx264 -crf 18 -y leftC.mp4
#ffmpeg -i right.mp4 -vf "lenscorrection=0.5:0.5:-0.335:0.097" -c:v libx264 -crf 18 -y rightC.mp4

#ffmpeg -i left.mp4 -i right.mp4 -filter_complex "vstack,format=yuv420p" -c:v libx264 -crf 18  -vcodec libx264 -x264opts "frame-packing=3" vr180.mp4

ffmpeg -i leftC.mp4 -i rightC.mp4 -filter_complex "hstack,format=yuv420p" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=left_right -y vr180.mkv
#ffmpeg -i leftC.mp4 -i rightC.mp4 -filter_complex "vstack,format=yuv420p" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=top_bottom -y vr180.mkv


exit 0
