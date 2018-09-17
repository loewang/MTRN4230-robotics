% Robotics Assignment 1 
% Jogging Buttons 

% Before main WHILE loop --------------------------------------------------

PrevJogSpeedKnob = 'Fine';
PrevBaseButton = 1;

% X plus, X minus, Y plus, Y minus, Z plus, Z minus
PrevJogButton = zeros(1,6);

PrevJointButton = zeros(1,6);

PrevJointMoveButton = zeros(1,2);
% Main WHILE loop ---------------------------------------------------------

% Jog Speed
JogSpeedKnob = app.JogSpeedKnob.Value;
pause(0.2);

if(~strcmp(JogSpeedKnob,PrevJogSpeedKnob))
    switch JogSpeedKnob
        case 'Fine'  
            fwrite(socket, 'SETSPEED v10');
        	disp('Fine');
            pause(0.1);
        case 'Slow'
            fwrite(socket, 'SETSPEED v50');
        	disp('Slow');
            pause(0.1);
        case 'Medium'
            fwrite(socket, 'SETSPEED v100');
        	disp('Medium');
            pause(0.1);
        case 'Fast'
            fwrite(socket, 'SETSPEED v200');
        	disp('Fast');
            pause(0.1);
    end
    PrevJogSpeedKnob = JogSpeedKnob;
end

% Jog Frame Button
BaseButton = app.BaseButton.Value;
pause(0.2);
EndEffectorButton = app.EndEffectorButton.Value;
pause(0.2);

if(BaseButton ~= PrevBaseButton)
    if (EndEffectorButton == 1)
        % MAKE SURE TO EDIT 
        fwrite(socket, 'JOGFRAME IS END EFFECTOR');
        disp('JOGFRAME IS END EFFECTOR');
        pause(0.1);
    else
        % MAKE SURE TO EDIT 
        fwrite(socket, 'JOGFRAME IS BASE');
        disp('JOGFRAME IS BASE');
        pause(0.1);
    end
    
    PrevBaseButton = BaseButton;
end

% Linear Mode XYZ

JogButton = zeros(1,6);

JogButton(1) = app.XButton.Value;
pause(0.2);
JogButton(2) = app.XButton_2.Value;
pause(0.2);
JogButton(3) = app.YButton_3.Value;
pause(0.2);
JogButton(4) = app.YButton.Value;
pause(0.2);
JogButton(5) = app.ZButton.Value;
pause(0.2);
JogButton(6) = app.ZButton_2.Value;
pause(0.2);

if(~isequal(JogButton,PrevJogButton))
    JogButtonIndex = find(JogButton);
    switch JogButtonIndex
        case 1  
            fwrite(socket, 'SETSPEED v10');
        	disp('X+');
            pause(0.1);
        case 2
            fwrite(socket, 'SETSPEED v50');
        	disp('X-');
            pause(0.1);
        case 3
            fwrite(socket, 'SETSPEED v100');
        	disp('Y+');
            pause(0.1);
        case 4
            fwrite(socket, 'SETSPEED v200');
        	disp('Y-');
            pause(0.1);
        case 5
            fwrite(socket, 'SETSPEED v200');
        	disp('Z+');
            pause(0.1);
        case 6
            fwrite(socket, 'SETSPEED v200');
        	disp('Z-');
            pause(0.1);
    end            
    JogButton = PrevJogButton;
end

% Joint Mode Buttons

JointButton(1) = app.q1Button.Value;
pause(0.2);
JointButton(2) = app.q2Button.Value;
pause(0.2);
JointButton(3) = app.q3Button.Value;
pause(0.2);
JointButton(4) = app.q4Button.Value;
pause(0.2);
JointButton(5) = app.q5Button.Value;
pause(0.2);
JointButton(6) = app.q6Button.Value;
pause(0.2);

if(~isequal(JointButton,PrevJointButton))
    JogButtonIndex = find(JogButton);
    switch JogButtonIndex
        case 1  
            fwrite(socket, 'SETSPEED v10');
        	disp('Q1');
            pause(0.1);
        case 2
            fwrite(socket, 'SETSPEED v50');
        	disp('Q2');
            pause(0.1);
        case 3
            fwrite(socket, 'SETSPEED v100');
        	disp('Q3');
            pause(0.1);
        case 4
            fwrite(socket, 'SETSPEED v200');
        	disp('Q4');
            pause(0.1);
        case 5
            fwrite(socket, 'SETSPEED v200');
        	disp('Q5');
            pause(0.1);
        case 6
            fwrite(socket, 'SETSPEED v200');
        	disp('Q6');
            pause(0.1);
    end            
    PrevJointButton = JointButton;
end

% Joint Movement (Plus, Minus)

JointMoveButton(1) = app.Button.Value;
pause(0.2);
JointMoveButton(2) = app.Button_2.Value;
pause(0.2);

if(~isequal(JointMoveButton,PrevJointMoveButton))
    JogMoveButtonIndex = find(JointMoveButton);
    switch JogMoveButtonIndex
        case 1  
            fwrite(socket, 'SETSPEED v10');
        	disp('+');
            pause(0.1);
        case 2
            fwrite(socket, 'SETSPEED v50');
        	disp('-');
            pause(0.1);
    end            
    JointMoveButton = PrevJointMoveButton;
end


