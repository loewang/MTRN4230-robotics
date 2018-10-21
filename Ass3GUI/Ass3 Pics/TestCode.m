clc; clear all;
img = imread('conveyor_img_10_03_12_16_23.jpg'); %Clear White horizontal box
%img = imread('conveyor_img_10_03_12_09_41.jpg'); %Horizontal white box with tiles
%img = imread('conveyor_img_10_03_11_59_59.jpg'); %White box angled
%img = imread('conveyor_img_10_03_12_04_18.jpg'); %White box angled with blocks
%imshow(img);
%J = imcomplement(img);

% Get rid of robot and other stuff in conveyor image
robot = img;

robot(:,1:550,:) = 255;
robot(:,1180:1600,:) = 255;

for i = 750:1200 
    robot(i,:,1) = 255;
    robot(i,:,2) = 255;
    robot(i,:,3) = 255;
end

%imshow(robot);
BITimg = trial(robot);

filterimg = bwareaopen(BITimg, 100);
binaryImage = imfill(filterimg, 'holes');
%BW = filterimg - bwareaopen(filterimg,5000);
imshow(binaryImage);
hold on;

blockprops = regionprops(binaryImage, 'Centroid', 'BoundingBox', 'Orientation', 'Area','Extrema');

for k = 1 : length(blockprops)
    BB = blockprops(k).BoundingBox;
    rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','b','LineWidth',2) ;
end

counter = 1;
for i = 1 : length(blockprops)
    if blockprops(i).Area > 30000 && blockprops(i).Area < 60000
        blockpropsEdit(counter) = blockprops(i);
        counter = counter + 1;
    end
end

for k = 1 : length(blockpropsEdit)
    BB = blockpropsEdit(k).BoundingBox;
    ExtremaPoints = blockpropsEdit(k).Extrema;
    rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','r','LineWidth',2) ;
    blockX(k) = blockpropsEdit(k).Centroid(1);%Temp values to store region props in
    blockY(k) = blockpropsEdit(k).Centroid(2);
    plot(blockX(k), blockY(k), 'ro');
    hold on;
    
    ExtremaPoints(end+1,:) = ExtremaPoints(1,:);
    
    
    boxPoints = bbox2points(BB); %Convert rectangel to corner points
    plot(boxPoints(:,1),boxPoints(:,2), '*');
    plot(ExtremaPoints(:,1), ExtremaPoints(:,2),'b*-');
    
     
     
%   theta = blockpropsEdit(k).Orientation; %Orientation
%   theta = 10;
%   tform = affine2d([cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1]);%Transformation matrix
%   boxPoints2 = transformPointsForward(tform,boxPoints);
%     
%   boxPoints2(end+1,:) = boxPoints2(1,:);
%     
%   figure(5);
%   imshow(binaryImage);
%   hold on;
%   plot(boxPoints2(:,1)-50,boxPoints2(:,2)-50, '*-');
%     
end


function [BW,maskedRGBImage] = WhiteMask(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 20-Oct-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.000;
channel1Max = 1.000;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.000;
channel2Max = 0.205;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.636;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = sliderBW;

% Initialize output masked image based on input image.
maskedRGBImage = RGB;

% Set background pixels where BW is false to zero.
maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

end
function [BW,maskedRGBImage] = WhiteMask2(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 20-Oct-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.000;
channel1Max = 1.000;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.000;
channel2Max = 0.250;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.359;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = sliderBW;

% Initialize output masked image based on input image.
maskedRGBImage = RGB;

% Set background pixels where BW is false to zero.
maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

end


function [BW,maskedRGBImage] = WhiteMask3(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 20-Oct-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.010;
channel1Max = 0.233;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.000;
channel2Max = 0.415;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.000;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = sliderBW;

% Initialize output masked image based on input image.
maskedRGBImage = RGB;

% Set background pixels where BW is false to zero.
maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

end

function [BW,maskedRGBImage] = trial(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 20-Oct-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2ycbcr(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 68.000;
channel1Max = 255.000;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 43.000;
channel2Max = 255.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.000;
channel3Max = 255.000;

% Create mask based on chosen histogram thresholds
sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = sliderBW;

% Initialize output masked image based on input image.
maskedRGBImage = RGB;

% Set background pixels where BW is false to zero.
maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

end
