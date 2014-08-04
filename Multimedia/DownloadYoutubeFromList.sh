#!/bin/bash

#cat $1 | grep youtube | sort | xargs -L 1 sh -c '~/MyScripts/Multimedia/DownloadYoutubeVid.pl "$0"'


#sudo curl https://yt-dl.org/downloads/2014.08.02.1/youtube-dl -o /usr/bin/youtube-dl
#sudo chmod a+x /usr/bin/youtube-dl
#sudo youtube-dl -U

if [ ! -e /usr/bin/youtube-dl ]
then
  echo "No Youtube-dl detected .. Will need to do something about that.."  

  echo
  echo
  echo "Would you like to download repository version of youtube download?"
  echo
  echo -n "            (Y/N)?"
  read answer
  if test "$answer" != "Y" -a "$answer" != "y";
  then
    sudo apt-get install youtube-dl
    echo "Please rerun script"
    exit 0
   fi


  echo
  echo
  echo "Would you like to download repository version of youtube download (potentially unsafe)?"
  echo
  echo -n "            (Y/N)?"
  read answer
  if test "$answer" != "Y" -a "$answer" != "y";
  then
    sudo curl https://yt-dl.org/downloads/2014.08.02.1/youtube-dl -o /usr/bin/youtube-dl
    sudo chmod a+x /usr/bin/youtube-dl
    sudo youtube-dl -U
    echo "Please rerun script"
    exit 0
   fi

 echo "You selected nothing to download , lets hope you have some weird configuration that works" 

fi


cat $1 | grep youtube | sort | xargs -L 1 sh -c 'youtube-dl --extract-audio --audio-format mp3 -l "$0"'


exit 0
