% %Table Block Detection
% clc; clear all; close all;
% img = imread('IMGTABLE.jpg');
% %imgTab = imread('table_img_10_03_11_38_02.jpg');

function detectedBlocks(img)

    tableImg = img;

    for i = 1:250 
        tableImg(i,:,1) = 255;
        tableImg(i,:,2) = 255;
        tableImg(i,:,3) = 255;
    end
    %colorThresholder(tableImg);

    %figure(2);
    %LetterImg = BWMask(tableImg);
    LetterImg = Test2(tableImg);
    %LetterImg = bwareaopen(LetterImg, 100);
    %noGrid = bwareaopen(imopen(LetterImg,[0 1 1 0;0 1 1 0; 1 1 1 1;0 1 1 0; 0 1 1 0]),50); %Need to find tune this line
    noGrid = bwareaopen(imopen(LetterImg,[0 1 1 0; 0 1 1 1;0 1 1 0; 1 1 1 0]),50);
    %noGrid = bwareaopen(noGrid, 800);

    filled = imfill(noGrid, 'holes');
    %imshow(filled);
    %imshowpair(LetterImg,filled,'montage');

    bpt = regionprops(filled, 'Centroid', 'BoundingBox', 'Orientation', 'Area','Extrema');

    %Colour Segmentation

    BMT = blueM(tableImg);
    YMT = yellowMask(tableImg);
    GMT = greenMask2(tableImg);
    PMT = purpleMask2(tableImg);
    OMT = OrangeMask4(tableImg);
    RMT = redMask(tableImg);

    %colorThresholder(tableImg);
    BMT = bwareaopen(BMT,200); %Need to change around
    YMT = bwareaopen(YMT,200);
    GMT = bwareaopen(GMT,200);
    RMT = bwareaopen(RMT,200);
    OMT = bwareaopen(OMT,200);
    PMT = bwareaopen(PMT,200);

    CMT = BMT + YMT + GMT + RMT + OMT + PMT;
    CMT = imfill(CMT,'holes');
    BWCMT = imbinarize(CMT);
    cbt = regionprops(BWCMT,'Centroid','BoundingBox','Orientation','Area');

    %Region Props printing
    figure(3);
    imshow(img);
    hold on;

    for i = 1:length(cbt)
        BBS = cbt(i).BoundingBox;
        rectangle('Position', [BBS(1),BBS(2),BBS(3),BBS(4)],'EdgeColor','r','LineWidth',2);

        blockS(1,i) = cbt(i).Centroid(1);%Temp values to store region props in
        blockS(2,i) = cbt(i).Centroid(2);
        plot(blockS(1,i), blockS(2,i), 'ro');

        hold on;
    end

    for k = 1 : length(bpt)
        BBtable2 = bpt(k).BoundingBox;
        bpt(k).Type = 1;
        rectangle('Position', [BBtable2(1),BBtable2(2),BBtable2(3),BBtable2(4)],'EdgeColor','g','LineWidth',2) ;
        block(1,k) = bpt(k).Centroid(1);%Temp values to store region props in
        block(2,k) = bpt(k).Centroid(2);
        plot(block(1,k), block(2,k), 'go');
        hold on;
    end

    block = dataAssociation(block, blockS);

end

function block = dataAssociation(block, objCent)
    mindist = 100000;
    index = 0;
    sizeblock = size(block);
    sizeobj = size(objCent);
    dist = [];
    
    if isempty(objCent)
    else

        for i = 1:sizeblock(1)
            for j = 1:sizeobj(1)
                dist(j) = sqrt((block(i,1)-objCent(j,1))^2 + (block(i,2)-objCent(j,2))^2);
            end 

            [mindist, index] = min(dist(:));
            dist = [];
            if (mindist ~= 100000)&&(mindist<15)
               block(i,3) = 1;  
               objCent(index,4) = 1;
               mindist = 100000;
            end
        end

        newBlocks = find(objCent(:,4) == 0);

        for i = 1:length(newBlocks)
            block(end+1,1) = objCent(newBlocks(i),1);
            block(end,2) = objCent(newBlocks(i),2);
            block(end,obj) = 1;
        end

    end

end

function [BW,maskedRGBImage] = Test2(RGB)

    % Convert RGB image to chosen color space
    I = rgb2ycbcr(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.000;
    channel1Max = 176.000;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.000;
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