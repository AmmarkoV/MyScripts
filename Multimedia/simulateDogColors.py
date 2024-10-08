import cv2
#python3 -m pip install opencv-python
import numpy as np

# Helper function for linear interpolation
def lerp(val, start_val, end_val, start_output, end_output):
    """Linearly interpolate a value."""
    return start_output + (val - start_val) * (end_output - start_output) / (end_val - start_val)

# Function to simulate how dogs see colors with continuous interpolation
def simulate_dog_vision(image):
    # Convert the image to the HSV color space
    hsv_image = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    
    # Extract the hue, saturation, and value channels
    hue = hsv_image[:, :, 0].astype(np.float32)
    saturation = hsv_image[:, :, 1].astype(np.float32)
    value = hsv_image[:, :, 2].astype(np.float32)
    
    # Define smooth interpolation rules for the hue channel:
    # Red hues: Move from red (0 degrees) to brownish (around 30 degrees)
    red_mask1 = (hue >= 0) & (hue <= 10)
    red_mask2 = (hue >= 170) & (hue <= 180)
    hue[red_mask1] = lerp(hue[red_mask1], 0, 10, 20, 30)  # Interpolating red to brown
    hue[red_mask2] = lerp(hue[red_mask2], 170, 180, 20, 30)

    # Greens: Shift to yellow (60 degrees)
    green_mask = (hue >= 40) & (hue <= 80)
    hue[green_mask] = lerp(hue[green_mask], 40, 80, 50, 60)

    # Apply the modified hue back to the image
    hsv_image[:, :, 0] = hue.astype(np.uint8)
    
    # Optionally reduce saturation to simulate the reduced color intensity in dog vision
    hsv_image[:, :, 1] = (saturation * 0.8).astype(np.uint8)
    
    # Convert back to BGR color space
    dog_image = cv2.cvtColor(hsv_image, cv2.COLOR_HSV2BGR)

    # Optionally apply a Gaussian blur to smooth out any remaining sharp transitions
    dog_image = cv2.GaussianBlur(dog_image, (5, 5), 0)
    
    return dog_image

# Open webcam
cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("Error: Could not open webcam.")
    exit()

# Process frames from the webcam
while True:
    # Capture frame-by-frame
    ret, frame = cap.read()
    
    if not ret:
        print("Error: Could not read frame.")
        break
    
    # Simulate dog vision on the frame
    dog_frame = simulate_dog_vision(frame)
    
    # Display the original frame and the transformed frame
    cv2.imshow('Original Webcam Feed', frame)
    cv2.imshow('Dog Vision Webcam Feed', dog_frame)
    
    # Exit the loop when 'q' is pressed
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release the webcam and close all OpenCV windows
cap.release()
cv2.destroyAllWindows()

