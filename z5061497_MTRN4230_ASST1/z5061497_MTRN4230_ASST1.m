% An example of how your function will be called, and what it should
% output.
% image_file_path is the absolute path to the image that you should
% process. This should be used to read in the file.
% image_file_name is just the name of the image. This should be written to
% the output file.
% output_file_path is the absolute path to the file where you should output
% the name of the file as well as the blocks that you have detected.
% program_folder is the folder that your function is running in.

function z5061497_MTRN4230_ASST1(image_file_path, image_file_name, ...
        output_file_path, program_folder)

    im = imread(image_file_path);
    
    blocks = detect_blocks(im,image_file_name);
    
    write_output_file(blocks, image_file_name, output_file_path);
  
end

% Your block detection.
function blocks = detect_blocks(im,name)
    warning off;
    mergecutoff = 5000;
    areacutoff = 500;
    Colcutoff = 350;
%     Do your image processing...    
    table = im(250:1200,:,:); % discard robot in image
    
    colormask = {@RedMask @OrangeMask @YellowMask @GreenMask @BlueMask @PurpleMask};

    %find blocks
    [BW,rgb] = BWMask(table); %isolate blocks from background
    noGrid = bwareaopen(imopen(BW,[0 1 1 0;0 1 1 0; 1 1 1 1;0 1 1 0; 0 1 1 0]),50);% remove grid lines
   
    %detect block locations
    blockprops = regionprops('table',noGrid,'Area','BoundingBox','Centroid');
    blockarea = blockprops.Area;
    blocksq = blockprops.BoundingBox;
    blockcent = blockprops.Centroid;
    
    %eliminate boxes too small to be blocks
    validarea = blockarea(blockarea>areacutoff);
    validcent = blockcent(blockarea>areacutoff,:);
    validsq = blocksq(blockarea>areacutoff,:);
    
    shape.colours = []; %shape block colour buffer
    shape.Cent = []; %shape centroid buffer
    shape.box = []; %shape box buffer
    shape.image = []; %shape image buffer
    
    %find shapes using colours
    for c = 1:numel(colormask)
        %Coloured shape properties
        [BW,rgb] = colormask{c}(table);
        colourprops = regionprops('table',BW,'Area','BoundingBox','Centroid');
        colourarea = colourprops.Area;
        coloursq = colourprops.BoundingBox;
        colourcent = colourprops.Centroid;

        %remove boxes to small to be blocks
        vcolourcent = colourcent(colourarea>Colcutoff,:);
        shape.Cent = vertcat(shape.Cent,vcolourcent);
        vcoloursq = coloursq(colourarea>Colcutoff,:);
        shape.box = vertcat(shape.box,vcoloursq);
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
                end
            end
        end

        validcent = [validcent; merge.letterCent]; % add merged blocks back
        validsq = [validsq; merge.letterBox];
%         validext = [validext; merge.letterext'];
    end
    
    blockcolour = NaN(size(validcent,1),1); % block colour buffer
    reach = NaN(size(validcent,1),1); % block reachable buffer
    blockletter = NaN(size(validcent,1),1); % block letter buffer
    blockshape = NaN(size(validcent,1),1); % block shape buffer
    blockOri = NaN(size(validcent,1),1); % block orientation buffer
    
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
            
            % rotate image through 90 degs for best letter match 
            ai = 1;
            Rletter.letter = [];
            Rletter.confid = [];
            for a = 1:45:361
               
                % remove background created from rotation
                rotletter = imrotate(cropletter,(a-1));
                Mrot = ~imrotate(true(size(cropletter)),(a-1));
                rotletter(Mrot&~imclearborder(Mrot)) = 1;
%                 figure(2);imshow(rotletter);
                
                ocrResults = ocr(rotletter, 'CharacterSet', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ','TextLayout', 'block');
                
                str = char(ocrResults.Words);
                str = str(~isspace(str));
                if((length(str)==1)&&isletter(str))
                    Rletter.letter(ai,1) = str;
                    Rletter.confid(ai) = ocrResults.WordConfidences(~isspace(str));  
                    Rletter.Ori(ai) = a;
                    ai = ai + 1;  
                end
            end
            
            [~,mi] = max(Rletter.confid);
            
            if(~isempty(mi))
                let = Rletter.letter(mi);
                blockOri(i) = pi/2 - wrapToPi(Rletter.Ori(mi)*pi/180);
                blockletter(i) = double(let)-64;
            end

        else % this is a shape
            blockcolour(i) = shape.colours(match); % match associated centroid with its colour
            blockletter(i) = 0;
            shapeim = shape.image{match};
            
            shaperegions = detectMSERFeatures(shapeim);
            [features, ShapePtsObj] = extractFeatures(shapeim, shaperegions);
%             figure(2);clf();imshow(blockimage); hold on;
%             plot(ShapePtsObj,'showOrientation',true);
%             plot(shaperegions,'showPixelList',true,'showEllipses',false);
%             hold off;
            shapeCent = ShapePtsObj.Location;
            shapeOri = ShapePtsObj.Orientation;
            
            % choose centre most area as shape
            d = sqrt((shapeCent(:,1)-size(shapeim,1)/2).^2+(shapeCent(:,2)-size(shapeim,2)/2).^2);
            [~,shRegions] = min(d);
            
            blockOri(i) = shapeOri(shRegions);

            mismatchscore = zeros(6,1);
%             imshow(shapeim);  

            rotshape = imrotate(shapeim,blockOri(i));
            Mrot = ~imrotate(true(size(shapeim)),blockOri(i));
            rotshape(Mrot&~imclearborder(Mrot)) = 1;
            shapeim = rotshape;
            
            for k = 1:6
                refim = imread(shapedata.Files{k});
                refshape = imbinarize(rgb2gray(refim));
                
%                 G = fspecial('average',25);
%                 filtshape = imfilter(shapeim, G); %smooth image
       
%                 shapeim = imresize(shapeim,[500 500]);
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

        % test if block is reachable
        y = sqrt(832.67^2 - (validcent(i,1)-805.84)^2)+25.419-250;
%         plot(validcent(i,1), y, 'co');
        
        % check if block centroid is in range
        if(validcent(i,2)<y)
            reach(i) = 1;
        else
            reach(i) = 0;
        end
    end
 
%     u = cos(blockOri);
%     v = sin(blockOri);
    
%     % plot processing results
%     close all;
%     figure('Name',name);
%     imshow(noGrid); hold on;
%     for k = 1:size(validcent,1)
%         rectangle('Position',[validsq(k,1), validsq(k,2), validsq(k,3), validsq(k,4)],'EdgeColor','g');
%         plot(validcent(k,1),validcent(k,2),'r+');
% %         plot([validext{k}(:,1); validext{k}(1,1)],[validext{k}(:,2); validext{k}(1,2)],'y-','LineWidth',2);
%         quiver(validcent(k,1),validcent(k,2),v(k),u(k),100,'m');
%         
%         y = sqrt(832.67^2 - (validcent(k,1)-805.84)^2)+25.419-250;
%         plot(validcent(k,1), y, 'co');
%     end   
    
    % define robot reachable range
%     reachable_points_x = 1:1600;
%     reachable_points_y = sqrt(832.67^2 - (reachable_points_x-805.84).^2)+25.419-250;

%     plot(reachable_points_x, reachable_points_y, '-b');
   
    % You may store your results in matrix as shown below.
    %           X Y  Theta Colour Shape Letter     1 = Reachable
    %                                              0 = Not reachable
    
    
    b.shape = blockshape;
    b.letter = blockletter;
    
    b.x = validcent(:,1);
    b.y = validcent(:,2)+250;
    b.theta = blockOri;
    b.colour = blockcolour;
    b.reachable = reach;
    
    for i = 1:length(b.shape)
        if(isnan(b.shape(i)))
            b.shape(i) = floor(6*rand(1));
        end
        
        if(isnan(b.letter(i)))
            b.letter(i) = floor(6*rand(1));
        end
    end
    
    %blocks results vector
    blocks = [b.x b.y b.theta b.colour b.shape b.letter b.reachable];
    
%     b.colour(b.colour == 0)= 7;
%     b.shape(b.shape == 0)= 7;
%     b.shape(isnan(b.shape))= 8;
%     b.letter(b.letter == 0)= 27;
%     b.letter(isnan(b.letter))= 28;
%     colours = colourname(b.colour)
%     shapes = shapename(b.shape)
%     letters = alpha(b.letter)
  
end

% This is an example of how to write the results to file.
% This will only work if you store your blocks exactly as above.
% Please ensure that you output your detected blocks correctly. A
% script will be made available so that you can run the comparison
% yourselves, to test that it is working.
function write_output_file(blocks, image_file_name, output_file_path)

    fid = fopen(output_file_path, 'w');
    
    fprintf(fid, 'image_file_name:\n');
    fprintf(fid, '%s\n', image_file_name);
    fprintf(fid, 'rectangles:\n');
    fprintf(fid, ...
        [repmat('%f ', 1, size(blocks, 2)), '\n'], blocks');
    
    % Please ensure that you close any files that you open. If you fail to do
    % so, there may be a noticeable decrease in the speed of your processing.
    fclose(fid);

end