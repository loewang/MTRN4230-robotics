function Ass3GUI2RAPID()
    clc; clear; close all; dbstop if error;

    %start GUI
    app = IRB120GUI();
    convapp = ConveyorFeedGUI();
    tabapp = TableFeedGUI();
    mvapp = MoveGUI();

    pause(0.5);
    disp('GUIs OPEN');
    
    prevMoved = 0;
    inmotion = 0;
    
    board = zeros(9,9);
    deckE.state = zeros(6,1);
    deckW.state = zeros(6,1);
%     deckE.state = ones(6,1);
%     deckW.state = ones(6,1);
    deckE.type = NaN(6,1);
    deckW.type = NaN(6,1);
    deckE.theta = NaN(6,1);
    deckW.theta = NaN(6,1);

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
    BP.deckW = [dX dWY];
    BP.deckE = [dX dEY];
    
    % TTT XY positions
    ti = sub2ind([9 9],[6 6 6 5 5 5 4 4 4],[6 5 4 6 5 4 6 5 4]); %D4
    BP.TTT = BP.XY(ti,:);
    
    % detected blocks buffer
    tablestate = [];
    listi = 1;
    
    table.type = NaN(9,9);
    table.theta = NaN(9,9);
    
    constate = [];
    conv.BP = [];
    
    % camera setup
    load('cameraConveyorParams.mat'); %Load Conveyor camera calibration
    load('RotationMatrix.mat');
    load('TranslationMatrix.mat');
    load('CameraTableParams.mat');
    
%     %clear table images
%     tabImg = imageDatastore('clear table images');
    
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
                        
            %update image-------------------------------------------------
            
            if(tabapp.UpdateImageButtonPressed)
                % vid2 = videoinput('winvideo', 2, 'MJPG_1600x1200');
                % preview(vid2);
                % img = getsnapshot(vid2);
                img = imread('table_img_10_03_11_59_57.jpg');
                tabledata = tableDetect(img,tabapp.UIAxes);
                tablestate = [NaN(size(tabledata,1),1) tabledata(:,3) tabledata(:,5:6) tabledata(:,4)];
                tabapp.UITable.Data = tablestate;
                tabapp.UpdateImageButtonPressed = 0;
            end
            
            if(convapp.UpdateImageButtonPressed)
                % vid2 = videoinput('winvideo', 2, 'MJPG_1600x1200');
                % preview(vid2);
                % img = getsnapshot(vid2);
                img = imread('conveyor_img_10_03_11_39_04.jpg');
                img = undistortImage(img, cameraConveyorParams); %Undistord image
                constate = ConveyorImageProcess(img,cameraConveyorParams,R,t,convapp.UIAxes);
                conv.BP = ones(size(constate,1),1);
                convapp.UpdateImageButtonPressed = 0;
            end
            
            if(convapp.ADDButtonPressed)
                 % vid2 = videoinput('winvideo', 2, 'MJPG_1600x1200');
                % preview(vid2);
                % img = getsnapshot(vid2);
                img = imread('conveyor_img_10_03_11_39_04.jpg');
                img = undistortImage(img, cameraConveyorParams); %Undistord image
                if(strcmp(convapp.BlockTypeDropDown.Value, 'Shape'))
                    type = 0;
                else
                    type = 1;
                end
                constate = AddConveyorBlock(constate,img,cameraConveyorParams,R,t,convapp.UIAxes, type);
                conv.BP = ones(size(constate,1),1);
                convapp.ADDButtonPressed = 0;
            end
            
            if(convapp.DELETEButtonPressed)
                % vid2 = videoinput('winvideo', 2, 'MJPG_1600x1200');
                % preview(vid2);
                % img = getsnapshot(vid2);
                img = imread('conveyor_img_10_03_11_39_04.jpg');
                img = undistortImage(img, cameraConveyorParams); %Undistord image
                constate = RemoveBlockConveyor(constate,img,cameraConveyorParams,R,t,convapp.UIAxes);
                conv.BP = ones(size(constate,1),1);
                convapp.DELETEButtonPressed = 0;
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
                       elseif(size(constate,1)==length(find(conv.BP==1)))
                           msg = 'Conveyor box full';
                           mvapp.StatusEditField_2.Value = msg;
                           pause(2);
                       else
                           msg = sprintf('Moving %s to conveyor...',targetBP);
                           mvapp.StatusEditField_2.Value = msg;

                           BPpickup(socket,tabXY);
                           board(ri,ci) = 0;
                           
                           freei = find(conv.BP==0,1);
                           conXY = constate(freei,1:2);
                           CONdropoff(socket,conXY);
                           conv.BP(freei) = 1;
                           
                           %remove block from list
                           editRow = find(tablestate(:,1)==BPi,1);
                           tablestate(editRow,:) = [];
                           if(listi ~= 1)
                               listi = listi - 1;
                           end
                           tabapp.UITable.Data = tablestate;
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
                       elseif(isempty(constate))
                           msg = 'Conveyor box empty. Please add blocks';
                           mvapp.StatusEditField_2.Value = msg;
                           pause(2);
                       else
                           msg = sprintf('Moving to block to %s...',targetBP);
                           mvapp.StatusEditField_2.Value = msg;
                           
                           filledi = find(conv.BP==1,1);
                           conXY = constate(filledi,1:2);
                           CONpickup(socket,conXY);
                           conv.BP(filledi) = 0;
                           
                           BPdropoff(socket,tabXY);
                           board(ri,ci) = 1;
                           
                           table.type(ri,ci) = constate(filledi,4);
                           table.theta(ri,ci) = constate(filledi,3);
                           
                           %add block to list
                           tablestate(listi,:) = [BPi table.type(ri,ci) tabXY table.theta(ri,ci)];
                           listi = listi + 1;
                           tabapp.UITable.Data = tablestate;
                       end

                   elseif(strcmp(mode,'BP to BP'))
                       BP1 = mvapp.BP1EditField.Value;
                       r1i = double(BP1(1))-64;
                       c1i = str2double(BP1(2));
                       BP1i = sub2ind([9 9],r1i,c1i);
                       tabXY1 = BP.XY(BP1i,:);  
                       
                       BP2 = mvapp.BP2EditField.Value;
                       r2i = double(BP2(1))-64;
                       c2i = str2double(BP2(2));
                       BP2i = sub2ind([9 9],r2i,c2i);
                       tabXY2 = BP.XY(BP2i,:);
                       
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
                           
                           BPpickup(socket,tabXY1);
                           BPdropoff(socket,tabXY2);
                           
                           board(r2i,c2i) = 1;
                           board(r1i,c1i) = 0;
                           table.type(r2i,c2i) = table.type(r1i,c1i);
                           table.type(r1i,c1i) = NaN;
                           table.theta(r2i,c2i) = table.theta(r1i,c1i);
                           table.theta(r1i,c1i) = NaN;
                           
                           %change block BPs
                           editRow = find(tablestate(:,1)==BP1i,1);
                           tablestate(editRow,:) = [BP2i table.type(r2i,c2i) tabXY2 table.theta(r2i,c2i)];
                           tabapp.UITable.Data = tablestate;
                       end
      
                   else % Rotate BP
                       targetBP = mvapp.BP1EditField.Value;
                       ri = double(targetBP(1))-64;
                       ci = str2double(targetBP(2));
                       BPi = sub2ind([9 9],ri,ci);
                       tabXY = BP.XY(BPi,:);
                       angle = str2double(mvapp.BP2EditField.Value);
                       
                       if(board(ri,ci)==0)
                           msg = sprintf('There is no block at %s',targetBP);
                           mvapp.StatusEditField_2.Value = msg;
                           pause(2);
                       else
                           msg = sprintf('Rotating to %s by %d degrees',targetBP,angle);
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
                           
                           %change block BPs
                           editRow = find(tablestate(:,1)==BPi,1);
                           tablestate(editRow,5) = table.theta(ri,ci)+angle;
                           tabapp.UITable.Data = tablestate;
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
                
                if(isempty(conv.BP)||sum(conv.BP)<=6)
                    msg = 'Not enough blocks in conveyor. Refill box';
                    mvapp.StatusEditField_3.Value = msg;
                    pause(2);
                else
                    % check if Player 1
                    if(strcmp(mvapp.DropDown_2.Value, 'Player 1'))
                        
                        msg = 'Filling Player 1 deck';
                        mvapp.StatusEditField_3.Value = msg;
                        
                        BPi = find(deckW.state==0);
                        emptyBP = BP.deckW(BPi,:);
                        for i = 1:length(emptyBP)
                            
                            filledi = find(conv.BP==1,1);
                            conXY = constate(filledi,1:2);
                            CONpickup(socket,conXY);
                            conv.BP(filledi) = 0;
                            
                            tabXY = emptyBP(i,:);
                            BPdropoff(socket,tabXY);
                            deckW.state(i) = 1;
                            
                            deckW.type(BPi(i)) = constate(filledi,4);
                            deckW.theta(BPi(i)) = constate(filledi,3);
                            
                            %add block to list
                            tablestate(listi,:) = [BPi(i)+100 deckW.type(BPi(i)) tabXY deckW.theta(BPi(i))];
                            listi = listi + 1;
                            tabapp.UITable.Data = tablestate;
                            
                            if(mvapp.CANCELButtonPressed)
                                mvapp.CANCELButtonPressed = 0;
                                break;
                            end
                        end
                        
                        % Player 2
                    else
                        msg = 'Filling Player 2 deck';
                        mvapp.StatusEditField_3.Value = msg;
                        
                        BPi = find(deckE.state==0);
                        emptyBP = BP.deckE(BPi,:);
                        for i = 1:length(emptyBP)
                            
                            filledi = find(conv.BP==1,1);
                            conXY = constate(filledi,1:2);
                            CONpickup(socket,conXY);
                            conv.BP(filledi) = 0;
                            
                            tabXY = emptyBP(i,:);
                            BPdropoff(socket,tabXY);
                            deckE.state(i) = 1;
                            
                            deckE.type(BPi(i)) = constate(filledi,4);
                            deckE.theta(BPi(i)) = constate(filledi,3);
                            
                            %add block to list
                            tablestate(listi,:) = [BPi(i)+200 deckE.type(BPi(i)) tabXY deckE.theta(BPi(i))];
                            listi = listi + 1;
                            tabapp.UITable.Data = tablestate;
                            
                            if(mvapp.CANCELButtonPressed)
                                mvapp.CANCELButtonPressed = 0;
                                break;
                            end
                        end
                    end
                end
                
                msg = 'Ready';
                mvapp.StatusEditField_3.Value = msg;
                mvapp.FILLButtonPressed = 0;
            end

            %--------------------------------------- Discard button pressed
            if(mvapp.DISCARDButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';
                
                if(size(constate,1)==length(find(conv.BP==1)))
                    msg = 'Conveyor box full. Empty box';
                    mvapp.StatusEditField_3.Value = msg;
                    pause(2);
                else
                    % check if Player 1
                    if(strcmp(mvapp.DropDown_2.Value, 'Player 1'))
                        
                        msg = 'Discarding Player 1 deck';
                        mvapp.StatusEditField_3.Value = msg;
                        
                        BPi = find(deckW.state==1);
                        filledBP = BP.deckW(BPi,:);
                        
                        for i = 1:length(filledBP)
                            
                            freei = find(conv.BP==0,1);
                            conXY = constate(freei,1:2);
                            
                            tabXY = filledBP(i,:);
                            BPpickup(socket,tabXY);
                            CONdropoff(socket,conXY);
                            conv.BP(freei) = 1;
                            deckW.state(i) = 0;
                            
                            deckW.type(BPi(i)) = NaN;
                            deckW.theta(BPi(i)) = NaN;
                            
                            %remove block from list
                            editRow = find(tablestate(:,1)==BPi(i)+100,1);
                            tablestate(editRow,:) = [];
                            if(listi ~= 1)
                                listi = listi - 1;
                            end
                            tabapp.UITable.Data = tablestate;
                            
                            if(mvapp.CANCELButtonPressed)
                                mvapp.CANCELButtonPressed = 0;
                                break;
                            end
                        end
                        
                        % Player 2
                    else
                        msg = 'Discarding Player 2 deck';
                        mvapp.StatusEditField_3.Value = msg;
                        
                        BPi = find(deckE.state==1);
                        filledBP = BP.deckE(BPi,:);
                        
                        for i = 1:length(filledBP)
                            
                            freei = find(conv.BP==0,1);
                            conXY = constate(freei,1:2);
                            
                            tabXY = filledBP(i,:);
                            BPpickup(socket,tabXY);
                            CONdropoff(socket,conXY);
                            conv.BP(freei) = 1;
                            deckE.state(i) = 0;
                            
                            deckW.type(BPi(i)) = NaN;
                            deckW.theta(BPi(i)) = NaN;
                            
                            %remove block from list
                            editRow = find(tablestate(:,1)==BPi(i)+200,1);
                            tablestate(editRow,:) = [];
                            if(listi ~= 1)
                                listi = listi - 1;
                            end
                            tabapp.UITable.Data = tablestate;
                            
                            if(mvapp.CANCELButtonPressed)
                                mvapp.CANCELButtonPressed = 0;
                                break;
                            end
                        end
                    end
                end
                
                msg = 'Ready';
                mvapp.StatusEditField_3.Value = msg;

                mvapp.DISCARDButtonPressed = 0;
            end

            
            %------------------------------------------ Sort button pressed
            if(mvapp.SORTButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';
                
                msg = 'Sorting decks';
                mvapp.StatusEditField_3.Value = msg;
                
                tempXY = [360 0];
                
                %0 = shape
                %1 = letter
                
                for i = 1:6
                    if(deckE.type(i)==0)
                        %pick up incorrect block
                        tabXY = BP.deckE(i,:);
                        BPpickup(socket,tabXY);
                        
                        %put block in temporary position
                        BPdropoff(socket,tempXY);
                        deckE.type(i) = NaN;  
                        
                        %find correct block
                        letteri = find(deckW.type==1,1);
                        tabXY = BP.deckW(letteri,:);
                        BPpickup(socket,tabXY);
                        tabXY = BP.deckE(i,:);
                        
                        %place correct block into deck
                        BPdropoff(socket,tabXY);
                        deckE.type(i) = 0;
                        temptheta = deckE.theta(i);
                        deckE.theta(i) = deckW.theta(letteri);
                        deckW.theta(letteri) = temptheta;
                        
                        %replace correct block in other deck
                        BPpickup(socket,tempXY);
                        tabXY = BP.deckW(letteri,:);
                        BPdropoff(socket,tabXY);
                        deckW.type(letteri) = 1; 
                        
                        %update block BPs
                        editRow = find(tablestate(:,1)==i+200,1);
                        %tablestate(editRow,:) = [i+200 1 BP.deckE(i,:) 90];
                        tablestate(editRow,2) = 1;
                        tablestate(editRow,5) = deckE.theta(i);
                        tabapp.UITable.Data = tablestate;
                        
                        %update block BPs
                        editRow = find(tablestate(:,1)==letteri+100,1);
                        %tablestate(editRow,:) = [letteri+100 0 BP.deckW(letteri,:) 90];
                        tablestate(editRow,2) = 0;
                        tablestate(editRow,5) = deckW.theta(letteri);
                        tabapp.UITable.Data = tablestate;
                        
                        if(mvapp.CANCELButtonPressed)
                            mvapp.CANCELButtonPressed = 0;
                            break;
                        end
                    end
                end
                
                msg = 'Ready';
                mvapp.StatusEditField_3.Value = msg;
                
                mvapp.SORTButtonPressed = 0;
            end

            %------------------------------------------ Clear table pressed
            if(mvapp.CLEARButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';

                scatteredBP = tablestate(:,3:4); % array of scatters block XY coords
                
                for i = 1:size(scatteredBP,1)
                    tabXY = scatteredBP(i,:);
                    BPpickup(socket,tabXY);
                    
%                     freei = find(conv.BP==0,1);
%                     conXY = constate(freei,1:2);
%                     CONdropoff(socket,conXY);
%                     conv.BP(freei) = 1;
                    cmd = 'MVPOSCON 0,0,200';
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
                
                
                tablestate = [];
                tabapp.UITable.Data = tablestate;

                mvapp.CLEARButtonPressed = 0;
            end
            
            %------------------------------------------- Fill table pressed
            if(mvapp.TableFILLButtonPressed)
                fwrite(socket, 'SETSOLEN 0');
                app.RobotReadyLamp.Color = 'r';
                mvapp.RobotReadyLamp.Color = 'r';
                
                deckBPi = find(deckE.state==1);
                deckXY = BP.deckE(deckBPi,:);

                for i = 1:length(deckBPi)
                    %find empty BPs to deploy to
                    freeBPi = find(board==0,1);
                    freeBP = BP.XY(freeBPi,:);
                    tabXY = deckXY(i,:);
                    BPpickup(socket,tabXY);
                    tabXY = freeBP;
                    BPdropoff(socket,tabXY);
                    [ex,ey] = ind2sub([9 9],freeBPi);
                   
                    board(ex,ey) = 1;
                    deckE.state(deckBPi(i)) = 0;
                    table.type(ex,ey) = deckE.type(deckBPi(i));
                    table.theta(ex,ey) = deckE.theta(deckBPi(i));
%                     deckE.type(deckBPi(i)) = NaN;
%                     deckE.theta(deckBPi(i)) = NaN;

                    %change block BPs
                    editRow = find(tablestate(:,1)==deckBPi(i)+200,1);
                    tablestate(editRow,:) = [freeBPi table.type(ex,ey) tabXY table.theta(ex,ey)];
                    tabapp.UITable.Data = tablestate;
                end
                
                deckBPi = find(deckW.state==1);
                deckXY = BP.deckW(deckBPi,:);
                
                for i = 1:length(deckBPi)
                    %find empty BPs to deploy to
                    freeBPi = find(board==0,1);
                    freeBP = BP.XY(freeBPi,:);
                    tabXY = deckXY(i,:);
                    BPpickup(socket,tabXY);
                    tabXY = freeBP;
                    BPdropoff(socket,tabXY);
                    [ex,ey] = ind2sub([9 9],freeBPi);
                   
                    board(ex,ey) = 1;
                    deckW.state(deckBPi(i)) = 0;
                    table.type(ex,ey) = deckW.type(deckBPi(i));
                    table.theta(ex,ey) = deckW.theta(deckBPi(i));
%                     deckW.type(deckBPi(i)) = NaN;
%                     deckW.theta(deckBPi(i)) = NaN;
                    
                    %change block BPs
                    editRow = find(tablestate(:,1)==deckBPi(i)+100,1);
                    tablestate(editRow,:) = [freeBPi table.type(ex,ey) tabXY table.theta(ex,ey)];
                    tabapp.UITable.Data = tablestate;
                end
                mvapp.TableFILLButtonPressed = 0;
            end

            %correct detected blocks--------------------------------------
            if(tabapp.EDITButtonPressed)            
                if(strcmp(tabapp.EDITButton.Text,'EDIT'))
                    tablestate = tabapp.UITable.Data;
                    
                    board = zeros(9,9);
                    gridi = tablestate(:,1)<82;
                    dWi = tablestate(:,1)>82 & tablestate(:,1)<107;
                    dEi = tablestate(:,1)>107 & tablestate(:,1)<207;
                    
                    deckWi = tablestate(dWi)-100;
                    deckEi = tablestate(dEi)-200;
                    
                    board(tablestate(gridi,1)) = 1;
                    
                    table.type(tablestate(gridi,1)) = tablestate(gridi,2);
                    table.theta(tablestate(gridi,1)) = tablestate(gridi,5);
                    
                    deckW.type(deckWi) = tablestate(dWi,2);
                    deckE.type(deckEi) = tablestate(dEi,2);
                    
                    deckW.theta(deckWi) = tablestate(dWi,5);
                    deckE.theta(deckEi) = tablestate(dEi,5);
                    
                    % vid2 = videoinput('winvideo', 2, 'MJPG_1600x1200');
                    % preview(vid2);
                    % img = getsnapshot(vid2);
%                     img = imread('table_img_10_03_11_59_57.jpg');
%                     tabledata = tableEditBlock(img,tabledata,1,shape,ori);
%                     plotFunction(tabledata,UIaxes);
                end
               
                tabapp.EDITButtonPressed = 0;
            end
            
            if(tabapp.ADDButtonPressed)
                % vid2 = videoinput('winvideo', 2, 'MJPG_1600x1200');
                % preview(vid2);
                % img = getsnapshot(vid2);
                img = imread('table_img_10_03_11_59_57.jpg');
                img = undistortImage(img,cameraParams); %Undistor image
                if(strcmp(tabapp.AddTypeDropDown.Value, 'Shape'))
                    type = 0;
                else
                    type = 1;
                end 
                ori = tabapp.AddOriEditField.Value;
                tabledata = tableAddblock(img, tabledata, type, ori);
                plotFunction(tabledata, img, tabapp.UIAxes);
                tablestate = [NaN(size(tabledata,1),1) tabledata(:,3) tabledata(:,5:6) tabledata(:,4)];
                tabapp.UITable.Data = tablestate;
                
                tabapp.ADDButtonPressed = 0;
            end
            
            if(tabapp.DELETEButtonPressed)
                % vid2 = videoinput('winvideo', 2, 'MJPG_1600x1200');
                % preview(vid2);
                % img = getsnapshot(vid2);
                img = imread('table_img_10_03_11_59_57.jpg');
                tabledata = RemoveBlock(tabledata,img,tabapp.UIAxes);
                tablestate = [NaN(size(tabledata,1),1) tabledata(:,3) tabledata(:,5:6) tabledata(:,4)];
                tabapp.UITable.Data = tablestate;

                tabapp.DELETEButtonPressed = 0;
            end
            
            %Path Planning-------------------------------------------------
            
            if(mvapp.NAVIGATEButtonPressed)
                startBP = mvapp.StartBPEditField.Value;
                ri = double(startBP(1))-64;
                ci = str2double(startBP(2));
                start = [ri ci];
                
                goalBP = mvapp.GoalBPEditField.Value;
                ri = double(goalBP(1))-64;
                ci = str2double(goalBP(2));
                goal = [ri ci];
                
                [ri,ci]= ind2sub([9 9],find(board==1));
                obstacles = [ri ci];
                
                pathStatus = PathTraverse(socket,start,goal,obstacles);
                
                if(pathStatus==0)
                    mvapp.StatusEditField.Value = 'No possible path found';
                    pause(2);
                end
                mvapp.StatusEditField.Value = 'Ready';
                mvapp.NAVIGATEButtonPressed = 0;
            end
            
            %-----------------------------------------PVP TicTacToe pressed
            if(mvapp.PvPButtonPressed)
                
                oi = sum(deckW.state);
                xi = sum(deckE.state);
                
                if(oi+xi==12)
                    if(sum(deckW.type)==0 && sum(deckE.type)==6)
                        % Open TTT GUI
                        tttapp = TTTGUI();
                        pause(1);
                        c = zeros(1,9);
                        
                        while(tttapp.EndGameButtonPressed == 0)
                            
                            % Once cell is pressed, calc the position on board (CP)
                            % The robot will pick up either a Letter or Shape block
                            % depending on the player turn, and release it on the Cell
                            % Point (CP).
                            
                            if(tttapp.EndGameButtonVal ==1)
                                tttapp.EndGameButtonPressed = 1;
                            else
                                % Cell 1 Pressed - D4
                                if(tttapp.CellOneVal == 1 && c(1) == 0)
                                    
                                    % Now we need to see which player turn it is.
                                    % Player 1 is 'O' (Shapes) and 2 is 'X'(Letters)
                                    if (tttapp.Cell1Button.Text == tttapp.Player1)
                                        
                                        % Player 1 deck is located WESTERN side of table
                                        % Move to first block pos (Western Side for Player 1)
                                        oi = find(deckW.state==1,1);
                                        tabXY = BP.deckW(oi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckW.state(oi) = 0;
                                        
                                        % Now move the block into Cell 1 Position
                                        ti = 1; % Cell 1
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(6,6) = deckW.type(oi);
                                        table.theta(6,6) = deckW.theta(oi);
                                        deckW.theta(oi) = NaN;
                                        deckW.type(oi) = NaN;
                                        editRow = find(tablestate(:,1)==oi+100,1);
                                    else
                                        xi = find(deckE.state==1,1);
                                        tabXY = BP.deckE(xi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckE.state(xi) = 0;
                                        
                                        % Now move the block into Cell 1 Position
                                        ti = 1; % Cell 1
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(6,6) = deckE.type(xi);
                                        table.theta(6,6) = deckE.theta(xi);
                                        deckE.theta(xi) = NaN;
                                        deckE.type(xi) = NaN;
                                        editRow = find(tablestate(:,1)==xi+200,1);
                                    end
                                    board(6,6) = 1;
                                    c(1) = 1;
                                    BPi  = sub2ind([9 9],6,6);
                                    
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                end
                                
                                % Cell 2 Pressed - D5
                                if(tttapp.CellTwoVal == 1 && c(2) == 0)
                                    if (tttapp.Cell2Button.Text == tttapp.Player1)
                                        oi = find(deckW.state==1,1);
                                        tabXY = BP.deckW(oi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckW.state(oi) = 0;
                                        
                                        ti = 2; % Cell 2
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(6,5) = deckW.type(oi);
                                        table.theta(6,5) = deckW.theta(oi);
                                        deckW.theta(oi) = NaN;
                                        deckW.type(oi) = NaN;
                                        editRow = find(tablestate(:,1)==oi+100,1);
                                    else
                                        xi = find(deckE.state==1,1);
                                        tabXY = BP.deckE(xi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckE.state(xi) = 0;
                                        
                                        ti = 2; % Cell 2
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(6,5) = deckE.type(xi);
                                        table.theta(6,5) = deckE.theta(xi);
                                        deckE.theta(xi) = NaN;
                                        deckE.type(xi) = NaN;
                                        editRow = find(tablestate(:,1)==xi+200,1);
                                    end
                                    board(6,5) = 1;
                                    c(2) = 1;
                                    BPi  = sub2ind([9 9],6,5);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                end
                                
                                % Cell 3 Pressed - D6
                                if(tttapp.CellThreeVal == 1 && c(3) == 0)
                                    if (tttapp.Cell3Button.Text == tttapp.Player1)
                                        oi = find(deckW.state==1,1);
                                        tabXY = BP.deckW(oi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckW.state(oi) = 0;
                                        
                                        ti = 3; % Cell 3
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(6,4) = deckW.type(oi);
                                        table.theta(6,4) = deckW.theta(oi);
                                        deckW.theta(oi) = NaN;
                                        deckW.type(oi) = NaN;
                                        editRow = find(tablestate(:,1)==oi+100,1);
                                    else
                                        xi = find(deckE.state==1,1);
                                        tabXY = BP.deckE(xi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckE.state(xi) = 0;
                                        
                                        ti = 3; % Cell 3
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(6,4) = deckE.type(xi);
                                        table.theta(6,4) = deckE.theta(xi);
                                        deckE.theta(xi) = NaN;
                                        deckE.type(xi) = NaN;
                                        editRow = find(tablestate(:,1)==xi+200,1);
                                    end
                                    board(6,4) = 1;
                                    c(3) = 1;
                                    BPi  = sub2ind([9 9],6,4);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                end
                                
                                % Cell 4 Pressed - E4
                                if(tttapp.CellFourVal == 1 && c(4) == 0)
                                    if (tttapp.Cell4Button.Text == tttapp.Player1)
                                        oi = find(deckW.state==1,1);
                                        tabXY = BP.deckW(oi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckW.state(oi) = 0;
                                        
                                        ti = 4; % Cell 4
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(5,6) = deckW.type(oi);
                                        table.theta(5,6) = deckW.theta(oi);
                                        deckW.theta(oi) = NaN;
                                        deckW.type(oi) = NaN;
                                        editRow = find(tablestate(:,1)==oi+100,1);
                                    else
                                        xi = find(deckE.state==1,1);
                                        tabXY = BP.deckE(xi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckE.state(xi) = 0;
                                        
                                        ti = 4; % Cell 4
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(5,6) = deckE.type(xi);
                                        table.theta(5,6) = deckE.theta(xi);
                                        deckE.theta(xi) = NaN;
                                        deckE.type(xi) = NaN;
                                        editRow = find(tablestate(:,1)==xi+200,1);
                                    end
                                    board(5,6) = 1;
                                    c(4) = 1;
                                    BPi  = sub2ind([9 9],5,6);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                end
                                
                                % Cell 5 Pressed - E5
                                if(tttapp.CellFiveVal == 1 && c(5) == 0)
                                    if (tttapp.Cell5Button.Text == tttapp.Player1)
                                        oi = find(deckW.state==1,1);
                                        tabXY = BP.deckW(oi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckW.state(oi) = 0;
                                        
                                        ti = 5; % Cell 5
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(5,5) = deckW.type(oi);
                                        table.theta(5,5) = deckW.theta(oi);
                                        deckW.theta(oi) = NaN;
                                        deckW.type(oi) = NaN;
                                        editRow = find(tablestate(:,1)==oi+100,1);
                                    else
                                        xi = find(deckE.state==1,1);
                                        tabXY = BP.deckE(xi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckE.state(xi) = 0;
                                        
                                        ti = 5; % Cell 5
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(5,5) = deckE.type(xi);
                                        table.theta(5,5) = deckE.theta(xi);
                                        deckE.theta(xi) = NaN;
                                        deckE.type(xi) = NaN;
                                        editRow = find(tablestate(:,1)==xi+200,1);
                                    end
                                    board(5,5) = 1;
                                    c(5) = 1;
                                    BPi  = sub2ind([9 9],5,5);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                end
                                
                                % Cell 6 Pressed - E6
                                if(tttapp.CellSixVal == 1 && c(6) == 0)
                                    if (tttapp.Cell6Button.Text == tttapp.Player1)
                                        oi = find(deckW.state==1,1);
                                        tabXY = BP.deckW(oi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckW.state(oi) = 0;
                                        
                                        ti = 6; % Cell 6
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(5,4) = deckW.type(oi);
                                        table.theta(5,4) = deckW.theta(oi);
                                        deckW.theta(oi) = NaN;
                                        deckW.type(oi) = NaN;
                                        editRow = find(tablestate(:,1)==oi+100,1);
                                    else
                                        xi = find(deckE.state==1,1);
                                        tabXY = BP.deckE(xi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckE.state(xi) = 0;
                                        
                                        ti = 6; % Cell 6
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(5,4) = deckE.type(xi);
                                        table.theta(5,4) = deckE.theta(xi);
                                        deckE.theta(xi) = NaN;
                                        deckE.type(xi) = NaN;
                                        editRow = find(tablestate(:,1)==xi+200,1);
                                    end
                                    board(5,4) = 1;
                                    c(6) = 1;
                                    BPi  = sub2ind([9 9],5,4);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                end
                                
                                % Cell 7 Pressed - F4
                                if(tttapp.CellSevenVal == 1 && c(7) == 0)
                                    if (tttapp.Cell7Button.Text == tttapp.Player1)
                                        oi = find(deckW.state==1,1);
                                        tabXY = BP.deckW(oi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckW.state(oi) = 0;
                                        
                                        ti = 7; % Cell 7
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(4,6) = deckW.type(oi);
                                        table.theta(4,6) = deckW.theta(oi);
                                        deckW.theta(oi) = NaN;
                                        deckW.type(oi) = NaN;
                                        editRow = find(tablestate(:,1)==oi+100,1);
                                    else
                                        xi = find(deckE.state==1,1);
                                        tabXY = BP.deckE(xi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckE.state(xi) = 0;
                                        
                                        ti = 7; % Cell 7
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(4,6) = deckE.type(xi);
                                        table.theta(4,6) = deckE.theta(xi);
                                        deckE.theta(xi) = NaN;
                                        deckE.type(xi) = NaN;
                                        editRow = find(tablestate(:,1)==xi+200,1);
                                    end
                                    board(4,6) = 1;
                                    c(7) = 1;
                                    BPi  = sub2ind([9 9],4,6);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                end
                                
                                % Cell 8 Pressed - F5
                                if(tttapp.CellEightVal == 1 && c(8) == 0)
                                    if (tttapp.Cell8Button.Text == tttapp.Player1)
                                        oi = find(deckW.state==1,1);
                                        tabXY = BP.deckW(oi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckW.state(oi) = 0;
                                        
                                        ti = 8; % Cell 8
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(4,5) = deckW.type(oi);
                                        table.theta(4,5) = deckW.theta(oi);
                                        deckW.theta(oi) = NaN;
                                        deckW.type(oi) = NaN;
                                        editRow = find(tablestate(:,1)==oi+100,1);
                                    else
                                        xi = find(deckE.state==1,1);
                                        tabXY = BP.deckE(xi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckE.state(xi) = 0;
                                        
                                        ti = 8; % Cell 8
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(4,5) = deckE.type(xi);
                                        table.theta(4,5) = deckE.theta(xi);
                                        deckE.theta(xi) = NaN;
                                        deckE.type(xi) = NaN;
                                        editRow = find(tablestate(:,1)==xi+200,1);
                                    end
                                    board(4,5) = 1;
                                    c(8) = 1;
                                    BPi  = sub2ind([9 9],4,5);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                end
                                
                                % Cell 9 Pressed - F6
                                if(tttapp.CellNineVal == 1 && c(9) == 0)
                                    if (tttapp.Cell9Button.Text == tttapp.Player1)
                                        oi = find(deckW.state==1,1);
                                        tabXY = BP.deckW(oi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckW.state(oi) = 0;
                                        
                                        ti = 9; % Cell 9
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(4,4) = deckW.type(oi);
                                        table.theta(4,4) = deckW.theta(oi);
                                        deckW.theta(oi) = NaN;
                                        deckW.type(oi) = NaN;
                                        editRow = find(tablestate(:,1)==oi+100,1);
                                    else
                                        xi = find(deckE.state==1,1);
                                        tabXY = BP.deckE(xi,:);
                                        TTTpickup(socket,tabXY,tttapp);
                                        deckE.state(xi) = 0;
                                        
                                        ti = 9; % Cell 9
                                        tabXY = BP.TTT(ti,:);
                                        TTTdropoff(socket,tabXY,tttapp);
                                        table.type(4,4) = deckE.type(xi);
                                        table.theta(4,4) = deckE.theta(xi);
                                        deckE.theta(xi) = NaN;
                                        deckE.type(xi) = NaN;
                                        editRow = find(tablestate(:,1)==xi+200,1);
                                    end
                                    board(4,4) = 1;
                                    c(9) = 1;
                                    BPi  = sub2ind([9 9],4,4);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                end
                                pause(1);
                            end
                        end
                        tttapp.EndGameButtonPressed = 0;
                        tttapp.EndGameButtonVal = 0;
                        
                        % Pack up blocks
                        ti = sub2ind([9 9],[6 6 6 5 5 5 4 4 4],[6 5 4 6 5 4 6 5 4]); %D4
                        tttType = table.type(ti);
                        
                        P1blocksi = find(tttType==0);
                        
                        if(~isempty(P1blocksi))
                            P1XY = BP.TTT(P1blocksi,:);
                            for i = 1:size(P1XY,1)
                                
                                [r,c] = ind2sub([3 3],P1blocksi(i));
                                tabXY = P1XY(i,:);
                                BPpickup(socket,tabXY);
                                board((4-r)+3,(4-c)+3) = 0;
                                
                                freeoi = find(deckW.state==0,1);
                                tabXY = BP.deckW(freeoi,:);
                                BPdropoff(socket,tabXY);
                                deckW.state(freeoi) = 1;
                                
                                %remove block from list
                                BPi = sub2ind([9 9],(4-r)+3,(4-c)+3);
                                editRow = find(tablestate(:,1)==BPi,1);
                                tablestate(editRow,:) = [freeoi+100 table.type((4-r)+3,(4-c)+3) tabXY table.theta((4-r)+3,(4-c)+3)];
                                tabapp.UITable.Data = tablestate;
                                
                                table.type((4-r)+3,(4-c)+3) = NaN;
                                table.theta((4-r)+3,(4-c)+3) = NaN;
                            end
                        end
                        
                        P2blocksi = find(tttType==1);
                        
                        if(~isempty(P2blocksi))
                            P2XY = BP.TTT(P2blocksi,:);
                            
                            for i = 1:size(P2XY,1)
                                
                                [r,c] = ind2sub([3 3],P2blocksi(i));
                                tabXY = P2XY(i,:);
                                BPpickup(socket,tabXY);
                                board((4-r)+3,(4-c)+3) = 0;
                                
                                freexi = find(deckE.state==0,1);
                                tabXY = BP.deckE(freexi,:);
                                BPdropoff(socket,tabXY);
                                deckE.state(freexi) = 1;
                                
                                %remove block from list
                                BPi = sub2ind([9 9],(4-r)+3,(4-c)+3);
                                editRow = find(tablestate(:,1)==BPi,1);
                                tablestate(editRow,:) = [freexi+200 table.type((4-r)+3,(4-c)+3) tabXY table.theta((4-r)+3,(4-c)+3)];
                                tabapp.UITable.Data = tablestate;
                                
                                table.type((4-r)+3,(4-c)+3) = NaN;
                                table.theta((4-r)+3,(4-c)+3) = NaN;
                            end
                        end
                        tttapp.delete();
                    else
                        mvapp.StatusEditField_4.Value = "Decks are not sorted";
                        pause(2);
                    end
                else
                    mvapp.StatusEditField_4.Value = "Decks aren't full";
                    pause(2);
                end
                mvapp.StatusEditField_4.Value = 'Ready';
                mvapp.PvPButtonPressed = 0;
            end
            
            %AIvP---------------------------------------------------------
            
            if(mvapp.AIvPButtonPressed)
                
                oi = sum(deckW.state);
                xi = sum(deckE.state);
                
                if(oi+xi==12)
                    if(sum(deckW.type)==0 && sum(deckE.type)==6)
                    % Open TTT GUI
                    tttapp = TTTGUI();
                    pause(1);
                    c = zeros(1,9);
                    turn = 0;
                    boardState = {1,2,3,4,5,6,7,8,9};
                    
                    % set a board state here before loop
                    
                    while(tttapp.EndGameButtonPressed == 0)
                        
                        if(tttapp.EndGameButtonVal == 1)
                            tttapp.EndGameButtonPressed = 1;
                        else
                            
                            if(turn==0)
                                bestMove = TTTAI(boardState);
                                
                                % Update GUI depending on the case
                                switch bestMove
                                    case 1
                                        tttapp.Cell1Button.Text = tttapp.Player1;
                                        tttapp.Cell1Button.FontSize = 28;
                                        tttapp.Cell1Button.FontWeight = 'bold';
                                        tttapp.CellOneVal = 1;
                                        tttapp.PlayerTurnTextArea.Value = 'Player Two Turn';
                                        tttapp.PlayerTurnTextArea.FontColor = [0.00, 0.45, 0.74];
                                        tttapp.counter = tttapp.counter + 1;
                                        tttapp.CellOneNum = 1;
                                        tttapp.GameErrorsTextArea.Value = 'No Errors!';
                                        tttapp.Lamp.Enable = 'off';
                                        
                                        c(1) = 1;
                                        boardState{1} = 'O';
                                    case 2
                                        tttapp.Cell2Button.Text = tttapp.Player1;
                                        tttapp.Cell2Button.FontSize = 28;
                                        tttapp.Cell2Button.FontWeight = 'bold';
                                        tttapp.CellTwoNum = 1;
                                        tttapp.PlayerTurnTextArea.Value = 'Player Two Turn';
                                        tttapp.PlayerTurnTextArea.FontColor = [0.00, 0.45, 0.74];
                                        tttapp.counter = tttapp.counter + 1;
                                        tttapp.CellTwoVal = 1;
                                        tttapp.GameErrorsTextArea.Value = 'No Errors!';
                                        tttapp.Lamp_2.Enable = 'off';
                                        
                                        c(2) = 1;
                                        boardState{2} = 'O';
                                    case 3
                                        tttapp.Cell3Button.Text = tttapp.Player1;
                                        tttapp.Cell3Button.FontSize = 28;
                                        tttapp.Cell3Button.FontWeight = 'bold';
                                        tttapp.CellThreeNum = 1;
                                        tttapp.PlayerTurnTextArea.Value = 'Player Two Turn';
                                        tttapp.PlayerTurnTextArea.FontColor = [0.00, 0.45, 0.74];
                                        tttapp.counter = tttapp.counter + 1;
                                        tttapp.CellThreeVal = 1;
                                        tttapp.GameErrorsTextArea.Value = 'No Errors!';
                                        tttapp.Lamp_3.Enable = 'off';
                                        
                                        c(3) = 1;
                                        boardState{3} = 'O';
                                    case 4
                                        tttapp.Cell4Button.Text = tttapp.Player1;
                                        tttapp.Cell4Button.FontSize = 28;
                                        tttapp.Cell4Button.FontWeight = 'bold';
                                        tttapp.CellFourVal = 1;
                                        tttapp.PlayerTurnTextArea.Value = 'Player Two Turn';
                                        tttapp.PlayerTurnTextArea.FontColor = [0.00, 0.45, 0.74];
                                        tttapp.counter = tttapp.counter + 1;
                                        tttapp.CellFourNum = 1;
                                        tttapp.GameErrorsTextArea.Value = 'No Errors!';
                                        tttapp.Lamp_4.Enable = 'off';
                                        
                                        c(4) = 1;
                                        boardState{4} = 'O';
                                    case 5
                                        tttapp.Cell5Button.Text = tttapp.Player1;
                                        tttapp.Cell5Button.FontSize = 28;
                                        tttapp.Cell5Button.FontWeight = 'bold';
                                        tttapp.CellFiveNum = 1;
                                        tttapp.PlayerTurnTextArea.Value = 'Player Two Turn';
                                        tttapp.PlayerTurnTextArea.FontColor = [0.00, 0.45, 0.74];
                                        tttapp.counter = tttapp.counter + 1;
                                        tttapp.CellFiveVal = 1;
                                        tttapp.GameErrorsTextArea.Value = 'No Errors!';
                                        tttapp.Lamp_5.Enable = 'off';
                                        
                                        c(5) = 1;
                                        boardState{5} = 'O';
                                    case 6
                                        tttapp.Cell6Button.Text = tttapp.Player1;
                                        tttapp.Cell6Button.FontSize = 28;
                                        tttapp.Cell6Button.FontWeight = 'bold';
                                        tttapp.CellSixNum = 1;
                                        tttapp.PlayerTurnTextArea.Value = 'Player Two Turn';
                                        tttapp.PlayerTurnTextArea.FontColor = [0.00, 0.45, 0.74];
                                        tttapp.counter = tttapp.counter + 1;
                                        tttapp.CellSixVal = 1;
                                        tttapp.GameErrorsTextArea.Value = 'No Errors!';
                                        tttapp.Lamp_6.Enable = 'off';
                                        
                                        c(6) = 1;
                                        boardState{6} = 'O';
                                    case 7
                                        tttapp.Cell7Button.Text = tttapp.Player1;
                                        tttapp.Cell7Button.FontSize = 28;
                                        tttapp.Cell7Button.FontWeight = 'bold';
                                        tttapp.CellSevenNum = 1;
                                        tttapp.PlayerTurnTextArea.Value = 'Player Two Turn';
                                        tttapp.PlayerTurnTextArea.FontColor = [0.00, 0.45, 0.74];
                                        tttapp.counter = tttapp.counter + 1;
                                        tttapp.CellSevenVal = 1;
                                        tttapp.GameErrorsTextArea.Value = 'No Errors!';
                                        tttapp.Lamp_7.Enable = 'off';
                                        
                                        c(7) = 1;
                                        boardState{7} = 'O';
                                    case 8
                                        tttapp.Cell8Button.Text = tttapp.Player1;
                                        tttapp.Cell8Button.FontSize = 28;
                                        tttapp.Cell8Button.FontWeight = 'bold';
                                        tttapp.CellEightNum = 1;
                                        tttapp.PlayerTurnTextArea.Value = 'Player Two Turn';
                                        tttapp.PlayerTurnTextArea.FontColor = [0.00, 0.45, 0.74];
                                        tttapp.counter = tttapp.counter + 1;
                                        tttapp.CellEightVal = 1;
                                        tttapp.GameErrorsTextArea.Value = 'No Errors!';
                                        tttapp.Lamp_8.Enable = 'off';
                                        
                                        c(8) = 1;
                                        boardState{8} = 'O';
                                    case 9
                                        tttapp.Cell9Button.Text = tttapp.Player1;
                                        tttapp.Cell9Button.FontSize = 28;
                                        tttapp.Cell9Button.FontWeight = 'bold';
                                        tttapp.CellNineNum = 1;
                                        tttapp.PlayerTurnTextArea.Value = 'Player Two Turn';
                                        tttapp.PlayerTurnTextArea.FontColor = [0.00, 0.45, 0.74];
                                        tttapp.counter = tttapp.counter + 1;
                                        tttapp.CellNineVal = 1;
                                        tttapp.GameErrorsTextArea.Value = 'No Errors!';
                                        tttapp.Lamp_9.Enable = 'off';
                                        
                                        c(9) = 1;
                                        boardState{9} = 'O';
                                end
                                
                                % Move block to position
                                oi = find(deckW.state==1,1);
                                tabXY = BP.deckW(oi,:);
                                TTTpickup(socket,tabXY,tttapp);
                                deckW.state(oi) = 0;
                                
                                ti = bestMove;
                                tabXY = BP.TTT(ti,:);
                                TTTdropoff(socket,tabXY,tttapp);
                                
                                [ri,ci] = ind2sub([3 3],ti);
                                table.type((4-ri)+3,(4-ci)+3) = deckW.type(oi);
                                
                                board((4-ri)+3,(4-ci)+3) = 1;
                                table.theta((4-ri)+3,(4-ci)+3) = deckW.theta(oi);
                                deckW.theta(oi) = NaN;
                                deckW.type(oi) = NaN;
                                turn = 1;
                                
                                BPi  = sub2ind([9 9],(4-ri)+3,(4-ci)+3);
                                
                                editRow = find(tablestate(:,1)==oi+100,1);
                                %change block BPs
                                tablestate(editRow,1) = BPi;
                                tablestate(editRow,3:4) = tabXY;
                                tabapp.UITable.Data = tablestate;
                                
                                res1 = tttapp.CellOneNum;
                                res2 = tttapp.CellTwoNum;
                                res3 = tttapp.CellThreeNum;
                                res4 = tttapp.CellFourNum;
                                res5 = tttapp.CellFiveNum;
                                res6 = tttapp.CellSixNum;
                                res7 = tttapp.CellSevenNum;
                                res8 = tttapp.CellEightNum;
                                res9 = tttapp.CellNineNum;
                                
                                % 1st row
                                if((res1 * res2 * res3 == 1)||(res4 * res5 * res6 == 1)||(res7 * res8 * res9 == 1)...
                                        ||(res1 * res4 * res7 == 1)||(res2 * res5 * res8 == 1)||(res3 * res6 * res9 == 1)...
                                        ||(res1 * res5 * res9 == 1)||(res3 * res5 * res7 == 1))
                                    tttapp.GameStateTextArea.Value = 'PLAYER 1 WINS!';
                                    tttapp.GameStateTextArea.BackgroundColor = [1.00, 0, 0];
                                    tttapp.PlayerTurnTextArea.FontColor = [0,0,0];
                                    tttapp.PlayerTurnTextArea.Value = 'Game Over!';
                                    tttapp.GameErrorsTextArea.Value = 'Game Over!';
                                    tttapp.EndGameButtonVal = 1;
                                elseif ((res1 + res2 + res3 == 6)||(res4 + res5 + res6 == 6)||(res7 + res8 + res9 == 6)...
                                        ||(res1 + res4 + res7 == 6)||(res2 + res5 + res8 == 6)||(res3 + res6 + res9 == 6)...
                                        ||(res1 + res5 + res9 == 6)||(res3 + res5 + res7 == 6))
                                    tttapp.GameStateTextArea.Value = 'PLAYER 2 WINS!';
                                    tttapp.GameStateTextArea.BackgroundColor = [0, 0.45, 0.74];
                                    tttapp.PlayerTurnTextArea.FontColor = [0,0,0];
                                    tttapp.PlayerTurnTextArea.Value = 'Game Over!';
                                    tttapp.GameErrorsTextArea.Value = 'Game Over!';
                                    tttapp.EndGameButtonVal = 1;
                                elseif(sum(c)==9)
                                    tttapp.GameStateTextArea.Value = 'Game has Drawn!';
                                    tttapp.PlayerTurnTextArea.Value = 'Game Over!';
                                    tttapp.GameErrorsTextArea.Value = 'Game Over!';
                                    tttapp.EndGameButtonVal = 1;
                                end
                                
                            else
                                
                                % player's turns--------------------------------------
                                
                                % Once cell is pressed, calc the position on board (CP)
                                % The robot will pick up either a Letter or Shape block
                                % depending on the player turn, and release it on the Cell
                                % Point (CP).
                                
                                % Cell 1 Pressed - D4
                                if(tttapp.CellOneVal == 1 && c(1) == 0)
                                    
                                    xi = find(deckE.state==1,1);
                                    tabXY = BP.deckE(xi,:);
                                    TTTpickup(socket,tabXY,tttapp);
                                    deckE.state(xi) = 0;
                                    
                                    % Now move the block into Cell 1 Position
                                    ti = 1; % Cell 1
                                    tabXY = BP.TTT(ti,:);
                                    TTTdropoff(socket,tabXY,tttapp);
                                    table.type(6,6) = deckE.type(xi);
                                    table.theta(6,6) = deckE.theta(xi);
                                    deckE.theta(xi) = NaN;
                                    deckE.type(xi) = NaN;
                                    boardState{1} = 'X';
                                    
                                    board(6,6) = 1;
                                    c(1) = 1;
                                    BPi  = sub2ind([9 9],6,6);
                                    editRow = find(tablestate(:,1)==xi+200,1);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                    
                                    turn = 0;
                                end
                                
                                % Cell 2 Pressed - D5
                                if(tttapp.CellTwoVal == 1 && c(2) == 0)
                                    
                                    xi = find(deckE.state==1,1);
                                    tabXY = BP.deckE(xi,:);
                                    TTTpickup(socket,tabXY,tttapp);
                                    deckE.state(xi) = 0;                                 
                                    
                                    ti = 2; % Cell 2
                                    tabXY = BP.TTT(ti,:);
                                    TTTdropoff(socket,tabXY,tttapp);
                                    table.type(6,5) = deckE.type(xi);
                                    table.theta(6,5) = deckE.theta(xi);
                                    deckE.theta(xi) = NaN;
                                    deckE.type(xi) = NaN;
                                    boardState{2} = 'X';
                                    
                                    board(6,5) = 1;
                                    c(2) = 1;
                                    BPi  = sub2ind([9 9],6,5);
                                    editRow = find(tablestate(:,1)==xi+200,1);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                    
                                    turn = 0;
                                end
                                
                                % Cell 3 Pressed - D6
                                if(tttapp.CellThreeVal == 1 && c(3) == 0)
                                    
                                    xi = find(deckE.state==1,1);
                                    tabXY = BP.deckE(xi,:);
                                    TTTpickup(socket,tabXY,tttapp);
                                    deckE.state(xi) = 0;                              
                                    
                                    ti = 3; % Cell 3
                                    tabXY = BP.TTT(ti,:);
                                    TTTdropoff(socket,tabXY,tttapp);
                                    table.type(6,4) = deckE.type(xi);
                                    table.theta(6,4) = deckE.theta(xi);
                                    deckE.theta(xi) = NaN;
                                    deckE.type(xi) = NaN;
                                    boardState{3} = 'X';
                                    
                                    board(6,4) = 1;
                                    c(3) = 1;
                                    BPi  = sub2ind([9 9],6,4);
                                    editRow = find(tablestate(:,1)==xi+200,1);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                    
                                    turn = 0;
                                end
                                
                                % Cell 4 Pressed - E4
                                if(tttapp.CellFourVal == 1 && c(4) == 0)
                                    
                                    xi = find(deckE.state==1,1);
                                    tabXY = BP.deckE(xi,:);
                                    TTTpickup(socket,tabXY,tttapp);
                                    deckE.state(xi) = 0;                    
                                    
                                    ti = 4; % Cell 4
                                    tabXY = BP.TTT(ti,:);
                                    TTTdropoff(socket,tabXY,tttapp);
                                    table.type(5,6) = deckE.type(xi);
                                    table.theta(5,6) = deckE.theta(xi);
                                    deckE.theta(xi) = NaN;
                                    deckE.type(xi) = NaN;
                                    boardState{4} = 'X';
                                    
                                    board(5,6) = 1;
                                    c(4) = 1;
                                    BPi  = sub2ind([9 9],5,6);
                                    editRow = find(tablestate(:,1)==xi+200,1);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                    
                                    turn = 0;
                                end
                                
                                % Cell 5 Pressed - E5
                                if(tttapp.CellFiveVal == 1 && c(5) == 0)
                                    
                                    xi = find(deckE.state==1,1);
                                    tabXY = BP.deckE(xi,:);
                                    TTTpickup(socket,tabXY,tttapp);
                                    deckE.state(xi) = 0;                            
                                    
                                    ti = 5; % Cell 5
                                    tabXY = BP.TTT(ti,:);
                                    TTTdropoff(socket,tabXY,tttapp);
                                    table.type(5,5) = deckE.type(xi);
                                    table.theta(5,5) = deckE.theta(xi);
                                    deckE.theta(xi) = NaN;
                                    deckE.type(xi) = NaN;
                                    boardState{5} = 'X';
                                    
                                    board(5,5) = 1;
                                    c(5) = 1;
                                    BPi  = sub2ind([9 9],5,5);
                                    editRow = find(tablestate(:,1)==xi+200,1);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                    
                                    turn = 0;
                                end
                                
                                % Cell 6 Pressed - E6
                                if(tttapp.CellSixVal == 1 && c(6) == 0)
                                    
                                    xi = find(deckE.state==1,1);
                                    tabXY = BP.deckE(xi,:);
                                    TTTpickup(socket,tabXY,tttapp);
                                    deckE.state(xi) = 0;

                                    ti = 6; % Cell 6
                                    tabXY = BP.TTT(ti,:);
                                    TTTdropoff(socket,tabXY,tttapp);
                                    table.type(5,4) = deckE.type(xi);
                                    table.theta(5,4) = deckE.theta(xi);
                                    deckE.theta(xi) = NaN;
                                    deckE.type(xi) = NaN;
                                    boardState{6} = 'X';
                                    
                                    board(5,4) = 1;
                                    c(6) = 1;
                                    BPi  = sub2ind([9 9],5,4);
                                    editRow = find(tablestate(:,1)==xi+200,1);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                    
                                    turn = 0;
                                end
                                
                                % Cell 7 Pressed - F4
                                if(tttapp.CellSevenVal == 1 && c(7) == 0)
                                    
                                    xi = find(deckE.state==1,1);
                                    tabXY = BP.deckE(xi,:);
                                    TTTpickup(socket,tabXY,tttapp);
                                    deckE.state(xi) = 0;
                                    
                                    ti = 7; % Cell 7
                                    tabXY = BP.TTT(ti,:);
                                    TTTdropoff(socket,tabXY,tttapp);
                                    table.type(4,6) = deckE.type(xi);
                                    table.theta(4,6) = deckE.theta(xi);
                                    deckE.theta(xi) = NaN;
                                    deckE.type(xi) = NaN;
                                    boardState{7} = 'X';
                                    
                                    board(4,6) = 1;
                                    c(7) = 1;
                                    BPi  = sub2ind([9 9],4,6);
                                    editRow = find(tablestate(:,1)==xi+200,1);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                    
                                    turn = 0;
                                end
                                
                                % Cell 8 Pressed - F5
                                if(tttapp.CellEightVal == 1 && c(8) == 0)
                                    
                                    xi = find(deckE.state==1,1);
                                    tabXY = BP.deckE(xi,:);
                                    TTTpickup(socket,tabXY,tttapp);
                                    deckE.state(xi) = 0;                                
                                    
                                    ti = 8; % Cell 8
                                    tabXY = BP.TTT(ti,:);
                                    TTTdropoff(socket,tabXY,tttapp);
                                    table.type(4,5) = deckE.type(xi);
                                    table.theta(4,5) = deckE.theta(xi);
                                    deckE.theta(xi) = NaN;
                                    deckE.type(xi) = NaN;
                                    boardState{8} = 'X';
                                    
                                    board(4,5) = 1;
                                    c(8) = 1;
                                    BPi  = sub2ind([9 9],4,5);
                                    editRow = find(tablestate(:,1)==xi+200,1);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                    
                                    turn = 0;
                                end
                                
                                % Cell 9 Pressed - F6
                                if(tttapp.CellNineVal == 1 && c(9) == 0)
                                    
                                    xi = find(deckE.state==1,1);
                                    tabXY = BP.deckE(xi,:);
                                    TTTpickup(socket,tabXY,tttapp);
                                    deckE.state(xi) = 0;                                   
                                    
                                    ti = 9; % Cell 9
                                    tabXY = BP.TTT(ti,:);
                                    TTTdropoff(socket,tabXY,tttapp);
                                    table.type(4,4) = deckE.type(xi);
                                    table.theta(4,4) = deckE.theta(xi);
                                    deckE.theta(xi) = NaN;
                                    deckE.type(xi) = NaN;
                                    boardState{9} = 'X';
                                    
                                    board(4,4) = 1;
                                    c(9) = 1;
                                    BPi  = sub2ind([9 9],4,4);
                                    editRow = find(tablestate(:,1)==xi+200,1);
                                    %change block BPs
                                    tablestate(editRow,1) = BPi;
                                    tablestate(editRow,3:4) = tabXY;
                                    tabapp.UITable.Data = tablestate;
                                    
                                    turn = 0;
                                end
                                pause(1);
                            end
                        end
                    end
                    
                    tttapp.EndGameButtonPressed = 0;
                    tttapp.EndGameButtonVal = 0;
                    
                    % Pack up blocks
                    ti = sub2ind([9 9],[6 6 6 5 5 5 4 4 4],[6 5 4 6 5 4 6 5 4]); %D4
                    tttType = table.type(ti);
                    
                    P1blocksi = find(tttType==0);
                    
                    if(~isempty(P1blocksi))
                        P1XY = BP.TTT(P1blocksi,:);
                        for i = 1:size(P1XY,1)
                            
                            [r,c] = ind2sub([3 3],P1blocksi(i));
                            tabXY = P1XY(i,:);
                            BPpickup(socket,tabXY);
                            board((4-r)+3,(4-c)+3) = 0;
                            
                            freeoi = find(deckW.state==0,1);
                            tabXY = BP.deckW(freeoi,:);
                            BPdropoff(socket,tabXY);
                            deckW.state(freeoi) = 1;
                            
                            %remove block from list
                            BPi = sub2ind([9 9],(4-r)+3,(4-c)+3);
                            editRow = find(tablestate(:,1)==BPi,1);
                            tablestate(editRow,:) = [freeoi+100 table.type((4-r)+3,(4-c)+3) tabXY table.theta((4-r)+3,(4-c)+3)];
                            tabapp.UITable.Data = tablestate;
                            
                            table.type((4-r)+3,(4-c)+3) = NaN;
                            table.theta((4-r)+3,(4-c)+3) = NaN;
                        end
                    end
                    
                    P2blocksi = find(tttType==1);
                    
                    if(~isempty(P2blocksi))
                        P2XY = BP.TTT(P2blocksi,:);
                        
                        for i = 1:size(P2XY,1)
                            
                            [r,c] = ind2sub([3 3],P2blocksi(i));
                            tabXY = P2XY(i,:);
                            BPpickup(socket,tabXY);
                            board((4-r)+3,(4-c)+3) = 0;
                            
                            freexi = find(deckE.state==0,1);
                            tabXY = BP.deckE(freexi,:);
                            BPdropoff(socket,tabXY);
                            deckE.state(freexi) = 1;
                            
                            %remove block from list
                            BPi = sub2ind([9 9],(4-r)+3,(4-c)+3);
                            editRow = find(tablestate(:,1)==BPi,1);
                            tablestate(editRow,:) = [freexi+200 table.type((4-r)+3,(4-c)+3) tabXY table.theta((4-r)+3,(4-c)+3)];
                            tabapp.UITable.Data = tablestate;
                            
                            table.type((4-r)+3,(4-c)+3) = NaN;
                            table.theta((4-r)+3,(4-c)+3) = NaN;
                        end
                    end
                    tttapp.delete;
                    else
                        mvapp.StatusEditField_4.Value = "Decks are not sorted";
                        pause(2);
                    end
                else
                    mvapp.StatusEditField_4.Value = "Decks aren't full";
                    pause(2);
                end
                mvapp.StatusEditField_4.Value = 'Ready';
                mvapp.AIvPButtonPressed = 0;
            end

            pause(0.01);
            % Fall out if no longer connected
        end
        
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
            close all;
            mvapp.delete();
            app.delete();
            tabapp.delete();
            convapp.delete();
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
   
   cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
   fwrite(socket,cmd);
   disp(cmd); 
   WaitForReady(socket);

   cmd = 'MVPOSTAB 0,0,14';
   fwrite(socket,cmd);
   disp(cmd);
   WaitForReady(socket);
end

function WaitForReady(socket)
    movecomplete = 0;
    while(~movecomplete)
       pause(0.5);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
end

function CheckPause(socket,tttapp)
    movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
       
       if(tttapp.PauseGameButtonPressed)
           fwrite(socket, 'ROBPAUSE');
           disp('ROBPAUSE');
           
           paused = 1;
           
           while(paused)
               pause(1);
               if(tttapp.ResumeGameButtonPressed)
                   fwrite(socket, 'ROBRESME');
                   disp('ROBRESME');
                   tttapp.ResumeGameButtonPressed = 0;
                   paused = 0;
               end
           end
           tttapp.PauseGameButtonPressed = 0;
       end
    end 
end

function TTTpickup(socket,tabXY,tttapp)
    %move to BP position
    cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
    fwrite(socket,cmd);
    disp(cmd);
    CheckPause(socket,tttapp);

    % pick up block
    cmd = 'VACUUMON';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    cmd = 'SETSOLEN 1';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    
    fwrite(socket, 'SETSPEED v50');
    disp('SETSPEED v50');
    pause(0.1);

    cmd = sprintf('MVPOSTAB %f,%f,10',tabXY);
    disp(cmd);
    fwrite(socket,cmd);
    CheckPause(socket,tttapp);

    %move to conveyor
    cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
    fwrite(socket,cmd);
    disp(cmd);
    CheckPause(socket,tttapp);
    
    fwrite(socket, 'SETSPEED v100');
    disp('SETSPEED v100');
    pause(0.1);
end

function TTTdropoff(socket,tabXY,tttapp)
   cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
   fwrite(socket,cmd);
   disp(cmd);
   CheckPause(socket,tttapp);
   
   fwrite(socket, 'SETSPEED v50');
   disp('SETSPEED v50');
   pause(0.1);
   
   cmd = sprintf('MVPOSTAB %f,%f,20',tabXY);
   fwrite(socket,cmd);
   disp(cmd); 
   CheckPause(socket,tttapp);

   cmd = 'SETSOLEN 0';
   fwrite(socket,cmd);
   disp(cmd);
   pause(0.1);
   
   cmd = 'VACUUMOF';
   fwrite(socket,cmd);
   disp(cmd);
   pause(0.1);
   
   cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
   fwrite(socket,cmd);
   disp(cmd);
   CheckPause(socket,tttapp);
   
   fwrite(socket, 'SETSPEED v100');
   disp('SETSPEED v100');
   pause(0.1);

   cmd = 'MVPOSTAB 0,0,14';
   fwrite(socket,cmd);
   disp(cmd);
   CheckPause(socket,tttapp);
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
        str = ReceiveState(socket);  
        pause(0.01);
    else
        fwrite(socket,'SETPOSES -90,0,0,0,0,0');
        disp('SETPOSES -90,0,0,0,0,0');
        str = ReceiveState(socket);  
        pause(0.01);
    end
end
