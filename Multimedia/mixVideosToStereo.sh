#!/bin/bash

#ffmpeg -i left.avi -i right.avi -filter_complex hstack -c:v ffv1 output.avi
#stereo_mode=1


#ffmpeg -i left.mp4 -vf "lenscorrection=0.5:0.5:-0.335:0.097" -c:v libx264 -crf 18 -y leftC.mp4
#ffmpeg -i right.mp4 -vf "lenscorrection=0.5:0.5:-0.335:0.097" -c:v libx264 -crf 18 -y rightC.mp4

#ffmpeg -i left.mp4 -i right.mp4 -filter_complex "vstack,format=yuv420p" -c:v libx264 -crf 18  -vcodec libx264 -x264opts "frame-packing=3" vr180.mp4



#ffmpeg -i leftC.mp4 -i rightC.mp4 -filter_complex "hstack,format=yuv420p" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=left_right -y vr180.mkv
#https://github.com/Vargol/spatial-media

#sudo apt install mkvtoolnix

#ffmpeg -i left/MOVI0002.avi  -filter:v "crop=1280:690:0:30"  -y l.avi
#ffmpeg -i right/MOVI0002.avi -filter:v "crop=1280:690:0:0"   -y r.avi 
#ffmpeg -i l.avi -i r.avi  -filter_complex "hstack,format=yuv420p" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=left_right -y vr180.mkv

#ffplay -i left/MOVI0003.avi -vf "eq=contrast=1.5:brightness=-0.05:saturation=0.75"


#ffmpeg -i left/MOVI0003.avi  -filter_complex "[0:v]hqdn3d=0:0:8:8[up]; [up]eq=contrast=1.2:brightness=-0.05:saturation=1.25[out]" -map [out] -y -c:v libx264 -pix_fmt yuv420p -threads 0 l.mp4


#Denoise :
#-vf nlmeans=h=10:range=5:temporal=3
#-vf atadenoise=s=7:p=7:0a=0:0b=0:1a=0:1b=0:2a=0:2b=0
#-vf hqdn3d=0:0:8:8
#-vf vaguedenoiser=2:2:6:85:15

FILE="MOVI0018.avi"
VERTICALCROP="40"
ffmpeg -i left/$FILE -i right/$FILE -filter_complex "[0:v]hqdn3d=0:0:8:8[l1]; [l1]eq=contrast=1.2:brightness=-0.05:saturation=1.25[l2]; [l2]crop=in_w:in_h-$VERTICALCROP:0:$VERTICALCROP[l3]; [l3]scale=900:in_h-$VERTICALCROP[l4]; [1:v]hqdn3d=0:0:8:8[r1]; [r1]eq=contrast=1.2:brightness=-0.05:saturation=1.25[r2]; [r2]crop=in_w:in_h-$VERTICALCROP:0:0[r3];[r3]scale=900:in_h-$VERTICALCROP[r4];[l4][r4]hstack,format=yuv420p"  -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=left_right -y -threads 0 c$FILE.mkv


#--projection-type TID:method 	
#Sets the video projection method used. Valid values are 0 (rectangular projection), 1 (equirectangular projection), 2 (cubemap projection) and 3 (mesh projection).
#--projection-private TID:data 	
#Sets private data that only applies to a specific projection. Data must be given as hex numbers with or without the "0x" prefix, with or without spaces. 

mkvmerge --output y2bVR.mkv  --projection-type 0:0 --projection-private 0:0x000000000x000000000x000000000x3fffffff0x3fffffff  --stereo-mode 0:side_by_side_left_first c$FILE.mkv 


#ffmpeg -i leftC.mp4 -i rightC.mp4 -filter_complex "vstack,format=yuv420p" -c:v libx264 -crf 18 -metadata:s:v:0 stereo_mode=top_bottom -y vr180.mkv


exit 0
