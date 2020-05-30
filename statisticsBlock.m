% statisticsBlock lets the user to visualize the analyzed datasets by
% plotting boxplots or scatter plots of the calculated parameters.

% editDatabase.m is used to load a single dataset from a database created
% by readData.m and provide it's information
databaseInfo = editDatabase('load', 'multi');
dataset = databaseInfo{1};
datasetName = databaseInfo{2};
caDatabase = databaseInfo{3};
databaseName = databaseInfo{4};

[height, ~] = size(dataset);
chosenROIs = [];

% If only one dataset is selected, ask which ROIs to include
if height == 1
    
    [~, width] = size(dataset{1,1});
    % Fill the roiList with the number of ROIs in the current dataset
    roiList = cell(1, width);
    
    for index = 1:width
        roiList{index} = ['ROI ', num2str(index)];
    end
    
    % Ask user which ROIs should be included in the visualization
    [chosenROIs, tf] = listdlg('PromptString', {'Select ROIs you want to visualize.'}, ...
        'SelectionMode', 'multiple', 'ListString', roiList);
    
    % Return to main menu if cancel is pressed
    if ~tf
        return
    end
    
end

while(true)
    clc
    
    % Menu for selecting the plot type
    plotType = menu('Select plot type', 'Boxplot', 'Scatter plot', ...
        'Return to main menu');
    % List of possible variables to be plotted
    variableList = {'maxAmplitude', 'rise50', 'time2max', 'firstHalf', ...
        'decay50', 'duration50'};
    
    if(plotType == 1)
        % Ask user for variable to plot in the boxplot
        variable = listdlg('PromptString', {'Variable to plot? '},...
            'SelectionMode', 'single','ListString', variableList);
        makeBoxplot(dataset, datasetName, variableList{variable}, chosenROIs)
    elseif(plotType == 2)
        % Ask user for variable to plot in the x-axis
        Xvar = listdlg('PromptString', {'Variable for x-axis? '},...
            'SelectionMode', 'single','ListString', variableList);

        % Ask user for variable to plot in the y-axis
        Yvar = listdlg('PromptString', {'Variable for y-axis? '},...
            'SelectionMode', 'single','ListString', variableList);

        makeScatterPlot(dataset, datasetName, variableList{Xvar}, ...
            variableList{Yvar}, chosenROIs)
    elseif(plotType == 3)
        % Return to main menu
        return
    end
end

function [] = makeBoxplot(dataset, datasetName, variable, chosenROIs)

% Makes the boxplot from user-given inputs


var{1} = variable;
data = getData(dataset, var, 'boxplot', chosenROIs);
[height, ~] = size(dataset);
mergedData = [];
maxHeight = 0;


if height > 1
    
    for datasetIdx = 1:height
        
        [height2, ~] = size(data{datasetIdx, 1});
        
        if height2 > maxHeight
            maxHeight = height2;
        end
        
    end
    
    for datasetIdx = 1:height
        
        [height2, ~] = size(data{datasetIdx, 1});
        mergedData(1:height2, datasetIdx) = data{datasetIdx, 1}(1:height2, 1);
        
        if height2 < maxHeight
            mergedData(height2+1:maxHeight, datasetIdx) = NaN;
        end
        
    end
    
    boxplot(mergedData)
    if strcmp(var{1}, 'maxAmplitude')
        ylabel('Max. relative amplitude')
    elseif strcmp(var{1}, 'rise50')
        ylabel('Rise time 0 - 50% intensity [s]')
    elseif strcmp(var{1}, 'time2max')
        ylabel('Rise time 0 - 100% intensity [s]')
    elseif strcmp(var{1}, 'firstHalf')
        ylabel('Rise time 50 - 100% intensity [s]')
    elseif strcmp(var{1}, 'decay50')
        ylabel('Decay time 100 - 50% intensity [s]')
    elseif strcmp(var{1}, 'duration50')
        ylabel('Response duration above 50% intensity [s]')
    end
    xlabel('dataset')
    set(gca,'XTickLabel',datasetName)
    
    % Save the boxplot data as a worksheet for later editing in other software
    filename = strcat('boxplotdata_merged.xlsx');
    xlswrite(filename, mergedData)
    
else
    
    i = 1;
    j = 1;
    k = 1;
    while true
        if k > length(data{1,1}) || i > length(chosenROIs)
            break
        elseif isnan(data{1,1}(k,1))
            ROI(j,i) = NaN;
            j = j + 1;
            k = k + 1;           
        elseif data{1,1}(k,2) == chosenROIs(i)
            ROI(j,i) = data{1,1}(k,1);
            j = j + 1;
            k = k + 1;
        elseif data{1,1}(k,2) ~= chosenROIs(i)
            i = i + 1;
            j = 1;
        end
        
    end
    
    boxplot(ROI)
    if strcmp(var{1}, 'maxAmplitude')
        ylabel('Max. relative amplitude')
    elseif strcmp(var{1}, 'rise50')
        ylabel('Rise time 0 - 50% intensity [s]')
    elseif strcmp(var{1}, 'time2max')
        ylabel('Rise time 0 - 100% intensity [s]')
    elseif strcmp(var{1}, 'firstHalf')
        ylabel('Rise time 50 - 100% intensity [s]')
    elseif strcmp(var{1}, 'decay50')
        ylabel('Decay time 100 - 50% intensity [s]')
    elseif strcmp(var{1}, 'duration50')
        ylabel('Response duration above 50% intensity [s]')
    end
    xlabel('ROI')
    title(datasetName)
    
    % Save the boxplot data as a worksheet for later editing in other software
    spaces = datasetName{1} == ' ';
    datasetName{1}(spaces) = '_';
    filename = strcat('boxplotdata_', datasetName{1}, '.xlsx');
    xlswrite(filename, data{1,1})
end


end

function [] = makeScatterPlot(dataset, datasetName, Xvar, Yvar, chosenROIs)

% Makes the scatter plot from user-given inputs

% Get data from the dataset in table form
data = getData(dataset, {Xvar, Yvar}, 'scatter', chosenROIs);

% Find min and max values of the variables for setting axis limits
xmin = min(data{1,1}(:,1));
xmax = max(data{1,1}(:,1));
ymin = min(data{1,1}(:,2));
ymax = max(data{1,1}(:,2));
maxTot = max(ymax, xmax);
minTot = min(ymin, xmin);

[height, ~] = size(data{1,1});

% Use the group colors corresponding to clustering data in the scatter plot
groupColors =  [0         0.4470    0.7410;
    0.6350    0.0780    0.1840;
    0.9290    0.6940    0.1250;
    0         0.5000    0];

hold on
for idx = 1:height
    % Plot each data point with corresponding group color
    if(data{1,1}(idx,3) == 1)
        h(1) = scatter(data{1,1}(idx,1), data{1,1}(idx,2), [], groupColors(1,:));
        legends{1} = 'Group 1';
    elseif(data{1,1}(idx,3) == 2)
        h(2) = scatter(data{1,1}(idx,1), data{1,1}(idx,2), [], groupColors(2,:));
        legends{2} = 'Group 2';
    elseif(data{1,1}(idx,3) == 3)
        h(3) = scatter(data{1,1}(idx,1), data{1,1}(idx,2), [], groupColors(3,:));
        legends{3} = 'Group 3';
    elseif(data{1,1}(idx,3) == 4)
        h(4) = scatter(data{1,1}(idx,1), data{1,1}(idx,2), [], groupColors(4,:));
        legends{4} = 'Group 4';
    end
end
hold off
if strcmp(Xvar, 'maxAmplitude')
    xlabel('Max. relative amplitude')
elseif strcmp(Xvar, 'rise50')
    xlabel('Rise time 0 - 50% intensity [s]')
elseif strcmp(Xvar, 'time2max')
    xlabel('Rise time 0 - 100% intensity [s]')
elseif strcmp(Xvar, 'firstHalf')
    xlabel('Rise time 50 - 100% intensity [s]')
elseif strcmp(Xvar, 'decay50')
    xlabel('Decay time 100 - 50% intensity [s]')
elseif strcmp(Xvar, 'duration50')
    xlabel('Response duration above 50% intensity [s]')
end

if strcmp(Yvar, 'maxAmplitude')
    ylabel('Max. relative amplitude')
elseif strcmp(Yvar, 'rise50')
    ylabel('Rise time 0 - 50% intensity [s]')
elseif strcmp(Yvar, 'time2max')
    ylabel('Rise time 0 - 100% intensity [s]')
elseif strcmp(Yvar, 'firstHalf')
    ylabel('Rise time 50 - 100% intensity [s]')
elseif strcmp(Yvar, 'decay50')
    ylabel('Decay time 100 - 50% intensity [s]')
elseif strcmp(Yvar, 'duration50')
    ylabel('Response duration above 50% intensity [s]')
end

title(datasetName)
legend(h, legends)
% Set x- and y-axis limit padding
xlim([xmin-0.1*(xmax-xmin) xmax+0.1*(xmax-xmin)])
ylim([ymin-0.1*(ymax-ymin) ymax+0.1*(ymax-ymin)])
% Save the scatter data as a worksheet for later editing in other software
spaces = datasetName{1} == ' ';
datasetName{1}(spaces) = '_';
filename = strcat('scatterdata_', datasetName{1}, '.xlsx');
xlswrite(filename, data{1,1})

end

function table = getData(dataset, variables, type, chosenROIs)

% Returns the data to be plotted either in boxplot of scatter plot in a
% table format

table = {};

[height1, ~] = size(dataset);
tableIdx = 1;

% Loop through each dataset in the database and include the cells that match
% the ROIs and are not discarded
for datasetIdx = 1:height1
    
    [height2, width2] = size(dataset{datasetIdx, 1});
    
    % Fill the empty cells with empty responses
    for i = 1:width2
        for j = 1:height2
            if isempty(dataset{datasetIdx,1}{j,i})
                dataset{datasetIdx,1}{j,i} = intensityResponse;
                dataset{datasetIdx,1}{j,i}.indices = NaN;
            end
        end
    end
    
    for ROIidx = 1:width2
        
        for cellIdx = 1:height2
            
            % Check if current cell's ROI index is on the ROI list chosen by
            % user to be plotted. If multiple datasets are selected, all
            % ROIs are included automatically.
            
            if height1 > 1
                isOnTheRoiList = true;
            else
                isOnTheRoiList = any(dataset{datasetIdx, 1}{cellIdx, ROIidx}.indices(1) == chosenROIs);
            end
            
            if isnan(dataset{datasetIdx, 1}{cellIdx, ROIidx}.indices(1))
                
                table{datasetIdx, 1}(tableIdx, 1) = NaN;
                table{datasetIdx, 1}(tableIdx, 2) = NaN;
            
            elseif(isOnTheRoiList && ~dataset{datasetIdx, 1}{cellIdx, ROIidx}.isDiscarded)
                
                % If ROI index matches and the cell is not discarded, pick the
                % variable(s) to the table
                if(strcmp(type, 'boxplot'))
                    table{datasetIdx, 1}(tableIdx, 1) = dataset{datasetIdx, 1}{cellIdx, ROIidx}.(variables{1});
                    table{datasetIdx, 1}(tableIdx, 2) = dataset{datasetIdx, 1}{cellIdx, ROIidx}.indices(1);
                elseif(strcmp(type, 'scatter'))
                    table{datasetIdx, 1}(tableIdx, 1) = dataset{datasetIdx, 1}{cellIdx, ROIidx}.(variables{1});
                    table{datasetIdx, 1}(tableIdx, 2) = dataset{datasetIdx, 1}{cellIdx, ROIidx}.(variables{2});
                    
                    % In scatter mode include also the group number (if empty,
                    % fill with 0, corresponding a discarded cell)
                    if(isempty(dataset{datasetIdx, 1}{cellIdx, ROIidx}.groupNumber))
                        table{datasetIdx, 1}(tableIdx, 3) = 0;
                    else
                        table{datasetIdx, 1}(tableIdx, 3) = dataset{datasetIdx, 1}{cellIdx, ROIidx}.groupNumber;
                    end
                    
                end
                
                
            elseif dataset{datasetIdx, 1}{cellIdx, ROIidx}.isDiscarded
                
                table{datasetIdx, 1}(tableIdx, 1) = NaN;
                table{datasetIdx, 1}(tableIdx, 2) = dataset{datasetIdx, 1}{cellIdx, ROIidx}.indices(1);
                              
                
            end
            
            tableIdx = tableIdx + 1;
            
        end
        
    end
    
    tableIdx = 1;
    
end

end