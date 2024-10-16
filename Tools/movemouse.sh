#!/bin/bash

# Infinite loop to move the mouse every second
while true; do
  # Get the current mouse position
  eval "$(xdotool getmouselocation --shell)"
  
  # Move the mouse by 1 pixel and then back to its original position
  xdotool mousemove $((X+1)) $Y
  sleep 1
  xdotool mousemove $X $Y

  # Wait for 1 second
  sleep 1
done
