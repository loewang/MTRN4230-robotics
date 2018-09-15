clear all;
clc;

addpath('D:\2018 Semester 2\MTRN4230\Ass 1\Labels Set A V2');

img = imread('IMG_001.jpg');

% Get rid of robot in the image 
robot = img;
        for i = 1:289 
            robot(i,:,1) = 255;
            robot(i,:,2) = 255;
            robot(i,:,3) = 255;
        end

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
        oriCent = [];
        oriTEMP = zeros(8,1);
        wordTemp = zeros(8,2);
        buffer = [];
        counterLetter = 1;

        for i = 1:length(region)
                editimg = padarray(region(i).Image, [6 6]);

                oriTEMP(1) = 90-region(i).Orientation;
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

                if (MAXconf<0.85)
                    % Assume not a letter
                else 
                    letterCent(counterLetter,1) = region(i).Centroid(1);
                    letterCent(counterLetter,2) = region(i).Centroid(2);
                    letterCent(counterLetter,3) = wordTemp(indexMAXconf,1) - 64;
                    letterCent(counterLetter,4) = 0;

                    counterLetter = counterLetter + 1;
                end

                oriTEMP(:) = 0;
                wordTemp(:) = 0;
        end

