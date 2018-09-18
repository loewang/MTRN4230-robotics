function GUI2RAPID()
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
        try
            fopen(socket);
            app.ConnectionStatusLamp.Color = 'g';
        catch
            fprintf('Could not open TCP connection to %s on port %d\n',robot_IP_address, robot_port);
            app.ConnectionStatusLamp.Color = 'r';
        end
    end

    while(1)
        if(~isequal(get(socket, 'Status'), 'open'))
            fprintf('Could not open TCP connection to %s on port %d\n',robot_IP_address, robot_port);
            app.ConnectionStatusLamp.Color = 'r';
        end
        
        while(isequal(get(socket, 'Status'), 'open'))
            
            if(app.QuitButton_Pressed)
                break;
            end

            if(app.DirectionSwitch_Changed)
                SwitchCommand(app.DirectionSwitch.Value,socket,'Forward','CONVDIRE 0','CONVDIRE 1')
                app.DirectionSwitch_Changed = 0;
            end 

            pause(0.1);

            if(app.PumpSwitch_Changed)
                SwitchCommand(app.PumpSwitch.Value,socket,'On','VACUUMOF','VACUUMON')
                app.PumpSwitch_Changed = 0;
            end     

            pause(0.1);

            if(app.ConRunButton_Pressed)
                ToggleCommand(app.ConRunButton.Value,socket,'CONVEYOF','CONVEYON')
                app.ConRunButton_Pressed = 0;
            end     

            pause(0.1);

            if(app.VacRunButton_Pressed)
                ToggleCommand(app.VacRunButton.Value,socket,'SETSOLEN 0','SETSOLEN 1')
                app.VacRunButton_Pressed = 0;
            end     

            pause(0.1);

            if(app.MovetoHomePositionButton_Pressed)
                ToggleCommand(app.ConRunButton.Value,socket,'SETPOSES -90,0,0,0,0,0','SETPOSES -90,0,0,0,0,0')
                app.MovetoHomePositionButton_Pressed = 0;
            end     

            pause(0.1);
        end
        
        if(app.ReconnectButton_Pressed)
            try
                fopen(socket);
                app.ConnectionStatusLamp.Color = 'g';
            catch
                disp('Reconnection Failed');
                app.ConnectionStatusLamp.Color = 'r';
            end
            app.ReconnectButton_Pressed = 0;
        end
        
        if(app.QuitButton_Pressed)
            app.delete();
            break;
        end
        
        pause(1);
    end
    disp('IRB120 Session Ended');
end

function SwitchCommand(Switch,socket,state1,command0,command1)   
    if(strcmp(Switch,state1))
        fwrite(socket,command1);
        disp(command1);
    else
        fwrite(socket,command0);
        disp(command0);
    end
end

function ToggleCommand(Toggle,socket,command0,command1)
    if(Toggle == 1)
        fwrite(socket,command1);
        disp(command1);
    else
        fwrite(socket,command0);
        disp(command0);
    end
end

function Val = CheckToggleButtonChange(socket,Tbutton,prevVal,command0,command1)
    TbuttVal = Tbutton;
    pause(0.2);
    
    if(TbuttVal~=prevVal)
        if(TbuttVal == 1)
            fwrite(socket, command1);
            disp(command1);
            pause(0.1);
        else
            fwrite(socket, command0);
            disp(command0);
            pause(0.1);
        end
    end
    Val = buttVal;
end

function Val = ReconnectButtonChange(app,socket,button,prevVal)
    buttVal = button;
    pause(0.2);
    
    if(buttVal~=prevVal)
        f(~isequal(get(socket, 'Status'), 'open'))
        fopen(socket);
        app.ConnectionStatusLamp.Color = 'g';
    end

    if(~isequal(get(socket, 'Status'), 'open'))
        warning(['Could not open TCP connection to ', robot_IP_address, ' on port ', robot_port]);
        sprintf('Could not open TCP connection to %s on port %s',robot_IP_address, robot_port);
        app.ConnectionStatusLamp.Color = 'r';
    end
      
    Val = buttVal;
end

% % DIO
% fwrite(socket, 'VACUUMON');
% pause(0.5);
% fwrite(socket, 'SETSOLEN 1');
% pause(2);
% fwrite(socket, 'SETSOLEN 0');
% pause(0.5);
% fwrite(socket, 'VACUUMOF');
% pause(0.5);
% fwrite(socket, 'CONVEYON');
% pause(2);
% fwrite(socket, 'CONVEYOF');
% pause(0.5);
% fwrite(socket, 'CONVDIRE 1');
% pause(0.5);
% fwrite(socket, 'CONVEYON');
% pause(2);
% fwrite(socket, 'CONVEYOF');
% 
% % Motion
% fwrite(socket, 'MVPOSTAB 100,100,100');
% pause(2);
% 
% fwrite(socket, 'JNTANGLE');
% str = ReceiveString(socket);
% 
% fwrite(socket, 'EEPOSITN');
% str = ReceiveString(socket);
% 
% fwrite(socket, 'EEORIENT');
% str = ReceiveString(socket);
% 
% fwrite(socket, 'SETSPEED v500');
% pause(0.5);
% 
% fwrite(socket, 'MVPOSCON 100,100,100');
% pause(2);
% 
% fwrite(socket, 'JNTANGLE');
% str = ReceiveString(socket);
% 
% fwrite(socket, 'EEPOSITN');
% str = ReceiveString(socket);
% 
% fwrite(socket, 'EEORIENT');
% str = ReceiveString(socket);
% 
% fwrite(socket, 'SETPOSES 10,10,10,10,10,10');
% pause(5);
% 
% fwrite(socket, 'SETSPEED v100');
% pause(0.5);
% 
% i = 0;
% while i < 10
%     fwrite(socket, 'LINMDEND X,neg');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 10
%     fwrite(socket, 'LINMDEND Y,neg');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 10
% 	fwrite(socket, 'LINMDEND Z,neg');
%     pause(0.1);
%     i = i + 1;
% end
% 
% fwrite(socket, 'EEORIENT 0,0,1,0');
% pause(1);
% 
% fwrite(socket, 'SETSPEED v10');
% 
% i = 0;
% while i < 20
% 	fwrite(socket, 'LINMDBAS X,neg');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 20
% 	fwrite(socket, 'LINMDBAS Y,neg');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 20
% 	fwrite(socket, 'LINMDBAS Z,neg');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 20
% 	fwrite(socket, 'JOGJOINT 1,pos');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 20
% 	fwrite(socket, 'JOGJOINT 2,neg');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 20
% 	fwrite(socket, 'JOGJOINT 3,pos');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 20
% 	fwrite(socket, 'JOGJOINT 4,neg');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 20
% 	fwrite(socket, 'JOGJOINT 5,pos');
%     pause(0.1);
%     i = i + 1;
% end
% 
% i = 0;
% while i < 20
% 	fwrite(socket, 'JOGJOINT 6,neg');
%     pause(0.1);
%     i = i + 1;
% end
% 
% function [str] =  ReceiveString(socket)
%     data = fgetl(socket);
%     str = strcat(char(data),'\n');
%     %fprintf(str);
% end
