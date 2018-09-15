% Your block detection.
function blocks = detect_blocks(im,name)
    
    mergecutoff = 5000;
    areacutoff = 500;
    Colcutoff = 350;
%     Do your image processing...    
    table = im(250:1200,:,:); % discard robot in image
%     colorThresholder(table)
    
    colormask = {@RedMask @OrangeMask @YellowMask @GreenMask @BlueMask @PurpleMask};

    %find blocks
    [BW,rgb] = BWMask(table); %isolate blocks from background
    noGrid = imopen(BW,[0 1 1 0;0 1 1 0; 1 1 1 1;0 1 1 0; 0 1 1 0]);% remove grid lines
   
    %detect block locations
    blockprops = regionprops('table',noGrid,'Area','BoundingBox','Centroid','Extrema');
    blockarea = blockprops.Area;
    blocksq = blockprops.BoundingBox;
    blockcent = blockprops.Centroid;
    blockext = blockprops.Extrema;
    
    %eliminate boxes too small to be blocks
    validarea = blockarea(blockarea>areacutoff);
    validcent = blockcent(blockarea>areacutoff,:);
    validsq = blocksq(blockarea>areacutoff,:);
    validext = blockext(blockarea>areacutoff,:);
    
    shape.colours = []; %shape block colour buffer
    shape.Cent = []; %shape centroid buffer
    shape.box = []; %shape box buffer
    shape.ext = []; %shape extrema buffer
    shape.image = []; %shape image buffer
    
    %find shapes using colours
    for c = 1:numel(colormask)
        %Coloured shape properties
        [BW,rgb] = colormask{c}(table);
        colourprops = regionprops('table',BW,'Area','BoundingBox','Centroid','Extrema');
        colourarea = colourprops.Area;
        coloursq = colourprops.BoundingBox;
        colourcent = colourprops.Centroid;
        colourext = colourprops.Extrema;

        %remove boxes to small to be blocks
        vcolourcent = colourcent(colourarea>Colcutoff,:);
        shape.Cent = vertcat(shape.Cent,vcolourcent);
        vcoloursq = coloursq(colourarea>Colcutoff,:);
        shape.box = vertcat(shape.box,vcoloursq);
        vcolourext = colourext(colourarea>Colcutoff,:);
        shape.ext = vertcat(shape.ext,vcolourext);
        shape.colours = vertcat(shape.colours, repmat(c,size(vcolourcent,1),1));
        
        % save cropped images of shapes
        shapeimage = cell(size(vcoloursq,1),1);
        for i = 1:size(vcoloursq,1)
            shapeimage{i} = BW(floor(vcoloursq(i,2)):floor(vcoloursq(i,2)+vcoloursq(i,4)),...
                floor(vcoloursq(i,1)):floor(vcoloursq(i,1)+vcoloursq(i,3)));
%             imshow(shapeimage{i})
        end
        shape.image = vertcat(shape.image,shapeimage);
    end
     
    mergedAreas = find(validarea>mergecutoff); % find merged areas
    
    if(~isempty(mergedAreas))
        
        merge.centroid = [];
        merge.letterCent = [];
        merge.area = [];
        merge.box = [];
        merge.letterBox = [];
        mergedShape.i = [];
        merge.Ori = [];
        
        %remove merged data
        merge.centroid = validcent(mergedAreas,:);
        validcent(mergedAreas,:) = [];
        merge.area = validarea(mergedAreas);
        merge.box = validsq(mergedAreas,:);
        validsq(mergedAreas,:) = [];
        validext(mergedAreas,:) = [];
        validarea(mergedAreas,:) = [];
        
        noshape = noGrid;
        
        %find merged blocks
        li = 1; % letter buffer counter
        avgblocklength = 50;
        merge.blocksX = floor(merge.box(:,4)./avgblocklength); % find how many box make up the merge box
        merge.blocksY = floor(merge.box(:,3)./avgblocklength);
         
        blocklengthX = zeros(length(mergedAreas),1);
        blocklengthY = zeros(length(mergedAreas),1);
        
        % find and add shapes back 
        for d = 1:length(mergedAreas)
            %associate shapes to their merged areas
            mergedShapei = find(shape.Cent(:,1)> merge.box(d,1)& shape.Cent(:,1)< merge.box(d,1)+ merge.box(d,3)...
           & shape.Cent(:,2)> merge.box(d,2)& shape.Cent(:,2)< merge.box(d,2)+ merge.box(d,4));
            mergedShape.i = [mergedShape.i; mergedShapei];
            mergedShape.i = unique(mergedShape.i);
            validcent = [validcent; shape.Cent(mergedShapei,:)];
            validsq = [validsq; shape.box(mergedShapei,:)];
            validext = [validext; shape.ext(mergedShapei,:)];
            
            %focus on merged area image
            merge.im{d} = noshape(merge.box(d,2):merge.box(d,2)+ merge.box(d,4),...
                merge.box(d,1):merge.box(d,1)+ merge.box(d,3));  
            
            %calculate number of blocks in merged area
            blocklengthX(d) = size(merge.im{d},1)/merge.blocksX(d);
            blocklengthY(d) = size(merge.im{d},2)/merge.blocksY(d);
        end
        
        % remove shape blocks from image
        for j = 1:length(mergedShape.i)
            noshape(shape.box(j,2):(shape.box(j,2)+ shape.box(j,4)),...
                shape.box(j,1):(shape.box(j,1)+ shape.box(j,3))) = 0;
        end
        
        % cycle through each guessed blocklocation for letters
        for k = 1:length(mergedAreas)
            for i = 1:merge.blocksX  
                for j = 1:merge.blocksY  
                    ix1 = floor((i-1)*blocklengthX(k))+1;
                    ix2 = floor((i-1)*blocklengthX(k) + blocklengthX(k));
                    if(ix2>size(merge.im{k},1))
                        ix2 = size(merge.im{k},1);
                    end
                    iy1 = floor((j-1)*blocklengthY(k))+1;
                    iy2 = floor((j-1)*blocklengthY(k) + blocklengthY(k));
                    if(iy2>size(merge.im{k},2))
                        iy2 = size(merge.im{k},2);
                    end
                    
                    mletter.im = merge.im{k}(ix1:ix2,iy1:iy2);
                    mletter.im = imcomplement(mletter.im);
                    G = fspecial('disk',5);
                    filtered = imfilter(mletter.im, G); %smooth image
%                     subplot(121)
%                     imshow(mletter.im);
%                     subplot(122)
%                     imshow(filtered);

                    % get letter props
                    letterprops = regionprops('table',filtered,'Centroid');
                    mletter.Cent = letterprops.Centroid;

                    % choose centre most area as letter
                    if(~isempty(mletter.Cent))
                        d = sqrt((mletter.Cent(:,1)-size(filtered,1)/2).^2+(mletter.Cent(:,2)-size(filtered,2)/2).^2);

                        dcutoff = 16;
                        if(min(d)<dcutoff)
                            
                            MSERregions = detectMSERFeatures(mletter.im);%,'RegionAreaRange',[300 800]);
                            [features, validPtsObj] = extractFeatures(mletter.im, MSERregions);
%                             imshow(mletter.im); hold on;
%                             plot(validPtsObj,'showOrientation',true);
%                             plot(MSERregions,'showPixelList',true,'showEllipses',false);
%                             hold off;

                            mletter.Cent = validPtsObj.Location;
                            mletter.Ori = validPtsObj.Orientation;
                            mletter.sz = validPtsObj.Scale;
                            
                            lettersize =  mletter.sz*10;
                            
                            %choose region closest to centre
                            dL = sqrt((mletter.Cent(:,1)-size(mletter.im,1)/2).^2+(mletter.Cent(:,2)-size(mletter.im,2)/2).^2);
                            [~,mletter.i] = min(dL);
                            
                            % save letter locations in global indices
                            letterCentX = mletter.Cent(mletter.i,2)+merge.box(k,2)+floor((i-1)*blocklengthX(k))+1; 
                            letterCentY = mletter.Cent(mletter.i,1)+merge.box(k,1)+floor((j-1)*blocklengthY(k))+1;
                            merge.letterCent(li,:) = [letterCentY letterCentX];
                            letterBoxX = letterCentX-(lettersize(mletter.i)/2);
                            letterBoxY = letterCentY-(lettersize(mletter.i)/2);
                            merge.letterBox(li,:) = [letterBoxY letterBoxX lettersize(mletter.i) lettersize(mletter.i)];
                            merge.Ori(li) = mletter.Ori(mletter.i);
                            li = li + 1;
                        end
                    end
%                     % cycle through letters to compare
%                     for x = 1:26
%                         refim = imread(letterdata.Files{x});
%                         refletter = imcomplement(imbinarize(rgb2gray(refim)));
%                         refletter = imresize(refletter,size(mletter.im));
%                         datapoints = detectSURFFeatures(refletter);
%                         letterpoints = detectSURFFeatures(mletter.im); 
%                         [f1,vpts1] = extractFeatures(mletter.im,letterpoints);
%                         [f2,vpts2] = extractFeatures(refletter,datapoints);
%                         indexPairs = matchFeatures(f1,f2) ;
%                         matchedPoints1 = vpts1(indexPairs(:,1));
%                         matchedPoints2 = vpts2(indexPairs(:,2));
%                         showMatchedFeatures(mletter.im,refletter,matchedPoints1,matchedPoints2);
%                         if(matchedPoints1.Count>0)
%                             letterlist(li,:) = x;
%                             li = li + 1;
%                             break;
%                         end
%                     end
                end
            end
        end

        validcent = [validcent; merge.letterCent]; % add merged blocks back
        validsq = [validsq; merge.letterBox];
%         validext = [validext; merge.letterext'];
    end
    
    % evaluate orientation of blocks
    validOri = NaN(length(validext),1);
    for i  = 1:length(validext)
        TLx = mean(validext{i}(1:2,1));
        TLy = mean(validext{i}(1:2,2));
        TRx = mean(validext{i}(3:4,1));
        TRy = mean(validext{i}(3:4,2));
        validOri(i) = atan2((TRx-TLx),(TRy-TLy));
    end
    
    if(~isempty(mergedAreas))
        validOri = [validOri; merge.Ori'];
    end
    
    u = cos(validOri);
    v = sin(validOri);
    
%     % plot processing results
%     close all;
%     figure('Name',name);
%     imshow(noGrid); hold on;
%     for k = 1:size(validcent,1)
%         rectangle('Position',[validsq(k,1), validsq(k,2), validsq(k,3), validsq(k,4)],'EdgeColor','g');
%         plot(validcent(k,1),validcent(k,2),'r+');
% %         plot([validext{k}(:,1); validext{k}(1,1)],[validext{k}(:,2); validext{k}(1,2)],'y-','LineWidth',2);
%         quiver(validcent(k,1),validcent(k,2),v(k),u(k),100,'m');
%     end   
    
    % define robot reachable range
%     reachable_points_x = 1:1600;
%     reachable_points_y = sqrt(832.67^2 - (reachable_points_x-805.84).^2)+25.419-250;


%     plot(reachable_points_x, reachable_points_y, '-b');
    
    blockcolour = NaN(size(validcent,1),1); % block colour buffer
    reach = NaN(size(validcent,1),1); % block reachable buffer
    blockletter = NaN(size(validcent,1),1); % block letter buffer
    blockshape = NaN(size(validcent,1),1); % block shape buffer
    
    shapedata = imageDatastore('./student_submissions\z5061497_MTRN4230_ASST1\shapes2');
    
%     alpha = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','shape','FAIL'};
%     shapename = {'Square','Diamond','Circle','Club','Cross','Star','letter','FAIL'};
%     colourname = {'Red','Orange','Yellow','Green','Blue','Purple','White'};
    
    %loop through valid centroids to determine wat they are
    for i = 1:size(validcent,1)
        blockimage = noGrid(validsq(i,2):validsq(i,2)+validsq(i,4), validsq(i,1):validsq(i,1)+validsq(i,3));

        dist = sqrt((validcent(i,1)-shape.Cent(:,1)).^2 + (validcent(i,2)-shape.Cent(:,2)).^2);
        match = find(dist<10,1); %associate centroids between coloured and all blocks
        
        if(isempty(match))% if the centroid doesnt match with any coloured shape, it is a letter

            blockcolour(i) = 0; 
            blockshape(i) = 0;
            
            % isolate letters from their background
            [MSERregions,cc] = detectMSERFeatures(blockimage);%'RegionAreaRange',[150 1000]);
            [features, validPtsObj] = extractFeatures(blockimage, MSERregions);
%             figure(2);clf();imshow(blockimage); hold on;
%             plot(validPtsObj,'showOrientation',true);
%             plot(MSERregions,'showPixelList',true,'showEllipses',false);
%             hold off;
            Rletter.Cent = validPtsObj.Location;
            Rletter.Ori = validPtsObj.Orientation;
            pixelList = cc.PixelIdxList;

            % choose centre most area as letter
            d = sqrt((Rletter.Cent(:,1)-size(blockimage,1)/2).^2+(Rletter.Cent(:,2)-size(blockimage,2)/2).^2);
            centreRegions = d<20;
            
            % keep centermost regions from being removed
            pixelList(centreRegions)= [];
            
            justletter = blockimage;
            
            % remove background
            for k = 1 : length(pixelList)
                regionpix = pixelList{k};
                justletter(regionpix) = 1;
            end
            
            margin = 8; 
            cropletter = imcrop(justletter, [margin, margin, size(justletter,2) - 2 * margin, size(justletter,1) - 2 * margin]);

%             figure(3); imshow(cropletter);
           
            Rletter.imletter = imrotate(cropletter,validOri(i)*180/pi);
            Mrot = ~imrotate(true(size(cropletter)),validOri(i)*180/pi);
            Rletter.imletter(Mrot&~imclearborder(Mrot)) = 1;
            
            % rotate image through 90 degs for best letter match
            for a = 1:4
                % remove background created from rotation
                rotletter = imrotate(Rletter.imletter,(a-1)*90);
                Mrot = ~imrotate(true(size(Rletter.imletter)),(a-1)*90);
                rotletter(Mrot&~imclearborder(Mrot)) = 1;
%                 figure(2);imshow(rotletter);
                
                ocrResults = ocr(rotletter, 'CharacterSet', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ','TextLayout', 'block');
                
                str = char(ocrResults.Words);
                str = str(~isspace(str));
                if((length(char(str))==1)&&isletter(str))
                    Rletter.letter(a,1) = str;
                    Rletter.confid(a) = ocrResults.WordConfidences(~isspace(str));  
                    [~,mi] = max(Rletter.confid);
                    let = Rletter.letter(mi);
                    blockletter(i) = double(let)-64;
                else
                    Rletter.letter(a) = NaN;
                    Rletter.confid(a) = NaN;
                end
            end
                     
%             pointmatches = zeros(26,1);
%             for k = 1:26
%                 refim = imread(letterdata.Files{k});
%                 refletter = imbinarize(rgb2gray(refim));
% %                 refletter = imresize(refletter,[500 500]);
%                 Rletter.imletter = imresize(Rletter.imletter,size(refletter));
%                 datapoints = detectSURFFeatures(refletter,'MetricThreshold',1000,'NumOctaves',3,'NumScaleLevels',3);
%                 letterpoints = detectSURFFeatures(Rletter.imletter,'MetricThreshold',1000,'NumOctaves',3,'NumScaleLevels',3);
%                 [f1,vpts1] = extractFeatures(Rletter.imletter,letterpoints,'Upright',false);
%                 [f2,vpts2] = extractFeatures(refletter,datapoints,'Upright',false);
%                 indexPairs = matchFeatures(f1,f2);
%                 matchedPoints1 = vpts1(indexPairs(:,1));
%                 matchedPoints2 = vpts2(indexPairs(:,2));
%                 figure(2);
%                 showMatchedFeatures(Rletter.imletter,refletter,matchedPoints1,matchedPoints2);
%                 pointmatches(k) = size(indexPairs,1);
%             end
%             [~,letnum] = max(pointmatches);
%             blockletter(i) = letnum;
        else % this is a shape
            blockcolour(i) = shape.colours(match); % match associated centroid with its colour
            blockletter(i) = 0;
            shapeim = shape.image{match};
            shapeim = imrotate(shapeim,validOri(i)*180/pi);
            
            mismatchscore = zeros(6,1);
%             imshow(shapeim);
            
            for k = 1:6
                refim = imread(shapedata.Files{k});
                refshape = imbinarize(rgb2gray(refim));
                shapeim = imresize(shapeim,[500 500]);
%                 G = fspecial('average',25);
%                 filtshape = imfilter(shapeim, G); %smooth image
                refshape = imresize(refshape,size(shapeim));
%                 figure(2); subplot(121)
%                 imshow(shapeim);
%                 subplot(122)
%                 imshow(refshape);
                
                overlay = xor(shapeim,refshape);
                mismatchscore(k) = sum(overlay(:));
            end
            
            [~,shapenum] = min(mismatchscore);
            blockshape(i) = shapenum;
        end
                        
%             %test for circle
%             [~,~,circMetric] = imfindcircles(shapeim,[10 30]);
%             if(circMetric>1.0)
%                 blockshape(i) = 3;
%                 break;
%             end
%             
%             %test for square
%             G = fspecial('sobel');
%             filtshape = imfilter(shapeim, G); %smooth image
%             imshow(filtshape);
%             corners = detectHarrisFeatures(filtshape,'MinQuality', 0.01,'FilterSize', 5);
%             hold on; plot(corners.Location(:,1),corners.Location(:,2),'g+');
%             
%             edgeim = edge(shapeim, 'canny');
% %             imshow(edgeim);
%             [H,theta,rho] = hough(edgeim,'RhoResolution',0.5,'Theta',-90:0.5:89);
%             P = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
%             lines = houghlines(edgeim,theta,rho,P,'FillGap',5,'MinLength',7);

        % test if blockis reachable
        y = sqrt(832.67^2 - (validcent(i,1)-805.84)^2)+25.419-250;
%         plot(validcent(i,1), y, 'co');
        
        % check if block centroid is in range
        if(validcent(i,2)<y)
            reach(i) = 1;
        else
            reach(i) = 0;
        end
    end
   
    % You may store your results in matrix as shown below.
    %           X Y  Theta Colour Shape Letter     1 = Reachable
    %                                              0 = Not reachable
    
    
    b.shape = blockshape;
    b.letter = blockletter;
    
    b.x = validcent(:,1);
    b.y = validcent(:,2)+250;
    b.theta = validOri;
    b.colour = blockcolour;
    b.reachable = reach;
    
    %blocks results vector
    blocks = [b.x b.y b.theta b.colour b.shape b.letter b.reachable];
    
%     b.colour(b.colour == 0)= 7;
%     b.shape(b.shape == 0)= 7;
%     b.shape(isnan(b.shape))= 8;
%     b.letter(b.letter == 0)= 27;
%     b.letter(isnan(b.letter))= 28;
% %     colours = colourname(b.colour)
%     shapes = shapename(b.shape)
%     letters = alpha(b.letter)
end