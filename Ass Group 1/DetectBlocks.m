function block = DetectBlocks(img)
    % Original of JUN YOUNG PARK
    % Z5062476
    try
    % Get rid of robot in the image 
        robot = img;
        for i = 1:289 
            robot(i,:,1) = 255;
            robot(i,:,2) = 255;
            robot(i,:,3) = 255;
        end
        BITimg = binaryM(robot);
        nogridimg = imopen(BITimg, [0 1 1 0 ; 0 1 1 0 ; 1 1 1 1; 0 1 1 0 ; 0 1 1 0]);
        filterimg = bwareaopen(nogridimg, 500); 

        % Centroid + Orientation CHECK --------------------------------------------
        centroids = regionprops(filterimg, 'Centroid', 'Area', 'BoundingBox', 'Orientation');

        block = zeros(length(centroids),7);
        x = zeros(length(centroids),1);
        y = zeros(length(centroids),1);

        for i = 1:length(centroids)
            ori = deg2rad(centroids(i).Orientation);
            block(i, 1:3) = [centroids(i).Centroid(1), centroids(i).Centroid(2), ori];
        end

        % Colour CHECK ------------------------------------------------------------

        red = redM(robot);
        red = bwareaopen(red, 110);

        orange = orangeM(robot);
        orange = bwareaopen(orange, 110);

        yellow = yellowM(robot);
        yellow = bwareaopen(yellow, 110);

        green = greenM(robot);
        green = bwareaopen(green, 110);

        blue = blueM(robot);
        blue = bwareaopen(blue, 110);

        purple = purpleM(robot);
        purple = bwareaopen(purple, 110);

        colorPAT = [1, 2, 3, 4, 5, 6];
        colorCent = [];
        counter = 1;

        [colorCent, counter] = checkColour(red, colorCent, colorPAT(1), counter);
        [colorCent, counter] = checkColour(orange, colorCent, colorPAT(2), counter);
        [colorCent, counter] = checkColour(yellow, colorCent, colorPAT(3), counter);
        [colorCent, counter] = checkColour(green, colorCent, colorPAT(4), counter);
        [colorCent, counter] = checkColour(blue, colorCent, colorPAT(5), counter);
        [colorCent, counter] = checkColour(purple, colorCent, colorPAT(6), counter);


        block = dataAssociation(block, colorCent,4);

    % Letter CHECK ------------------------------------------------------
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

                if (MAXconf<0.85)
                    % Assume not a letter
                else 
                    letterCent(counterLetter,1) = region(i).Centroid(1);
                    letterCent(counterLetter,2) = region(i).Centroid(2);
                    letterCent(counterLetter,3) = wordTemp(indexMAXconf,1) - 64;
                    letterCent(counterLetter,4) = 0;

                    oriCent(counterLetter,1) = region(i).Centroid(1);
                    oriCent(counterLetter,2) = region(i).Centroid(2);
                    oriCent(counterLetter,3) = oriTEMP(indexMAXconf);
                    oriCent(counterLetter,4) = 1;
                    counterLetter = counterLetter + 1;
                end

                oriTEMP(:) = 0;
                wordTemp(:) = 0;
        end



        block = dataAssociation(block, letterCent,6);    

    % Orientation CHECK ------------------------------------------------------

        if isempty(oriCent)
        else
            for i = 1:length(oriCent(:,3))
                while (oriCent(i,3)>180) || (oriCent(i,3)<(-180))
                    if (oriCent(i,3)>180)
                        oriCent(i,3) = oriCent(i,3) - 360;    
                    end
                end
                oriCent(i,3) = deg2rad(oriCent(i,3));
            end
        end

        block = dataAssociation(block, oriCent,3);

    % Shape CHECK -------------------------------------------------------------
        shapeMask = red + orange + yellow + green + blue + purple;
        shapeMask = imfill(shapeMask, 'holes');
        shapeMask = bwmorph(shapeMask, 'bridge', Inf);
        shapeMask = imfill(shapeMask, 'holes');

        shapeDet = regionprops(shapeMask, 'Centroid', 'image', 'Area', 'Perimeter', 'Orientation');
        shapeCent = [];
        shapeCounter = 1;
        randMAT = [4 5 6];
        shapeORI = [];

        for i = 1:length(shapeDet)
            editimg = padarray(shapeDet(i).Image, [6 6]);
            centers = imfindcircles(editimg, [15 25]);
            areaTemp = (shapeDet(i).Perimeter/4)^2;
            ratio = shapeDet(i).Area/areaTemp;

            if ~isempty(centers)
                shapeCent(shapeCounter,1) = shapeDet(i).Centroid(1);
                shapeCent(shapeCounter,2) = shapeDet(i).Centroid(2);
                shapeCent(shapeCounter,3) = 3;
                shapeCent(shapeCounter,4) = 0;

                shapeORI(shapeCounter,1) = shapeDet(i).Centroid(1);
                shapeORI(shapeCounter,2) = shapeDet(i).Centroid(2);
                shapeORI(shapeCounter,3) = shapeDet(i).Orientation;
                shapeORI(shapeCounter,4) = 1;

            elseif (ratio>0.85) && (ratio<1.2)
                shapeCent(shapeCounter,1) = shapeDet(i).Centroid(1);
                shapeCent(shapeCounter,2) = shapeDet(i).Centroid(2);
                shapeCent(shapeCounter,3) = 1;
                shapeCent(shapeCounter,4) = 0;

                shapeORI(shapeCounter,1) = shapeDet(i).Centroid(1);
                shapeORI(shapeCounter,2) = shapeDet(i).Centroid(2);
                shapeORI(shapeCounter,3) = shapeDet(i).Orientation;
                shapeORI(shapeCounter,4) = 1;
            else 
                shapeCent(shapeCounter,1) = shapeDet(i).Centroid(1);
                shapeCent(shapeCounter,2) = shapeDet(i).Centroid(2);
                randPOS = randi(length(randMAT));
                shapeCent(shapeCounter,3) = randMAT(randPOS);
                shapeCent(shapeCounter,4) = 0;

                shapeORI(shapeCounter,1) = shapeDet(i).Centroid(1);
                shapeORI(shapeCounter,2) = shapeDet(i).Centroid(2);
                shapeORI(shapeCounter,3) = shapeDet(i).Orientation;
                shapeORI(shapeCounter,4) = 1;
            end
            shapeCounter = shapeCounter + 1;
        end

        block = dataAssociation(block, shapeCent,5);

        if isempty(shapeORI)
        else
            for i = 1:length(shapeORI(:,3))
                while (shapeORI(i,3)>180) || (shapeORI(i,3)<(-180))
                    if (shapeORI(i,3)>180)
                        shapeORI(i,3) = shapeORI(i,3) - 360;    
                    end
                end
                shapeORI(i,3) = deg2rad(shapeORI(i,3));
            end
        end

        block = dataAssociation(block, shapeORI,3);  
    % Reachability CHECK ------------------------------------------------------

        sizeblock = size(block);

        for i = 1:sizeblock(1)

           x(i) = block(i,1);
           y(i) = block(i,2);

           reach = isReachable(x(i), y(i));

           block(i, 1:2) = [x(i), y(i)];
           block(i, 7) = reach;
        end

    catch




    end
end
% Functions ---------------------------------------------------------------

function block = dataAssociation(block, objCent, obj)

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
               block(i,obj) = objCent(index,3);  
               objCent(index,4) = 1;
               mindist = 100000;
            end
        end

        newBlocks = find(objCent(:,4) == 0);

        for i = 1:length(newBlocks)
            block(end+1,1) = objCent(newBlocks(i),1);
            block(end,2) = objCent(newBlocks(i),2);
            block(end,obj) = objCent(newBlocks(i),3);
        end

    end

end

function [data, counter] = checkColour(img, data, color, counter)
    colouredBlocks = regionprops(img, 'Centroid');
    for i = 1:length(colouredBlocks)
        data(counter, 1:2) = [colouredBlocks(i).Centroid(1), colouredBlocks(i).Centroid(2)];
        data(counter, 3) = color;
        data(counter, 4) = 0;
        counter = counter + 1;
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