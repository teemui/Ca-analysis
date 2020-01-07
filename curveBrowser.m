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
cell = answer{2};
discarded = answer{3};

[~, numberOfROIs] = size(dataset);

for ROIidx = ROI:numberOfROIs
    
    % Leave out empty cells in the end of each ROI column.
    notEmpty = find(~cellfun(@isempty,dataset(:, ROIidx)));
    
    % Loop through and plot all the populated cells one by one in the ROI.
    for cellIdx = cell:notEmpty(end)
        
        obj = dataset{cellIdx, ROIidx};
        
        if(discarded == 2 && obj.isDiscarded)
            
                % If discarded cells selected
                figure
                hold on
                plot(obj.timeVector, obj.rawData, 'b')
                plot(obj.timeVector, obj.rawData, 'g')
                legend('original data', 'corrected data')
                title(['ROI ', num2str(ROIidx), ', cell ', num2str(cellIdx)])
                hold off
                selection = menu('MENU', 'Next', 'Main menu');
                if(selection == 1)
                    continue
                elseif(selection == 2)
                    return
                end
                close
            
        elseif(discarded == 1 && (~isempty(obj.maxAmplitude) && ~obj.isDiscarded))
            
                % If accepted cells selected
                figure('units','normalized','outerposition',[0 0 1 1]);
                subplot(1,2,1)
                plotBleachCorrection(obj);
                subplot(1,2,2)
                plotAnalyzedData(obj);
                suptitle(['ROI ', num2str(ROIidx), ', cell ', num2str(cellIdx)])
                selection = menu('MENU', 'Next', 'Main menu');
                if(selection == 1)
                    continue
                elseif(selection == 2)
                    return
                end
                close
            
        end
        
    end
    
    % Reset cell number after each ROI
    cell = 1;
    
end

end

function [] = plotCurves(dataset, datasetName)

clc

% Dialog to choose plot type and accepted/discarded responses
dlgName = 'Choose plot type';

prompt(1,:) = {['Plot type'], []};
prompt(2,:) = {['Accepted or dircarded?'], []};

formats = struct('type', {}, 'style', {}, 'items', {}, ...
  'format', {}, 'limits', {}, 'size', {});
formats(1,1).type   = 'list';
formats(1,1).style  = 'popupmenu';
formats(1,1).items  = {'Plot all responses to a single figure', 'Separate by ROIs'};

formats(2,1).type   = 'list';
formats(2,1).style  = 'popupmenu';
formats(2,1).items  = {'accepted', 'discarded'};
defaultanswer = {1, 1};

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

for ROIidx = 1:numberOfROIs
    
    % Leave out empty cells in the end of each ROI column.
    notEmpty = find(~cellfun(@isempty,dataset(:, ROIidx)));
    
    % Loop through and plot all the populated cells in the ROI.
    for cellIdx = 1:notEmpty(end)
        
        % Plot responses separated by ROIs
        if(answer2{1} == 2)
            subplot(1,numberOfROIs,ROIidx)
        end
        
        % Plot all responses to same figure (accepted cells)
        if(answer2{2} == 1)
            hold on
            if dataset{cellIdx, ROIidx}.isDiscarded == 0 && ...
                    ~isempty(dataset{cellIdx, ROIidx}.maxAmplitude)
                
                plot(dataset{cellIdx, ROIidx}.timeVector, ...
                    dataset{cellIdx, ROIidx}.relativeData, 'Color', [0.5 0.5 0.5])
                Ncells = Ncells + 1;
                NcellsROI = NcellsROI + 1;
            end
            hold off
        end
        
        % Plot all responses to same figure (accepted cells)
        if(answer2{2} == 2)
            hold on
            if dataset{cellIdx, ROIidx}.isDiscarded == 1 && ...
                    ~isempty(dataset{cellIdx, ROIidx}.maxAmplitude)
                
                plot(dataset{cellIdx, ROIidx}.timeVector, ...
                    dataset{cellIdx, ROIidx}.relativeData, 'Color', [0.5 0.5 0.5])
                Ndiscarded = Ndiscarded + 1;
                NdiscardedROI = NdiscardedROI + 1;
                
            end
        end
        
        Ntot = Ntot + 1;
        NtotROI = NtotROI + 1; 
        
    end
    
    % Calculate the percentage of analyzed and discarded cells
    percentageAnalyzedROI = round(100*NcellsROI/NtotROI, 1);
    percentageDiscardedROI = round(100*NdiscardedROI/NtotROI, 1);
    
    ylim([0.9, 2.0])
    xlim([0, 600])
    if(answer2{1} == 2 && answer2{2} == 2)
        % If plotting discarded cells
        title(['ROI ', num2str(ROIidx), ' (', num2str(NdiscardedROI),'/',num2str(NtotROI),' = ', sprintf('%g', round(percentageDiscardedROI, 1)), '%)'])
    elseif(answer2{1} == 2 && answer2{2} == 1)
        % If plotting accepted cells
        title(['ROI ', num2str(ROIidx), ' (', num2str(NcellsROI),'/',num2str(NtotROI),' = ', sprintf('%g', percentageAnalyzedROI), '%)'])
    end
    
    % Reset the counters
    NcellsROI = 0;
    NdiscardedROI = 0;
    NtotROI = 0;
end

     if(answer2{1} == 1 && answer2{2} == 2)
        suptitle({datasetName{1}; ['Discarded responses N = ', num2str(Ndiscarded), ' (ROIs 1 - ', num2str(numberOfROIs),')']}) 
     elseif(answer2{1} == 2 && answer2{2} == 1)
        suptitle({datasetName{1}; ['Analyzed responses N = ', num2str(Ncells), ' (ROIs 1 - ', num2str(numberOfROIs),')']}) 
     end
end

function [] = compareCurves(dataset, datasetName)

    % Lets the user compare responses of the same cell side by side, if the
    % ROIs correspond to measurements of the same frame and cell numbering
    % is the same

    % Ask user which ROI and cell they want to start from
    clc
    cell = inputdlg('Start from cell', 'Input', 1, {'1'});
    cell = str2num(cell{1});
    
    [~, numberOfROIs] = size(dataset);
    % Titles for the different measurements (move to user input later)
    titles = {'ATP1', 'TG', 'ATP2'};
    titles2 = {'ATP1', 'ATP2'};
    
    % Leave out empty cells from the end of each ROI
    notEmpty = find(~cellfun(@isempty,dataset(:, 1)));
    
    % Loop from user-given cell
    for cellIdx = cell:notEmpty(end)
    
        % For each ROI, plot the same numbered cells  side by side
        for ROIidx = 1:numberOfROIs

            obj = dataset{cellIdx, ROIidx};
            subplot(1,numberOfROIs,ROIidx)
            plot(obj.timeVector, obj.filteredData)
            
            if numberOfROIs == 3
                title(titles(ROIidx));
            elseif numberOfROIs == 2
                title(titles2(ROIidx));
            end
            
            % Find max and min values of the axes for each ROI for plotting
            maxY(ROIidx) = max(obj.filteredData);
            maxX(ROIidx) = max(obj.timeVector);
            minY(ROIidx) = min(obj.filteredData);
            axes(ROIidx) = gca;
            notEmpty = find(~cellfun(@isempty,dataset(:, ROIidx)));
            
        end
        
        for ROIidx = 1:numberOfROIs
            
            % Set the axis limits
            ylim = [min(minY) - 0.1*(max(maxY)-min(minY)), max(maxY)+ 0.1*(max(maxY)-min(minY))];
            xlim = [0, max(maxX)];
            set(axes(ROIidx), 'Ylim', ylim);
            set(axes(ROIidx), 'Xlim', xlim);
            
        end
        
        suptitle([datasetName, {['Cell ', num2str(cellIdx)]}])
        selection = menu('MENU', 'Next', 'Main menu');
        if(selection == 1)
            continue
        elseif(selection == 2)
            return
        end
        
    end

end