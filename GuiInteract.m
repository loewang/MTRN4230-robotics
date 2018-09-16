%Code to interact with the GUI
%_2 for Conevyor Figure
clear all; close all; clc;
app = IRB120GUI_temp();
counter1 = 0;
counter2 = 0;

while (1)
    %disp('Receiving 1');
    val1 = app.EnableCameraButton_2.Value; %Table Camera Value
    val2 = app.EnableCameraButton.Value; %Conveyor Camera Value
    
    pause(0.001);
    if val1 == 1
        if counter1 == 0
            fig3 = figure(3);
            %fig3 = app.UIFigure
            axes3 = axes();
            %axes3 = app.UIAxes
            axes3.Parent = fig3;

            vid3 = videoinput('winvideo',1);
            video_resolution3 = vid3.VideoResolution;
            nbands3 = vid3.NumberOfBands;
            img = imshow(zeros([video_resolution3(2), video_resolution3(1), nbands3]), 'Parent', axes3);
            prev1 = preview(vid3,img);
            counter1 = 1;
        end
        snap1 = getsnapshot(vid3);
        cla reset;
        imshow(snap1,'Parent', app.UIAxes);
        %%Process Image Here ie snap1
        
    elseif val1 == 0
        disp('Camera Table is offline');
        if val1 == 0 && counter1 == 1
            stoppreview(vid3);
            counter1 = 0;
        end
    end
    
     if val2 == 1
        if counter2 == 0
            fig4 = figure(4);
            %fig3 = app.UIFigure
            axes4 = axes();
            %axes3 = app.UIAxes
            axes4.Parent = fig4;

            vid4 = videoinput('winvideo',3);
            video_resolution4 = vid4.VideoResolution;
            nbands4 = vid4.NumberOfBands;
            img1 = imshow(zeros([video_resolution4(2), video_resolution4(1), nbands4]), 'Parent', axes4);
            prev2 = preview(vid4,img1);
            counter2 = 1;
        end
        snap2 = getsnapshot(vid4);
        cla reset;
        imshow(snap2,'Parent', app.UIAxes_2);
        %%Process Image Here ie snap2
        
    elseif val2 == 0
        disp('Camera Conveyor is offline');
        if val2 == 0 && counter2 == 1
            stoppreview(vid4);
            counter2 = 0;
        end
    end
    
   
end

