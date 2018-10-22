%% run_analysis
% Function for looping through the cellData cell array to analyze each
% ca_response object with the ca_analysis function in ca_response.m. The
% function takes the ROI and cell numbers as inputs, so the analysis can be
% started anywhere in the array. Example: run_analysis(2,13) starts the 
% analysis from cell 13 of ROI 2 and starts looping the cells in ROI 2,
% moving to ROI 3 after that, etc. For the function to work, the user has
% to navigate to the folder containing the data to be analyzed. The folder 
% should not contain any other mat-files.
%
% Copyright 2018 Juhana Sorvari, Tampere University, Faculty of Medicine 
% and Health Technology, Biophysics of the Eye group.


function run_analysis(ROI,cell)

% Load the mat-file in the folder
mat = dir('*.mat');
load(mat.name)

[~, w] = size(cellData); %#ok<*NODEF>

% Loop ROIs beginning from the one specified in the ROI input.
for id1 = ROI:w
    
    % Leave out empty cells in the end of each ROI column.
    notEmpty = find(~cellfun(@isempty,cellData(:,id1)));
    
    % Loop through and analyze all the populated cells in the ROI with ca_analysis.
    for id2 = cell:notEmpty(end)
        
        cellData{id2,id1} = ca_analysis(cellData{id2,id1},id1,id2); %#ok<*AGROW,*SAGROW>
        save(mat.name, 'cellData', 'allSheets')
        
    end
    
    cell = 1; % Reset the cell number to 1 after each ROI ends.
    
end

end