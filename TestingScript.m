
function TestingScript
    clc; clear; close all; dbstop if error;
    cameraConveyorParams = [];
    R = [];
    t = [];
     load('cameraConveyorParams.mat'); %Load Conveyor camera calibration
    load('RotationMatrix.mat');
   load('TranslationMatrix.mat');
    %% robot ip
         robot_IP_address = '192.168.125.1';
    %robot_IP_address = '127.0.0.1'; % Simulation ip address

    robot_port = 1025;

    socket = tcpip(robot_IP_address, robot_port);
    set(socket, 'ReadAsyncMode', 'continuous');
    
    

    %% Connect
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
    %% predefining variables
     
     conapp = ConveyorFeedGUI();
    %get joint angles
    fwrite(socket, 'JNTANGLE');
    str = ReceiveString(socket);
    jAng = str2num(str);

    tabXY = [];
   
    vid = videoinput('winvideo', 1, 'MJPG_1600x1200');
    vid2 = videoinput('winvideo', 2, 'MJPG_1600x1200');
    
    img = getsnapshot(vid);
    img2 = getsnapshot(vid);
     % img2 = imread('conveyor_img_10_03_11_39_04.jpg');
    % img = imread('table_img_08_21_16_22_57.jpg');
    conData = ConveyorImageProcess(img2,cameraConveyorParams,R,t,conapp.UIaxes);
    blockData = tableDetect(img);
    tabXY1 = blockData(1:2,1);
    tabXY2 = blockData(1:2,2);
    tabXY3 = blockData(1:2,3);
    tabXY4 = tabXY3 +20;
    tabXY5 = blockData(1:2,4);
    %% Script
    
    report = 0;
    report = BPtoCON_test(socket,tabXY1,[0,0])
    if report 
        fwrite('BPtoCON Success')
    else
        fwrite('BPtoCON failed')
    end
    report = 0;
    report = CONtoBP_test(socket,tabXY2,conData(1:2,1))
    if report 
        fwrite('BPtoCON Success')
    else
        fwrite('BPtoCON failed')
    end
    
    report = 0;
    report = BPtoBP_test(socket,tabXY3, tabXY4)
    if report 
        fwrite('BPtoCON Success')
    else
        fwrite('BPtoCON failed')
    end
    
    report = 0;
    report = Rotate_test(socket,tabXY5,jAng,72)
    if report 
        fwrite('BPtoCON Success')
    else
        fwrite('BPtoCON failed')
    end
    
%% Testing BP to converyor
function report = BPtoCON_test(socket,tabXY,conXY)
   
%move to BP position
    cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
    fwrite(socket,cmd);
    disp(cmd);
    pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end

    % pick up block (turn on vac and move down)
    cmd = 'VACUUMON';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    cmd = 'SETSOLEN 1';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    
    cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
    disp(cmd);
    fwrite(socket,cmd);
    pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end

    %move up
    cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
    fwrite(socket,cmd);
    disp(cmd);
    pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
  

%% CON Dropoff

    cmd = sprintf('MVPOSCON %f,%f,100',conXY);
    fwrite(socket,cmd);
    disp(cmd);
    pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
    cmd = sprintf('MVPOSCON %f,%f,14',conXY);
    fwrite(socket,cmd);
    disp(cmd);
    pause(3);
    movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
    blockreleased = 0;
    while(~blockreleased)
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
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

    % Move out of the way to home 
    fwrite(socket,'SETPOSES -90,0,0,0,0,0');
    disp('SETPOSES -90,0,0,0,0,0');
    pause(0.01);
    %check if in motion
    movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
    % CAMERA CHECK
     vid = videoinput('winvideo', 1, 'MJPG_1600x1200');
   
    img = getsnapshot(vid);
    
     % img2 = imread('conveyor_img_10_03_11_39_04.jpg');
    % img = imread('table_img_08_21_16_22_57.jpg');
   
    blockData = tableDetect(img);
    moveSuccessful =0;
    moveSuccessful = moveCheck(tabXY,blockData);
  
    if moveSuccessful
        report = 0; % failed because block is still on table
    else
      report = 1;
    end
    
end

function report = CONtoBP_test(socket,tabXY,conXY)
     
% Con pick up
    cmd = sprintf('MVPOSCON %f,%f,200',conXY);
   disp(cmd);
   fwrite(socket,cmd);
   pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
   % pick up block
   cmd = 'VACUUMON';
   fwrite(socket,cmd);
   disp(cmd);
   pause(0.1);
   cmd = 'SETSOLEN 1';
   fwrite(socket,cmd);
   disp(cmd);
   pause(0.2);

   cmd = sprintf('MVPOSCON %f,%f,14',conXY);
   disp(cmd);
   fwrite(socket,cmd);
   pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
   cmd = sprintf('MVPOSCON %f,%f,200',conXY);
   disp(cmd);
   fwrite(socket,cmd);
   pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
   
  

   %% BP Dropoff
   cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
   fwrite(socket,cmd);
   disp(cmd);
   pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
   
   cmd = sprintf('MVPOSTAB %f,%f,14',tabXY);
   fwrite(socket,cmd);
   disp(cmd);
   pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
   blockreleased = 0;
   while(~blockreleased)
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
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
   

    
    % Move out of the way to home 
    fwrite(socket,'SETPOSES -90,0,0,0,0,0');
    disp('SETPOSES -90,0,0,0,0,0');
    pause(0.01);
    %check if in motion
    movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
    % CAMERA CHECK
    vid = videoinput('winvideo', 1, 'MJPG_1600x1200');
    
    img = getsnapshot(vid);
   
     % img2 = imread('conveyor_img_10_03_11_39_04.jpg');
    % img = imread('table_img_08_21_16_22_57.jpg');
   
    blockData = tableDetect(img);
    moveSuccessful =0;
    moveSuccessful = moveCheck(tabXY,blockData);
  
    if moveSuccessful
        report = 1; % success because block is now on table
    else
        report = 0;
    end
end

function report = BPtoBP_test(socket,tabXYP, tabXYD) % P = pickup , d= dropoff
%BP pick up
 global convapp;
    global tabapp;
cmd = sprintf('MVPOSTAB %f,%f,100',tabXYP);
    fwrite(socket,cmd);
    disp(cmd);
    pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end

    % pick up block (turn on vac and move down)
    cmd = 'VACUUMON';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    cmd = 'SETSOLEN 1';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    
    cmd = sprintf('MVPOSTAB %f,%f,13',tabXYP);
    disp(cmd);
    fwrite(socket,cmd);
    pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end

    %move up
    cmd = sprintf('MVPOSTAB %f,%f,100',tabXYP);
    fwrite(socket,cmd);
    disp(cmd);
    pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
  
    
   %% BP Dropoff
   cmd = sprintf('MVPOSTAB %f,%f,100',tabXYD);
   fwrite(socket,cmd);
   disp(cmd);
   pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
   
   cmd = sprintf('MVPOSTAB %f,%f,14',tabXYD);
   fwrite(socket,cmd);
   disp(cmd);
   pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
   blockreleased = 0;
   while(~blockreleased)
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
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
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
    % Move out of the way to home 
    fwrite(socket,'SETPOSES -90,0,0,0,0,0');
    disp('SETPOSES -90,0,0,0,0,0');
    pause(0.01);
    %check if in motion
    movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
    % CAMERA CHECK
    vid = videoinput('winvideo', 1, 'MJPG_1600x1200');
    
    img = getsnapshot(vid);
   
     % img2 = imread('conveyor_img_10_03_11_39_04.jpg');
    % img = imread('table_img_08_21_16_22_57.jpg');
  
    blockData = tableDetect(img);
    moveSuccessful =0;
    moveSuccessful = moveCheck(tabXYD,blockData);
  
    if moveSuccessful
        report = 1; % success because block is now at the chosen point
    else
        report = 0;
    end
end

function report = Rotate_test(socket,tabXY,jAng,angle)
     
    % BP Pick up
    cmd = sprintf('MVPOSTAB %f,%f,100',tabXY);
    fwrite(socket,cmd);
    disp(cmd);
    pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end

    % pick up block (turn on vac and move down)
    cmd = 'VACUUMON';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    cmd = 'SETSOLEN 1';
    fwrite(socket,cmd);
    disp(cmd);
    pause(0.1);
    
    cmd = sprintf('MVPOSTAB %f,%f,13',tabXY);
    disp(cmd);
    fwrite(socket,cmd);
    pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end

    % Rotate
    cmd = sprintf('SETPOSES %f,%f,%f,%f,%f,%f',jAng(1:5),angle);
   fwrite(socket,cmd);
   disp(cmd);
   pause(6);
  
   % confirm position and release
   
   cmd = sprintf('MVPOSTAB %f,%f,14',tabXY);
   fwrite(socket,cmd);
   disp(cmd);
   pause(3);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
   blockreleased = 0;
   while(~blockreleased)
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
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
   
   % CAMERA CHECK
     vid = videoinput('winvideo', 1, 'MJPG_1600x1200');
    
    img = getsnapshot(vid);
   
     % img2 = imread('conveyor_img_10_03_11_39_04.jpg');
    % img = imread('table_img_08_21_16_22_57.jpg');
    block = [tabXY(1);tabXY(2);1;angle];
    blockData = tableDetect(img);
    rotateSuccessful = rotateCheck(block,blockData);
    
    if rotateSuccessful
        report = 1;
    else 
        report = 0;
    end
    
end

function moveSuccessful = moveCheck(blockData,tableData)
% 
% % example data: x, y, orientation, type
% blockData = [28; 95; 0; 1];
% tableData = [[0; 60; 90; 0],[30; 90; 0; 1],[25; -60; 30; 0],[45; -45; 60; 1]];

blockData = blockData';
tableData = tableData';

blockXY = blockData(1:2);
tableXY = tableData(:,1:2);

% check if blockXY is member of tableXY, Check will either be 1 or 0
% tolerance for table: 5mm
tableCheck = ismembertol(blockXY,tableXY,5,'DataScale',1,'ByRows',true);

if tableCheck 
    moveSuccessful = 1;
else
    moveSuccessful = 0;
end

end
function rotateSuccessful = rotateCheck(blockData,tableData)

% % example data: x, y, type, orientation
% blockData = [34; 88; 1; 38];
% tableData = [[0; 60; 0; 90],[30; 90; 1; 45],[25; -60; 0; -30],[45; -45; 1; 60]];

blockData = blockData';
tableData = tableData';

blockXY = blockData(1:2);
tableXY = tableData(:,1:2);

blockOri = blockData(4);
tableOri = tableData(:,4);

% find block from table list
[tableCheck,tableIndex] = ismembertol(blockXY,tableXY,5,'DataScale',1,'ByRows',true);

% check block Ori is close to what its supposed to be, Check will either be 1 or 0
% tolerance for orientation: 10 deg
if tableCheck
    oriCheck = ismembertol(blockOri,tableOri(tableIndex),10,'DataScale',1,'ByRows',true);
else
    % blockXY was not matched
    rotateSuccessful = 0;
    return;
end

if oriCheck 
    rotateSuccessful = 1;
else
    rotateSuccessful = 0;
end

end

function [str] =  ReceiveState(socket)
%ReceiveState : Retrieves current robot state from robot studio
%ReceiveState(socket)
%Requires:
%   "socket" : tcpip(robot_IP_address, robot_port)
    data = fgetl(socket);
    str = char(data);
end
end