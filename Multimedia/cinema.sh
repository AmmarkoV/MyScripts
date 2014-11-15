#!/bin/bash

#Cinema Automation Script sudo apt-get install xdotool mplayer

function startOfMovie
{
xdotool mousemove --sync 1920 1080 click 0
./FullScreenViewer start.jpg&
sleep 10
}


function endOfMovie
{
 xdotool mousemove --sync 1920 1080 click 0
 sleep 10
}

function intermission
{ 
  xdotool mousemove --sync 1920 1080 click 0
  #todo open lights etc here
  timeout $1 ./FullScreenViewer timeout.png
  #todo close lights etc here
}  


#--------------------------------------------
startOfMovie
#--------------------------------------------


mplayer -ss 46 -endpos 67 -utf8 -fs -slang gr,en -sub Mad.Max.1979.1080p.BluRay.x264.anoXmous.srt  -v Mad.Max.1979.1080p.BluRay.x264.anoXmous_.mp4
 


#--------------------------------------------
intermission 10
#--------------------------------------------


mplayer -ss 56 -endpos 47 -utf8 -fs -slang gr,en -sub ../2.Mad.Max.2.The.Road.Warrior.1981.1080p.BluRay.x264.anoXmous/Mad.Max.2.The.Road.Warrior.1981.1080p.BluRay.x264.anoXmous_eng.srt  -v ../2.Mad.Max.2.The.Road.Warrior.1981.1080p.BluRay.x264.anoXmous/Mad.Max.2.The.Road.Warrior.1981.1080p.BluRay.x264.anoXmous_.mp4

#--------------------------------------------
endOfMovie
#--------------------------------------------

exit 0
