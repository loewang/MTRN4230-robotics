%RemoveBlockCode
function blockRemove = RemoveBlock(blockData,img,UIaxes)
    blockRemove = [];
    imshow(img);
    hold on;
    [x,y] = ginput(1);
    hold off;
    
    counter = 1;
    for i = 1:length(blockData(:,1))
        distance = sqrt((blockData(i,1) - x)^2 + (blockData(i,2) - y)^2);
        disp(distance);
        if distance > 10
            blockRemove(counter,:) = blockData(i,:);
            counter = counter + 1;
        end
    end
    
    for i = 1:length(blockRemove(:,1))
        blockRemove(i,5) = (blockRemove(i,2)-286)/(55/36);
        blockRemove(i,6) = (blockRemove(i,1)-798)/(55/36);
    end
    
     for i = 1:length(blockRemove(:,1))
        text_str{i} = [num2str(round(blockRemove(i,4)))];
    end

    img = insertText(img,blockRemove(:,1:2),text_str,'FontSize',18,'BoxColor','red','BoxOpacity',1,'TextColor','white');

    imshow(img,'Parent',UIaxes);
    hold(UIaxes, 'on');
    pan(UIaxes,'on');
    zoom(UIaxes,'on');

    for  j = 1:length(blockRemove(:,1))
        if blockRemove(j,3)==1
            plot(UIaxes,blockRemove(j,1), blockRemove(j,2), 'r*');           
        else
            plot(UIaxes,blockRemove(j,1), blockRemove(j,2), 'g*');
        end
    end
    close all;
end