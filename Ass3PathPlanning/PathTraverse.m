function PathTraverse(start,goal,obstacles)

% Examples

% Easy
start = [9 1];
goal = [7 4];
obstacles = [8 2; 8 3];

% Medium
start = [9 1];
goal = [8 6];
obstacles = [8 2; 8 3; 7 5; 7 6; 8 5; 9 5];
 
% % Hard
% start = [9 1];
% goal = [8 6];
% obstacles = [8 2; 8 3; 7 5; 7 6; 8 5; 9 5];
% 
% % No Path
% start = [9 1];
% goal = [8 6];
% obstacles = [8 2; 8 3; 7 5; 7 6; 8 5; 9 5];

% just for visualising - comment out when not needed
board = ones(9,9);
board(start(1),start(2)) = 2;
board(goal(1),goal(2)) = 3;
for i = 1:length(obstacles)
    board(obstacles(i,1), obstacles(i,2)) = 4;
end
imagesc(board);

% generate path 
path = PathPlan(start, goal, obstacles);

if path ~= 0
    % path exists
    [x,y] = BP2Coord(start);
    command = sprintf('MVPOSTAB %f,%f,5',x,y);
    %disp(command) % for debugging
    
    fwrite(socket, command);
    str = ReceiveString(socket);
    inMotion = checkMotion(socket);
    
    while(inMotion)
       pause(0.1);
       inMotion = checkMotion(socket);
    end
    
    pathCounter = 1;
    [row,~] = size(path);
    while pathCounter <= row
        [x,y] = BP2Coord(path(pathCounter,:));
        command = sprintf('MVPOSTAB %f,%f,5',x,y);
        % disp(command) % for debugging
        
        fwrite(socket, command);
        str = ReceiveString(socket);
        inMotion = checkMotion(socket);

        while(inMotion)
           pause(0.1);
           inMotion = checkMotion(socket);
        end
        
        pathCounter = pathCounter + 1;
    end

else
    % no path 
end

end

% either reached goal or no path

function [x,y] = BP2Coord(bp)
    % dummy for now
    x = bp(1);
    y = bp(2);
end

function [str] =  ReceiveString(socket)
    data = fgetl(socket);
    str = strcat(char(data),'\n');
    fprintf(str);
end

function inMotion = checkMotion(socket)
    fwrite(socket, 'INMOTION');
    str = ReceiveString(socket);
    inMotion = str2num(str);
end
