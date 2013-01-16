#!/bin/bash
ffmpeg -f x11grab -s 1680x1050 -r 25 -i :0.0+0,0 -vcodec libx264 -preset ultrafast -s 1280x768 -acodec libfaac -threads 0 -f mpegts - | vlc -I dummy - --sout '#std{access=http,mux=ts,dst=:8082}'
exit 0
