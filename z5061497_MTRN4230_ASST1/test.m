% test main program
% image_file_path is the absolute path to the image that you should
% process. This should be used to read in the file.
% image_file_name is just the name of the image. This should be written to
% the output file.
% output_file_path is the absolute path to the file where you should output
% the name of the file as well as the blocks that you have detected.
% program_folder is the folder that your function is running in.
function test()
    
    clc; clear; close all; dbstop if error; warning off;
    tic; 
%     for i = 1:47
%         imNum = i;
        imNum =1;
        imNumstr = num2str(imNum,'%03.f');
        imagename = strcat('IMG_',imNumstr,'.JPG');

        image_file_path = strcat('../../training_set',imagename);
        image_file_name = imagename;
        output_file_path = strcat('../../training_labels\IMG_',imNumstr,'.txt');
        program_folder = 'C:\Users\Sharina Cheung\Documents\MTRN4230\Assignment 1';
        
        imageT = tic;
        z5061497_MTRN4230_ASST1(image_file_path,image_file_name,output_file_path, program_folder);
        fprintf('%s: %f\n',imagename,toc(imageT));
%     end
    fprintf('Total time for %d images = %f',47,toc);
end
