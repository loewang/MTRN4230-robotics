% %robot_IP_address = '192.168.125.1';
% robot_IP_address = '127.0.0.1'; % Simulation ip address
% 
% robot_port = 1025;
% 
% socket = tcpip(robot_IP_address, robot_port);
% set(socket, 'ReadAsyncMode', 'continuous');
% 
% if(~isequal(get(socket, 'Status'), 'open'))
%     fopen(socket);
% end
% 
% if(~isequal(get(socket, 'Status'), 'open'))
%     warning(['Could not open TCP connection to ', robot_IP_address, ' on port ', robot_port]);
%     return;
% end

% Motion
fwrite(socket, 'MVPOSTAB 0,520,0'); %T3 
str = ReceiveString(socket);

% function [str] =  ReceiveString(socket)
%     data = fgetl(socket);
%     str = strcat(char(data),'\n');
%     fprintf(str);
% end