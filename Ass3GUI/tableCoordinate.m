function [x,y,xi,yi] = tableCoordinate(img);

    tableImg = img;

    for i = 1:250 
        tableImg(i,:,1) = 255;
        tableImg(i,:,2) = 255;
        tableImg(i,:,3) = 255;
    end

    figure(1)
    imshow(tableImg);
    hold on;
    [xi, yi, but] = ginput(1);
    close;

    x = (yi-286)/(55/36);
    y = (xi-798)/(55/36);

end
