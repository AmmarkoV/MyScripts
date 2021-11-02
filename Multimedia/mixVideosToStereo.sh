#!/bin/bash

#ffmpeg -i left.avi -i right.avi -filter_complex hstack -c:v ffv1 output.avi
#stereo_mode=1

#ffmpeg -i left.mp4 -i right.mp4 -filter_complex "hstack,format=yuv420p" -c:v libx264 -crf 18  -vcodec libx264 -x264opts "frame-packing=3" vr180.mp4

ffmpeg -i left.mp4 -i right.mp4 -filter_complex "hstack,format=yuv420p" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=left_right vr180.mkv


exit 0
