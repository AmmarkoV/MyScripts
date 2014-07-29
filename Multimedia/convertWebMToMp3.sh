#!/bin/bash
ffmpeg -i $1.webm -acodec libmp3lame -aq 4 $1.mp3
exit 0
