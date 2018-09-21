%robot_IP_address = '192.168.125.1';
robot_IP_address = '127.0.0.1'; % Simulation ip address

robot_port = 1025;

socket = tcpip(robot_IP_address, robot_port);
set(socket, 'ReadAsyncMode', 'continuous');

if(~isequal(get(socket, 'Status'), 'open'))
    fopen(socket);
end

if(~isequal(get(socket, 'Status'), 'open'))
    warning(['Could not open TCP connection to ', robot_IP_address, ' on port ', robot_port]);
    return;
end

% DIO
fwrite(socket, 'VACUUMON');
pause(1);
fwrite(socket, 'SETSOLEN 1');
pause(3);
fwrite(socket, 'SETSOLEN 0');
pause(3);
fwrite(socket, 'VACUUMOF');
pause(1);
fwrite(socket, 'CONVDIRE 1');
pause(1);
fwrite(socket, 'CONVEYON');
pause(3);
fwrite(socket, 'CONVEYOF');
pause(1);
fwrite(socket, 'CONVDIRE 0');
pause(1);
fwrite(socket, 'CONVEYON');
pause(3);
fwrite(socket, 'CONVEYOF');

function [str] =  ReceiveString(socket)
    data = fgetl(socket);
    str = strcat(char(data),'\n');
    fprintf(str);
end
