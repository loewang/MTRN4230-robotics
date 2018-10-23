function Ass3GUI2RAPID()
    clc; clear; close all;

    %start GUI
    app = IRB120GUI();
    mvapp = MoveGUI();
    pause(0.5);
    disp('GUIs OPEN');
    
    prevMoved = 0;
    inmotion = 0;
    
    letters = {'A','B','C','D','E','F','G','H','I'}';
    rows = repmat(letters,1,9);
    numbers = {'1','2','3','4','5','6','7','8','9'};
    cols = repmat(numbers,9,1);
    BP.names = strcat(rows,cols);
    
    BPX = ((35/2 + 1):36:((35/2 + 1) + (36*8)))';
    rows = repmat(BPX,9,1);
    BPY = (-(36*4):36:(36*4));
    cols = repelem(BPY,9)';
    BP.XY = [rows cols];

    if(strcmp(app.ControlModeButtonGroup.SelectedObject.Text,'Robot'))
        robot_IP_address = '192.168.125.1';
    else
        robot_IP_address = '127.0.0.1'; % Simulation ip address
    end

    robot_port = 1025;

    socket = tcpip(robot_IP_address, robot_port);
    set(socket, 'ReadAsyncMode', 'continuous');
    
    %attempt to connect to Robot
    if(~isequal(get(socket, 'Status'), 'open'))
        try
            fopen(socket);
            disp('Connected');
            app.ConnectionStatusLamp.Color = 'g';
            mvapp.ConnectionLamp.Color = 'g';
            app.DirectionSwitch_Changed = 1;
            app.PumpSwitch_Changed = 1;
            app.ConRunButton_Pressed = 1;
            app.VacRunButton_Pressed = 1;
            
        catch
            fprintf('Could not open TCP connection to %s on port %d\n',robot_IP_address, robot_port);
            app.ConnectionStatusLamp.Color = 'r';
            mvapp.ConnectionLamp.Color = 'r';
        end
    end
    
    % MAIN LOOP
    while(1)
        %attempt to Reconnect
        if(~isequal(get(socket, 'Status'), 'open'))
            fprintf('Could not open TCP connection to %s on port %d\n',robot_IP_address, robot_port);
            app.ConnectionStatusLamp.Color = 'r';
            mvapp.ConnectionLamp.Color = 'r';
        end
        
        % Loop GUI buttons if connected
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
                mvapp.ConveyorReadyLamp.Color = 'g';
                app.ConveyorStatusLamp.Color = 'g';
            else
                mvapp.ConveyorReadyLamp.Color = 'r';
                app.ConveyorStatusLamp.Color = 'r';
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
            else
                app.MotorsONLamp.Color = 'r';
            end
            
            fwrite(socket,'GTESTOP1');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.EmergencyStopLamp.Color = 'g';
            else
                app.EmergencyStopLamp.Color = 'r';
            end
            
            fwrite(socket,'GTEXCERR');
            str = ReceiveString(socket);
            if(strcmp(str,'0'))
                app.ExecutionErrorLamp.Color = 'g';
            else
                app.ExecutionErrorLamp.Color = 'r';
            end

            fwrite(socket,'GTHDENBL');
            str = ReceiveString(socket);
            if(strcmp(str,'1'))
                app.MotorsEnableLamp.Color = 'g';
            else
                app.MotorsEnableLamp.Color = 'r';
            end
            
            fwrite(socket,'GTLTCURT');
            str = ReceiveString(socket);
            if(strcmp(str,'0'))
                app.LightCurtainLamp.Color = 'g';
            else
                app.LightCurtainLamp.Color = 'r';
            end
            
            fwrite(socket,'GTMOTSUP');
            str = ReceiveString(socket);
            if(strcmp(str,'0'))
                app.MotionSupervisionLamp.Color = 'g';
            else
                app.MotionSupervisionLamp.Color = 'r';
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
                mvapp.RobotReadyLamp.Color = 'g';
                app.RobotReadyLamp.Color = 'g'; 
                if(inmotion)
                    app.MoveButton.Value = 0;
                    app.MovetoHomePositionButton.Value = 0;
                    mvapp.MOVEButton.Text = 'MOVE';
                    inmotion = 0;
                end
            else
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';
                inmotion = 1;
            end
            
            %Process buttons
            if(mvapp.LoadingBayButtonPressed)
                disp('Moving to loading bay');
                fwrite(socket,'CONVEYOF');
                pause(0.15);
                fwrite(socket,'CONVDIRE 0');
                pause(0.15);
                fwrite(socket,'CONVEYON');
                pause(10);
                fwrite(socket,'CONVEYOF');
                pause(0.15);

                mvapp.LoadingBayButtonPressed = 0;
            end
            
             if(mvapp.RobotBayButtonPressed)
                disp('Moving to Robot bay');
                fwrite(socket,'CONVEYOF');
                pause(0.15);
                fwrite(socket,'CONVDIRE 1');
                pause(0.15);
                fwrite(socket,'CONVEYON');
                pause(10);
                fwrite(socket,'CONVEYOF');
                pause(0.15);

                mvapp.RobotBayButtonPressed = 0;
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
            
            %IRB120GUI Move button
            if(app.MoveButton_Pressed)  
                if(app.MoveButton.Value == 1)
                    if(prevMoved == 1)
                        % if move = 1 -> move
                        fwrite(socket, 'ROBRESME');
                        disp('ROBRESME');
                        prevMoved = 0;
                    else
                        if(strcmp(app.InputMethodButtonGroup.SelectedObject.Text, 'Joint Angles'))
                            disp('Joint Angle Mode');
                            cmd = sprintf('SETPOSES %f,%f,%f,%f,%f,%f',...
                                app.JointAnglesEditField_q1.Value,app.JointAnglesEditField_q2.Value,...
                                app.JointAnglesEditField_q3.Value, app.JointAnglesEditField_q4.Value,...
                                app.JointAnglesEditField_q5.Value,app.JointAnglesEditField_q6.Value);
                            disp(cmd);
                            fwrite(socket,cmd);
                        
                        elseif(strcmp(app.InputMethodButtonGroup.SelectedObject.Text, 'Reorient End Effector'))
                            disp('Reorient EE Mode');
                            cmd = sprintf('EEORIENT %f,%f,%f,%f',...
                                app.ReorientEndEffectorEditField.Value, app.ReorientEndEffectorEditField_2.Value, ...
                                app.ReorientEndEffectorEditField_3.Value,  app.ReorientEndEffectorEditField_4.Value);
                            disp(cmd);
                            fwrite(socket,cmd);
                        
                        elseif(strcmp(app.InputMethodButtonGroup.SelectedObject.Text, 'End Effector Position'))
                            disp('EE Position Mode');
                            
                            if(strcmp(app.RelativeHomeDropDown.Value, 'Table'))
                                cmd = sprintf('MVPOSTAB %f,%f,%f',...
                                    app.EndEffectorPositionEditField_X.Value, app.EndEffectorPositionEditField_Y.Value,...
                                    app.EndEffectorPositionEditField_Z.Value);
                                disp(cmd);
                                fwrite(socket,cmd);
                            else
                                cmd = sprintf('MVPOSCON %f,%f,%f',...
                                    app.EndEffectorPositionEditField_X.Value, app.EndEffectorPositionEditField_Y.Value,...
                                    app.EndEffectorPositionEditField_Z.Value);
                                disp(cmd);
                            	fwrite(socket,cmd);
                            end
                            
                        end
                        prevMoved = 1;
                    end
                else
                    %if move = 0 -> pause
                    fwrite(socket, 'ROBPAUSE');
                    disp('ROBPAUSE');
                end
                app.MoveButton_Pressed = 0;
                pause(0.1);
            end
            
            %SIMPLE MOVE 
            if(mvapp.MOVEButtonPressed)  
                fwrite(socket,'SETSOLEN 0');
                if(strcmp(mvapp.MOVEButton.Text,"PAUSE"))
                    mode = mvapp.DropDown.Value;
                    
                   if(strcmp(mode,'BP to Conveyor'))
                       targetBP = mvapp.BP1EditField.Value;
                       ri = double(targetBP(1))-64;
                       ci = str2double(targetBP(2));
                       BPi = sub2ind([9 9],ri,ci);
                       tabXY = BP.XY(BPi,:);
                       

                       %move to BP position
                       cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                       fprintf("Moving to %s\n",targetBP);
                       disp(cmd);
                       fwrite(socket,cmd);
                       pause(5);
                       
                       % pick up block
                       cmd = 'VACUUMON';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(0.1);
                       cmd = 'SETSOLEN 1';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(0.1);
                       
                       %move to conveyor
                       cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(3);
                       cmd ='SETPOSES 90,0,20,0,0,0';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(5);
                       cmd = 'MVPOSCON 0,0,100';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(1);
                       
                       blockreleased = 0;
                       while(~blockreleased)
                           fwrite(socket, 'INMOTION');
                           str = ReceiveString(socket); 
                           pause(0.2);
                           if(strcmp(str,'FALSE'))
                               cmd = 'SETSOLEN 0';
                               fwrite(socket,cmd);
                               disp(cmd);
                               pause(0.1);
                               
                               cmd = 'VACUUMOF';
                               fwrite(socket,cmd);
                               disp(cmd);
                               pause(0.1);
                               blockreleased = 1;
                           end
                       end

                       %move back to table 
                       cmd = 'MVPOSCON 0,0,200';
                       fwrite(socket,cmd);
                       disp(cmd); 
                       pause(3);
                       cmd ='SETPOSES 0,0,20,0,0,0';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(6);
                       cmd = 'MVPOSTAB 0,0,14';
                       fwrite(socket,cmd);
                       disp(cmd);
                       
                   elseif(strcmp(mode,'Conveyor to BP'))
                       targetBP = mvapp.BP1EditField.Value;
                       ri = double(targetBP(1))-64;
                       ci = str2double(targetBP(2));
                       BPi = sub2ind([9 9],ri,ci);
                       tabXY = BP.XY(BPi,:);

                       %move to conveyor block
                       cmd ='SETPOSES 90,0,20,0,0,0';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(6);
                       cmd = 'MVPOSCON 0,0,13';
                       disp(cmd);
                       fwrite(socket,cmd);
                       pause(3);
                       
                       % pick up block
                       cmd = 'VACUUMON';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(0.1);
                       cmd = 'SETSOLEN 1';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(0.2);
                       
                       %move to table
                       cmd = 'MVPOSCON 0,0,150';
                       disp(cmd);
                       fwrite(socket,cmd);
                       pause(3);
                       cmd ='SETPOSES 0,0,20,0,0,0';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(5);
                       cmd = sprintf('MVPOSTAB %f,%f,14',tabXY);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(3);
                       
                       blockreleased = 0;
                       while(~blockreleased)
                           fwrite(socket, 'INMOTION');
                           str = ReceiveString(socket); 
                           pause(0.2);
                           if(strcmp(str,'FALSE'))
                               cmd = 'SETSOLEN 0';
                               fwrite(socket,cmd);
                               disp(cmd);
                               pause(0.1);
                               
                               cmd = 'VACUUMOF';
                               fwrite(socket,cmd);
                               disp(cmd);
                               pause(0.1);
                               blockreleased = 1;
                           end
                       end
                       cmd = 'MVPOSTAB 0,0,14';
                       fwrite(socket,cmd);
                       disp(cmd);
                       
                   elseif(strcmp(mode,'BP to BP'))
                       BP1 = mvapp.BP1EditField.Value;
                       ri = double(BP1(1))-64;
                       ci = str2double(BP1(2));
                       BPi = sub2ind([9 9],ri,ci);
                       tabXY1 = BP.XY(BPi,:);
                       
                       BP2 = mvapp.BP2EditField.Value;
                       ri = double(BP2(1))-64;
                       ci = str2double(BP2(2));
                       BPi = sub2ind([9 9],ri,ci);
                       tabXY2 = BP.XY(BPi,:);

                       %move to start BP
                       cmd ='SETPOSES 0,0,20,0,0,0';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(3);
                       cmd = sprintf('MVPOSTAB %f,%f,14',tabXY1);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(6);
                       
                       % pick up block
                       cmd = 'VACUUMON';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(0.1);
                       cmd = 'SETSOLEN 1';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(1);
                       
                       %move to goal BP
                       cmd = sprintf('MVPOSTAB %f,%f,50',tabXY1);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(1);
                       cmd = sprintf('MVPOSTAB %f,%f,50',tabXY2);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(6);
                       cmd = sprintf('MVPOSTAB %f,%f,14',tabXY2);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(3);
            
                       cmd = 'SETSOLEN 0';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(0.1);
                       
                       cmd = 'VACUUMOF';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(0.1);
                       
                       cmd = sprintf('MVPOSTAB %f,%f,50',tabXY2);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(3);       
                       cmd = 'MVPOSTAB 0,0,14';
                       fwrite(socket,cmd);
                       disp(cmd);
                       
                   else
                       targetBP = mvapp.BP1EditField.Value;
                       ri = double(targetBP(1))-64;
                       ci = str2double(targetBP(2));
                       BPi = sub2ind([9 9],ri,ci);
                       tabXY = BP.XY(BPi,:);
                       
                       %move to BP
                       cmd ='SETPOSES 0,0,20,0,0,0';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(3);
                       cmd = sprintf('MVPOSTAB %f,%f,14',tabXY);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(6);
                       
                       % pick up block
                       cmd = 'VACUUMON';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(0.1);
                       cmd = 'SETSOLEN 1';
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(1);
                       
                       cmd = sprintf('MVPOSTAB %f,%f,50',tabXY);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(2);
                       
                       angle = str2double(mvapp.BP2EditField.Value);
                       cmd = sprintf('SETPOSES 0,0,20,0,0,%f',angle);
                       fwrite(socket,cmd);
                       disp(cmd);
                       pause(2);
                       
                       cmd = sprintf('MVPOSTAB %f,%f,14',tabXY);
                       fwrite(socket,cmd);
                       disp(cmd);
                       
                       blockreleased = 0;
                       while(~blockreleased)
                           fwrite(socket, 'INMOTION');
                           str = ReceiveString(socket); 
                           pause(0.2);
                           if(strcmp(str,'FALSE'))
                               cmd = 'SETSOLEN 0';
                               fwrite(socket,cmd);
                               disp(cmd);
                               pause(0.1);
                               
                               cmd = 'VACUUMOF';
                               fwrite(socket,cmd);
                               disp(cmd);
                               pause(0.1);
                               blockreleased = 1;
                           end
                           cmd = sprintf('MVPOSTAB %f,%f,50',tabXY);
                           fwrite(socket,cmd);
                           disp(cmd);
                           pause(3);
                           cmd = 'MVPOSTAB 0,0,14';
                           fwrite(socket,cmd);
                           disp(cmd);
                       end
                       
                   end
                end

                mvapp.MOVEButtonPressed = 0;
                pause(0.1);
            end
            
            
         
            % ---------------------------------------- Fill button pressed
            if(mvapp.FILLButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                
                % check if Player 1
                if(strcmp(mvapp.DropDown_2.Value, 'Player 1'))
                
                    % Move to conveyer to pick up block
                    cmd = 'SETPOSES 90,0,20,0,0,0';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(5);
                    
                    cmd = 'MVPOSCON 0,0,100';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(1);
                    
                    % Pick up block
                    cmd = 'VACUUMON';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.5);
                    
                    cmd = 'SETSOLEN 1';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    % Move block to table
                    cmd = 'MVPOSCON 0,0,200';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(3);
                    
                    % Depending where next block is, move to that pos
                    % Block pos in an array for WESTERN SIDE (Player 1)
                    cmd = sprintf('MVPOSTAB %f,%f,14', blockPosWesternSide);
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(1);
                    
                    % Release block in its position
                    cmd = 'SETSOLEN 0';
                    fwrite(socket, cmd);
                    pause(0.1);
                    disp(cmd);
                    
                    cmd = 'VACUUMOF';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    % Repeat this 5 more times since 6 blocks
                    
                % Player 2
                else
                    
                    % Move to conveyer to pick up block
                    cmd = 'SETPOSES 90,0,20,0,0,0';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(5);
                    
                    cmd = 'MVPOSCON 0,0,100';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(1);
                    
                    % Pick up block
                    cmd = 'VACUUMON';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.5);
                    
                    cmd = 'SETSOLEN 1';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    % Move block to table
                    cmd = 'MVPOSCON 0,0,200';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(3);
                    
                    % Depending where next block is, move to that pos
                    % Block pos in an array for EASTERN SIDE (Player 2)
                    cmd = sprintf('MVPOSTAB %f,%f,14', blockPosEasternSide);
                    fwrite(socket, cmd);
                    disp(cmd);
                    
                    % Release block in its position
                    cmd = 'SETSOLEN 0';
                    fwrite(socket, cmd);
                    pause(0.1);
                    disp(cmd);
                    
                    cmd = 'VACUUMOF';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    % Repeat this 5 more times since 6 blocks
                    
                end
            end
            
            
            %--------------------------------------- Discard button pressed
            if(mvapp.DISCARDButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                
                % check if Player 1
                if(strcmp(mvapp.DropDown_2.Value, 'Player 1'))
                
                    % Move to first block pos (Western Side for Player 1)
                    cmd = sprintf('MVPOSTAB %f,%f,13', blockPosWesternSide);
                    disp(cmd);
                    fwrite(socket, cmd);
                    pause(5);
                    
                    % Pick up the block
                    cmd = 'VACUUMON';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    cmd = 'SETSOLEN 1';
                    fwrtie(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    % Move block to conveyor
                    cmd = sprintf('MVPOSTAB %f,%f,100', blockPosWesternSide);
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(1);
                    
                    cmd = 'SETPOSES 90,0,20,0,0,0';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(3);
                    
                    cmd = 'MVPOSCON 0,0,100';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(3);
                    
                    % Release block
                    cmd = 'SETSOLEN 0';
                    fwrite(socket, cmd);
                    pause(0.1);
                    disp(cmd);
                    
                    cmd = 'VACUUMOF';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    % Now move back to second Western Pos in array
                    
                    % Repeat until all blocks placed back.

                % Player 2
                else
                    
                    % Move to first block pos (Eastern Side for Player 2)
                    cmd = sprintf('MVPOSTAB %f,%f,13', blockPosEasternSide);
                    disp(cmd);
                    fwrite(socket, cmd);
                    pause(5);
                    
                    % Pick up the block
                    cmd = 'VACUUMON';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    cmd = 'SETSOLEN 1';
                    fwrtie(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    % Move block to conveyor
                    cmd = sprintf('MVPOSTAB %f,%f,100', blockPosEasternSide);
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(1);
                    
                    cmd = 'SETPOSES 90,0,20,0,0,0';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(3);
                    
                    cmd = 'MVPOSCON 0,0,100';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(3);
                    
                    % Release block
                    cmd = 'SETSOLEN 0';
                    fwrite(socket, cmd);
                    pause(0.1);
                    disp(cmd);
                    
                    cmd = 'VACUUMOF';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    % Now move back to second Eastern Pos in array
                    
                    % Repeat until all blocks placed back.
               
                end
            end

            
            %------------------------------------------ Sort button pressed
            if(mvapp.SORTButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                
                % check if Player 1
                if(strcmp(mvapp.DropDown_2.Value, 'Player 1'))
                
                % Player 2
                else
                    
                end
            end
            
            
            
            %------------------------------------------ Clear table pressed
            if(mvapp.CLEARButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                
                % Block positions placed in an array 'BlockPoses'
                % Move to the first block pos
                cmd = sprintf('MVPOSTAB %f,%f,13', BlockPoses);
                disp(cmd);
                fwrite(socket,cmd);
                pause(5);
                
                % Pick up block
                cmd = 'VACUUMON';
                fwrite(socket, cmd);
                disp(cmd);
                pause(0.1);
                
                cmd = 'SETSOLEN 1';
                fwrite(socket, cmd);
                disp(cmd);
                pause(0.1);
                
                % Move to conveyor
                cmd = sprintf('MVPOSTAB %f,%f,100', BlockPoses);
                fwrite(socket, cmd);
                disp(cmd);
                pause(3);
                
                cmd = 'SETPOSES 90,0,20,0,0,0';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(3);
                    
                    cmd = 'MVPOSCON 0,0,100';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(3);
                    
                    % Release block
                    cmd = 'SETSOLEN 0';
                    fwrite(socket, cmd);
                    pause(0.1);
                    disp(cmd);
                    
                    cmd = 'VACUUMOF';
                    fwrite(socket, cmd);
                    disp(cmd);
                    pause(0.1);
                    
                    % Now move back to second element or block in the 
                    % BlockPoses array, and repeat until all finished
            end
            
            
            %------------------------------------------- Fill table pressed
            if(mvapp.TableFILLButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                
                
            end

            
            
            
            pause(0.01);
        end
        % Fall out if no longer connected
        
        if(app.ReconnectButton_Pressed)
            try
                socket = tcpip(robot_IP_address, robot_port);
                set(socket, 'ReadAsyncMode', 'continuous');
                fopen(socket);
                disp('Connected');
                app.ConnectionStatusLamp.Color = 'g';
                mvapp.ConnectionLamp.Color = 'g';
                
                app.DirectionSwitch_Changed = 1;
                app.PumpSwitch_Changed = 1;
                app.ConRunButton_Pressed = 1;
                app.VacRunButton_Pressed = 1;
            catch
                disp('Reconnection Failed');
                app.ConnectionStatusLamp.Color = 'r';
                mvapp.ConnectionLamp.Color = 'r';
            end
            app.ReconnectButton_Pressed = 0;
        end
        
        if(app.QuitButton_Pressed)
            mvapp.delete();
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