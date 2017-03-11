#!/bin/bash
#sudo add-apt-repository ppa:mc3man/ffmpeg-test
#sudo apt-get update
#sudo apt-get install ffmpeg-static

ffmpeg2 -i $1 -vf vidstabdetect -f null -
ffmpeg2 -i $1 -vf vidstabdetect=show=1 dummy_$1
ffmpeg2 -i $1 -vf vidstabtransform=zoom=5:smoothing=30 stabilized_$1

exit 0
