%% readData
% Reads the time-intensity data from spreadsheets in the current folder
% and saves them in folders corresponding to the filename. Files should be 
% named as <cellLine>_<surface>_<timepoint>_<ATP stimulus number>.xlsx
% and the excel sheets should be named as the corresponding ROIs (e.g. ROI1, 
% ROI2, etc.) The intensity vectors are saved to the allSheets struct and 
% the objects for each cell in the cellData cell array in the mat-file.


%% List all files in the folder and loop to find all excel files.

files = dir('*.xlsx');
r = length(files(:,1));
xlsxFiles = cell(r,1);

for idx = 1:r
    xlsxFiles{idx,1} = files(idx).name;
end

%% Loop every excel file with readCaData-function to read the data.

idx2 = length(xlsxFiles);

for k = 1:idx2
    readCaData(xlsxFiles{k})
end

clear

%% readCaData
% readCaData reads intensity data from every sheet of an excel file containing
% time and intensity data. Takes the filename as input from the readData script.

function readCaData( filename )
%% Get file info from the filename

idx = strfind(filename, '_');
cellLine = filename(idx(1)-6:idx(1)-1);
ATPstimulus = filename(idx(3)+1:idx(3)+4);
surface = filename(idx(1)+1:idx(2)-1);
timepoint = filename(idx(2)+1:idx(3)-1);
[~,ROI] = xlsfinfo(filename); %xlsx file sheet names
c = length(ROI);
foldername = filename(1:end-5);

%% Read all the sheets of  the excel file to the variable allSheets

for idx2 = 1:c  
    allSheets{idx2} = readtable(filename, 'Sheet', idx2, 'ReadVariableNames', 0);
end

% Convert data from cell to struct
allSheets = cell2struct(allSheets, ROI, 2);

%% Pick only absolute intensity data from allSheets (relative data calculated later, not needed from excel)

for idx3 = 1:c
    
    w = width(allSheets.(ROI{idx3}));
    m = 2;
   
    
    for k = 2:w
        
        if allSheets.(ROI{idx3}){1,k} > 2
           allSheets.(ROI{idx3}){:,m} = allSheets.(ROI{idx3}){:,k};
           m = m+1;
        end
        
    end

    allSheets.(ROI{idx3}) = allSheets.(ROI{idx3})(:,1:m-1);

end

%% Create a cell of ca_response objects

sheets = fieldnames(allSheets);
cellData = cell(150,3); % default value for 3 ROIs with maximum of 
                        % 150 cells each (adjust if needed)

for idx4 = 1:length(sheets)
    
    time = allSheets.(sheets{idx4})(:,1); % Picks the time vector from the first column.
    
    for idx5 = 2:width(allSheets.(sheets{idx4}))
        
        % Create the object (see ca_response.m) and add properties 
        % for each cell object.
        a = ca_response; 
        a.timeVector = time{:,:};
        a.rawData = allSheets.(sheets{idx4}){:,idx5};
        a.ATPtype = ATPstimulus;
        a.surface = surface;
        a.timepoint = timepoint;
        a.cellLine = cellLine;
        a.isDiscarded = 0;
        a.isSkipped = 0;
        cellData{idx5-1,idx4} = a; %Places the object in the cellData array.
        
    end
    
end

%% Save the data to a file and create a folder for the mat-file and the original xlsx

mkdir(foldername);
movefile(filename, foldername)
cd(foldername)
save(foldername, 'allSheets', 'cellData')
cd ../

end
