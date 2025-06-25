#!/bin/bash

#Use xrandr --query to see configuration
xrandr --output DP-3 --mode 1920x1080 --pos 0x0 --output HDMI-0 --primary --mode 1920x1080 --pos 1920x0 --output DP-1 --mode 1920x1080 --pos 3840x0 

exit 0
