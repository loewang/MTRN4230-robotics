%Block Detection Conveyor
% clc; clear all;
% img = imread('conveyor_img_09_17_17_33_45.jpg');
% 
% % Get rid of robot and other stuff in conveyor image
% robot = img;
% 
% robot(:,1:580,:) = 0;
% robot(:,1180:1600,:) = 0;
% 
% for i = 710:1200 
%     robot(i,:,1) = 0;
%     robot(i,:,2) = 0;
%     robot(i,:,3) = 0;
% end

clear all; close all;
addpath('D:\2018 Semester 2\MTRN4230\Ass 1\Labels Set A V2');

app = IRB120GUI_temp();

img = imread('IMG_001.jpg');

% Get rid of robot and other stuff in conveyor image
robot = img;

for i = 1:289 
    robot(i,:,1) = 255;
    robot(i,:,2) = 255;
    robot(i,:,3) = 255;
end

%figure(10);
%imshow(robot,'Parent',app.UIAxes_2);
% Orientation -------------------------------------------------------------

BITimg = binaryM(robot);
nogridimg = imopen(BITimg, [0 1 1 0 ; 0 1 1 0 ; 1 1 1 1; 0 1 1 0 ; 0 1 1 0]);
filterimg = bwareaopen(nogridimg, 500); 
robotGray = rgb2gray(img);
robotEdge = edge(robotGray,'roberts');

check = bitand(filterimg, robotEdge);
[B,L] = bwboundaries(check, 'noholes');

% Letter Detection --------------------------------------------------------

grayrobotLETTER = rgb2gray(robot);

% Image edit
Icorrected = imtophat(grayrobotLETTER, strel('disk', 15));
marker = imerode(Icorrected, strel('line',10,0));
Iclean = imreconstruct(marker, Icorrected);
BW = imbinarize(Iclean);
BW = bwareaopen(BW, 300); 
BW = BW - bwareaopen(BW,800);
BW = imbinarize(BW);

region = regionprops(BW, 'Centroid', 'Area', 'BoundingBox', 'Orientation', 'image');

letterCent = [];
oriTEMP = zeros(8,1);
wordTemp = zeros(8,2);
buffer = [];
counterLetter = 1;

for i = 1:length(region)
        editimg = padarray(region(i).Image, [10 10]);
        
        
        oriTEMP(1) = 90 - region(i).Orientation;
        rot = imrotate(editimg,oriTEMP(1),'crop');
        
        
        results = ocr(rot, 'TextLayout', 'Block', 'CharacterSet', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');

        if (length(results.Words)>1)
            [mx,mxindex] = max(results.WordConfidences);

            buffer = double(cell2mat(results.Words(mxindex)));
            wordTemp(1,1) = buffer(1);
            wordTemp(1,2) = results.WordConfidences(mxindex);
            buffer = [];

        elseif (isempty(results.Words))
            % No letters found
            wordTemp(1,2) = 0;

        else
            if (length(double(cell2mat(results.Words)))>1)
                buffer = double(cell2mat(results.Words(1)));
                wordTemp(1,1) = buffer(1);
                wordTemp(1,2) = results.WordConfidences(1);
                buffer = [];
            else
                wordTemp(1,1) = double(cell2mat(results.Words));
                wordTemp(1,2) = results.WordConfidences;
            end
        end

        for j = 1:7
            oriTEMP(1+j) = oriTEMP(j) + 45;
            rot = imrotate(editimg,oriTEMP(1+j),'crop');
            results = ocr(rot, 'TextLayout', 'Block', 'CharacterSet', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');

            if (length(results.Words)>1)
                [mx,mxindex] = max(results.WordConfidences);

                buffer = double(cell2mat(results.Words(mxindex)));
                wordTemp(1+j,1) = buffer(1);
                wordTemp(1+j,2) = results.WordConfidences(mxindex);
                buffer = [];

            elseif (isempty(results.Words))
                % No letters found
                wordTemp(1+j,2) = 0;
            else
                if (length(double(cell2mat(results.Words)))>1)
                    buffer =  double(cell2mat(results.Words(1)));
                    wordTemp(1+j,1) = buffer(1);
                    wordTemp(1+j,2) = results.WordConfidences(1);
                    buffer = [];
                else
                    wordTemp(1+j,1) = double(cell2mat(results.Words));
                    wordTemp(1+j,2) = results.WordConfidences;
                end
            end
        end

        [MAXconf, indexMAXconf] = max(wordTemp(:,2));

        if (MAXconf<0.80)
            % Assume not a letter
        else 
            letterCent(counterLetter,1) = region(i).Centroid(1);
            letterCent(counterLetter,2) = region(i).Centroid(2);
            letterCent(counterLetter,3) = wordTemp(indexMAXconf,1) - 64;
            letterCent(counterLetter,4) = oriTEMP(indexMAXconf);
            
            counterLetter = counterLetter + 1;
        end

        oriTEMP(:) = 0;
        wordTemp(:) = 0;
end

if (~isempty(letterCent))
    letters = char(letterCent(:,3) + 64);

    for i = 1:length(letters)
        text_str{i} = [letters(i)];
    end

    img = insertText(img,letterCent(:,1:2),text_str,'FontSize',18,'BoxColor','red','BoxOpacity',1,'TextColor','white');
    %fig = figure(1);
    %figure(1)
    imshow(img,'Parent',app.UIAxes_2);
    hold(app.UIAxes_2,'on');

else
    %figure(1)
    imshow(img,'Parent',app.UIAxes_2);
    hold(app.UIAxes_2,'on');
end

% Block Outline -----------------------------------------------------------

for i = 1:length(B)
    boundary = B{i};
    %imshow(img,'Parent',app.UIAxes_2); hold on;
    %axs = app.UIAxes_2;
    plot(app.UIAxes_2,boundary(:,2), boundary(:,1),'b','LineWidth',2);
    hold(app.UIAxes_2,'on');
end

% [sizex,sizey,sizez] = size(img);
% for i = 1:length(B)
%     boundary = B{i};
%     for j = 1:sizex
%         if j == boundary(:,1)
%         for k = 1:sizey
%             if k == boundary(:,2)
%                 img(j,k,:) = 255;
%             end
%         end
%         end
%     end
% end
% 
%     figure(1)
%     imshow(img,'Parent',app.UIAxes_2);
%     hold on;
% Reachability ------------------------------------------------------------

sizeblock = size(letterCent);

for i = 1:sizeblock(1)

    reach = isReachable(letterCent(i,1), letterCent(i,2));
    if (reach == 0)
        plot(letterCent(i,1), letterCent(i,2), 'y*', 'MarkerSize', 50);
        hold(app.UIAxes_2,'on');
    end
end

% End ---------------------------------------------------------------------

function reach = isReachable(x, y)
    if (((x - 805.84)^2) + ((y - 25.419)^2) > (832.67^2))
        reach = 0;
    else 
        reach = 1;
    end
    
    return
end

%Return LetterCen and display this on Leos GUI
