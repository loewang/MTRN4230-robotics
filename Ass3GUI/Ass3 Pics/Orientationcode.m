%Trying orientation
clear all; close all;
bbox = [10,20,50,60];
points = bbox2points(bbox);
figure(1);
plot(points(:,1),points(:,2), '*');
hold on;

theta = 45;
tform = affine2d([cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1]);
points2 = transformPointsForward(tform,points);
points2(end+1,:) = points2(1,:);
plot(points2(:,1),points2(:,2), '*-');