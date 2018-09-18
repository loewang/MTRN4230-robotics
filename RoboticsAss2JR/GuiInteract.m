%Code to interact with the GUI
%_2 for Conevyor Figure
% Need to uncomment the socket shit
clear all; close all; clc;
app = IRB120GUI_temp();
load('cameraConveyorParams.mat'); %Load In Camera Parameters for Conveyor
load('CameraTableParams.mat'); %Load In Camera Parameters for Table
counter1 = 0;
counter2 = 0;
dummyVal = 0;
dummyVal2 = 0;


ratioMMtoPixel = (1200/660); %Ratio of Table to Pixels
T1x = 805.84;
T1y = 25.419 + ratioMMtoPixel*175;

ratioMMtoPixel2 = (1200/810); %Ratio of Conveyor to Pixels
T2x = 208 + ratioMMtoPixel*409;
T2y = 509;

while (1)
    val1 = app.EnableCameraButton_2.Value; %Table Camera Value
    val2 = app.EnableCameraButton.Value; %Conveyor Camera Value
    val3 = app.EnableCameraMovementControlCheckBox_2.Value; %Enable robot move table camera
    val4 = app.EnableCameraMovementControlCheckBox.Value;%Enable robot move conveyor camera
    val5 = app.EnableImageProcessingCheckBox_2; %Enable Processing images for Table 
    val6 = app.EnableImageProcessingCheckBox; %Enabel Procesing images for Conveyor
    
    pause(1);
    if val1 == 1
        if counter1 == 0
            vid3 = imaq.VideoDevice('winvideo',1); % Acquire one frame at a time from video device
            preview(vid3); %Preview live stream
            counter1 = 1;
        
        elseif counter1 == 1
            snap1 = step(vid3); %Obtain single frame
            snap1 = undistortImage(snap1,cameraParams); %Apply Table camera parameters to remove distortion
            if val3 == 1
                if dummyVal == 0 %If first intialise of clicking moving button create figure
                    fig4 = figure(4);
                    imshow(snap1); hold on;
                     
                    dummyVal = 1; %Change dummy value to 1
                else
                    imshow(snap1); hold on; %Click position of live feed and move robot to that position
                    [xi, yi, but] = ginput(1);
                    
                    plot(xi, yi, '*');

                    convY = ((xi - T1x)*(1/ratioMMtoPixel));
                    convX = ((yi -  T1y)*(1/ratioMMtoPixel));
                    %string = sprintf('MVPOSTAB %d,%d,0)',convX, convY);
                    %fwrite(socket,string);
                    %str = ReceiveString(socket);
                    
                    %disp(convY);
                    %disp(convX);
                end
                
            else
              if dummyVal == 1 %Close figure 4
                  close(fig4);
                  dummyVal = 0;
              end
                imshow(snap1,'Parent', app.UIAxes); %Perform image processing
                
              if val5 == 1 %Begin Table Camera Processing
                    img = snap1;
                    robot = img;

                    for i = 1:289  %Remove Top part of robot from image
                        robot(i,:,1) = 255;
                        robot(i,:,2) = 255;
                        robot(i,:,3) = 255;
                    end

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

                        letters = char(letterCent(:,3) + 64); %Actual Letters
                        let = cellstr(letters);

                        text = strjoin(let);
                        app.TextArea_5.Value = sprintf('%s',text);

                        for i = 1:length(letters)
                            text_str{i} = [letters(i)];
                        end

                        img = insertText(img,letterCent(:,1:2),text_str,'FontSize',18,'BoxColor','red','BoxOpacity',1,'TextColor','white');

                        imshow(img,'Parent',app.UIAxes);
                        hold(app.UIAxes,'on');
                        text_str = {};
                    else
                        imshow(img,'Parent',app.UIAxes);
                        hold(app.UIAxes,'on');
                    end

                    % Block Outline -----------------------------------------------------------

                    for i = 1:length(B)
                        boundary = B{i};
                        %imshow(img,'Parent',app.UIAxes_2); hold on;
                        plot(app.UIAxes,boundary(:,2), boundary(:,1),'b','LineWidth',2);
                        hold(app.UIAxes,'on');
                    end

                    % Reachability ------------------------------------------------------------

                    sizeblock = size(letterCent);

                    for i = 1:sizeblock(1)

                        reach = isReachable(letterCent(i,1), letterCent(i,2));
                        if (reach == 0)
                            plot(app.UIAxes,letterCent(i,1), letterCent(i,2), 'y*', 'MarkerSize', 50);
                            hold(app.UIAxes,'on');
                        end
                    end
                    app.TextArea_5.Value = []; %Check if this clears it
              end
            end
        end
        
    elseif val1 == 0 %If button is not on do nothing
        if val1 == 0 && counter1 == 1 %If button switched off close camera vids
            stoppreview(vid3);
            delete(vid3);
            counter1 = 0;
            pause(0.5);
        end
    end
    
    %Process Repeated for Camera 2
    if val2 == 1
        if counter2 == 0
            vid4 = imaq.VideoDevice('winvideo',3);
            counter2 = 1;
        elseif counter2 == 1
            snap2 = step(vid4);
            snap2 = undistortImage(snap2,cameraConveyorParams); %Apply conveyor camera parameters to remove distortion 
            
            if val4 == 1
                if dummyVal2 == 0
                    fig5 = figure(5);
                    imshow(snap2); hold on;
                    dummyVal2 = 1;
                else
                    imshow(snap2); hold on;
                    [xi, yi, but] = ginput(1);
                    
                    plot(xi, yi, '*');

                    convY = ((xi - T2x)*(1/ratioMMtoPixel2));
                    convX = ((yi -  T2y)*(1/ratioMMtoPixel2));
                    %string = sprintf('MVPOSCON %d,%d,0)',convX, convY);
                    %fwrite(socket,string);
                    %str = ReceiveString(socket);
                end
            else
                if dummyVal2 == 1
                    close(fig4);
                    dummyVal2 = 0;
                end
                imshow(snap2,'Parent', app.UIAxes_2); %Perform image processing
                
                if val6 == 1 %Begin Conveyor Processing
                    img = snap2;
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
                    BW = filterimg - bwareaopen(filterimg,3000);
                    BW = imfill(BW,'holes');
                    BW = imbinarize(BW);
                    regionConv = regionprops(BW, 'Centroid', 'Area', 'BoundingBox');


                    imshow(img,'Parent',app.UIAxes_2);
                    hold(app.UIAxes_2,'on');

                    for i = 1:length(regionConv)
                        rectangle(app.UIAxes_2,'Position', [regionConv(i).BoundingBox], 'EdgeColor','r', 'LineWidth', 3);
                        hold(app.UIAxes_2,'on');
                    end
                end
            end
        end
    elseif val2 == 0
        if val2 == 0 && counter2 == 1
            stoppreview(vid4);
            delete(vid4);
            counter2 = 0;
        end
    end
end

function reach = isReachable(x, y)
    if (((x - 805.84)^2) + ((y - 25.419)^2) > (832.67^2))
        reach = 0;
    else 
        reach = 1;
    end
    
    return
end