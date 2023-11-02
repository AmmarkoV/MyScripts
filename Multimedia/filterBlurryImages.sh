#!/bin/bash

# Specify the folder containing the images
input_folder="$1"

# Specify the threshold for blur detection
threshold=$2  # You can adjust this value as needed

# Create a subfolder to move blurry images
output_folder="$input_folder/blurry_images"
mkdir -p "$output_folder"

# Loop through all JPG files in the input folder
for image in "$input_folder"/*.JPG; do
    # Use ImageMagick to check blur level
    blur_level=$(convert "$image" -blur 0x1 -format "%[fx:mean]" info:)
    echo "$image -> blur : $blur_level"
    # Compare the blur level to the threshold
    if (( $(bc <<< "$blur_level > $threshold") )); then
        # Move the blurry image to the output folder
        echo "FILTERING $image"
        mv "$image" "$output_folder"
    fi
done

