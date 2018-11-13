function blockAdded = AddConveyorBlock(blockData,img,cameraConveyorParams,R,t)
    [x,y] = ginput(1);
    Point(1) = x;
    Point(2) = y;
    NewBlock = length(blockData(:,1)) + 1;
    
    Point = pointsToWorld(cameraConveyorParams, R, t, Point);
    
    blockAdded = blockData;
    blockAdded(NewBlock,1) = Point(1); %World Point X
    blockAdded(NewBlock,2) = Point(2); %World Point Y
    blockAdded(NewBlock,3) = blockData(1,3); %Orientation
    blockAdded(NewBlock,4) = 0; %This is where u add what type it is
    blockAdded(NewBlock,5) = x; %Image x
    blockAdded(NewBlock,6) = y; %Image y
    blockAdded(NewBlock,7) = x - 18;
    blockAdded(NewBlock,8) = y - 15;
    blockAdded(NewBlock,9) = 35;
    blockAdded(NewBlock,10) = 35;
    
    figure(3);
    imshow(img);
    hold on;
    
     for  j = 1:length(blockAdded(:,1))
        if blockAdded(j,4)==1
            plot(blockAdded(j,5), blockAdded(j,6), 'ro'); %Letter
            hold on;
            BBL = blockAdded(j,7:10);
            rectangle('Position', [BBL(1),BBL(2),BBL(3),BBL(4)],'EdgeColor','r','LineWidth',2);
            hold on;
        else
            plot(blockAdded(j,5), blockAdded(j,6), 'go'); %Shape
            hold on;
            BBS = blockAdded(j,7:10);
            rectangle('Position', [BBS(1),BBS(2),BBS(3),BBS(4)],'EdgeColor','g','LineWidth',2);
            hold on;
        end
    end
    
end