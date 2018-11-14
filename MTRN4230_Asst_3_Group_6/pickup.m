function pickup 
%% robot ip
    %     robot_IP_address = '192.168.125.1';
    robot_IP_address = '127.0.0.1'; % Simulation ip address

    robot_port = 1025;

    socket = tcpip(robot_IP_address, robot_port);
    set(socket, 'ReadAsyncMode', 'continuous');
tabapp = TableFeedGUI();
conapp = ConveyorFeedGUI();
%% Load images
myFolder = 'D:\Matlab Files\ClearTable';
myFolder2 = 'D:\Matlab Files\ClearTablecon';

filePattern = fullfile(myFolder, '*.jpg');
filePattern2 = fullfile(myFolder2, '*.jpg');

jpegFiles = dir(filePattern);
jpegFiles2 = dir(filePattern2);
for k = 1:length(jpegFiles)
  baseFileName = jpegFiles(k).name;
  fullFileName = fullfile(myFolder, baseFileName);
  fprintf(1, 'Now reading %s\n', fullFileName);
  imageArray{k} = imread(fullFileName);
  
end

for k = 1:length(jpegFiles2)
  baseFileName2 = jpegFiles2(k).name;
  fullFileName2 = fullfile(myFolder2, baseFileName2);
  fprintf(1, 'Now reading %s\n', fullFileName2);
  imageArray2{k} = imread(fullFileName2);
  
end

imshow(imageArray{1},'Parent',tabapp.UIAxes);
imshow(imageArray2{1},'Parent',conapp.UIAxes);
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
   
    i =1;
    j =1;
    k = 0;
    NewCoords = [18,-144;36,-72;54,0;72,72;90,-126;108,-54;126,18;144,90;162,-108;180,-36;198,36;216,108;234,-90;252,-18;270,54;288,126;];
    while i < 17
        
         if i == 7
            k = 1;
            j = 1;
         end
         
         if i == 13 
             k =2;
             j = 1;
         end
     
    %move to BP position
 
    cmd = sprintf('MVPOSTAB %f,%f,100',NewCoords(i,:)); %%[125,200] 4
    fwrite(socket,cmd);
    disp(cmd);
    %pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
     
    cmd = sprintf('MVPOSTAB %f,%f,3',NewCoords(i,:)); %%[125,200] 4
    fwrite(socket,cmd);
    disp(cmd);
   % pause(8);
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
   % pause(2);
     fwrite(socket, 'SETSPEED v200');
    cmd = sprintf('MVPOSTAB %f,%f,100',NewCoords(i,:)); %[125,200] 100
    fwrite(socket,cmd);
    disp(cmd);
    %pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
     
cmd = sprintf('MVPOSTAB %f,%f,200',[-420+(j*25),420+(k*25)]); %-(i*13)
    fwrite(socket,cmd);
    disp(cmd);
   % pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
    end
    
    imshow(imageArray{i+1},'Parent',tabapp.UIAxes);
     % Move out of the way to home 
    %move to BP position
    cmd = sprintf('MVPOSTAB %f,%f,-120',[-420+(j*25),420+(k* 25)]); %+(i*13)
    fwrite(socket,cmd);
    disp(cmd);
   % pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
       
    end
     fwrite(socket, 'SETSPEED v200');
    
     cmd = 'SETSOLEN 0';
           fwrite(socket,cmd);
           disp(cmd);
           pause(0.1);
        
           cmd = 'VACUUMOF';
           fwrite(socket,cmd);
           disp(cmd);
           pause(0.1);
    
          % pause(2);
    cmd = sprintf('MVPOSTAB %f,%f,200',[-420+(i*25),420+(k*25)]); %+(i*13)
    fwrite(socket,cmd);
    disp(cmd);
    %pause(8);
   movecomplete = 0;
    while(~movecomplete)
       pause(0.2);
       fwrite(socket, 'INMOTION');
       str = ReceiveState(socket); 
       if(strcmp(str,'FALSE'))
           movecomplete = 1;
       end
       
    end
   imshow(imageArray2{i+1},'Parent',conapp.UIAxes);
    i = i + 1;
    j = j+1;
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