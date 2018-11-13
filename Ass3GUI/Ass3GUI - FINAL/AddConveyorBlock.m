function blockAdded = AddConveyorBlock(blockData,img,cameraConveyorParams,R,t,UIaxes,type)
    imshow(img);
    hold on;
    
    for i = 1:size(blockData,1)
        rectangle('Position', blockData(i,7:10),'EdgeColor','m','LineWidth',2);
        plot(blockData(i,1),blockData(i,2),'mo'); 
    end
    
    [x,y] = ginput(1);
    Point(1) = x;
    Point(2) = y;
    NewBlock = length(blockData(:,1)) + 1;
    hold off;
    
    Point = pointsToWorld(cameraConveyorParams, R, t, Point);
    
    blockAdded = blockData;
    blockAdded(NewBlock,1) = Point(1); %World Point X
    blockAdded(NewBlock,2) = Point(2); %World Point Y
    blockAdded(NewBlock,3) = blockData(1,3); %Orientation
    blockAdded(NewBlock,4) = type; %This is where u add what type it is
    blockAdded(NewBlock,5) = x; %Image x
    blockAdded(NewBlock,6) = y; %Image y
    blockAdded(NewBlock,7) = x - 18;
    blockAdded(NewBlock,8) = y - 15;
    blockAdded(NewBlock,9) = 35;
    blockAdded(NewBlock,10) = 35;
    
    imshow(img,'Parent',UIaxes);
    hold(UIaxes, 'on');
    pan(UIaxes,'on');
    zoom(UIaxes,'on');
    
     for  j = 1:length(blockAdded(:,1))
        if blockAdded(j,4)==1
            plot(UIaxes,blockAdded(j,5), blockAdded(j,6), 'ro'); %Letter
            BBL = blockAdded(j,7:10);
            rectangle('Position', [BBL(1),BBL(2),BBL(3),BBL(4)],'EdgeColor','r','LineWidth',2, 'Parent', UIaxes);
        else
            plot(UIaxes,blockAdded(j,5), blockAdded(j,6), 'go'); %Shape
            BBS = blockAdded(j,7:10);
            rectangle('Position', [BBS(1),BBS(2),BBS(3),BBS(4)],'EdgeColor','g','LineWidth',2, 'Parent', UIaxes);
        end
     end   
     
     close all;
end