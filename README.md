# Validation of CETCS Microneedles
These codes are used to calculate the displacement, repeatability, and backlash of the microneedles in the CETCS device.
Example image set: https://drive.google.com/drive/folders/1dWiazVgbnNAnP1ZvxbhG594k3ry1HmUi?usp=drive_link

## Manual Selection of Endpoints (Manual_Selection.m)
Purpose: User identifies the endpoints of the microneedles for analysis
How to use:
  1. Load the example image set into MATLAB without the needle orientation image and begin running the code
  2. Move and adjust the measuring line to measure the diameter of the catheter (not the microneedles) of the front view. Double click the line if positioning is finished. Repeat for the bottom view, then side view.
  3. Select the endpoints of microneedles in the front image in the order labeled in the needle orientation image. Press the 'enter' key when all six needle endpoints are identified. Repeat for all 13 images of the front view, then repeat for bottom view, and lastly the side view.

## Automated Endpoint Detection (Automated_Endpoint_Detection.m)
Purpose: Automatic identification of the endpoints of the microneedles for analysis
How to use:
  1. Load the example image set into MATLAB without the needle orientation image and begin running the code
  2. Drag the mouse to draw a line across the diameter of the catheter (not the microneedles) of the front view. Double click the line if positioning is finished. Repeat for the bottom view, then side view.
  3. Drag the mouse to create a rectangle over the microneedles in the front view. Make sure to include the ends of all needles, but do not include the catheter. The needles should be slightly cut off on the top, but as long as all endpoints are within the rectangle that is ok. Double click the rectangle when finished.
  4. Repeat the above step for the bottom view, except this time the box should contain all of the needles and center of the catheter. Double click on the box when finished with positioning. Repeat the front view method for the side view.
  5. In the bottom view that pops up, place a point on the center of the catheter to indicate the location of needle 1 (center needle). Press the 'enter' key when finished.
  6. Using the needle orientation image, enter the front view needle number indicated in the figure in the Command Window for all six needles. Continue for the bottom view, then the side view.

## Variable names for displacement, repeatability, and backlash
1. delta (6x13 double): 12 displacement values across the 13 images for each of the six needles
2. rep_r (6x1 double): Repeatability of the retraction movement for each of the six needles
3. rep_d (6x1 double): Repeatability of the deployment movement for each of the six needles
4. r2d_bk (6x1 double): Backlash of the retraction-to-deployment movement for each of the six needles
5. d2r_bk (6x1 double): Backlash of the deployment-to-retraction movement for each of the six needles

