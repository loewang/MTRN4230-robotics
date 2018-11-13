function [block] = tableEditBlock(img,block,xy,shape,ori)

    % Put in -1 if you dont want to change a certain factor
    figure(1)
    imshow(img);
    hold on;
    [xi, yi, but] = ginput(1);
    close;

    szb = size(block);

    for  i = 1:szb(1)
        dist(i) = sqrt((block(i,1)-xi)^2 + (block(i,2)-yi)^2);
    end
    
    [mindist, index] = min(dist(:));
    
    if xy~=(-1)
        block(index,1) = xi;
        block(index,2) = yi;
        block(index,5) = (block(end,2)-286)/(55/36);
        block(index,6) = (block(end,1)-798)/(55/36);
    end
    
    if shape~=(-1)
        block(index,3) = shape;
    end
    
    if ori~='no'
        block(index,4) = ori;
    end
    close all;
end

