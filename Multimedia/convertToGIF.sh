#!/bin/bash 

mkdir -P tmpimages/
mplayer -ao null $1 -vo jpeg:outdir=tmpimages/
convert  -resize 30% -delay 1x30 -loop 1 tmpimages/* tmpimages/abc.gif
convert tmpimages/abc.gif -fuzz 10% -layers Optimize ./opt-gif.gif
rm -rf tmpimages/{abc.gif images/} 
