%Measuring Planar Objects with a Calibrated Camera for Table

%Block tiles are 35x35
clc; clear all;
load('CameraTableParams.mat'); %Load Table camera calibration
imgTab = imread('table_img_10_03_11_38_02.jpg');
%imshow(imgTab);
imT = undistortImage(imgTab, cameraParams); %Undistort image
%imshowpair(imgTab,imT,'montage');
imshow(imT);
%[imagePointsTable, boardsizeT] = detectCheckerboardPoints(imT); %Find points in checkboard
WorldPointsTestTable = zeros(64,2);

load('ImagePointsFromTableGINPUT.mat'); %Loads image points in that were manually clicked through ginput of calibrated pic
counter = 1;
for i = 1:7
    for j = 1:8
        x = 175 + (i*35);
        y = -157.5 + (j*35);
        
        WorldPointsTestTable(counter,1) = x;
        WorldPointsTestTable(counter,2) = y;
        counter = counter + 1;
    end
end

for i = 8
    for j = 1:8
        x = 175 + (i*35);
        y = -157.5 + (j*35);
        if j == 5
            WorldPointsTestTable(counter,1) = 175;
            WorldPointsTestTable(counter,2) = 0;
        elseif j == 6
            WorldPointsTestTable(counter,1) = 175;
            WorldPointsTestTable(counter,2) = -520;
        elseif j == 7
            WorldPointsTestTable(counter,1) = 175;
            WorldPointsTestTable(counter,2) = 520;
        elseif j == 8
            WorldPointsTestTable(counter,1) = 548.6;
            WorldPointsTestTable(counter,2) = 0;
        else
            WorldPointsTestTable(counter,1) = x;
            WorldPointsTestTable(counter,2) = y;
        end
        counter = counter + 1;
    end
end

[RTable,tTable] = extrinsics(imagePoints,WorldPointsTestTable, cameraParams);

[x,y,but] = ginput(1);
PointsT(1,1) = x;
PointsT(1,2) = y;

worldPointsFinalTable = pointsToWorld(cameraParams, RTable, tTable, PointsT);
disp(worldPointsFinalTable);
