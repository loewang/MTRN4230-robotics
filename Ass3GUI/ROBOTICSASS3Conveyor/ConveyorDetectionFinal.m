%Note i havent done rechability yet for conveyor!!
clc; clear all;

load('cameraConveyorParams.mat'); %Load Conveyor camera calibration
load('RotationMatrix.mat');
load('TranslationMatrix.mat');
% vid2 = videoinput('winvideo', 2, 'MJPG_1600x1200');
% preview(vid2);
% img = getsnapshot(vid2);
img = imread('conveyor_img_10_03_12_04_18.jpg');
img = undistortImage(img, cameraConveyorParams); %Undistord image
CBData = ConveyorImageProcess(img,cameraConveyorParams,R,t);

function [CBData] = ConveyorImageProcess(img,cameraConveyorParams,R,t)

    robot = img;
    robot(:,1:570,:) = 255;
    robot(:,1180:1600,:) = 255;

    for i = 750:1200 
        robot(i,:,1) = 255;
        robot(i,:,2) = 255;
        robot(i,:,3) = 255;
    end
    
    %Large Whitebox
    BITimg = trial(robot);
    filterimg = bwareaopen(BITimg, 100);
    binaryImage = imfill(filterimg, 'holes');

%     figure(7);
%     imshow(binaryImage);
%     hold on;

    %Large Bounding Box
    blockprops = regionprops(binaryImage, 'Centroid', 'BoundingBox', 'Orientation', 'Area','Extrema');

    %Smaller Bounding Box of Letters % Shapes
    LetterImg = whiteMask(robot);

    LetterImg = imfill(LetterImg, 'holes');
    LetterImg = bwareaopen(LetterImg, 100);

%     figure(8);
%     imshow(LetterImg);
%     hold on;

    blockprops2 = regionprops(LetterImg, 'Centroid', 'BoundingBox', 'Orientation', 'Area','Extrema');

%     for k = 1 : length(blockprops2)
%         if blockprops2(k).Area > 100 && blockprops2(k).Area < 1000 && blockprops2(k).BoundingBox(3) < 50
%             BB2 = blockprops2(k).BoundingBox;
%             rectangle('Position', [BB2(1),BB2(2),BB2(3),BB2(4)],'EdgeColor','g','LineWidth',2) ;
%         end
%     end

    %New Masks
    BM = blueMaskT(robot);
    YM = yellowMaskT(robot);
    GM = greenMaskT(robot);
    PM = purpleMaskT(robot);
    RM = redMaskT(robot);
    OM = orangeMaskT(robot);


    BM = bwareaopen(BM,200);
    YM = bwareaopen(YM,200);
    GM = bwareaopen(GM,200);
    RM = bwareaopen(RM,200);
    OM = bwareaopen(OM,200);
    PM = bwareaopen(PM,200);

    RedBlocks = regionprops(RM, 'Centroid','BoundingBox','Orientation','Area');
    OrangeBlocks = regionprops(OM, 'Centroid','BoundingBox','Orientation','Area');
    YellowBlocks = regionprops(YM, 'Centroid','BoundingBox','Orientation','Area');
    GreenBlocks = regionprops(GM, 'Centroid','BoundingBox','Orientation','Area');
    BlueBlocks = regionprops(BM, 'Centroid','BoundingBox','Orientation','Area');
    PurpleBlocks = regionprops(PM, 'Centroid','BoundingBox','Orientation','Area');

    figure(9);
    imshow(img);
    hold on;


    for k = 1 : length(blockprops)
        if blockprops(k).Area > 30000 && blockprops(k).Area < 60000
            BigBox = blockprops(k).BoundingBox;
            Ori = blockprops(k).Orientation;
            rectangle('Position', [BigBox(1),BigBox(2),BigBox(3),BigBox(4)],'EdgeColor','g','LineWidth',2) ;
            blockX(k) = blockprops(k).Centroid(1);%Temp values to store region props in
            blockY(k) = blockprops(k).Centroid(2);
            plot(blockX(k), blockY(k), 'go');
            hold on;
        end
    end



    counter = 1;
    for i = 1:length(OrangeBlocks)
        CBData(counter,1) = OrangeBlocks(i).Centroid(1);
        CBData(counter,2) = OrangeBlocks(i).Centroid(2);
        CBData(counter,3) = Ori;
        CBData(counter,4) = 1;
        BBO = OrangeBlocks(i).BoundingBox;
        rectangle('Position', [BBO(1),BBO(2),BBO(3),BBO(4)],'EdgeColor','m','LineWidth',2);
        hold on;
        plot(CBData(counter,1),CBData(counter,2),'mo'); 
        counter = counter + 1;
    end

    for i = 1:length(RedBlocks)
        CBData(counter,1) = RedBlocks(i).Centroid(1);
        CBData(counter,2) = RedBlocks(i).Centroid(2);
        CBData(counter,3) = Ori;
        CBData(counter,4) = 1;
        BBR = RedBlocks(i).BoundingBox;
        rectangle('Position', [BBR(1),BBR(2),BBR(3),BBR(4)],'EdgeColor','m','LineWidth',2);
        hold on;
        plot(CBData(counter,1),CBData(counter,2),'mo'); 
        counter = counter + 1;
    end

    for i = 1:length(YellowBlocks)
        CBData(counter,1) = YellowBlocks(i).Centroid(1);
        CBData(counter,2) = YellowBlocks(i).Centroid(2);
        CBData(counter,3) = Ori;
        CBData(counter,4) = 1;
        BBY = YellowBlocks(i).BoundingBox;
        rectangle('Position', [BBY(1),BBY(2),BBY(3),BBY(4)],'EdgeColor','m','LineWidth',2);
        hold on;
        plot(CBData(counter,1),CBData(counter,2),'mo'); 
        counter = counter + 1;
    end

    for i = 1:length(GreenBlocks)
        CBData(counter,1) = GreenBlocks(i).Centroid(1);
        CBData(counter,2) = GreenBlocks(i).Centroid(2);
        CBData(counter,3) = Ori;
        CBData(counter,4) = 1;
        BBG = GreenBlocks(i).BoundingBox;
        rectangle('Position', [BBG(1),BBG(2),BBG(3),BBG(4)],'EdgeColor','m','LineWidth',2);
        hold on;
        plot(CBData(counter,1),CBData(counter,2),'mo'); 
        counter = counter + 1;
    end

    for i = 1:length(BlueBlocks)
        CBData(counter,1) = BlueBlocks(i).Centroid(1);
        CBData(counter,2) = BlueBlocks(i).Centroid(2);
        CBData(counter,3) = Ori;
        CBData(counter,4) = 1;
        BBB = BlueBlocks(i).BoundingBox;
        rectangle('Position', [BBB(1),BBB(2),BBB(3),BBB(4)],'EdgeColor','m','LineWidth',2);
        hold on;
        plot(CBData(counter,1),CBData(counter,2),'mo'); 
        counter = counter + 1;
    end

    for i = 1:length(PurpleBlocks)
        CBData(counter,1) = PurpleBlocks(i).Centroid(1);
        CBData(counter,2) = PurpleBlocks(i).Centroid(2);
        CBData(counter,3) = Ori;
        CBData(counter,4) = 1;
        BBP = PurpleBlocks(i).BoundingBox;
        rectangle('Position', [BBP(1),BBP(2),BBP(3),BBP(4)],'EdgeColor','m','LineWidth',2);
        hold on;
        plot(CBData(counter,1),CBData(counter,2),'mo'); 
        counter = counter + 1;
    end

    %Letters
    for k = 1 : length(blockprops2)
        if blockprops2(k).Area > 100 && blockprops2(k).Area < 1000 && blockprops2(k).BoundingBox(3) < 40 && blockprops2(k).BoundingBox(3) > 14 && blockprops2(k).BoundingBox(4) > 14 && blockprops2(k).BoundingBox(4) < 40
            BBTest = blockprops2(k).BoundingBox;
            rectangle('Position', [BBTest(1),BBTest(2),BBTest(3),BBTest(4)],'EdgeColor','r','LineWidth',2) ;

            blockX(k) = blockprops2(k).Centroid(1);%Temp values to store region props in
            blockY(k) = blockprops2(k).Centroid(2);
            plot(blockX(k), blockY(k), 'ro');

            CBData(counter,1) = blockprops2(k).Centroid(1);
            CBData(counter,2) = blockprops2(k).Centroid(2);
            CBData(counter,3) = Ori;
            CBData(counter,4) = 0;
            counter = counter + 1;
        end
    end
    
    %Convert image points to world Points using calibrated camera
    %worldPointsFinal = pointsToWorld(cameraConveyorParams, R, t, Points);
    for i = 1:length(CBData)
        CBData(i,1:2) = pointsToWorld(cameraConveyorParams, R, t, CBData(i,1:2));
    end
    
    
    
    
end

function [BW,maskedRGBImage] = whiteMask(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 23-Oct-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = RGB;

% Define thresholds for channel 1 based on histogram settings
channel1Min = 173.000;
channel1Max = 255.000;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 172.000;
channel2Max = 255.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 174.000;
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

function [BW,maskedRGBImage] = OrangeMask6(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder app. The colorspace and
%  range for each channel of the colorspace were set within the app. The
%  segmentation mask is returned in BW, and a composite of the mask and
%  original RGB images is returned in maskedRGBImage.

% Auto-generated by colorThresholder app on 07-Nov-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.019;
channel1Max = 0.116;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.335;
channel2Max = 1.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.159;
channel3Max = 0.717;

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



%NEW MASK
function [BW,maskedRGBImage] = blueMaskT(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 09-Nov-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.508;
channel1Max = 0.637;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.321;
channel2Max = 1.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.202;
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



function [BW,maskedRGBImage] = purpleMaskT(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 09-Nov-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.638;
channel1Max = 0.801;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.209;
channel2Max = 0.746;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.101;
channel3Max = 0.740;

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


function [BW,maskedRGBImage] = yellowMaskT(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 09-Nov-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.127;
channel1Max = 0.246;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.222;
channel2Max = 1.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.000;
channel3Max = 0.836;

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

function [BW,maskedRGBImage] = redMaskT(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 09-Nov-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.944;
channel1Max = 0.020;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.317;
channel2Max = 1.000;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.366;
channel3Max = 1.000;

% Create mask based on chosen histogram thresholds
sliderBW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...
    (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = sliderBW;

% Initialize output masked image based on input image.
maskedRGBImage = RGB;

% Set background pixels where BW is false to zero.
maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

end
function [BW,maskedRGBImage] = orangeMaskT(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 09-Nov-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.012;
channel1Max = 0.079;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.317;
channel2Max = 0.866;

% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.546;
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

function [BW,maskedRGBImage] = greenMaskT(RGB)
%createMask  Threshold RGB image using auto-generated code from colorThresholder app.
%  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
%  auto-generated code from the colorThresholder App. The colorspace and
%  minimum/maximum values for each channel of the colorspace were set in the
%  App and result in a binary mask BW and a composite image maskedRGBImage,
%  which shows the original RGB image values under the mask BW.

% Auto-generated by colorThresholder app on 09-Nov-2018
%------------------------------------------------------


% Convert RGB image to chosen color space
I = rgb2hsv(RGB);

% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.295;
channel1Max = 0.460;

% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.136;
channel2Max = 1.000;

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