start = [1 1];
goal = [3 1];
obstacles = [2 1; 2 2; 2 3];

path = PathPlan(start, goal, obstacles);

if ~path
    % path exists
    [x,y] = BP2Coord(start);
    command = sprintf('MVPOSTAB %f,%f,5',x,y);
    fwrite(socket, command);
    str = ReceiveString(socket);
    inMotion = checkMotion(socket);
    
    while(inMotion)
        pause(0.1);
        inMotion = checkMotion(socket);
    end
    
    pathCounter = 1;
    [row,~] = size(obstacles);
    while pathCounter <= row
        [x,y] = BP2Coord(obstacles(row,:));
        command = sprintf('MVPOSTAB %f,%f,5',x,y);
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

% either reached goal or no path

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