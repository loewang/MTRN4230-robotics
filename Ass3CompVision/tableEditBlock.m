function [block] = tableEditBlock(img,block,xy,shape,ori);

    % Put in -1 if you dont want to change a certain factor
    figure(1)
    imshow(tableImg);
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
    
    if ori~=(-1)
        block(index,4) = ori;
    end
    
    for  j = 1:szb(1)
        if block(j,3)==1
            plot(block(j,1), block(j,2), 'ro');
            hold on;
        else
            plot(block(j,1), block(j,2), 'go');
            hold on;
        end
    end

end

