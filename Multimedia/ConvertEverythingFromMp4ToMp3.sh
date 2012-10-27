#!/bin/bash
echo "This will extract audio from all mp4 videos in the current directory to mp3"
for i in *.mp4 ;
do  
  ./Mp4ToMp3.sh $i;
echo " Converted $i " ; 
done 

