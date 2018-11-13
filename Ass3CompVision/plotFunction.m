function plotFunction(block, img, tabAxis);

    for i = 1:szb(1)
        text_str{i} = [num2str(round(block(i,4)))];
    end

    img = insertText(img,block(:,1:2),text_str,'FontSize',18,'BoxColor','red','BoxOpacity',1,'TextColor','white');

    imshow(img,'Parent',tabAxis);
    hold(tabAxis, 'on');
    pan(tabAxis,'on');
    zoom(tabAxis,'on');

    for  j = 1:szb(1)
        if block(j,3)==1
            plot(tabAxis, block(j,1), block(j,2), 'r*');
        else
            plot(tabAxis, block(j,1), block(j,2), 'g*');
        end
    end

end

