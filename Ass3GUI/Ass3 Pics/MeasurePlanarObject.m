%Measuring Planar Objects with a Calibrated Camera
clc; clear all;
load('cameraConveyorParams.mat'); %Load conveyor calibration
%Read in Test Image

vid1 = videoinput('winvideo',2,'MJPG_1600x1200');
preview(vid1);
imageVid = getsnapshot(vid1);
img = imread('conveyor_img_10_03_11_57_53.jpg'); %Load in conveyor image
%imshow(imageVid);

imBoard = undistortImage(img, cameraConveyorParams); %Undistort image
im = undistortImage(imageVid, cameraConveyorParams); %Undistort image
imshow(im);
[imagePointsT, boardsize] = detectCheckerboardPoints(imBoard); %Find points in checkboard
WorldPointsTest = zeros(49,2);
counter = 1;
for k = 1:7
    for L = 1:7
        x = -225 + (L*30);
        y = 235.7 + (k*30) - 409;
        
        WorldPointsTest(counter,1) = x;
        WorldPointsTest(counter,2) = y;
        counter = counter + 1;
    end
end

%ImagePointsT and world Points must be same matrix size
[R,t] = extrinsics(imagePointsT,WorldPointsTest, cameraConveyorParams);

[x,y,but] = ginput(1);
Points(1,1) = x;
Points(1,2) = y;

worldPointsFinal = pointsToWorld(cameraConveyorParams, R, t, Points);
disp(worldPointsFinal);


% imagePoints = zeros(10,2); %Can manually get checkerboard coordinates
% for i = 1:10
%     [x,y,but] = ginput(1);
%     disp(x);
%     disp(y);
%     imagePoints(i,1) = x;
%     imagePoints(i,2) = y;
% end