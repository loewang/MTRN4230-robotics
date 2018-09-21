%Code to interact with the matlab GUI for live video feeds
clear all; close all; clc;
app = IRB120GUI_temp();
load('cameraConveyorParams.mat'); %Load In Camera Parameters for Conveyor
load('CameraTableParams.mat'); %Load In Camera Parameters for Table


%Counter Variables
counter1 = 0;
counter2 = 0;
dummyVal = 0;
dummyVal2 = 0;


ratioMMtoPixel = (1200/660); %Convert coordinate Pixels from table image to global
T1x = 805.84;
T1y = 25.419 + ratioMMtoPixel*175;

ratioMMtoPixel2 = (1200/810); %Convert coordinate Pixels from conveyor image to global
T2x = 208 + ratioMMtoPixel*409;
T2y = 509;

while (1)
    
    val1 = app.EnableCameraButton_2.Value; %Table Camera Value
    val2 = app.EnableCameraButton.Value; %Conveyor Camera Value
    val3 = app.EnableCameraMovementControlCheckBox_2.Value; %Enable robot move table camera
    val4 = app.EnableCameraMovementControlCheckBox.Value;%Enable robot move conveyor camera
    val5 = app.EnableImageProcessingCheckBox.Value; %Enable Processing images for Table 
    val6 = app.EnableImageProcessingCheckBox_2.Value; %Enabel Procesing images for Conveyor
    
    pause(5); %Allow for values from the Matlab Gui to change
    if val1 == 1
        if counter1 == 0
            vid3 = imaq.VideoDevice('winvideo',3,'MJPG_1600x1200'); % Acquire one frame at a time from video device
            counter1 = 1; %Set counter to 1 so video object is only created once
        
        elseif counter1 == 1
            snap1 = step(vid3); %Obtain single frame
            snap1 = undistortImage(snap1,cameraParams); %Apply Table camera parameters to remove distortion
            if val3 == 1
                if dummyVal == 0 %If first intialise of clicking moving button create figure
                    fig4 = figure(4); %Create a new figure
                    imshow(snap1); hold on; %Show 1 frame of figure
                     
                    dummyVal = 1; %Change dummy value to 1
                else
                    imshow(snap1); hold on; %Click position of live feed and obtain the X and Y coordinates to move robot to that position
                    [xi, yi, but] = ginput(1); %Reads in mouse click
                    
                    plot(xi, yi, '*');

                    convY = ((xi - T1x)*(1/ratioMMtoPixel)); %Convert X coordinate from image to global
                    convX = ((yi -  T1y)*(1/ratioMMtoPixel));%Convert Y coordinate from image to global
                    
                    %Send X and Y coordinate values to Robot studios
                    %string = sprintf('MVPOSTAB %d,%d,0)',convX, convY);
                    %fwrite(socket,string);
                    %str = ReceiveString(socket);
                    
                    %disp(convY);
                    %disp(convX);
                end
                
            else
              if dummyVal == 1 %If dummyVal has been triggered close figure 4
                  close(fig4);
                  dummyVal = 0; %Reset dummyVal
              end
                imshow(snap1,'Parent', app.UIAxes); %Display 1 frame on matlab gui
                
              if val5 == 1 %Begin Table Camera Processing
                    img = snap1;
                    robot = img;

                    for i = 1:289  %Remove Top part of robot from image
                        robot(i,:,1) = 255;
                        robot(i,:,2) = 255;
                        robot(i,:,3) = 255;
                    end

                    % Orientation -------------------------------------------------------------
                    
                    %Apply filter methods/masks to remove grid/objects from
                    %image
                    BITimg = binaryM(robot);
                    nogridimg = imopen(BITimg, [0 1 1 0 ; 0 1 1 0 ; 1 1 1 1; 0 1 1 0 ; 0 1 1 0]);
                    filterimg = bwareaopen(nogridimg, 500); 
                    robotGray = rgb2gray(img);
                    robotEdge = edge(robotGray,'roberts');

                    check = bitand(filterimg, robotEdge);


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

                    % Create temporary value arrays
                    letterCent = [];
                    oriTEMP = zeros(8,1);
                    wordTemp = zeros(8,2);
                    buffer = [];
                    counterLetter = 1;
                    
                    % Process each region to check for a letter
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
                            % Loop through the blocks and rotate blocks so
                            % ocr can detect which letter
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
                                % Store letters and orientations
                                % (converted)
                                letterCent(counterLetter,1) = region(i).Centroid(1);
                                letterCent(counterLetter,2) = region(i).Centroid(2);
                                letterCent(counterLetter,3) = wordTemp(indexMAXconf,1) - 64;
                                if oriTEMP(indexMAXconf) > 270
                                    oriTEMP(indexMAXconf) = oriTEMP(indexMAXconf) - 360;
                                elseif oriTEMP(indexMAXconf) > 180
                                    oriTEMP(indexMAXconf) = 360 - oriTEMP(indexMAXconf);
                                elseif oriTEMP(indexMAXconf) > 90
                                    oriTEMP(indexMAXconf) = oriTEMP(indexMAXconf) - 180;
                                end
                                letterCent(counterLetter,4) = oriTEMP(indexMAXconf);
                                letterCent(counterLetter,5) = i;

                                counterLetter = counterLetter + 1;
                            end
                            
                            % Reset temporary values 
                            oriTEMP(:) = 0;
                            wordTemp(:) = 0;
                    end

                    % If blocks were found display blocks onto image
                    if (~isempty(letterCent))

                        letters = char(letterCent(:,3) + 64); %Actual Letters
                        let = cellstr(letters);

                        text = strjoin(let);
                        app.TextArea_5.Value = sprintf('%s',text);
                        
                        % Display Letter and Orientation
                        
                        sizeLetter = size(letterCent);
                        
                        for i = 1:sizeLetter(1)
                            % Store the letters and orientation into
                            % appropriate annotation format
                            text_str{i} = [letters(i) ' - ' num2str(letterCent(i,4))];
                        end

                        img = insertText(img,letterCent(:,1:2),text_str,'FontSize',18,'BoxColor','red','BoxOpacity',1,'TextColor','white');

                        imshow(img,'Parent',app.UIAxes);
                        hold(app.UIAxes,'on');
                        text_str = {};
                    else
                        % No letters found
                        imshow(img,'Parent',app.UIAxes);
                        hold(app.UIAxes,'on');
                    end

                    % Block Outline -----------------------------------------------------------

                    for i = 1:sizeLetter(1)
                        %imshow(img,'Parent',app.UIAxes_2); hold on;
                        rectangle(app.UIAxes,'Position', [region(letterCent(i,5)).BoundingBox], 'EdgeColor','r', 'LineWidth', 3);
                        hold(app.UIAxes,'on');
                    end

                    % Reachability ------------------------------------------------------------

                    % If blocks are out of reachability plot a yellow star onto the
                    % blocks
                    sizeblock = size(letterCent);

                    for i = 1:sizeblock(1)

                        reach = isReachable(letterCent(i,1), letterCent(i,2));
                        if (reach == 0)
                            plot(app.UIAxes,letterCent(i,1), letterCent(i,2), 'y*', 'MarkerSize', 50);
                            hold(app.UIAxes,'on');
                        end
                    end
              end
            end
        end
        
    elseif val1 == 0 %If button is not on do nothing
        if val1 == 0 && counter1 == 1 %If button switched off close camera vids
            %stoppreview(vid3);
            delete(vid3);
            counter1 = 0;
            pause(0.5);
        end
    end
    
    % Process Repeated for Camera 2
    if val2 == 1 
        if counter2 == 0 % If statement to create video object for conveyor
            vid4 = imaq.VideoDevice('winvideo',2,'MJPG_1600x1200');
            counter2 = 1;
        elseif counter2 == 1
            snap2 = step(vid4); % Get single frame from conveyor camera
            snap2 = undistortImage(snap2,cameraConveyorParams); %Apply conveyor camera parameters to remove distortion 
            
            if val4 == 1 % If move robot button is clicked
                if dummyVal2 == 0
                    fig5 = figure(5); % Create a new figure and display it
                    imshow(snap2); hold on;
                    dummyVal2 = 1;
                else
                    imshow(snap2); hold on;
                    [x1i, y1i, but] = ginput(1); % Read in mouse input
                    
                    plot(x1i, y1i, '*'); % Plot star at x and y

                    convY = ((x1i - T2x)*(1/ratioMMtoPixel2)); % Convert X from conveyor image to global Y
                    convX = ((y1i -  T2y)*(1/ratioMMtoPixel2)); % Convert Y from conveyor image to global X
                    disp(convY);
                    disp(convX);
                    
                    string = sprintf('MVPOSCON %d,%d,0)',convX, convY); % Send X and Y global to robot
                    fwrite(socket,string);
                    str = ReceiveString(socket);
                end
            else
                if dummyVal2 == 1 % If move robot is completed close figure
                    close(fig4);
                    dummyVal2 = 0;
                end
                imshow(snap2,'Parent', app.UIAxes_2); % Perform image processing
                hold(app.UIAxes_2,'on');
                
                if val6 == 1 % Begin Conveyor Processing
                    img = snap2;
                    % Get rid of robot and other stuff in conveyor image so
                    % that only the conveyor remains
                    robot = img;

                    robot(:,1:600,:) = 255;
                    robot(:,1180:1600,:) = 255;

                    for i = 650:1200 
                        robot(i,:,1) = 255;
                        robot(i,:,2) = 255;
                        robot(i,:,3) = 255;
                    end

                    % Image processing to remove red background of conveyor
                    BITimg = TestMask(robot);
                    filterimg = bwareaopen(BITimg, 600); 
                    figure(7)
                    imshow(filterimg);
                    BW = imfill(BW,'holes');
                    BW = imbinarize(BW);
                    
                    % Perform regionprops to get the centroids of the Blocks
                    regionConv = regionprops(BW, 'Centroid', 'Area', 'BoundingBox','Orientation');
                        
                    % Store region probs into temporary variables
                    sizeConv = size(regionConv);
                    for i = 1:sizeConv(1)
                        oriConv = regionConv(i).Orientation;
                        text_str{i} = [num2str(oriConv)];
                        xConv(i) = regionConv(i).Centroid(1);
                        yConv(i) = regionConv(i).Centroid(2);
                    end
                    
                    % Display region probs data onto image through insert
                    % Text companyed
                    img = insertText(img,[xConv' yConv'],text_str,'FontSize',18,'BoxColor','red','BoxOpacity',1,'TextColor','white');
                    imshow(img,'Parent', app.UIAxes_2);
                    hold(app.UIAxes_2,'on');
                    
                    % Loops through region props bounding box and plots the
                    % outline of blocks onto the image
                    for i = 1:length(regionConv)
                            rectangle(app.UIAxes_2,'Position', [regionConv(i).BoundingBox], 'EdgeColor','r', 'LineWidth', 3);
                            hold(app.UIAxes_2,'on');
                    end
                end
            end
        end
    elseif val2 == 0 % Clean up code
        if val2 == 0 && counter2 == 1
            delete(vid4);
            counter2 = 0;
        end
    end
    
end

% Determine whether blocks are reachable
function reach = isReachable(x, y)
    if (((x - 805.84)^2) + ((y - 25.419)^2) > (832.67^2))
        reach = 0;
    else 
        reach = 1;
    end
    
    return
end