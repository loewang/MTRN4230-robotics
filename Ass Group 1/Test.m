clear all;
clc;

addpath('D:\2018 Semester 2\MTRN4230\Ass 1\Labels Set A V2');

img = imread('IMG_027.jpg');
%imshow(img);
imshow(img);
% Get rid of robot in the image 
robot = img;
        for i = 1:289 
            robot(i,:,1) = 255;
            robot(i,:,2) = 255;
            robot(i,:,3) = 255;
        end

gray = rgb2gray(robot);
hsvROBOT = rgb2hsv(robot);

value = hsvROBOT(:,:,3);

[row, col] = find(value>0.7);


%     % Image edit
%     Icorrected = imtophat(grayrobotLETTER, strel('disk', 15));
%     marker = imerode(Icorrected, strel('line',10,0));
%     Iclean = imreconstruct(marker, Icorrected);
%     BW = imbinarize(Iclean);
%     BW = bwareaopen(BW, 300); 
%     BW = BW - bwareaopen(BW,1000);
%     BW = imbinarize(BW);

img(row(:), col(:)) = 0;
imshow(img);

% black 643 527
% white 545 550