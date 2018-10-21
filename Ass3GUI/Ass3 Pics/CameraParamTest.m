%Camera Params Test
clc; close all;

img = imread('IMG_001.jpg');
load('CameraTableParams.mat');


J = undistortImage(img,cameraParams);
imshowpair(img,J,'montage');

