function pathFound = PathTraverse(socket,start,goal,obstacles)

% Initialise for debug
% robot_IP_address = '127.0.0.1'; % Simulation ip address
% 
% robot_port = 1025;
% 
% socket = tcpip(robot_IP_address, robot_port);
% set(socket, 'ReadAsyncMode', 'continuous');
% 
% if(~isequal(get(socket, 'Status'), 'open'))
%     fopen(socket);
% end
% 
% if(~isequal(get(socket, 'Status'), 'open'))
%     warning(['Could not open TCP connection to ', robot_IP_address, ' on port ', robot_port]);
%     return;
% end

% Examples

% % Easy
% start = [9 1];
% goal = [7 4];
% obstacles = [8 2; 8 3];
% 
% % Medium
% start = [9 1];
% goal = [8 6];
% obstacles = [8 2; 8 3; 7 5; 7 6; 8 5; 9 5];
%  
% % % Hard 1
% start = [9 1];
% goal = [8 6];
% obsMap = [zeros(1,9);
%              zeros(1,9);
%              1 1 1 0 0 1 0 0 0;
%              0 0 0 0 0 0 1 0 0;
%              0 1 0 1 1 0 0 1 0;
%              0 0 1 0 0 0 1 0 0;
%              0 0 0 0 1 1 0 0 0;
%              0 1 1 0 1 0 0 1 0
%              0 0 0 0 1 0 0 0 0];
%  
% [obsX,obsY] = find(obsMap == 1);
% obstacles = [obsX obsY];
% 
% % % Hard 2
% start = [9 1];
% goal = [8 6];
% obsMap = [zeros(1,9);
%              zeros(1,9);
%              1 1 1 0 0 1 0 0 0;
%              0 0 0 1 0 0 1 0 0;
%              0 1 0 1 1 0 0 1 0;
%              0 0 1 0 0 0 1 0 0;
%              0 0 0 0 1 1 0 0 0;
%              0 1 1 0 1 0 0 1 0
%              0 0 0 0 1 0 0 0 0];
%  
% [obsX,obsY] = find(obsMap == 1);
% obstacles = [obsX obsY];

% % No Path
% start = [9 1];
% goal = [8 6];
% obsMap = [zeros(1,9);
%              zeros(1,9);
%              1 1 1 0 0 1 0 0 0;
%              0 0 0 0 0 0 1 0 0;
%              0 1 0 1 1 0 0 1 0;
%              0 0 1 0 0 0 1 0 0;
%              0 0 0 0 1 1 1 0 0;
%              0 1 1 0 1 0 0 1 0
%              0 0 0 0 1 0 1 0 0];
%  
% [obsX,obsY] = find(obsMap == 1);
% obstacles = [obsX obsY];

% just for visualising - comment out when not needed
board = ones(9,9);
board(start(1),start(2)) = 2;
board(goal(1),goal(2)) = 3;
for i = 1:size(obstacles,1)
    board(obstacles(i,1), obstacles(i,2)) = 4;
end
imagesc(board);

% generate path 
path = PathPlan(start, goal, obstacles);

% visualisation of path
if path ~= 0
    for i = 1:length(path)-1
        board(path(i,1), path(i,2)) = 5;
    end
    imagesc(board);
end

if path ~= 0
    % path exists
    pathFound = 1;
    
    % convert BP coordinate to coordinates rel. to TableHome
    [x,y] = BP2Coord(start);
    
    % move end effector to above start point - 5cm above BP centre
    command = sprintf('MVPOSTAB %f,%f,50',x,y);
    fwrite(socket, command);
    
    inMotion = 1;
    while(inMotion)
       pause(0.1);
       inMotion = checkMotion(socket);
    end
    pause(1);
    
    % move end effector down to start point - 5mm above BP centre
    command = sprintf('MVPOSTAB %f,%f,5',x,y);
    fwrite(socket, command);
    
    inMotion = 1;
    while(inMotion)
       pause(0.1);
       inMotion = checkMotion(socket);
    end
    pause(2);
    
    pathCounter = 1;
    [row,~] = size(path);
    while pathCounter <= row
        [x,y] = BP2Coord(path(pathCounter,:));
        command = sprintf('MVPOSTAB %f,%f,5',x,y);
        disp(command);
        fwrite(socket, command);
        
        inMotion = 1;
        while(inMotion)
           pause(0.1);
           inMotion = checkMotion(socket);
        end
        
        pathCounter = pathCounter + 1;
        pause(1);
    end
    
    % finish by moving above goal point
    command = sprintf('MVPOSTAB %f,%f,50',x,y);
    fwrite(socket, command);

    inMotion = 1;
    while(inMotion)
       pause(0.1);
       inMotion = checkMotion(socket);
    end
    
    command = 'MVPOSTAB 0,0,14';
    fwrite(socket, command);

    inMotion = 1;
    while(inMotion)
       pause(0.1);
       inMotion = checkMotion(socket);
    end

else
    % no path 
    pathFound = 0;
end
    % either reached goal or no path
end

function [x,y] = BP2Coord(bp)    
    BPX = (18:36:(18 + (36*8)))';
    %rows = repmat(BPX,9,1);
    BPY = (-(36*4):36:(36*4));
    %cols = repelem(BPY,9)';
    
    x = BPX(bp(1));
    y = BPY(bp(2));
end

function [str] =  ReceiveString(socket)
    data = fgetl(socket);
    str = strcat(char(data),'\n');
    fprintf(str);
end

function inMotion = checkMotion(socket)
    pause(0.1);
    fwrite(socket, 'INMOTION');
    str = ReceiveString(socket);
    inMotion = str2num(str);
end
