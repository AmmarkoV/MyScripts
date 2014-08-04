#!/bin/bash

#cat $1 | grep youtube | sort | xargs -L 1 sh -c '~/MyScripts/Multimedia/DownloadYoutubeVid.pl "$0"'

sudo apt-get install youtube-dl
cat $1 | grep youtube | sort | xargs -L 1 sh -c 'youtube-dl "$0"'


exit 0
