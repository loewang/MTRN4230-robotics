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
pause(0.5);
fwrite(socket, 'SETSOLEN 1');
pause(2);
fwrite(socket, 'SETSOLEN 0');
pause(0.5);
fwrite(socket, 'VACUUMOF');
pause(0.5);
fwrite(socket, 'CONVEYON');
pause(2);
fwrite(socket, 'CONVEYOF');
pause(0.5);
fwrite(socket, 'CONVDIRE 1');
pause(0.5);
fwrite(socket, 'CONVEYON');
pause(2);
fwrite(socket, 'CONVEYOF');

% Motion
fwrite(socket, 'MVPOSTAB 100,100,100');
pause(2);

fwrite(socket, 'JNTANGLE');
str = ReceiveString(socket);

fwrite(socket, 'EEPOSITN');
str = ReceiveString(socket);

fwrite(socket, 'EEORIENT');
str = ReceiveString(socket);

fwrite(socket, 'SETSPEED v500');
pause(0.5);

fwrite(socket, 'MVPOSCON 100,100,100');
pause(6);

fwrite(socket, 'JNTANGLE');
str = ReceiveString(socket);

fwrite(socket, 'EEPOSITN');
str = ReceiveString(socket);

fwrite(socket, 'EEORIENT');
str = ReceiveString(socket);

fwrite(socket, 'SETPOSES 10,10,10,10,10,10');
pause(2);

fwrite(socket, 'ROBPAUSE');
pause(3);
fwrite(socket, 'ROBRESME');
pause(5);
fwrite(socket, 'ROBPAUSE');
pause(1);
fwrite(socket, 'ROBCANCL');
pause(1);

fwrite(socket, 'SETSPEED v100');
pause(0.5);

i = 0;
while i < 10
    fwrite(socket, 'LINMDEND X,neg');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 10
    fwrite(socket, 'LINMDEND Y,neg');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 20
	fwrite(socket, 'LINMDEND Z,neg');
    pause(0.1);
    i = i + 1;
end

fwrite(socket, 'EEORIENT 0,0,1,0');
pause(1);

fwrite(socket, 'SETSPEED v10');
pause(0.5);

i = 0;
while i < 20
	fwrite(socket, 'LINMDBAS X,neg');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 20
	fwrite(socket, 'LINMDBAS Y,neg');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 20
	fwrite(socket, 'LINMDBAS Z,neg');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 20
	fwrite(socket, 'JOGJOINT 1,pos');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 20
	fwrite(socket, 'JOGJOINT 2,neg');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 20
	fwrite(socket, 'JOGJOINT 3,pos');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 20
	fwrite(socket, 'JOGJOINT 4,neg');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 20
	fwrite(socket, 'JOGJOINT 5,pos');
    pause(0.1);
    i = i + 1;
end

i = 0;
while i < 20
	fwrite(socket, 'JOGJOINT 6,neg');
    pause(0.1);
    i = i + 1;
end

function [str] =  ReceiveString(socket)
    data = fgetl(socket);
    str = strcat(char(data),'\n');
    fprintf(str);
end



