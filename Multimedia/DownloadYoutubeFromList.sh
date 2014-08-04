#!/bin/bash

#cat $1 | grep youtube | sort | xargs -L 1 sh -c '~/MyScripts/Multimedia/DownloadYoutubeVid.pl "$0"'


#sudo curl https://yt-dl.org/downloads/2014.08.02.1/youtube-dl -o /usr/bin/youtube-dl
#sudo chmod a+x /usr/bin/youtube-dl
#sudo youtube-dl -U


sudo apt-get install youtube-dl
cat $1 | grep youtube | sort | xargs -L 1 sh -c 'youtube-dl --extract-audio --audio-format mp3 -l "$0"'


exit 0
