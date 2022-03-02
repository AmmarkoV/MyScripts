#!/bin/bash

VIDEO="Six Feet Under (2001) - S02E01 - In the Game (480p x265 Silence).mkv"
VIDEOBASENAME=`basename "$VIDEO"`

ffprobe -show_entries stream=index,codec_type:stream_tags=language -of compact "$VIDEO" 2>&1 | { while read line; do if $(echo "$line" | grep -q -i "stream #"); then echo "$line"; fi; done; while read -d $'\x0D' line; do if $(echo "$line" | grep -q "time="); then echo "$line" | awk '{ printf "%s\r", $8 }'; fi; done; }

ffmpeg -threads 4 -i "$VIDEO" -vn -an -codec:s:3 srt "$VIDEOBASENAME.srt"

exit 0
