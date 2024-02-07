#!/bin/bash

TIME="0.3"

while true
do
echo -n -e "\x00\x00\x00\n" > /tmp/colorPipe1
echo -n -e "\xFF\xFF\xFF\n" > /tmp/colorPipe2
sleep $TIME
echo -n -e "\xFF\xFF\xFF\n" > /tmp/colorPipe1
echo -n -e "\x00\x00\x00\n" > /tmp/colorPipe2
sleep $TIME
done

exit 0

