
clc; clear; close all;

%start GUI
app = IRB120GUI();
pause(0.5);
disp('GUI OPEN');
%robot_IP_address = '192.168.125.1';
robot_IP_address = '127.0.0.1'; % Simulation ip address

robot_port = 1025;

socket = tcpip(robot_IP_address, robot_port);
set(socket, 'ReadAsyncMode', 'continuous');

if(~isequal(get(socket, 'Status'), 'open'))
    fopen(socket);
    app.ConnectionStatusLamp.Color = 'g';
end

if(~isequal(get(socket, 'Status'), 'open'))
    warning(['Could not open TCP connection to ', robot_IP_address, ' on port ', robot_port]);
    sprintf('Could not open TCP connection to %s on port %s',robot_IP_address, robot_port);
    app.ConnectionStatusLamp.Color = 'r';
    return;
end

PrevConDir = 'Backward';
PrevVacRun = 'Off';
PrevMvtoHom = 0;

while(isequal(get(socket, 'Status'), 'open'))

    ConDir = app.DirectionSwitch.Value;
    pause(0.2);
    if(~strcmp(ConDir,PrevConDir))
        if(strcmp(ConDir,'Forward'))
            fwrite(socket, 'CONVDIRE 1');
            disp('CONVDIRE 1');
            pause(0.1);
        else
            fwrite(socket, 'CONVDIRE 0');
            disp('CONVDIRE 0');
            pause(0.1);
        end
        PrevConDir = ConDir;
    end
    

    VacRun = app.PumpSwitch.Value;
    pause(0.2);
    if(~strcmp(VacRun,PrevVacRun))
        if(strcmp(VacRun,'On'))
            fwrite(socket, 'VACUUMON');
            disp('VACUUMON');
            pause(0.1);
        else
            fwrite(socket, 'VACUUMOF');
            disp('VACUUMOF');
            pause(0.1);
        end
        PrevVacRun = VacRun;
    end
    
    MvtoHom = app.MovetoHomePositionButton.Value;
    pause(0.2);
    if(MvtoHom~=PrevMvtoHom)
        if(MvtoHom==1)
            fwrite(socket, 'SETPOSES -90,0,0,0,0,0');
            disp('SETPOSES -90,0,0,0,0,0');
            pause(0.1);
        end
        PrevMvtoHom = MvtoHom;
    end

end

disp('Disconnected');
app.ConnectionStatusLamp.Color = 'r';

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
pause(2);

fwrite(socket, 'JNTANGLE');
str = ReceiveString(socket);

fwrite(socket, 'EEPOSITN');
str = ReceiveString(socket);

fwrite(socket, 'EEORIENT');
str = ReceiveString(socket);

fwrite(socket, 'SETPOSES 10,10,10,10,10,10');
pause(5);

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
while i < 10
	fwrite(socket, 'LINMDEND Z,neg');
    pause(0.1);
    i = i + 1;
end

fwrite(socket, 'EEORIENT 0,0,1,0');
pause(1);

fwrite(socket, 'SETSPEED v10');

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
    %fprintf(str);
end