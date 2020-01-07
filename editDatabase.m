% Function to load a database to different program blocks to be either
% analyzed, visualized, etc. The endProduct contais the database, its name,
% the dataset names it contains.

function endProduct = editDatabase(action, amount)


dataset = {};

% Selection window for the database file
[dbName, path] = uigetfile('*.mat', 'Select the database (mat-file) you want to analyze');

% Get the current folder path
currentFolder = pwd;

% Change to the database folder, if it doesn't equal the current folder
% path
if strcmp(path, currentFolder) == 0
    cd(path)
end

% Load the database as caDatabase variable
load(dbName, 'caDatabase');
% Read the dataset names from the database
datasetNames = fieldnames(caDatabase);

if(strcmp(action, 'load'))
    
    % Provide a list dialog of the datasets contained in the database
    if(strcmp(amount, 'multi'))
        % Multiple databases
        [dsIdx, tf] = listdlg('PromptString', {'Select a dataset to be analysed.'}, ...
            'SelectionMode', 'multiple', 'ListString', datasetNames);
    else
        % Single database
        [dsIdx, tf] = listdlg('PromptString', {'Select a dataset to be analysed.'}, ...
            'SelectionMode', 'single', 'ListString', datasetNames);
    end
    
    % Return empty cell if nothing is selected
    if(tf == 0)
        endProduct = {};
        return
    end
    
    % Pick the dataset(s) corresponding to the selected indices
    dsName_selected = datasetNames(dsIdx);
    
    for i = 1:length(dsName_selected)
        % For each selected database, check its size and extract it to the
        % dataset variable
        [height, width] = size(caDatabase.(dsName_selected{i}));
        dataset(1:height,1:width) = caDatabase.(dsName_selected{i});
    end
    
end

% The final product to be returned
endProduct = {dataset, dsName_selected, caDatabase, dbName};


end
