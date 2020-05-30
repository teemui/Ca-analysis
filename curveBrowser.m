% curveBrowser lets the user browse analyzed datasets either one response
% at a time or by plotting response populations (single or multiple ROIs
% together). Also gives the option to compare different responses of the
% same cell (if ROIs of the dataset correspond to different measurements of
% the same frame).

% editDatabase.m is used to load a single dataset from a database created
% by readData.m and provide it's information
databaseInfo = editDatabase('load', 'single');
if(isempty(databaseInfo))
    return
end

dataset = databaseInfo{1};
datasetName = databaseInfo{2};
caDatabase = databaseInfo{3};
databaseName = databaseInfo{4};

% Ask user if they want to browse or plot curves
browseOrPlot = menu('What do you desire?', 'Browse single response', ...
    'Compare responses of the same cell', 'Plot response populations',...
    'Return to main menu');

if(browseOrPlot == 1)
    browseCurves(dataset)
elseif(browseOrPlot == 2)
    compareCurves(dataset, datasetName)
elseif(browseOrPlot == 3)
    plotCurves(dataset, datasetName)
elseif(browseOrPlot == 4)
    return;
end

%%
function [] = browseCurves(dataset)
% Ask user which ROI and cell they want to start from
clc

% Dialog to choose starting ROI, cell and accepted/discarded cells
dlgName = 'Enter start values for browsing';

prompt(1,:) = {['Starting ROI'], [], []};
prompt(2,:) = {['Starting cell'], [], []};
prompt(3,:) = {['Accepted of discared cells?'], [], []};

formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(1,1).type   = 'edit';
formats(1,1).format = 'integer';
formats(1,1).size = 25;

formats(2,1).type   = 'edit';
formats(2,1).format = 'integer';
formats(2,1).size = 25;

formats(3,1).type   = 'list';
formats(3,1).style  = 'popupmenu';
formats(3,1).items  = {'accepted', 'discarded'};
defaultanswer = {1, 1, 1};

[answer, canceled] = inputsdlg(prompt, dlgName, formats, defaultanswer);

if(canceled == 1)
    return
end

ROI = answer{1};
cellIdx = answer{2};
discarded = answer{3};

[~, numberOfROIs] = size(dataset);



for ROIidx = ROI:numberOfROIs
    
    % Leave out empty cells in the end of each ROI column.
    notEmpty = ~cellfun(@isempty,dataset(:, ROIidx));
    dsNotEmpty = dataset(notEmpty,ROIidx);
    
    for i = 1:length(dsNotEmpty)
        accepted(i,1) = getfield(dsNotEmpty{i,1}, 'isAnalyzed');
    end
    
    accIdxOnly = find(accepted == 1);
    disIdxOnly = find(accepted == 0);
    i = 1;
    
    % Loop through and plot all the populated cells one by one in the ROI.
    while true

        if discarded == 2
            
            % If discarded cells selected
            while true
                % Check if the user given cell is discarded. If not, then
                % find the next one that is.
                if ~isempty(dsNotEmpty) > 0 && cellIdx <= length(dsNotEmpty) && getfield(dsNotEmpty{cellIdx,1}, 'isDiscarded') == 1
                    obj = dsNotEmpty{cellIdx};
                    i = find(disIdxOnly == cellIdx);
                    break
                elseif ~isempty(dsNotEmpty) && cellIdx < length(dsNotEmpty) && getfield(dsNotEmpty{cellIdx,1}, 'isDiscarded') == 0
                    cellIdx = cellIdx + 1;  
                else
                    break
                end
            end
            
            if exist('obj')
                figure
                hold on
                plot(obj.timeVector, obj.rawData, 'b')
                plot(obj.timeVector, obj.rawData, 'g')
                legend('original data', 'corrected data')
                title(['ROI ', num2str(ROIidx), ', cell ', num2str(obj.indices(2))])
                hold off
                selection = menu('MENU', 'Next', 'Previous', 'Main menu');
                if selection == 1
                    if cellIdx < length(dsNotEmpty)
                        cellIdx = cellIdx + 1;
                        i = i + 1;
                        close
                        continue
                    end
                elseif selection == 2
                    if cellIdx > 1
                        cellIdx = disIdxOnly(i-1);
                        close
                        continue
                    end
                elseif(selection == 3)
                    close
                    return
                end
            end
                close
                break
            
            
            
        elseif discarded == 1
            
            % If accepted cells selected
            while true
                % Check if the user given cell is discarded. If not, then
                % find the next one that is.
                if ~isempty(dsNotEmpty) > 0 && cellIdx <= length(dsNotEmpty) && getfield(dsNotEmpty{cellIdx,1}, 'isAnalyzed') == 1
                    obj = dsNotEmpty{cellIdx};
                    i = find(accIdxOnly == cellIdx);
                    break
                elseif ~isempty(dsNotEmpty) && cellIdx < length(dsNotEmpty) && getfield(dsNotEmpty{cellIdx,1}, 'isAnalyzed') == 0
                    cellIdx = cellIdx + 1;  
                else
                    break
                end
            end
            
            if exist('obj')
                figure('units','normalized','outerposition',[0 0 1 1]);
                subplot(1,2,1)
                plotBleachCorrection(obj);
                subplot(1,2,2)
                plotAnalyzedData(obj);
                suptitle(['ROI ', num2str(ROIidx), ', cell ', num2str(obj.indices(2))])
                selection = menu('MENU', 'Next', 'Previous', 'Main menu');
                if selection == 1
                    if cellIdx < length(dsNotEmpty)
                        cellIdx = cellIdx + 1;
                        i = i + 1;
                        close
                        continue
                    end
                elseif selection == 2
                    if cellIdx > 1
                        cellIdx = accIdxOnly(i-1);
                        close
                        continue
                    end
                elseif(selection == 3)
                    close
                    return
                end
            end
            
            close
            break
            

        
            
        end
        
    end
    
    % Reset cell number and accepted/discarded cells after each ROI
    cellIdx = 1;
    acceptedCells = [];
    discardedCells = [];
    clear('obj');
    
end

end

function [] = plotCurves(dataset, datasetName)

clc

% Dialog to choose plot type and accepted/discarded responses
dlgName = 'Choose plot type';

prompt(1,:) = {['Plot type'], []};
%prompt(2,:) = {['Accepted or dircarded?'], []};

formats = struct('type', {}, 'style', {}, 'items', {}, ...
    'format', {}, 'limits', {}, 'size', {});
formats(1,1).type   = 'list';
formats(1,1).style  = 'popupmenu';
formats(1,1).items  = {'Plot all responses to a single figure', 'Separate by ROIs'};

% formats(2,1).type   = 'list';
% formats(2,1).style  = 'popupmenu';
% formats(2,1).items  = {'accepted', 'discarded'};
defaultanswer = {1};

[answer2, canceled] = inputsdlg(prompt, dlgName, formats, defaultanswer);

if(canceled)
    return
end

[~, numberOfROIs] = size(dataset);
Ncells = 0;
Ntot = 0;
Ndiscarded = 0;
NdiscardedROI = 0;
NcellsROI = 0;
NtotROI = 0;
maxInt = 0; % max intensity for y-ax limits
spIdx = 0; % subplot index


figure('units','normalized','outerposition',[0 0 1 1]);

for ROIidx = 1:numberOfROIs
    
    % Leave out empty cells in the end of each ROI column.
    notEmpty = find(~cellfun(@isempty,dataset(:, ROIidx)));
    
    % Loop through and plot all the populated cells in the ROI.
    for cellIdx = 1:notEmpty(end)
        
        
        if answer2{1,1} == 1
            
            % Plot all accpted into same figure
            if dataset{cellIdx, ROIidx}.isAnalyzed == 1
                subplots(1) = subplot(1,2,1);
                hold on
                plot(dataset{cellIdx, ROIidx}.timeVector, ...
                    dataset{cellIdx, ROIidx}.relativeData, 'Color', [0.5 0.5 0.5])
                Ncells = Ncells + 1;
                NcellsROI = NcellsROI + 1;
                hold off
                title(['Accepted (N = ', num2str(Ncells), ')'])
                xlabel('Time [s]')
                ylabel('Relative intensity')
            end
            
            % Plot all discarded into same figure
            if dataset{cellIdx, ROIidx}.isDiscarded == 1
                subplots(2) = subplot(1,2,2);
                hold on
                
                plot(dataset{cellIdx, ROIidx}.timeVector, ...
                    dataset{cellIdx, ROIidx}.relativeData, 'Color', [0.5 0.5 0.5])
                Ndiscarded = Ndiscarded + 1;
                NdiscardedROI = NdiscardedROI + 1;
                
                hold off
                title(['Discarded (N = ', num2str(Ndiscarded), ')'])
                xlabel('Time [s]')
                ylabel('Relative intensity')
            end
        end
        
        % Plot responses separated by ROIs
        if(answer2{1} == 2)
            if dataset{cellIdx, ROIidx}.isAnalyzed == 1
                subplots(ROIidx) = subplot(2,numberOfROIs,ROIidx);
                hold on
                plot(dataset{cellIdx, ROIidx}.timeVector, ...
                    dataset{cellIdx, ROIidx}.relativeData, 'Color', [0.5 0.5 0.5])
                Ncells = Ncells + 1;
                NcellsROI = NcellsROI + 1;
                hold off
                title(['ROI ', num2str(ROIidx), ' Accepted (N = ', num2str(NcellsROI), ')'])
                xlabel('Time [s]')
                ylabel('Relative intensity')
            end
            
            if dataset{cellIdx, ROIidx}.isDiscarded == 1
                subplots(ROIidx+numberOfROIs) = subplot(2,numberOfROIs,ROIidx+numberOfROIs);
                hold on
                plot(dataset{cellIdx, ROIidx}.timeVector, ...
                    dataset{cellIdx, ROIidx}.relativeData, 'Color', [0.5 0.5 0.5])
                Ndiscarded = Ndiscarded + 1;
                NdiscardedROI = NdiscardedROI + 1;
                hold off
                title(['ROI ', num2str(ROIidx), ' Discarded (N = ', num2str(NdiscardedROI), ')'])
                xlabel('Time [s]')
                ylabel('Relative intensity')
            end
        end
        
        Ntot = Ntot + 1;
        NtotROI = NtotROI + 1;
        
        % Find max intensity of the dataset for the y-axis limits
        if max(dataset{cellIdx, ROIidx}.relativeData) > maxInt
            maxInt = max(dataset{cellIdx, ROIidx}.relativeData);
        end
        
    end
    
    % Reset the counters
    NcellsROI = 0;
    NdiscardedROI = 0;
    NtotROI = 0;
    
end

% Set the y-axis limits for all subplots as the same
for i = 1:length(subplots)
    if isa(subplots(1,i),'matlab.graphics.axis.Axes')
        ylim(subplots(1,i), [0.9, maxInt+0.1*(maxInt-0.9)])
        xlim(subplots(1,i), [0, 600])
    end
end

suptitle({datasetName; ['All responses (N = ', num2str(Ntot), ', ROIs 1 - ', num2str(numberOfROIs),')']})

end

function [] = compareCurves(dataset, datasetName)

% Lets the user compare responses of the same cell side by side, if the
% ROIs correspond to measurements of the same frame and cell numbering
% is the same

% Ask user which ROI and cell they want to start from
clc
cell = inputdlg('Start from cell', 'Input', 1, {'1'});
cellIdx = str2num(cell{1});

[~, numberOfROIs] = size(dataset);
% Titles for the different measurements (move to user input later)
titles = inputdlg('Titles for the different responses', 'Input', 1);
spaces = find(titles{1,1} == ' ');

for i = 1:length(spaces)+1
    
    if i == 1
        parsedTitles{i,1} = titles{1,1}(1:spaces(1)-1);
    elseif i == length(spaces)+1
        parsedTitles{i,1} = titles{1,1}(spaces(i-1)+1:end);
    else
        parsedTitles{i,1} = titles{1,1}(spaces(i-1)+1:spaces(i)-1);
    end
     
end

% Leave out empty cells from the end of each ROI
notEmpty = find(~cellfun(@isempty,dataset(:, 1)));

% Loop from user-given cell
while true
    
    figure('units','normalized','outerposition',[0 0 1 1]);
    
    % For each ROI, plot the same numbered cells  side by side
    for ROIidx = 1:numberOfROIs
        
        obj = dataset{cellIdx, ROIidx};
        subplot(1,numberOfROIs,ROIidx)
        plot(obj.timeVector, obj.filteredData)
        xlabel('Time [s]')
        ylabel('Relative intensity')
        title(parsedTitles{ROIidx});


        
        % Find max and min values of the axes for each ROI for plotting
        maxY(ROIidx) = max(obj.filteredData);
        maxX(ROIidx) = max(obj.timeVector);
        minY(ROIidx) = min(obj.filteredData);
        axes(ROIidx) = gca;
        notEmpty = find(~cellfun(@isempty,dataset(:, ROIidx)));
        
    end
    
    for ROIidx = 1:numberOfROIs
        
        % Set the axis limits to same for all plot windows
        ylim = [min(minY) - 0.1*(max(maxY)-min(minY)), max(maxY)+ 0.1*(max(maxY)-min(minY))];
        xlim = [0, max(maxX)];
        set(axes(ROIidx), 'Ylim', ylim);
        set(axes(ROIidx), 'Xlim', xlim);
        
    end
    
    suptitle([datasetName, {['Cell ', num2str(cellIdx)]}])
    selection = menu('MENU', 'Next', 'Previous', 'Main menu');
    
    if selection == 1
        if cellIdx < length(notEmpty)
            close
            cellIdx = cellIdx + 1;
            continue
        else
            close
            return
        end
    elseif selection == 2 && cellIdx > 1
        close
        cellIdx = cellIdx - 1;
        continue
    elseif selection == 3
        close
        return
    end
    
end

end