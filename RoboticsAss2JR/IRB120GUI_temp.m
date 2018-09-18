classdef IRB120GUI_temp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        TabGroup                   matlab.ui.container.TabGroup
        IRB120ControlTab           matlab.ui.container.Tab
        JoggingPanel               matlab.ui.container.Panel
        JogSpeedKnobLabel          matlab.ui.control.Label
        JogSpeedKnob               matlab.ui.control.DiscreteKnob
        PAUSEButton                matlab.ui.control.StateButton
        CancelButton               matlab.ui.control.Button
        EditField                  matlab.ui.control.NumericEditField
        EditField_2                matlab.ui.control.NumericEditField
        EditField_3                matlab.ui.control.NumericEditField
        EditField_4                matlab.ui.control.NumericEditField
        EditField_5                matlab.ui.control.NumericEditField
        EditField_6                matlab.ui.control.NumericEditField
        q1SliderLabel              matlab.ui.control.Label
        q1Slider                   matlab.ui.control.Slider
        ResetButton                matlab.ui.control.Button
        q2SliderLabel              matlab.ui.control.Label
        q2Slider                   matlab.ui.control.Slider
        q3SliderLabel              matlab.ui.control.Label
        q3Slider                   matlab.ui.control.Slider
        q3Slider_2Label            matlab.ui.control.Label
        q3Slider_2                 matlab.ui.control.Slider
        q4SliderLabel              matlab.ui.control.Label
        q4Slider                   matlab.ui.control.Slider
        q5SliderLabel              matlab.ui.control.Label
        q5Slider                   matlab.ui.control.Slider
        JogModeButtonGroup         matlab.ui.container.ButtonGroup
        JointButton                matlab.ui.control.RadioButton
        CartesianButton            matlab.ui.control.RadioButton
        MATLABCommandsPanel        matlab.ui.container.Panel
        TextArea                   matlab.ui.control.TextArea
        RAPIDCommandsPanel         matlab.ui.container.Panel
        TextArea_2                 matlab.ui.control.TextArea
        DIOsPanel                  matlab.ui.container.Panel
        EStopLampLabel             matlab.ui.control.Label
        EStopLamp                  matlab.ui.control.Lamp
        LightCurtainLampLabel      matlab.ui.control.Label
        LightCurtainLamp           matlab.ui.control.Lamp
        MotorsONLampLabel          matlab.ui.control.Label
        MotorsONLamp               matlab.ui.control.Lamp
        MotorsEnableLampLabel      matlab.ui.control.Label
        MotorsEnableLamp           matlab.ui.control.Lamp
        ExecutionErrorLampLabel    matlab.ui.control.Label
        ExecutionErrorLamp         matlab.ui.control.Lamp
        ConveyorEnableLabel        matlab.ui.control.Label
        ConveyorEnableLamp         matlab.ui.control.Lamp
        ResetIOsButton             matlab.ui.control.Button
        ConveyorLabel              matlab.ui.control.Label
        EnableSwitchLabel          matlab.ui.control.Label
        EnableSwitch               matlab.ui.control.ToggleSwitch
        RunSwitchLabel             matlab.ui.control.Label
        RunSwitch                  matlab.ui.control.ToggleSwitch
        DirectionSwitchLabel       matlab.ui.control.Label
        DirectionSwitch            matlab.ui.control.ToggleSwitch
        VaccumLabel                matlab.ui.control.Label
        PumpSwitchLabel            matlab.ui.control.Label
        PumpSwitch                 matlab.ui.control.ToggleSwitch
        SolenoidSwitchLabel        matlab.ui.control.Label
        SolenoidSwitch             matlab.ui.control.ToggleSwitch
        ConveyorStatusLampLabel    matlab.ui.control.Label
        ConveyorStatusLamp         matlab.ui.control.Lamp
        RobotManagementPanel       matlab.ui.container.Panel
        StartUpRobotButton         matlab.ui.control.Button
        ShutdownRobotButton        matlab.ui.control.Button
        ConnectionStatusLampLabel  matlab.ui.control.Label
        ConnectionStatusLamp       matlab.ui.control.Lamp
        ReconnectButton            matlab.ui.control.Button
        ControlModeButtonGroup     matlab.ui.container.ButtonGroup
        SimulationButton           matlab.ui.control.RadioButton
        RobotButton                matlab.ui.control.RadioButton
        TableCameraFeed            matlab.ui.container.Tab
        UIAxes                     matlab.ui.control.UIAxes
        EnableCameraButton_2       matlab.ui.control.StateButton
        TextArea_5                 matlab.ui.control.TextArea
        LettersDetectedLabel_3     matlab.ui.control.Label
        CancelMovementButton_2     matlab.ui.control.Button
        EnableCameraMovementControlCheckBox_2  matlab.ui.control.CheckBox
        ConveyorCameraFeedTab_2    matlab.ui.container.Tab
        UIAxes_2                   matlab.ui.control.UIAxes
        EnableCameraButton         matlab.ui.control.StateButton
        TextArea_4                 matlab.ui.control.TextArea
        LettersDetectedLabel_2     matlab.ui.control.Label
        CancelMovementButton       matlab.ui.control.Button
        EnableCameraMovementControlCheckBox  matlab.ui.control.CheckBox
    end


    methods (Access = private)

        % Value changed function: EnableCameraButton_2
        function EnableCameraButton_2ValueChanged(app, event)
            value = app.EnableCameraButton_2.Value;
            %disp(value);
            disp('hellow word');
            fig3 = figure(3);
            axe3 = axes();
            axe3.Parent = fig3;

            vid3 = videoinput('winvideo',1);
            video_resolution3 = vid3.VideoResolution;
            nbands3 = vid3.NumberOfBands;
            img = imshow(zeros([video_resolution3(2), video_resolution3(1), nbands3]), 'Parent', axe3);
            prev1 = preview(vid3,img);
        end
        
        function LiveCode(value)
            disp(value);
            disp('hellow word');
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 1032 752];
            app.UIFigure.Name = 'UI Figure';
            setAutoResize(app, app.UIFigure, true)

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 1032 752];

            % Create IRB120ControlTab
            app.IRB120ControlTab = uitab(app.TabGroup);
            app.IRB120ControlTab.Title = 'IRB120 Control';
            app.IRB120ControlTab.Units = 'pixels';

            % Create JoggingPanel
            app.JoggingPanel = uipanel(app.IRB120ControlTab);
            app.JoggingPanel.Title = 'Jogging';
            app.JoggingPanel.FontWeight = 'bold';
            app.JoggingPanel.FontSize = 16;
            app.JoggingPanel.Position = [23 14 532 453];

            % Create JogSpeedKnobLabel
            app.JogSpeedKnobLabel = uilabel(app.JoggingPanel);
            app.JogSpeedKnobLabel.HorizontalAlignment = 'center';
            app.JogSpeedKnobLabel.Position = [413 18 64 15];
            app.JogSpeedKnobLabel.Text = 'Jog Speed';

            % Create JogSpeedKnob
            app.JogSpeedKnob = uiknob(app.JoggingPanel, 'discrete');
            app.JogSpeedKnob.Items = {'Fine', 'Slow', 'Medium', 'Fast'};
            app.JogSpeedKnob.Position = [415 48 60 60];
            app.JogSpeedKnob.Value = 'Fine';

            % Create PAUSEButton
            app.PAUSEButton = uibutton(app.JoggingPanel, 'state');
            app.PAUSEButton.Text = 'PAUSE';
            app.PAUSEButton.Position = [395 200 100 210];

            % Create CancelButton
            app.CancelButton = uibutton(app.JoggingPanel, 'push');
            app.CancelButton.Position = [395 160 100 22];
            app.CancelButton.Text = 'Cancel';

            % Create EditField
            app.EditField = uieditfield(app.JoggingPanel, 'numeric');
            app.EditField.Position = [248 325 100 22];

            % Create EditField_2
            app.EditField_2 = uieditfield(app.JoggingPanel, 'numeric');
            app.EditField_2.Position = [248 269 100 22];

            % Create EditField_3
            app.EditField_3 = uieditfield(app.JoggingPanel, 'numeric');
            app.EditField_3.Position = [248 213 100 22];

            % Create EditField_4
            app.EditField_4 = uieditfield(app.JoggingPanel, 'numeric');
            app.EditField_4.Position = [248 158 100 22];

            % Create EditField_5
            app.EditField_5 = uieditfield(app.JoggingPanel, 'numeric');
            app.EditField_5.Position = [248 103 100 22];

            % Create EditField_6
            app.EditField_6 = uieditfield(app.JoggingPanel, 'numeric');
            app.EditField_6.Position = [248 48 100 22];

            % Create q1SliderLabel
            app.q1SliderLabel = uilabel(app.JoggingPanel);
            app.q1SliderLabel.HorizontalAlignment = 'right';
            app.q1SliderLabel.Position = [18 330 25 15];
            app.q1SliderLabel.Text = 'q1';

            % Create q1Slider
            app.q1Slider = uislider(app.JoggingPanel);
            app.q1Slider.Position = [64 336 150 3];

            % Create ResetButton
            app.ResetButton = uibutton(app.JoggingPanel, 'push');
            app.ResetButton.Position = [248 385 100 22];
            app.ResetButton.Text = 'Reset ';

            % Create q2SliderLabel
            app.q2SliderLabel = uilabel(app.JoggingPanel);
            app.q2SliderLabel.HorizontalAlignment = 'right';
            app.q2SliderLabel.Position = [18 275 25 15];
            app.q2SliderLabel.Text = 'q2';

            % Create q2Slider
            app.q2Slider = uislider(app.JoggingPanel);
            app.q2Slider.Position = [64 281 150 3];

            % Create q3SliderLabel
            app.q3SliderLabel = uilabel(app.JoggingPanel);
            app.q3SliderLabel.HorizontalAlignment = 'right';
            app.q3SliderLabel.Position = [18 220 25 15];
            app.q3SliderLabel.Text = 'q3';

            % Create q3Slider
            app.q3Slider = uislider(app.JoggingPanel);
            app.q3Slider.Position = [64 226 150 3];

            % Create q3Slider_2Label
            app.q3Slider_2Label = uilabel(app.JoggingPanel);
            app.q3Slider_2Label.HorizontalAlignment = 'right';
            app.q3Slider_2Label.Position = [18 165 25 15];
            app.q3Slider_2Label.Text = 'q3';

            % Create q3Slider_2
            app.q3Slider_2 = uislider(app.JoggingPanel);
            app.q3Slider_2.Position = [64 171 150 3];

            % Create q4SliderLabel
            app.q4SliderLabel = uilabel(app.JoggingPanel);
            app.q4SliderLabel.HorizontalAlignment = 'right';
            app.q4SliderLabel.Position = [18 110 25 15];
            app.q4SliderLabel.Text = 'q4';

            % Create q4Slider
            app.q4Slider = uislider(app.JoggingPanel);
            app.q4Slider.Position = [64 116 150 3];

            % Create q5SliderLabel
            app.q5SliderLabel = uilabel(app.JoggingPanel);
            app.q5SliderLabel.HorizontalAlignment = 'right';
            app.q5SliderLabel.Position = [18 56 25 15];
            app.q5SliderLabel.Text = 'q5';

            % Create q5Slider
            app.q5Slider = uislider(app.JoggingPanel);
            app.q5Slider.Position = [64 62 150 3];

            % Create JogModeButtonGroup
            app.JogModeButtonGroup = uibuttongroup(app.JoggingPanel);
            app.JogModeButtonGroup.Title = 'Jog Mode';
            app.JogModeButtonGroup.Position = [14 352 212 54];

            % Create JointButton
            app.JointButton = uiradiobutton(app.JogModeButtonGroup);
            app.JointButton.Text = 'Joint';
            app.JointButton.Position = [11 8 48 15];
            app.JointButton.Value = true;

            % Create CartesianButton
            app.CartesianButton = uiradiobutton(app.JogModeButtonGroup);
            app.CartesianButton.Text = 'Cartesian';
            app.CartesianButton.Position = [105 8 75 15];

            % Create MATLABCommandsPanel
            app.MATLABCommandsPanel = uipanel(app.IRB120ControlTab);
            app.MATLABCommandsPanel.Title = 'MATLAB Commands';
            app.MATLABCommandsPanel.FontWeight = 'bold';
            app.MATLABCommandsPanel.FontSize = 16;
            app.MATLABCommandsPanel.Position = [568 164 450 152];

            % Create TextArea
            app.TextArea = uitextarea(app.MATLABCommandsPanel);
            app.TextArea.Position = [13 12 427 101];

            % Create RAPIDCommandsPanel
            app.RAPIDCommandsPanel = uipanel(app.IRB120ControlTab);
            app.RAPIDCommandsPanel.Title = 'RAPID Commands';
            app.RAPIDCommandsPanel.FontWeight = 'bold';
            app.RAPIDCommandsPanel.FontSize = 16;
            app.RAPIDCommandsPanel.Position = [568 14 450 144];

            % Create TextArea_2
            app.TextArea_2 = uitextarea(app.RAPIDCommandsPanel);
            app.TextArea_2.Position = [11 14 427 97];

            % Create DIOsPanel
            app.DIOsPanel = uipanel(app.IRB120ControlTab);
            app.DIOsPanel.Title = 'DIOs';
            app.DIOsPanel.FontWeight = 'bold';
            app.DIOsPanel.FontSize = 16;
            app.DIOsPanel.Position = [568 320 450 398];

            % Create EStopLampLabel
            app.EStopLampLabel = uilabel(app.DIOsPanel);
            app.EStopLampLabel.HorizontalAlignment = 'right';
            app.EStopLampLabel.Position = [29 344 68 15];
            app.EStopLampLabel.Text = 'E-Stop';

            % Create EStopLamp
            app.EStopLamp = uilamp(app.DIOsPanel);
            app.EStopLamp.Position = [29 341 20 20];

            % Create LightCurtainLampLabel
            app.LightCurtainLampLabel = uilabel(app.DIOsPanel);
            app.LightCurtainLampLabel.HorizontalAlignment = 'right';
            app.LightCurtainLampLabel.Position = [16 298 119 15];
            app.LightCurtainLampLabel.Text = 'Light Curtain';

            % Create LightCurtainLamp
            app.LightCurtainLamp = uilamp(app.DIOsPanel);
            app.LightCurtainLamp.Position = [29 291 20 20];

            % Create MotorsONLampLabel
            app.MotorsONLampLabel = uilabel(app.DIOsPanel);
            app.MotorsONLampLabel.HorizontalAlignment = 'right';
            app.MotorsONLampLabel.Position = [29 243 93 15];
            app.MotorsONLampLabel.Text = 'Motors ON';

            % Create MotorsONLamp
            app.MotorsONLamp = uilamp(app.DIOsPanel);
            app.MotorsONLamp.Position = [29 242 20 20];

            % Create MotorsEnableLampLabel
            app.MotorsEnableLampLabel = uilabel(app.DIOsPanel);
            app.MotorsEnableLampLabel.HorizontalAlignment = 'right';
            app.MotorsEnableLampLabel.Position = [7 195 137 15];
            app.MotorsEnableLampLabel.Text = 'Motors Enable';

            % Create MotorsEnableLamp
            app.MotorsEnableLamp = uilamp(app.DIOsPanel);
            app.MotorsEnableLamp.Position = [29 193 20 20];

            % Create ExecutionErrorLampLabel
            app.ExecutionErrorLampLabel = uilabel(app.DIOsPanel);
            app.ExecutionErrorLampLabel.HorizontalAlignment = 'right';
            app.ExecutionErrorLampLabel.Position = [1 146 150 15];
            app.ExecutionErrorLampLabel.Text = 'Execution Error';

            % Create ExecutionErrorLamp
            app.ExecutionErrorLamp = uilamp(app.DIOsPanel);
            app.ExecutionErrorLamp.Position = [29 144 20 20];

            % Create ConveyorEnableLabel
            app.ConveyorEnableLabel = uilabel(app.DIOsPanel);
            app.ConveyorEnableLabel.HorizontalAlignment = 'right';
            app.ConveyorEnableLabel.Position = [29 98 136 15];
            app.ConveyorEnableLabel.Text = ' Conveyor Enable';

            % Create ConveyorEnableLamp
            app.ConveyorEnableLamp = uilamp(app.DIOsPanel);
            app.ConveyorEnableLamp.Position = [29 95 20 20];

            % Create ResetIOsButton
            app.ResetIOsButton = uibutton(app.DIOsPanel, 'push');
            app.ResetIOsButton.Position = [175 337 265 22];
            app.ResetIOsButton.Text = 'Reset IOs';

            % Create ConveyorLabel
            app.ConveyorLabel = uilabel(app.DIOsPanel);
            app.ConveyorLabel.FontWeight = 'bold';
            app.ConveyorLabel.Position = [175 315 61 15];
            app.ConveyorLabel.Text = 'Conveyor';

            % Create EnableSwitchLabel
            app.EnableSwitchLabel = uilabel(app.DIOsPanel);
            app.EnableSwitchLabel.HorizontalAlignment = 'center';
            app.EnableSwitchLabel.Position = [176 192 44 15];
            app.EnableSwitchLabel.Text = 'Enable';

            % Create EnableSwitch
            app.EnableSwitch = uiswitch(app.DIOsPanel, 'toggle');
            app.EnableSwitch.Position = [188 243 20 45];

            % Create RunSwitchLabel
            app.RunSwitchLabel = uilabel(app.DIOsPanel);
            app.RunSwitchLabel.HorizontalAlignment = 'center';
            app.RunSwitchLabel.Position = [394 192 28 15];
            app.RunSwitchLabel.Text = 'Run';

            % Create RunSwitch
            app.RunSwitch = uiswitch(app.DIOsPanel, 'toggle');
            app.RunSwitch.Position = [398 243 20 45];

            % Create DirectionSwitchLabel
            app.DirectionSwitchLabel = uilabel(app.DIOsPanel);
            app.DirectionSwitchLabel.HorizontalAlignment = 'center';
            app.DirectionSwitchLabel.Position = [280 192 54 15];
            app.DirectionSwitchLabel.Text = 'Direction';

            % Create DirectionSwitch
            app.DirectionSwitch = uiswitch(app.DIOsPanel, 'toggle');
            app.DirectionSwitch.Items = {'Backward', 'Forward'};
            app.DirectionSwitch.Position = [297 243 20 45];
            app.DirectionSwitch.Value = 'Backward';

            % Create VaccumLabel
            app.VaccumLabel = uilabel(app.DIOsPanel);
            app.VaccumLabel.FontWeight = 'bold';
            app.VaccumLabel.Position = [175 163 52 15];
            app.VaccumLabel.Text = 'Vaccum';

            % Create PumpSwitchLabel
            app.PumpSwitchLabel = uilabel(app.DIOsPanel);
            app.PumpSwitchLabel.HorizontalAlignment = 'center';
            app.PumpSwitchLabel.Position = [227 28 37 15];
            app.PumpSwitchLabel.Text = 'Pump';

            % Create PumpSwitch
            app.PumpSwitch = uiswitch(app.DIOsPanel, 'toggle');
            app.PumpSwitch.Position = [235 79 20 45];

            % Create SolenoidSwitchLabel
            app.SolenoidSwitchLabel = uilabel(app.DIOsPanel);
            app.SolenoidSwitchLabel.HorizontalAlignment = 'center';
            app.SolenoidSwitchLabel.Position = [328 28 54 15];
            app.SolenoidSwitchLabel.Text = 'Solenoid';

            % Create SolenoidSwitch
            app.SolenoidSwitch = uiswitch(app.DIOsPanel, 'toggle');
            app.SolenoidSwitch.Position = [345 79 20 45];

            % Create ConveyorStatusLampLabel
            app.ConveyorStatusLampLabel = uilabel(app.DIOsPanel);
            app.ConveyorStatusLampLabel.HorizontalAlignment = 'right';
            app.ConveyorStatusLampLabel.Position = [1 47 156 15];
            app.ConveyorStatusLampLabel.Text = 'Conveyor Status';

            % Create ConveyorStatusLamp
            app.ConveyorStatusLamp = uilamp(app.DIOsPanel);
            app.ConveyorStatusLamp.Position = [29 46 20 20];

            % Create RobotManagementPanel
            app.RobotManagementPanel = uipanel(app.IRB120ControlTab);
            app.RobotManagementPanel.Title = 'Robot Management';
            app.RobotManagementPanel.FontWeight = 'bold';
            app.RobotManagementPanel.FontSize = 16;
            app.RobotManagementPanel.Position = [23 483 532 235];

            % Create StartUpRobotButton
            app.StartUpRobotButton = uibutton(app.RobotManagementPanel, 'push');
            app.StartUpRobotButton.Position = [14 14 245 123];
            app.StartUpRobotButton.Text = 'Start Up Robot';

            % Create ShutdownRobotButton
            app.ShutdownRobotButton = uibutton(app.RobotManagementPanel, 'push');
            app.ShutdownRobotButton.Position = [269 14 245 123];
            app.ShutdownRobotButton.Text = 'Shutdown Robot';

            % Create ConnectionStatusLampLabel
            app.ConnectionStatusLampLabel = uilabel(app.RobotManagementPanel);
            app.ConnectionStatusLampLabel.HorizontalAlignment = 'right';
            app.ConnectionStatusLampLabel.Position = [254 166 152 15];
            app.ConnectionStatusLampLabel.Text = 'Connection Status';

            % Create ConnectionStatusLamp
            app.ConnectionStatusLamp = uilamp(app.RobotManagementPanel);
            app.ConnectionStatusLamp.Position = [283 163 20 20];

            % Create ReconnectButton
            app.ReconnectButton = uibutton(app.RobotManagementPanel, 'push');
            app.ReconnectButton.Position = [428 162 86 22];
            app.ReconnectButton.Text = 'Reconnect';

            % Create ControlModeButtonGroup
            app.ControlModeButtonGroup = uibuttongroup(app.RobotManagementPanel);
            app.ControlModeButtonGroup.Title = 'Control Mode';
            app.ControlModeButtonGroup.Position = [14 144 245 52];

            % Create SimulationButton
            app.SimulationButton = uiradiobutton(app.ControlModeButtonGroup);
            app.SimulationButton.Text = 'Simulation';
            app.SimulationButton.Position = [11 6 80 15];
            app.SimulationButton.Value = true;

            % Create RobotButton
            app.RobotButton = uiradiobutton(app.ControlModeButtonGroup);
            app.RobotButton.Text = 'Robot';
            app.RobotButton.Position = [101 6 55 15];

            % Create TableCameraFeed
            app.TableCameraFeed = uitab(app.TabGroup);
            app.TableCameraFeed.Title = 'Table Camera Feed';
            app.TableCameraFeed.Units = 'pixels';

            % Create UIAxes
            app.UIAxes = uiaxes(app.TableCameraFeed);
            title(app.UIAxes, 'Table Camera Feed');
            xlabel(app.UIAxes, 'X');
            ylabel(app.UIAxes, 'Y');
            app.UIAxes.Box = 'on';
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Position = [32 26 732 677];

            % Create EnableCameraButton_2
            app.EnableCameraButton_2 = uibutton(app.TableCameraFeed, 'state');
            app.EnableCameraButton_2.ValueChangedFcn = createCallbackFcn(app, @EnableCameraButton_2ValueChanged, true);
            app.EnableCameraButton_2.Text = 'Enable Camera';
            app.EnableCameraButton_2.Position = [798 582 205 121];

            % Create TextArea_5
            app.TextArea_5 = uitextarea(app.TableCameraFeed);
            app.TextArea_5.Position = [801 26 202 299];

            % Create LettersDetectedLabel_3
            app.LettersDetectedLabel_3 = uilabel(app.TableCameraFeed);
            app.LettersDetectedLabel_3.FontSize = 16;
            app.LettersDetectedLabel_3.FontWeight = 'bold';
            app.LettersDetectedLabel_3.Position = [801 344 131 20];
            app.LettersDetectedLabel_3.Text = 'Letters Detected';

            % Create CancelMovementButton_2
            app.CancelMovementButton_2 = uibutton(app.TableCameraFeed, 'push');
            app.CancelMovementButton_2.Position = [798 394 205 86];
            app.CancelMovementButton_2.Text = 'Cancel Movement';

            % Create EnableCameraMovementControlCheckBox_2
            app.EnableCameraMovementControlCheckBox_2 = uicheckbox(app.TableCameraFeed);
            app.EnableCameraMovementControlCheckBox_2.Text = 'Enable Camera Movement Control';
            app.EnableCameraMovementControlCheckBox_2.Position = [801 525 212 15];

            % Create ConveyorCameraFeedTab_2
            app.ConveyorCameraFeedTab_2 = uitab(app.TabGroup);
            app.ConveyorCameraFeedTab_2.Title = 'Conveyor Camera Feed';
            app.ConveyorCameraFeedTab_2.Units = 'pixels';

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.ConveyorCameraFeedTab_2);
            title(app.UIAxes_2, 'Conveyor Camera Feed');
            xlabel(app.UIAxes_2, 'X');
            ylabel(app.UIAxes_2, 'Y');
            app.UIAxes_2.Box = 'on';
            app.UIAxes_2.XGrid = 'on';
            app.UIAxes_2.YGrid = 'on';
            app.UIAxes_2.Position = [32 26 732 677];

            % Create EnableCameraButton
            app.EnableCameraButton = uibutton(app.ConveyorCameraFeedTab_2, 'state');
            app.EnableCameraButton.Text = 'Enable Camera';
            app.EnableCameraButton.Position = [798 582 205 121];

            % Create TextArea_4
            app.TextArea_4 = uitextarea(app.ConveyorCameraFeedTab_2);
            app.TextArea_4.Position = [801 26 202 299];

            % Create LettersDetectedLabel_2
            app.LettersDetectedLabel_2 = uilabel(app.ConveyorCameraFeedTab_2);
            app.LettersDetectedLabel_2.FontSize = 16;
            app.LettersDetectedLabel_2.FontWeight = 'bold';
            app.LettersDetectedLabel_2.Position = [801 344 131 20];
            app.LettersDetectedLabel_2.Text = 'Letters Detected';

            % Create CancelMovementButton
            app.CancelMovementButton = uibutton(app.ConveyorCameraFeedTab_2, 'push');
            app.CancelMovementButton.Position = [798 394 205 86];
            app.CancelMovementButton.Text = 'Cancel Movement';

            % Create EnableCameraMovementControlCheckBox
            app.EnableCameraMovementControlCheckBox = uicheckbox(app.ConveyorCameraFeedTab_2);
            app.EnableCameraMovementControlCheckBox.Text = 'Enable Camera Movement Control';
            app.EnableCameraMovementControlCheckBox.Position = [801 525 212 15];
        end
    end

    methods (Access = public)

        % Construct app
        function app = IRB120GUI_temp()

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
