#!/bin/bash

NUMBEROFSCREENSAVERDAEMONSRUNNING=`ps -A | grep xscreensaver | wc -l`

if [ "$NUMBEROFSCREENSAVERDAEMONSRUNNING" -eq "0" ]; then
     #if xscreensaver is not running then run it..! 
     echo "XScreensaver not running, starting it up" 
     xscreensaver -nosplash&
     sleep 1
fi


xscreensaver-command -lock
#dm-tool lock

exit 0
