% Function to load a database to different program blocks to be either
% analyzed, visualized, etc. The endProduct contais the database, its name,
% the dataset names it contains. The function also has the option to merge
% two or more databases.

function endProduct = editDatabase(action, amount)

if strcmp(action, 'load')
    endProduct = loadDatabase(amount);
elseif strcmp(action, 'merge')
    caDatabase = mergeDatabases();
    
    if isempty(caDatabase)
        endProduct = {};
        return
    end
    
    prompt = {'Merged database name (without file extensions):'};
    dlgTitle = 'Input';
    num_lines = 1;
    def = {''};
    mergedName = inputdlg(prompt, dlgTitle, num_lines, def);
    
    endProduct = {caDatabase, mergedName};
end



end

function database = loadDatabase(amount)

dataset = {};

% Selection window for the database file
[dbName, path] = uigetfile('*.mat', 'Select the database (mat-file) you want to analyze');
% If user selects "cancel" in the selection window -> return to main menu
if dbName == 0
    database = {};
    return
end


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
    database = {};
    return
end

% Pick the dataset(s) corresponding to the selected indices
dsName_selected = datasetNames(dsIdx);
dataset = cell(length(dsName_selected), 1);

for i = 1:length(dsName_selected)
    % For each selected database, check its size and extract it to the
    % dataset variable
    [height, width] = size(caDatabase.(dsName_selected{i}));
    dataset{i, 1}(1:height,1:width) = caDatabase.(dsName_selected{i});
    underscores = dsName_selected{i} == '_';
    dsName_selected{i}(underscores) = ' ';
end



% The database to be returned
if(strcmp(amount, 'multi'))
    database = {dataset, dsName_selected, caDatabase, dbName};
else
    database = {dataset{1,1}, dsName_selected{1,1}, caDatabase, dbName};
end


end

function merged_db = mergeDatabases()

merged_db = struct();

% Selection window for the database files
[dbNames, path] = uigetfile('*.mat', 'Select the database (mat-file) you want to analyze', ...
                            'MultiSelect', 'on');
                        
% If user selects "cancel" in the selection window -> return to main menu
if ~iscell(dbNames) && dbNames == 0
    merged_db = {};
    return
end

% Get the current folder path
currentFolder = pwd;

% Change to the database folder, if it doesn't equal the current folder
% path
if strcmp(path, currentFolder) == 0
    cd(path)
end


for dbIdx = 1:length(dbNames)
    % Load the database as caDatabase variable
    load(dbNames{1, dbIdx}, 'caDatabase');
    % Read the dataset names from the database
    dsNames = fieldnames(caDatabase);

    for nameIdx = 1:length(dsNames)
       % Copy the datasets to the new merged database 
       merged_db.(dsNames{nameIdx,1}) = caDatabase.(dsNames{nameIdx,1});
        
    end
    
    clear('caDatabase')
    
end
    
end
