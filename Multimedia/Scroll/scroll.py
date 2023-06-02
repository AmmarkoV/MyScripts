import os
import cv2

# Define the path to the input image
image_path = 'in.jpg'

# Define the dimensions of the scrolling window
window_width = 1080
window_height = 1920

# Define the overlap size
#overlap = 334

# Load the input image
image = cv2.imread(image_path)

# Calculate the step size for scrolling
step_x = 10
step_y = 1

i=10
frameNumber=0
os.system("rm colorFrame*.jpg")
# Iterate over each frame
#for i in range(0, image.shape[0] - window_height + 1, step_y):
for j in range(0, image.shape[1] - window_width + 1, step_x):
        # Calculate the starting and ending coordinates of the window for the current frame
        start_x = j
        start_y = i
        end_x = start_x + window_width
        end_y = start_y + window_height

        # Extract the current frame from the image
        frame = image[start_y:end_y, start_x:end_x]

        # Save the frame as an image
        cv2.imwrite('colorFrame_0_%05u.jpg' % frameNumber, frame)
        frameNumber+=1

os.system("ffmpeg -framerate 30 -i colorFrame_0_%05d.jpg  -s 1080x1920  -y -r 30 -pix_fmt yuv420p -threads 8 scroll.mp4 && rm colorFrame*.jpg") 
