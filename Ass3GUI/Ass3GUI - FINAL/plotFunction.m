function plotFunction(block,img,UIaxes)

    for i = 1:size(block,1)
        text_str{i} = [num2str(round(block(i,4)))];
    end

    img = insertText(img,block(:,1:2),text_str,'FontSize',18,'BoxColor','red','BoxOpacity',1,'TextColor','white');

    imshow(img,'Parent',UIaxes);
    hold(UIaxes, 'on');

    for  j = 1:size(block,1)
        if block(j,3)==1
            plot(UIaxes,block(j,1), block(j,2), 'r*');
        else
            plot(UIaxes,block(j,1), block(j,2), 'g*');
        end
    end
end

