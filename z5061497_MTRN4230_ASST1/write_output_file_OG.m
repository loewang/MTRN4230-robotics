% This is an example of how to write the results to file.
% This will only work if you store your blocks exactly as above.
% Please ensure that you output your detected blocks correctly. A
% script will be made available so that you can run the comparison
% yourselves, to test that it is working.
function write_output_file(blocks, image_file_name, output_file_path)
    
    fid = fopen(output_file_path, 'w');
    
    fprintf(fid, 'image_file_name:\n');
    fprintf(fid, '%s\n', image_file_name);
    fprintf(fid, 'rectangles:\n');
    fprintf(fid, ...
        [repmat('%f ', 1, size(blocks, 2)), '\n'], blocks');
    
    % Please ensure that you close any files that you open. If you fail to do
    % so, there may be a noticeable decrease in the speed of your processing.
    fclose(fid);
end