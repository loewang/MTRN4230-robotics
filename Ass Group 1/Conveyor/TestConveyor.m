%Block Detection Conveyor
clear all;
close all;
clc;

addpath('D:\2018 Semester 2\MTRN4230\Ass Group 1');
img = imread('conveyor_img_09_17_17_33_45.jpg');

% Get rid of robot and other stuff in conveyor image
robot = img;

robot(:,1:600,:) = 255;
robot(:,1180:1600,:) = 255;

for i = 650:1200 
    robot(i,:,1) = 255;
    robot(i,:,2) = 255;
    robot(i,:,3) = 255;
end

BITimg = TestMask(robot);
filterimg = bwareaopen(BITimg, 500); 
BW = filterimg - bwareaopen(filterimg,2000);
BW = imfill(BW,'holes');
BW = imbinarize(BW);
figure(2)
imshow(BW);
regionConv = regionprops(BW, 'Centroid', 'Area', 'BoundingBox');


figure(1)
imshow(img);
hold on;
for i = 1:length(regionConv)
    rectangle('Position', [regionConv(i).BoundingBox], 'EdgeColor','r', 'LineWidth', 3);
end
