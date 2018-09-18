function GUI2RAPID()
    clc; clear; close all;

    %start GUI
    app = IRB120GUI();
    pause(0.5);
    disp('GUI OPEN');
    
    if(strcmp(app.ControlModeButtonGroup.SelectedObject.Text,'Robot'))
        robot_IP_address = '192.168.125.1';
    else
        robot_IP_address = '127.0.0.1'; % Simulation ip address
    end

    robot_port = 1025;

    socket = tcpip(robot_IP_address, robot_port);
    set(socket, 'ReadAsyncMode', 'continuous');
    
    if(~isequal(get(socket, 'Status'), 'open'))
        try
            fopen(socket);
            disp('Connected');
            app.ConnectionStatusLamp.Color = 'g';
            app.DirectionSwitch_Changed = 1;
            app.PumpSwitch_Changed = 1;
            app.ConRunButton_Pressed = 1;
            app.VacRunButton_Pressed = 1;
            
        catch
            fprintf('Could not open TCP connection to %s on port %d\n',robot_IP_address, robot_port);
            app.ConnectionStatusLamp.Color = 'r';
        end
    end
    
    prevMoved = 0;
    PrevConStat = 'g';
    PrevMotorsON = 'g';
    PrevEstop = 'g';
    PrevExErr = 'g';
    PrevMotEn = 'g';
    PrevLightCurt = 'g';
    PrevMotionSup = 'g';
    
    while(1)
        if(~isequal(get(socket, 'Status'), 'open'))
            fprintf('Could not open TCP connection to %s on port %d\n',robot_IP_address, robot_port);
            app.ConnectionStatusLamp.Color = 'r';
        end
        
        while(isequal(get(socket, 'Status'), 'open'))
            
            if(app.QuitButton_Pressed)
                break;
            end
            
            if(app.ControlModeButton_Changed)
                if(strcmp(app.ControlModeButtonGroup.SelectedObject.Text,'Robot'))
                    robot_IP_address = '192.168.125.1';
                else
                    robot_IP_address = '127.0.0.1'; % Simulation ip address
                end
                break;
            end
            
            % Get Robot status update
            
            fwrite(socket,'GTCONSTA');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.ConveyorStatusLamp.Color = 'g';
                PrevConStat = 'g';
            else
                app.ConveyorStatusLamp.Color = 'r';
                if(PrevConStat == 'g')
                    run('Message_ConveyorEnable.mlapp');
                end
                PrevConStat = 'r';
            end
            
            fwrite(socket,'GTVACRUN');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.PumpLamp.Color = 'g';
            else
                app.PumpLamp.Color = 'r';
            end
            
            fwrite(socket,'GTVACSOL');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.VacSolLamp.Color = 'g';
            else
                app.VacSolLamp.Color = 'r';
            end
            
            fwrite(socket,'GTCONRUN');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.ConRunLamp.Color = 'g';
            else
                app.ConRunLamp.Color = 'r';
            end
            
            fwrite(socket,'GTCONDIR');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.DirectionLamp.Color = 'g';
            else
                app.DirectionLamp.Color = 'r';
            end
            
            fwrite(socket,'GTMOTONS');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.MotorsONLamp.Color = 'g';
                PrevMotorsON = 'g';
            else
                app.MotorsONLamp.Color = 'r';
                if(PrevMotorsON == 'g')
                    run('Message_MotorOff.mlapp');
                end
                PrevMotorsON = 'r';
            end
            
            fwrite(socket,'GTESTOP1');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.EmergencyStopLamp.Color = 'g';
                PrevEstop = 'g';
            else
                app.EmergencyStopLamp.Color = 'r';
                if(PrevEstop == 'g')
                    run('Message_eStop.mlapp');
                end
                PrevEstop = 'r';
            end
            
            fwrite(socket,'GTEXCERR');
            str = ReceiveString(socket);
            if(strcmp(str,'0'))
                app.ExecutionErrorLamp.Color = 'g';
                PrevExErr = 'g';
            else
                app.ExecutionErrorLamp.Color = 'r';
                if(PrevExErr == 'g')
                    run('Message_ExcecutionError.mlapp');
                end
                PrevExErr = 'r';
            end

            fwrite(socket,'GTHDENBL');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.MotorsEnableLamp.Color = 'g';
                PrevMotEn = 'g';
            else
                app.MotorsEnableLamp.Color = 'r';
                if(PrevMotEn == 'g')
                    run('Message_HoldEnable.mlapp');
                end
                PrevMotEn = 'r';
            end
            
            fwrite(socket,'GTLTCURT');
            str = ReceiveString(socket);
            if(strcmp(str,'0'))
                app.LightCurtainLamp.Color = 'g';
                PrevLightCurt = 'g';
            else
                app.LightCurtainLamp.Color = 'r';
                if(PrevLightCurt == 'g')
                    run('Message_LightCurtain.mlapp');
                end
                PrevLightCurt = 'r';
            end
            
            fwrite(socket,'GTMOTSUP');
            str = ReceiveString(socket);
            if(strcmp(str,'0'))
                app.MotionSupervisionLamp.Color = 'g';
                PrevMotionSup = 'g';
            else
                app.MotionSupervisionLamp.Color = 'r';
                if(PrevMotionSup == 'g')
                    run('Message_MotionSupervision.mlapp');
                end
                PrevMotionSup = 'r';
            end
            
            fwrite(socket, 'JNTANGLE');
            str = ReceiveString(socket);
            jAng = str2num(str);
            
            app.JointAnglesEditField.Value = jAng(1);
            app.JointAnglesEditField_2.Value = jAng(2);
            app.JointAnglesEditField_3.Value = jAng(3);
            app.JointAnglesEditField_4.Value = jAng(4);
            app.JointAnglesEditField_5.Value = jAng(5);
            app.JointAnglesEditField_6.Value = jAng(6);

            fwrite(socket, 'EEPOSITN');
            str = ReceiveString(socket);
            EEPos = str2num(str);
            
            app.EEPosEditField_X.Value = EEPos(1);
            app.EEPosEditField_Y.Value = EEPos(2);
            app.EEPosEditField_Z.Value = EEPos(3);

            fwrite(socket, 'EEORIENT');
            str = ReceiveString(socket);
            EEOri = str2num(str);
            
            app.EEOriEditField_X.Value = EEOri(1);
            app.EEOriEditField_Y.Value = EEOri(2);
            app.EEOriEditField_Z.Value = EEOri(3);
            
            fwrite(socket, 'INMOTION');
            str = ReceiveString(socket);
            
            if(strcmp(str,'FALSE'))
                app.RobotReadyLamp.Color = 'g';
            else
                app.RobotReadyLamp.Color = 'r';
            end

            if(app.DirectionSwitch_Changed)
                SwitchCommand(app.DirectionSwitch.Value,socket,'Forward','CONVDIRE 0','CONVDIRE 1');
                app.DirectionSwitch_Changed = 0;
            end 

            if(app.PumpSwitch_Changed)
                SwitchCommand(app.PumpSwitch.Value,socket,'On','VACUUMOF','VACUUMON');
                app.PumpSwitch_Changed = 0;
            end     

            if(app.ConRunButton_Pressed)
                ToggleCommand(app.ConRunButton.Value,socket,'CONVEYOF','CONVEYON');
                app.ConRunButton_Pressed = 0;
            end     

            if(app.VacRunButton_Pressed)       
                ToggleCommand(app.VacRunButton.Value,socket,'SETSOLEN 0','SETSOLEN 1');
                app.VacRunButton_Pressed = 0;
            end     

            if(app.MovetoHomePositionButton_Pressed)
                MovetoHomePositionButtonCommand(app,socket);
                app.MovetoHomePositionButton_Pressed = 0;
            end     
            
            if(app.JogSpeedKnob_Changed)
                KnobCommand(app.JogSpeedKnob.Value, socket)
                app.JogSpeedKnob_Changed = 0;
            end

           if(strcmp(app.JogFrameButtonGroup.SelectedObject.Text, 'Base'))
                if(app.XButton_Pressed)
                    fwrite(socket, 'LINMDBAS X,pos');
                    disp('LINMDBAS X,pos');
                    app.XButton_Pressed = 0;
                end

                if(app.XButton_2_Pressed)       
                    fwrite(socket, 'LINMDBAS X,neg');
                    disp('LINMDBAS X,neg');
                    app.XButton_2_Pressed = 0;
                end

                if(app.YButton_Pressed)          
                    fwrite(socket, 'LINMDBAS Y,pos');  
                    disp('LINMDBAS Y,pos');
                    app.YButton_Pressed = 0;
                end

                if(app.YButton_3_Pressed)              
                    fwrite(socket, 'LINMDBAS Y,neg'); 
                    disp('LINMDBAS Y,neg');
                    app.YButton_3_Pressed = 0;
                end

                if(app.ZButton_Pressed)             
                    fwrite(socket, 'LINMDBAS Z,pos');    
                    disp('LINMDBAS Z,pos');
                    app.ZButton_Pressed = 0;
                end

                if(app.ZButton_2_Pressed)              
                    fwrite(socket, 'LINMDBAS Z,neg'); 
                    disp('LINMDBAS Z,neg');
                    app.ZButton_2_Pressed = 0;
                end
            end
            
            
            if(strcmp(app.JogFrameButtonGroup.SelectedObject.Text, 'End Effector'))
                if(app.XButton_Pressed)
                    fwrite(socket, 'LINMDEND X,pos');
                    disp('LINMDEND X,pos');
                    app.XButton_Pressed = 0;
                end

                if(app.XButton_2_Pressed)             
                    fwrite(socket, 'LINMDEND X,neg');
                    disp('LINMDEND X,pos');         
                    app.XButton_2_Pressed = 0;
                end

                pause(0.1);

                if(app.YButton_Pressed)              
                    fwrite(socket, 'LINMDEND Y,pos');
                    disp('LINMDEND Y,pos');             
                    app.YButton_Pressed = 0;
                end

                if(app.YButton_3_Pressed)               
                    fwrite(socket, 'LINMDEND Y,neg');
                    disp('LINMDEND Y,neg');
                    app.YButton_3_Pressed = 0;
                end

                pause(0.1);

                if(app.ZButton_Pressed)            
                    fwrite(socket, 'LINMDEND Z,pos');
                    disp('LINMDEND Z,pos');         
                    app.ZButton_Pressed = 0;
                end
                
                if(app.ZButton_2_Pressed)               
                    fwrite(socket, 'LINMDEND Z,neg');
                    disp('LINMDEND Z,neg');                
                    app.ZButton_2_Pressed = 0;
                end
            end

            if(app.Button_Pressed)
                disp('Joint + pressed');
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q1'))
                    fwrite(socket, 'JOGJOINT 1,pos');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q2'))
                    fwrite(socket, 'JOGJOINT 2,pos');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q3'))
                    fwrite(socket, 'JOGJOINT 3,pos');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q4'))
                    fwrite(socket, 'JOGJOINT 4,pos');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q5'))
                    fwrite(socket, 'JOGJOINT 5,pos');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q6'))
                    fwrite(socket, 'JOGJOINT 6,pos');
                end
                
                app.Button_Pressed = 0;
            end
            
            
            if(app.Button_4_Pressed)
                disp('Joint - Pressed');
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q1'))
                    fwrite(socket, 'JOGJOINT 1,neg');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q2'))
                    fwrite(socket, 'JOGJOINT 2,neg');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q3'))
                    fwrite(socket, 'JOGJOINT 3,neg');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q4'))
                    fwrite(socket, 'JOGJOINT 4,neg');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q5'))
                    fwrite(socket, 'JOGJOINT 5,neg');
                end
                
                if(strcmp(app.JointButtonGroup.SelectedObject.Text, 'q6'))
                    fwrite(socket, 'JOGJOINT 6,neg');
                end
                
                app.Button_4_Pressed = 0;
            end
            
           if(app.MoveButton_Pressed)
                
                if(app.MoveButton.Value == 1)
                    if(prevMoved == 1)
                        % if move = 1 -> move
                        fwrite(socket, 'ROBRESME');
                        prevMoved = 0;
                    else
                        if(strcmp(app.InputMethodButtonGroup.SelectedObject.Text, 'Joint Angles'))
                            disp('Joint Angle Mode');

                            fwrite(socket, sprintf('SETPOSES %f,%f,%f,%f,%f,%f',...
                            app.JointAnglesEditField_q1.Value,app.JointAnglesEditField_q2.Value,...
                            app.JointAnglesEditField_q3.Value, app.JointAnglesEditField_q4.Value,...
                            app.JointAnglesEditField_q5.Value,app.JointAnglesEditField_q6.Value)); 
                        end
                        
                        if(strcmp(app.InputMethodButtonGroup.SelectedObject.Text, 'Reorient End Effector'))
                            disp('Reorient EE Mode');

                            fwrite(socket, sprintf('EEORIENT %f,%f,%f,%f',...
                            app.ReorientEndEffectorEditField.Value, app.ReorientEndEffectorEditField_2.Value, ...
                            app.ReorientEndEffectorEditField_3.Value,  app.ReorientEndEffectorEditField_4.Value)); 
                        end
                        
                        if(strcmp(app.InputMethodButtonGroup.SelectedObject.Text, 'End Effector Position'))
                            disp('EE Position Mode');
                            
                            if(strcmp(app.RelativeHomeDropDown.Value, 'Table'))
                                fwrite(socket, sprintf('MVPOSTAB %f,%f,%f',...
                                    app.EndEffectorPositionEditField_X.Value, app.EndEffectorPositionEditField_Y.Value,...
                                    app.EndEffectorPositionEditField_Z.Value));
                            else
                                fwrite(socket, sprintf('MVPOSCON %f,%f,%f',...
                                    app.EndEffectorPositionEditField_X.Value, app.EndEffectorPositionEditField_Y.Value,...
                                    app.EndEffectorPositionEditField_Z.Value));
                            end
                        
                        end
                        
                    end 
                else 
                    %if move = 0 -> pause
                    fwrite(socket, 'ROBPAUSE');
                end
                prevMoved = 1;
                pause(0.1);
            end
            
            pause(0.01);
        end
        
        if(app.ReconnectButton_Pressed)
            try
                socket = tcpip(robot_IP_address, robot_port);
                set(socket, 'ReadAsyncMode', 'continuous');
                fopen(socket);
                disp('Connected');
                app.ConnectionStatusLamp.Color = 'g';
                
                app.DirectionSwitch_Changed = 1;
                app.PumpSwitch_Changed = 1;
                app.ConRunButton_Pressed = 1;
                app.VacRunButton_Pressed = 1;
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

function [str] =  ReceiveString(socket)
    data = fgetl(socket);
    %str = strcat(char(data),'\n');
    str = char(data);
%     disp(str);
end

function SwitchCommand(Switch,socket,state1,command0,command1)   
    if(strcmp(Switch,state1))
        fwrite(socket,command1);
        disp(command1);
        pause(0.15);
    else
        fwrite(socket,command0);
        disp(command0);
        pause(0.15);
    end
end

function ToggleCommand(Toggle,socket,command0,command1)
    if(Toggle == 1)
        fwrite(socket,command1);
        disp(command1);
        pause(0.15);
    else
        fwrite(socket,command0);
        disp(command0);
        pause(0.15);
    end
end

function KnobCommand(speedValue, socket)

    switch speedValue
            case 'Fine'  
                fwrite(socket, 'SETSPEED v10');
                disp('Fine');
            case 'Slow'
                fwrite(socket, 'SETSPEED v50');
                disp('Slow');
            case 'Medium'
                fwrite(socket, 'SETSPEED v100');
                disp('Medium');
            case 'Fast'
                fwrite(socket, 'SETSPEED v200');
                disp('Fast');
    end
end

function MovetoHomePositionButtonCommand(app,socket)
    if(app.MovetoHomePositionButton.Value == 1)
        fwrite(socket,'SETPOSES -90,0,0,0,0,0');
        disp('SETPOSES -90,0,0,0,0,0');
        pause(0.01);
    else
        fwrite(socket,'SETPOSES -90,0,0,0,0,0');
        disp('SETPOSES -90,0,0,0,0,0');
        pause(0.01);
    end
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
