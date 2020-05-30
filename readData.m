% readData lets the user choose the spreadsheet files to import and add them 
% into a database

xlsxFiles = {};
% The file selection window
[files, path] = uigetfile('*.xlsx', 'Select the spreadsheet you want to read in.', 'MultiSelect', 'on');

% Current folder path
currentFolder = pwd;

% If no files are selected, return to main menu
if(isempty(files))
    return
end

% Add the chosen files to a cell array
if(ischar(files))
    xlsxFiles{1} = files;
else
    xlsxFiles = files;
end

% Navigate to the folder with the spreadsheet files
if strcmp(path, currentFolder) == 0
    cd(path)
end

dataset = cell(length(xlsxFiles),2);

for fileIdx = 1:length(xlsxFiles)
    
    [~,sheets] = xlsfinfo(xlsxFiles{fileIdx});
    
    allSheets = {};
    
    %% Loop through every excel file sheet and read data to intensity_response form
    
    for sheetIdx = 1:length(sheets)
        % Read the sheets in as a table
        allSheets{sheetIdx} = readtable(xlsxFiles{fileIdx}, 'Sheet', sheetIdx, 'ReadVariableNames', 0); %#ok<*SAGROW>
        % Get the width of the sheets
        [~, sheetLengths(sheetIdx)] = size(allSheets{1,sheetIdx});
        sheetLengths(sheetIdx) = sheetLengths(sheetIdx) - 1;
        % Convert the table to an array
        allSheets{sheetIdx} = table2array(allSheets{sheetIdx}); 
    end
    
    % Make a struct containing all the sheet arrays
    allSheets = cell2struct(allSheets, sheets, 2);
    % Use sheet names as the struct field names
    sheetNames = fieldnames(allSheets);
    % get the maximum sheet length to calculate the number of cells
    maxSheetLength = max(sheetLengths); 
    cellData = cell(maxSheetLength/4,length(sheetNames));
    
    % Ask user input for sampling rate and dataset info
    prompt = {'Enter name for the dataset :', 'Sample interval (in seconds) of the measurement:', 'Dataset info (optional)'};
    dlgTitle = ['File ', num2str(fileIdx), ' of ', num2str(length(xlsxFiles))];
    numLines = 1;
    def = {['ds_', xlsxFiles{fileIdx}(1:end-5)], '0.5', ''};
    answer = inputdlg(prompt, dlgTitle, numLines, def);     
    dataset{fileIdx,1} = answer{1};
    rate = str2num(answer{2});
    
    % Loop through the sheets and convert the data to intensityResponse class
    % objects to the cellData array
    for sheetIdx = 1:length(sheets)
        
        cellDataIdx = 1;
        
        for cellIdx = 2:4:sheetLengths(sheetIdx)-1
            % Create the intensityResponse object
            a = intensityResponse;
            % Extract the data for each cell from the array
            a.timeVector = allSheets.(sheetNames{sheetIdx})(:,1)*rate;
            radius = round(sqrt(allSheets.(sheetNames{sheetIdx})(1,cellIdx)/pi));
            a.rawData = allSheets.(sheetNames{sheetIdx})(:,cellIdx+1);
            a.samplingInterval = rate;
            a.datasetInfo = answer{3};
            a.coordinates = [allSheets.(sheetNames{sheetIdx})(1,cellIdx+2), allSheets.(sheetNames{sheetIdx})(1,cellIdx+3), radius];
            a.indices = [sheetIdx, cellDataIdx];
            a.fitIndices = [1 201];
            a.isDiscarded = 0; 
            a.isSkipped = 0;
            cellData{cellDataIdx,sheetIdx} = a;
            cellDataIdx = cellDataIdx + 1;
        end
        
    end
    
    % Collect the datasets to a cell array to be saved in a database
    dataset{fileIdx,2} = cellData;

end

% Ask user input for which database the dataset should be added to

addToDataBase(dataset);

clear


%% addToDatabase
% Adds the read data to a selected database or creates a new database

function [] = addToDataBase(data)

while(true)
    
    answer = menu('What do you want to do?',...
                            'Add the data to an existing database',...
                            'Create a new database',...
                            'Return to main menu');
   
    if (answer == 1)
        
        % Add to an existing database
        
        [dbName, path] = uigetfile('*.mat', 'Select the database file.');
        
        if(isempty(dbName))
            return
        end
        
        currentFolder = pwd;
        if strcmp(path, currentFolder) == 0
            cd(path)
        end
        
        load(dbName, 'caDatabase')
        
        for dbIdx = 1:(length(data(:,1)))
            caDatabase.(data{dbIdx,1}) = data{dbIdx,2};
        end
        
        save(dbName, 'caDatabase')
        break
        
    elseif (answer == 2)
     
        % Create new database
        dbName = inputdlg('Name of the database:', ...
                            'Create new database', 1, {''});
        
        for dbIdx = 1:length(data(:,1))
            caDatabase.(data{dbIdx,1}) = data{dbIdx,2};
        end
        
        save(dbName{1}, 'caDatabase')
        break
        
    elseif (answer == 3)
        
        % Return to main menu
        return
        
    end
    
end

end