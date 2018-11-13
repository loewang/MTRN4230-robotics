function moveSuccessful = moveCheck(blockData,tableData)
% 
% % example data: x, y, orientation, type
% blockData = [28; 95; 0; 1];
% tableData = [[0; 60; 90; 0],[30; 90; 0; 1],[25; -60; 30; 0],[45; -45; 60; 1]];

blockData = blockData';
tableData = tableData';

blockXY = blockData(1:2);
tableXY = tableData(:,1:2);

% check if blockXY is member of tableXY, Check will either be 1 or 0
% tolerance for table: 5mm
tableCheck = ismembertol(blockXY,tableXY,5,'DataScale',1,'ByRows',true);

if tableCheck 
    moveSuccessful = 1;
else
    moveSuccessful = 0;
end

end