#!/bin/bash

# Name of the output file list
output_file="filelist.txt"

# Remove the filelist.txt if it already exists
rm -f $output_file

# Loop over all PNG files in the directory and append to the filelist.txt
for img in *.png; 
do 
    echo "file '$img'" >> $output_file
done

echo "File list generated in $output_file"
ffmpeg -r 1 -f concat -safe 0 -i filelist.txt -c:v libx264 -pix_fmt yuv420p output.mp4

