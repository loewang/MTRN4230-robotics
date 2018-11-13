function rotateSuccessful = rotateCheck(blockData,tableData)

% % example data: x, y, orientation, type
% blockData = [28; 95; 5; 1];
% tableData = [[0; 60; 90; 0],[30; 90; 0; 1],[25; -60; 30; 0],[45; -45; 60; 1]];

blockData = blockData';
tableData = tableData';

blockXY = blockData(3);
tableXY = tableData(:,3);

% check if blockXY is member of tableXY, Check will either be 1 or 0
% tolerance for orientation: 10 deg
tableCheck = ismembertol(blockXY,tableXY,10,'DataScale',1,'ByRows',true);

if tableCheck 
    rotateSuccessful = 1;
else
    rotateSuccessful = 0;
end

end