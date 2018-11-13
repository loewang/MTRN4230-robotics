function blockRemoveC = RemoveBlockConveyor(blockData,img,cameraConveyorParams,R,t,UIaxes)
    blockRemoveC = [];
    Point = [];
    BBL = [];
    BBS = [];
    imshow(img);
    hold on;
    
    for i = 1:size(blockData,1)
        rectangle('Position', blockData(i,7:10),'EdgeColor','m','LineWidth',2);
        plot(blockData(i,1),blockData(i,2),'mo'); 
        hold on;
    end

    [x,y] = ginput(1);
    Point(1) = x;
    Point(2) = y;
    hold off;
    
    Point = pointsToWorld(cameraConveyorParams, R, t, Point);
    
    counter = 1;
    for i = 1:length(blockData(:,1))
        distance = sqrt((blockData(i,1) - Point(1))^2 + (blockData(i,2) - Point(2))^2);
        disp(distance);
        if distance > 10
            blockRemoveC(counter,:) = blockData(i,:);
            counter = counter + 1;
        end
    end
    
    imshow(img,'Parent',UIaxes);
    hold(UIaxes, 'on');
    pan(UIaxes, 'on');
    zoom(UIaxes, 'on');

    for  j = 1:length(blockRemoveC(:,1))
        if blockRemoveC(j,4)==1
            plot(UIaxes, blockRemoveC(j,5), blockRemoveC(j,6), 'ro'); %Letter
            BBL = blockRemoveC(j,7:10);
            rectangle('Position', [BBL(1),BBL(2),BBL(3),BBL(4)],'EdgeColor','r','LineWidth',2,'Parent',UIaxes);
        else
            plot(UIaxes, blockRemoveC(j,5), blockRemoveC(j,6), 'go'); %Shape
            BBS = blockRemoveC(j,7:10);
            rectangle('Position', [BBS(1),BBS(2),BBS(3),BBS(4)],'EdgeColor','g','LineWidth',2,'Parent',UIaxes);
        end
    end
    close all;
end