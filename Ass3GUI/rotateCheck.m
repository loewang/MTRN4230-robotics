function rotateSuccessful = rotateCheck(blockData,tableData)

% % example data: x, y, type, orientation
% blockData = [34; 88; 1; 38];
% tableData = [[0; 60; 0; 90],[30; 90; 1; 45],[25; -60; 0; -30],[45; -45; 1; 60]];

blockData = blockData';
tableData = tableData';

blockXY = blockData(1:2);
tableXY = tableData(:,1:2);

blockOri = blockData(4);
tableOri = tableData(:,4);

% find block from table list
[tableCheck,tableIndex] = ismembertol(blockXY,tableXY,5,'DataScale',1,'ByRows',true);

% check block Ori is close to what its supposed to be, Check will either be 1 or 0
% tolerance for orientation: 10 deg
if tableCheck
    oriCheck = ismembertol(blockOri,tableOri(tableIndex),10,'DataScale',1,'ByRows',true);
else
    % blockXY was not matched
    rotateSuccessful = -1;
    return;
end

if oriCheck 
    rotateSuccessful = 1;
else
    rotateSuccessful = 0;
end

end
