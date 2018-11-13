function plotFunction(block);

    for i = 1:szb(1)
        text_str{i} = [num2str(round(block(i,4)))];
    end

    img = insertText(img,block(:,1:2),text_str,'FontSize',18,'BoxColor','red','BoxOpacity',1,'TextColor','white');

    figure(1)
    imshow(img);
    hold on;

    for  j = 1:szb(1)
        if block(j,3)==1
            plot(block(j,1), block(j,2), 'r*');
            hold on;
        else
            plot(block(j,1), block(j,2), 'g*');
            hold on;
        end
    end





end

