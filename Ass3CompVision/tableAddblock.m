function block = tableAddBlock(img,block,shape,ori);

    tableImg = img;
    
    figure(1)
    imshow(tableImg);
    hold on;
    [xi, yi, but] = ginput(1);
    close;
    
    block(end+1,1) = xi;
    block(end,2) = yi;
    block(end,3) = shape;
    block(end,4) = ori;
    block(end,5) = (block(end,2)-286)/(55/36);
    block(end,6) = (block(end,1)-798)/(55/36);
    
    szb = size(block);

%     for  j = 1:szb(1)
%         if block(j,3)==1
%             plot(block(j,1), block(j,2), 'ro');
%             hold on;
%         else
%             plot(block(j,1), block(j,2), 'go');
%             hold on;
%         end
%     end
    close all;
end

    