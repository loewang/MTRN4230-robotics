function Ass3GUI2RAPID()
    clc; clear; close all; dbstop if error;

    %start GUI
    app = IRB120GUI();
    mvapp = MoveGUI();
    tabapp = TableFeedGUI();

    pause(0.5);
    disp('GUIs OPEN');
    
    prevMoved = 0;
    inmotion = 0;
    
    board = zeros(9,9);
    deckE.state = zeros(6,1);
    deckW.state = zeros(6,1);
    
    % BP coordinate system
    letters = {'A','B','C','D','E','F','G','H','I'}';
    rows = repmat(letters,1,9);
    numbers = {'1','2','3','4','5','6','7','8','9'};
    cols = repmat(numbers,9,1);
    BP.names = strcat(rows,cols);
    
    % BP XY positions
    BPX = (18:36:(18 + (36*8)))';
    rows = repmat(BPX,9,1);
    BPY = (-(36*4):36:(36*4));
    cols = repelem(BPY,9)';
    BP.XY = [rows cols];
    
    % deck XY positions
    dEY = repelem(-230,6)';
    dWY = repelem(230,6)';
    dX = (18:36:(18 + (36*5)))';
    BP.deckE = [dX dWY];
    BP.deckW = [dX dEY];
    
    % TTT XY positions
    ti = sub2ind([9 9],[4 4 4 5 5 5 6 6 6],[4 5 6 4 5 6 4 5 6]); %D4
    BP.TTT = BP.XY(ti,:);
    
    % detected blocks buffer
%     tablestate = cell(28,1);
%     listi = 1;
    
%     robot_IP_address = '192.168.125.1';
    robot_IP_address = '127.0.0.1'; % Simulation ip address

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
            
            % Get Robot status update-------------------------------------
            
            fwrite(socket,'GTCONSTA');
            str = ReceiveState(socket);
            if(strcmp(str,'1'))
                mvapp.ConveyorReadyLamp.Color = 'g';
                app.ConveyorStatusLamp.Color = 'g';
            else
                mvapp.ConveyorReadyLamp.Color = 'r';
                app.ConveyorStatusLamp.Color = 'r';
            end

            fwrite(socket,'GTVACRUN');
            str = ReceiveState(socket);
            if(strcmp(str,'1'))
                app.PumpLamp.Color = 'g';
            else
                app.PumpLamp.Color = 'r';
            end

            fwrite(socket,'GTVACSOL');
            str = ReceiveState(socket);
            if(strcmp(str,'1'))
                app.VacSolLamp.Color = 'g';
            else
                app.VacSolLamp.Color = 'r';
            end

            fwrite(socket,'GTCONRUN');
            str = ReceiveState(socket);
            if(strcmp(str,'1'))
                app.ConRunLamp.Color = 'g';
            else
                app.ConRunLamp.Color = 'r';
            end

            fwrite(socket,'GTCONDIR');
            str = ReceiveState(socket);
            if(strcmp(str,'1'))
                app.DirectionLamp.Color = 'g';
            else
                app.DirectionLamp.Color = 'r';
            end

            fwrite(socket,'GTMOTONS');
            str = ReceiveState(socket);
            if(strcmp(str,'1'))
                app.MotorsONLamp.Color = 'g';
            else
                app.MotorsONLamp.Color = 'r';
            end

            fwrite(socket,'GTESTOP1');
            str = ReceiveState(socket);
            if(strcmp(str,'1'))
                app.EmergencyStopLamp.Color = 'g';
            else
                app.EmergencyStopLamp.Color = 'r';
            end

            fwrite(socket,'GTEXCERR');
            str = ReceiveState(socket);
            if(strcmp(str,'0'))
                app.ExecutionErrorLamp.Color = 'g';
            else
                app.ExecutionErrorLamp.Color = 'r';
            end

            fwrite(socket,'GTHDENBL');
            str = ReceiveState(socket);
            if(strcmp(str,'1'))
                app.MotorsEnableLamp.Color = 'g';
            else
                app.MotorsEnableLamp.Color = 'r';
            end

            fwrite(socket,'GTLTCURT');
            str = ReceiveState(socket);
            if(strcmp(str,'0'))
                app.LightCurtainLamp.Color = 'g';
            else
                app.LightCurtainLamp.Color = 'r';
            end

            fwrite(socket,'GTMOTSUP');
            str = ReceiveState(socket);
            if(strcmp(str,'0'))
                app.MotionSupervisionLamp.Color = 'g';
            else
                app.MotionSupervisionLamp.Color = 'r';
            end
            
            fwrite(socket, 'INMOTION');
            str = ReceiveState(socket);    
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
            if(inmotion == 0)
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
            end
            
            %Process buttons--------------------------------------------
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
            
            %SIMPLE MOVE --------------------------------------------------
            if(mvapp.MOVEButtonPressed)  
                fwrite(socket,'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';
                
                if(strcmp(mvapp.MOVEButton.Text,"WAIT"))
                   mode = mvapp.DropDown.Value;
                  
                   if(strcmp(mode,'BP to Conveyor'))
                       targetBP = mvapp.BP1EditField.Value;
                       ri = double(targetBP(1))-64;
                       ci = str2double(targetBP(2));
                       BPi = sub2ind([9 9],ri,ci);
                       tabXY = BP.XY(BPi,:);
                       
                       if(board(ri,ci)==0)
                           msg = sprintf('There is no block at %s',targetBP);
                           mvapp.StatusEditField_2.Value = msg;
                           pause(2);
                       else
                           msg = sprintf('Moving %s to conveyor...',targetBP);
                           mvapp.StatusEditField_2.Value = msg;
                           board(ri,ci) = 0;
                           BPpickup(socket,tabXY);
                           conXY = [0 0];
                           CONdropoff(socket,conXY);
                           
%                            %remove block from list
%                            editBlocki = strfind(targetBP,tablestate);
%                            [editRow,~] = ind2sub(size(tablestate),editBlocki);
%                            tablestate(editRow,:) = [];
%                            tabapp.TextArea.Value = tablestate;
                       end
                       
                   elseif(strcmp(mode,'Conveyor to BP'))
                       targetBP = mvapp.BP1EditField.Value;
                       ri = double(targetBP(1))-64;
                       ci = str2double(targetBP(2));
                       BPi = sub2ind([9 9],ri,ci);
                       tabXY = BP.XY(BPi,:);
                       
                       if(board(ri,ci)==1)
                           msg = sprintf('%s is already occupied!',targetBP);
                           mvapp.StatusEditField_2.Value = msg;
                           pause(2);
                       else
                           msg = sprintf('Moving to block to %s...',targetBP);
                           mvapp.StatusEditField_2.Value = msg;
                           board(ri,ci) = 1;
                           conXY = [0 0];
                           CONpickup(socket,conXY);
                           BPdropoff(socket,tabXY);
                           
%                            %add block to list
%                            blockdata = sprintf('%s  SHAPE   %3.1f   %3.1f   %3d',targetBP, tabXY,90);
%                            tablestate{listi} = blockdata;
%                            listi = listi + 1;
%                            tabapp.TextArea.Value = cell2mat(tablestate);
                       end

                   elseif(strcmp(mode,'BP to BP'))
                       BP1 = mvapp.BP1EditField.Value;
                       r1i = double(BP1(1))-64;
                       c1i = str2double(BP1(2));
                       BPi = sub2ind([9 9],r1i,c1i);
                       tabXY1 = BP.XY(BPi,:);  
                       
                       BP2 = mvapp.BP2EditField.Value;
                       r2i = double(BP2(1))-64;
                       c2i = str2double(BP2(2));
                       BPi = sub2ind([9 9],r2i,c2i);
                       tabXY2 = BP.XY(BPi,:);
                       
                       if(board(r1i,c1i)==0)
                           msg = sprintf('There is no block at %s',BP1);
                           mvapp.StatusEditField_2.Value = msg;
                           pause(2);
                       elseif(board(r2i,c2i)==1)
                           msg = sprintf('%s is already occupied!',BP2);
                           mvapp.StatusEditField_2.Value = msg;
                           pause(2);
                       else                      
                           msg = sprintf('Moving to %s to %s',BP1,BP2);
                           mvapp.StatusEditField_2.Value = msg;
                           board(r2i,c2i) = 1;
                           board(r1i,c1i) = 0;
                           BPpickup(socket,tabXY1);
                           BPdropoff(socket,tabXY2);
                           
%                            %change block BPs
%                            editBlocki = strfind(BP1,tablestate);
%                            [editRow,~] = ind2sub(size(tablestate),editBlocki);
%                            tablestate(editRow,:) = [];
%                            blockdata = sprintf('%s  SHAPE   %3.1f	%3.1f	%3d',BP2, tabXY2,90);
%                            tablestate = [tablestate; blockdata];
%                            tabapp.TextArea.Value = tablestate;
                       end
      
                   else % Rotate BP
                       targetBP = mvapp.BP1EditField.Value;
                       ri = double(targetBP(1))-64;
                       ci = str2double(targetBP(2));
                       BPi = sub2ind([9 9],ri,ci);
                       tabXY = BP.XY(BPi,:);
                       angle = str2double(mvapp.BP2EditField.Value);
                       
                       if(board(ri,ci)==0)
                           msg = sprintf('There is no block at %s',BP1);
                           mvapp.StatusEditField_2.Value = msg;
                           pause(2);
                       else
                           msg = sprintf('Rotating to %s by %d',targetBP,angle);
                           mvapp.StatusEditField_2.Value = msg;
                           
                           %move to BP
                           BPpickup(socket,tabXY);
                           WaitForReady(socket);
                           
                           fwrite(socket, 'JNTANGLE');
                           str = ReceiveString(socket);
                           jAng = str2num(str);
                           
                           cmd = sprintf('SETPOSES %f,%f,%f,%f,%f,%f',jAng(1:5),angle);
                           fwrite(socket,cmd);
                           disp(cmd);
                           WaitForReady(socket);
                           
                           cmd = sprintf('MVLINEAR %f,%f,14',tabXY);
                           fwrite(socket,cmd);
                           disp(cmd);
                           WaitForReady(socket);
                           
                           cmd = 'SETSOLEN 0';
                           fwrite(socket,cmd);
                           disp(cmd);
                           pause(0.1);
                           
                           cmd = 'VACUUMOF';
                           fwrite(socket,cmd);
                           disp(cmd);
                           pause(0.1);
                           
                           cmd = 'MVPOSTAB 0,0,14';
                           fwrite(socket,cmd);
                           disp(cmd);
                           WaitForReady(socket);
                           
%                            %change block BPs
%                            editBlocki = strfind(BP1,tablestate);
%                            [editRow,~] = ind2sub(size(tablestate),editBlocki);
%                            tablestate(editRow,:) = [];
%                            blockdata = sprintf('%s  SHAPE   %3.1f	%3.1f	%3d',targetBP, tabXY,angle);
%                            tablestate = [tablestate; blockdata];
%                            tabapp.TextArea.Value = tablestate;
                       end
                   end
                end
                
                msg = 'Ready';
                mvapp.StatusEditField_2.Value = msg;
                mvapp.MOVEButton.Text = 'MOVE';
                mvapp.MOVEButtonPressed = 0;
                pause(0.1);
            end
           
            %COMPLEX MOVE-------------------------------------------------
         
            % Fill button pressed
            if(mvapp.FILLButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';
                
                % check if Player 1
                if(strcmp(mvapp.DropDown_2.Value, 'Player 1'))
                    
                    emptyBP = BP.deckW(deckW.state==0,:);
                    for i = 1:length(emptyBP)
        
                        conXY = [0 0];
                        tabXY = emptyBP(i,:);
                        CONpickup(socket,conXY);       
                        BPdropoff(socket,tabXY); 
                        deckW.state(i) = 1;
                        
                        if(mvapp.CANCELButtonPressed)
                            mvapp.CANCELButtonPressed = 0;
                            break;
                        end
                    end
                    
                % Player 2
                else
                    
                    emptyBP = BP.deckE(deckE.state==0,:);
                    for i = 1:length(emptyBP)
        
                        conXY = [0 0];
                        tabXY = emptyBP(i,:);
                        CONpickup(socket,conXY);       
                        BPdropoff(socket,tabXY); 
                        deckE.state(i) = 1;
                    end
                end
                mvapp.FILLButtonPressed = 0;
            end

            %--------------------------------------- Discard button pressed
            if(mvapp.DISCARDButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';
                
                % check if Player 1
                if(strcmp(mvapp.DropDown_2.Value, 'Player 1'))
                    
                    filledBP = BP.deckW(deckW.state==1,:);
                    
                    for i = 1:length(filledBP)
                        
                        conXY = [0 0];
                        tabXY = filledBP(i,:);
                        BPpickup(socket,tabXY);
                        CONdropoff(socket,conXY);
                        deckW.state(i) = 0;
                    end

                % Player 2
                else
                     filledBP = BP.deckE(deckE.state==1,:);
                    
                     for i = 1:length(filledBP)
                        conXY = [0 0];
                        tabXY = filledBP(i,:);
                        BPpickup(socket,tabXY);
                        CONdropoff(socket,conXY);
                        deckE.state(i) = 0;
                     end
                end
                mvapp.DISCARDButtonPressed = 0;
            end

            
            %------------------------------------------ Sort button pressed
            if(mvapp.SORTButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';
                
                tempXY = [250 0];
                
                %1 = shape
                %0 = letter
                deckE.type = NaN(6,1);
                deckE.type(:) = 1;
                deckW.type = NaN(6,1);
                deckW.type(:) = 0;
                
                for i = 1:6
                    if(deckE.type(i)==1)
                        %pick up incorrect block
                        tabXY = BP.deckE(i,:);
                        BPpickup(socket,tabXY);
                        %put block in temporary position
                        BPdropoff(socket,tempXY);
                        deckE.type(i) = NaN; 
                        %find correct block
                        letteri = find(deckW.type==0,1);
                        tabXY = BP.deckW(letteri,:);
                        BPpickup(socket,tabXY);
                        tabXY = BP.deckE(i,:);
                        %place correct block into deck
                        BPdropoff(socket,tabXY);
                        deckE.type(i) = 0;
                        %replace correct block in other deck
                        BPpickup(socket,tempXY);
                        tabXY = BP.deckW(letteri,:);
                        BPdropoff(socket,tabXY);
                        deckW.type(letteri) = 1; 
                    end
                end

                mvapp.SORTButtonPressed = 0;
            end

            %------------------------------------------ Clear table pressed
            if(mvapp.CLEARButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';
                
                scatteredBP = zeros(16,2); % array of scatters block XY coords
                
                for i = 1:size(scatteredBP,1)
                    tabXY = scatteredBP(i,:);
                    BPpickup(socket,tabXY);
                    conXY = [0 0];
                    CONdropoff(socket,conXY);
                end

                mvapp.CLEARButtonPressed = 0;
            end
            
            
            %------------------------------------------- Fill table pressed
            if(mvapp.TableFILLButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';

                for i = 1:6
                    %find empty BPs to deploy to
                    freeBPi = find(board==0,1);
                    freeBP = BP.XY(freeBPi,:);
                    tabXY = BP.deckE(i,:);
                    BPpickup(socket,tabXY);
                    tabXY = freeBP;
                    BPdropoff(socket,tabXY);
                    [ex,ey] = ind2sub([9 9],freeBPi);
                    board(ex,ey) = 1;
                    deckE.state(i) = 0;
                end
                
                for i = 1:6
                    %find empty BPs to deploy to
                    freeBPi = find(board==0,1);
                    freeBP = BP.XY(freeBPi,:);
                    tabXY = BP.deckW(i,:);
                    BPpickup(socket,tabXY);
                    tabXY = freeBP;
                    BPdropoff(socket,tabXY);
                    [ex,ey] = ind2sub([9 9],freeBPi);
                    board(ex,ey) = 1;
                    deckW.state(i) = 0;
                end
                mvapp.TableFILLButtonPressed = 0;
            end

            %-----------------------------------------PVP TicTacToe pressed
            if(mvapp.PvPButtonPressed)

                % Open TTT GUI
                tttapp = TTTGUI();
                
                % Once cell is pressed, calc the position on board (CP)
                % The robot will pick up either a Letter or Shape block
                % depending on the player turn, and release it on the Cell
                % Point (CP).
                
                % Cell 1 Pressed - D4
                if(tttapp.CellOneVal == 1)
                    
                    % Now we need to see which player turn it is.
                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                    if (tttapp.Cell1Button.Text == app.Player1)
                        
                        % Player 1 deck is located WESTERN side of table
                        % Move to first block pos (Western Side for Player 1)
                        oi = find(deckW.state==1,1);
                        tabXY = BP.deckW(oi,:);
                        BPpickup(socket,tabXY);
                        pause(6);
                        
                        % Now move the block into Cell 1 Position
                        ri = double(68)-64;
                        ci = 4;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                        BPdropoff(socket,tabXY);
                        pause(6);

                    else
                        
                        xi = find(deckE.state==1,1);
                        tabXY = BP.deckE(xi,:);
                        BPpickup(socket,tabXY);
                        pause(6);
                        
                        % Now move the block into Cell 1 Position
                        ri = double(68)-64;
                        ci = 4;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                        BPdropoff(socket,tabXY);
                        pause(6);
                        
                    end 
                end
                
                % Cell 2 Pressed - D5
                if(tttapp.CellTwoVal == 1)
                    
                    % Now we need to see which player turn it is.
                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                    if (tttapp.Cell2Button.Text == app.Player1)
                        
                        % Player 1 deck is located WESTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosWesternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 2 Position
                        ri = double(68)-64;
                        ci = 5;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);

                    else
                        
                        % Player 2 deck is located EASTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosEasternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 2 Position
                        ri = double(68)-64;
                        ci = 5;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                    end
                end
                
                % Cell 3 Pressed - D6
                if(tttapp.CellThreeVal == 1)
                    
                    % Now we need to see which player turn it is.
                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                    if (tttapp.Cell3Button.Text == app.Player1)
                        
                        % Player 1 deck is located WESTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosWesternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 3 Position
                        ri = double(68)-64;
                        ci = 6;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);

                    else
                        
                        % Player 2 deck is located EASTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosEasternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 3 Position
                        ri = double(68)-64;
                        ci = 6;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                    end
                end
                
                % Cell 4 Pressed - E4
                if(tttapp.CellFourVal == 1)
                    
                    % Now we need to see which player turn it is.
                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                    if (tttapp.Cell4Button.Text == app.Player1)
                        
                        % Player 1 deck is located WESTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosWesternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 4 Position
                        ri = double(69)-64;
                        ci = 4;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);

                    else
                        
                        % Player 2 deck is located EASTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosEasternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 4 Position
                        ri = double(69)-64;
                        ci = 4;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                    end
                end
                
                % Cell 5 Pressed - E5
                if(tttapp.CellFiveVal == 1)
                    
                    % Now we need to see which player turn it is.
                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                    if (tttapp.Cell1Button.Text == app.Player1)
                        
                        % Player 1 deck is located WESTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosWesternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 5 Position
                        ri = double(69)-64;
                        ci = 5;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);

                    else
                        
                        % Player 2 deck is located EASTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosEasternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 5 Position
                        ri = double(69)-64;
                        ci = 5;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                    end
                end
                
                % Cell 6 Pressed - E6
                if(tttapp.CellSixVal == 1)
                    
                    % Now we need to see which player turn it is.
                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                    if (tttapp.Cell6Button.Text == app.Player1)
                        
                        % Player 1 deck is located WESTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosWesternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 1 Position
                        ri = double(69)-64;
                        ci = 6;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);

                    else
                        
                        % Player 2 deck is located EASTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosEasternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 6 Position
                        ri = double(69)-64;
                        ci = 6;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                    end
                end
                
                % Cell 7 Pressed - F4
                if(tttapp.CellSevenVal == 1)
                    
                    % Now we need to see which player turn it is.
                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                    if (tttapp.Cell7Button.Text == app.Player1)
                        
                        % Player 1 deck is located WESTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosWesternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 7 Position
                        ri = double(70)-64;
                        ci = 4;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);

                    else
                        
                        % Player 2 deck is located EASTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosEasternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 7 Position
                        ri = double(70)-64;
                        ci = 4;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                    end
                end
                
                % Cell 8 Pressed - F5
                if(tttapp.CellEightVal == 1)
                    
                    % Now we need to see which player turn it is.
                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                    if (tttapp.Cell8Button.Text == app.Player1)
                        
                        % Player 1 deck is located WESTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosWesternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 8 Position
                        ri = double(70)-64;
                        ci = 5;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);

                    else
                        
                        % Player 2 deck is located EASTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosEasternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 8 Position
                        ri = double(70)-64;
                        ci = 5;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                    end
                end
                
                % Cell 9 Pressed - F6
                if(tttapp.CellNineVal == 1)
                    
                    % Now we need to see which player turn it is.
                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                    if (tttapp.Cell9Button.Text == app.Player1)
                        
                        % Player 1 deck is located WESTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosWesternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 9 Position
                        ri = double(70)-64;
                        ci = 6;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);

                    else
                        
                        % Player 2 deck is located EASTERN side of table
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
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100', blockPosEasternSide);
                        disp(cmd);
                        fwrite(socket, cmd);
                        pause(5);
                        
                        % Now move the block into Cell 9 Position
                        ri = double(70)-64;
                        ci = 6;
                        BPi = sub2ind([9 9],ri,ci);
                        tabXY = BP.XY(BPi,:);
                       
                        % Move to BP position
                        cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                        % Release block in its position
                        cmd = 'SETSOLEN 0';
                        fwrite(socket, cmd);
                        pause(0.1);
                        disp(cmd);
                    
                        cmd = 'VACUUMOF';
                        fwrite(socket, cmd);
                        disp(cmd);
                        pause(0.1);
                        
                        % Move up
                        cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
                        fprintf("Moving to %s\n",targetBP);
                        disp(cmd);
                        fwrite(socket,cmd);
                        pause(5);
                        
                    end
                end
                mvapp.PvPButtonPressed = 0;
            end
            
            if(mvapp.AIvPButtonPressed)
                TTTapp = TTTGUI();
                
                mvapp.AIvPButtonPressed = 0;
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
            tabapp.delete();
            break;
        end
        
        pause(1);
    end
    disp('IRB120 Session Ended');
end

function BPpickup(socket,tabXY)
    %move to BP position
    cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
    fwrite(socket,cmd);
    disp(cmd);
    WaitForReady(socket);

    % pick up block
    cmd = 'VACUUMON';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    cmd = 'SETSOLEN 1';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);

    cmd = sprintf('MVPOSTAB %f,%f,10',tabXY);
    disp(cmd);
    fwrite(socket,cmd);
    WaitForReady(socket);

    %move to conveyor
    cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
    fwrite(socket,cmd);
    disp(cmd);
    WaitForReady(socket);
end

function CONdropoff(socket,conXY)
    cmd = sprintf('MVPOSCON %f,%f,200',conXY);
    fwrite(socket,cmd);
    disp(cmd);
    WaitForReady(socket);

    cmd = sprintf('MVPOSCON %f,%f,20',conXY);
    fwrite(socket,cmd);
    disp(cmd);
    WaitForReady(socket);
    
    cmd = 'SETSOLEN 0';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    
    cmd = 'VACUUMOF';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);

    %move back to table 
    cmd = sprintf('MVPOSCON %f,%f,200',conXY);
    fwrite(socket,cmd);
    disp(cmd); 
    WaitForReady(socket);

    cmd = 'MVPOSTAB 0,0,14';
    fwrite(socket,cmd);
    disp(cmd);
    WaitForReady(socket);
end

function CONpickup(socket,conXY)
   cmd = sprintf('MVPOSCON %f,%f,200',conXY);
   disp(cmd);
   fwrite(socket,cmd);
   WaitForReady(socket);

   % pick up block
   cmd = 'VACUUMON';
   fwrite(socket,cmd);
   disp(cmd);
   pause(0.1);
   cmd = 'SETSOLEN 1';
   fwrite(socket,cmd);
   disp(cmd);
   pause(0.1);

   cmd = sprintf('MVPOSCON %f,%f,10',conXY);
   disp(cmd);
   fwrite(socket,cmd);
   WaitForReady(socket);

   cmd = sprintf('MVPOSCON %f,%f,200',conXY);
   disp(cmd);
   fwrite(socket,cmd);
   WaitForReady(socket);
end

function BPdropoff(socket,tabXY)
   cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
   fwrite(socket,cmd);
   disp(cmd);
   WaitForReady(socket);
   
   cmd = sprintf('MVPOSTAB %f,%f,20',tabXY);
   fwrite(socket,cmd);
   disp(cmd);
   WaitForReady(socket);

   cmd = 'SETSOLEN 0';
   fwrite(socket,cmd);
   disp(cmd);
   pause(0.1);
   
   cmd = 'VACUUMOF';
   fwrite(socket,cmd);
   disp(cmd);
   pause(0.1);

   cmd = 'MVPOSTAB 0,0,14';
   fwrite(socket,cmd);
   disp(cmd);
   WaitForReady(socket);
end

function WaitForReady(socket)
    movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
end

function [str] =  ReceiveState(socket)
    data = fgetl(socket);
    str = char(data);
end

function [str] =  ReceiveString(socket)
    data = fgetl(socket);
    str = data;
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
