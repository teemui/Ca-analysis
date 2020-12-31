% plotLocationData visualizes the grouping done by clusterAnalysis over the
% original image to show where the cell belonging to each group are located

% editDatabase.m is used to load a single dataset from a database created 
% by readData.m and provide it's information
databaseInfo = editDatabase('load', 'single');

% If nothing is selected or user clicks cancel in the selection window ->
% return to main menu
if(isempty(databaseInfo))
    return
end

dataset = databaseInfo{1};
datasetName = databaseInfo{2};
caDatabase = databaseInfo{3};
databaseName = databaseInfo{4};
[height, width] = size(dataset);
coords = zeros(1,3);

% The ratio of pixels to micrometers in the original image (check from
% ImageJ) [move to user input later]
answer = inputdlg('Enter pixels/length (check from ImageJ)', 'Input', 1);
divMark = find(answer{1} == '/');
pixels = answer{1}(1:divMark-1);
microns = answer{1}(divMark+1:end);
pixelRatio = str2double(pixels)/str2double(microns);

% colors for the grouping plots (each row corresponds one color)
groupColors =  [0         0.4470    0.7410;
                0.6350    0.0780    0.1840;
                0.9290    0.6940    0.1250;
                0         0.5000    0
                0.5       0.5       0.5];

figure('units','normalized','outerposition',[0 0 1 1]);
% Ask user to browse for the image file 
[img, path] = uigetfile('*.*','Select the image file you want to analyze', 'MultiSelect', 'on');
currentFolder = pwd;

if strcmp(path, currentFolder) == 0
    cd(path)
end

for ROIidx = 1:width

    % Leave out empty cells
    notEmpty = find(~cellfun(@isempty,dataset(:,ROIidx)));
    height = length(notEmpty);
    
    % Read the image to Matlab
    if ischar(img)
        % If only one ROI -> img is a char variable
        I = imread(img);
    else
        % If multiple ROIs -> img is a cell variable
        I = imread(img{ROIidx});
    end

    subplot(1, width, ROIidx)
    
    for cellIdx = 1:height
        
        % x-coordinate
        coords(1,1) = pixelRatio*dataset{cellIdx, ROIidx}.coordinates(1);
        % y-coordinate
        coords(1,2) = pixelRatio*dataset{cellIdx, ROIidx}.coordinates(2);
        % marker radius
        coords(1,3) = pixelRatio*dataset{cellIdx, ROIidx}.coordinates(3);
        
        % Plot each cell to its coordinates with the corresponding group
        % color. Empty group color (gray circle) means discarded cell.
        if dataset{cellIdx, ROIidx}.groupNumber == 1
            I = insertShape(I, 'FilledCircle', coords, 'color', ...
                256*groupColors(1,1:end), 'Opacity', 0.4);
        elseif dataset{cellIdx, ROIidx}.groupNumber == 2
            I = insertShape(I, 'FilledCircle', coords, 'color', ...
                256*groupColors(2,1:end), 'Opacity', 0.4);
        elseif dataset{cellIdx, ROIidx}.groupNumber == 3
            I = insertShape(I, 'FilledCircle', coords, 'color', ...
                256*groupColors(3,1:end), 'Opacity', 0.4);
        elseif dataset{cellIdx, ROIidx}.groupNumber == 4
            I = insertShape(I, 'FilledCircle', coords, 'color', ...
                256*groupColors(4,1:end), 'Opacity', 0.4);
        elseif isempty(dataset{cellIdx, ROIidx}.groupNumber)
            I = insertShape(I, 'FilledCircle', coords, 'color', ...
                256*groupColors(5,1:end), 'Opacity', 0.4);
        end
        
        % Insert the cell number of each cell to the middle of the circle
        I = insertText(I, [coords(1) coords(2)], cellIdx, ...
            'AnchorPoint', 'center', 'TextColor', 'white', ...
            'BoxOpacity', 0, 'FontSize', 8);
        
        % View the edited image
        imshow(I)
        if ischar(img)
            title(img(1:end-4), 'Interpreter', 'none')
        else
            title(img{ROIidx}(1:end-4), 'Interpreter', 'none')
        end
    end
    
    % Save the edited image
    if ischar(img)
        imwrite(I, [img(1:end-4), '_edited.jpg'])
    else
        imwrite(I, [img{ROIidx}(1:end-4), '_edited.jpg'])
    end
    
end