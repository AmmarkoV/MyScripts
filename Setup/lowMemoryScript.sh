#!/bin/bash

#This should be added as an action in the Resource Monitor of LxPanel
#/bin/bash "/home/ammar/Documents/Programming/MyScripts/Setup/lowMemoryScript.sh"

killall firefox
killall MainThread #For some stupid reason the main process/thread of firefox is now called MainThread
killall "Isolated Web Co" #For some stupid reason the main process/thread of firefox is now called MainThread
killall "Web Content" #For some stupid reason the main process/thread of firefox is now called MainThread
killall thunderbird
#gnome-system-monitor


exit 0
