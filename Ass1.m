
for imgNum = 1:10
imgName = sprintf('IMG_%.3d.txt',imgNum);
IMGread = readtable(imgName);

IMG.x = IMGread.Var1;
IMG.y = IMGread.Var2;
IMG.theta = IMGread.Var3;
IMG.colour = IMGread.Var4;
IMG.shape = IMGread.Var5;
IMG.letter = IMGread.Var6;
IMG.reach = IMGread.Var7;

%letterArray = cell(10,26); % load this in command window first
letterList = [];

for i = 1:numel(IMG.x)
    
    theta = rad2deg(IMG.theta(i));
    while theta > 45 || theta < -45
        if theta > 45
            theta = theta - 90;
        elseif theta < -45
            theta = theta + 90;
        end       
    end
    
    size = abs(round(50/cosd(theta)));

    letter = IMG.letter(i);
    letterList(end+1) = letter;

    if isempty(letterArray) || isempty(letterArray{imgNum,letter})
        letterArray(imgNum,letter) = {[IMG.x(i) - size/2, IMG.y(i) - size/2, size, size]};
    else
        letterArray{imgNum,letter} = [letterArray{imgNum,letter}; [IMG.x(i) - size/2, IMG.y(i) - size/2, size, size]];
    end
    
end

letterList2 = 1:26;

letterList2 = setdiff(letterList2,letterList);

for i = 1:numel(letterList2)
   letterArray(imgNum,letterList2(i)) = {[]};
end

end



