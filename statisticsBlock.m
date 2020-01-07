% statisticsBlock lets the user to visualize the analyzed datasets by
% plotting boxplots or scatter plots of the calculated parameters.

% editDatabase.m is used to load a single dataset from a database created 
% by readData.m and provide it's information
databaseInfo = editDatabase('load', 'multi');
dataset = databaseInfo{1};
datasetName = databaseInfo{2};
caDatabase = databaseInfo{3};
databaseName = databaseInfo{4};

[~, width] = size(dataset);

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
        % Get Y-axis text as input from user
        Ytext = inputdlg('Y-axis text: ', 'Input', 1);
        makeBoxplot(dataset, datasetName, variableList{variable}, Ytext, chosenROIs)
    elseif(plotType == 2)
        % Ask user for variable to plot in the x-axis
        Xvar = listdlg('PromptString', {'Variable for x-axis? '},...
            'SelectionMode', 'single','ListString', variableList);
        % Get Y-axis text as input from user
        Xtext = inputdlg('X-axis text: ', 'Input', 1);
        % Ask user for variable to plot in the y-axis
        Yvar = listdlg('PromptString', {'Variable for y-axis? '},...
            'SelectionMode', 'single','ListString', variableList);
        % Get Y-axis text as input from user
        Ytext = inputdlg('Y-axis text: ', 'Input', 1);
        makeScatterPlot(dataset, datasetName, variableList{Xvar}, ...
            variableList{Yvar}, Xtext, Ytext, chosenROIs)
    elseif(plotType == 3)
        % Return to main menu
        return
    end
end

function [] = makeBoxplot(dataset, datasetName, variable, Ytext, chosenROIs)

% Makes the boxplot from user-given inputs

var{1} = variable;
data = getData(dataset, var, 'boxplot', chosenROIs);

boxplot(data)
ylabel(Ytext)
xlabel('ROI')
% Save the boxplot data as a worksheet for later editing in other software
filename = strcat('boxplotdata_', datasetName, '.xlsx');
xlswrite(filename{1}, data)

end

function [] = makeScatterPlot(dataset, datasetName, Xvar, Yvar, Xtext, Ytext, chosenROIs)

% Makes the scatter plot from user-given inputs

% Get data from the dataset in table form
data = getData(dataset, {Xvar, Yvar}, 'scatter', chosenROIs);

% Find min and max values of the variables for setting axis limits
xmin = min(data(:,1));
xmax = max(data(:,1));
ymin = min(data(:,2));
ymax = max(data(:,2));

[height, ~] = size(data);

% Use the group colors corresponding to clustering data in the scatter plot
groupColors =  [0         0.4470    0.7410;
                0.6350    0.0780    0.1840;
                0.9290    0.6940    0.1250;
                0         0.5000    0];

hold on
for idx = 1:height
    % Plot each data point with corresponding group color
    if(data(idx,3) == 1)
        scatter(data(idx,1), data(idx,2), [], groupColors(1,:))
    elseif(data(idx,3) == 2)
        scatter(data(idx,1), data(idx,2), [], groupColors(2,:))
    elseif(data(idx,3) == 3)
        scatter(data(idx,1), data(idx,2), [], groupColors(3,:))
    elseif(data(idx,3) == 4)
        scatter(data(idx,1), data(idx,2), [], groupColors(4,:))
    end
end
hold off
xlabel(Xtext)
ylabel(Ytext)
% Set x- and y-axis limit padding
xlim([xmin-0.1*(xmax-xmin) xmax+0.1*(xmax-xmin)])
ylim([ymin-0.1*(ymax-ymin) ymax+0.1*(ymax-ymin)])
% Save the scatter data as a worksheet for later editing in other software
filename = strcat('scatterdata_', datasetName, '.xlsx');
xlswrite(filename{1}, data)

end

function table = getData(dataset, variables, type, chosenROIs)

% Returns the data to be plotted either in boxplot of scatter plot in a
% table format

table = [];
index = 1;

[~, width] = size(dataset);
tableIdx = 1;

% Loop through each dataset in the database and include the cells that match
% the ROIs and are not discarded
for datasetIdx = 1:width
    
    [height, ~] = size(dataset(:,datasetIdx));
    
    for cellIdx = 1:height
        
        % Check if current cell's ROI index is on the ROI list chosen by
        % user to be plotted
        isOnTheRoiList = any(dataset{cellIdx, datasetIdx}.indices(1) == chosenROIs);
        
        if(isOnTheRoiList && ~dataset{cellIdx, datasetIdx}.isDiscarded)
            
            % If ROI index matches and the cell is not discarded, pick the
            % variable(s) to the table
            if(strcmp(type, 'boxplot'))
                table(tableIdx, datasetIdx) = dataset{cellIdx, datasetIdx}.(variables{1});
            elseif(strcmp(type, 'scatter'))
                table(tableIdx, 1) = dataset{cellIdx, datasetIdx}.(variables{1});
                table(tableIdx, 2) = dataset{cellIdx, datasetIdx}.(variables{2});
                
                % In scatter mode include also the group number (if empty,
                % fill with 0, corresponding a discarded cell)
                if(isempty(dataset{cellIdx, datasetIdx}.groupNumber))
                    table(tableIdx, 3) = 0;
                else
                    table(tableIdx, 3) = dataset{cellIdx, datasetIdx}.groupNumber;
                end
                
            end
            
            tableIdx = tableIdx + 1;
            
        end
        
    end
    
    if(strcmp(type, 'boxplot'))
        % Reset the boxIdx when switching to new dataset if making a boxplot
        tableIdx = 1; 
    end
    
end

end