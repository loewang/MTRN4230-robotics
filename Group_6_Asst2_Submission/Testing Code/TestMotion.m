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

% Motion

fwrite(socket, 'MVPOSTAB 0,0,0'); %T3 
str = ReceiveString(socket);
pause(10);
fwrite(socket, 'EEPOSITN');
str = ReceiveString(socket);
pause(0.1);

fwrite(socket, 'SETSPEED v200');
pause(0.5);
fwrite(socket, 'MVPOSCON 0,0,0'); %C1 
str = ReceiveString(socket);
pause(6);
fwrite(socket, 'EEPOSITN');
str = ReceiveString(socket);
pause(0.1);

fwrite(socket, 'SETSPEED v100');
pause(0.5);
fwrite(socket, 'SETPOSES 10,10,10,10,10,10');
str = ReceiveString(socket);
pause(10);
fwrite(socket, 'JNTANGLE');
str = ReceiveString(socket);
pause(0.1);
fwrite(socket, 'EEPOSITN');
str = ReceiveString(socket);
pause(0.1);

fwrite(socket, 'EEORIENT 0,0,1,0');
str = ReceiveString(socket);
pause(2);
fwrite(socket, 'EEORIENT');
str = ReceiveString(socket);
pause(0.1);
fwrite(socket, 'EEPOSITN');
str = ReceiveString(socket);
pause(0.1);


function [str] =  ReceiveString(socket)
    data = fgetl(socket);
    str = strcat(char(data),'\n');
    fprintf(str);
end