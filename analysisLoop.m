% analysisLoop script is used to run the intensity analysis after the data is
% imported with readData.m. It is started from the
% intensityAnalysis_start.m master file. The class intensityResponse class
% definition is located in intensityResponse.m.

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

spaces = find(datasetName == '_');
datasetName(spaces) = ' ';

% Ask user which ROI and cell they want to start from (pressing enter finds the
% first non-analyzed)
prompt = {'Start from ROI:', 'Start from cell (leave empty to find first non-analyzed cell):'};
dlgTitle = 'Input';
num_lines = 1;
def = {'',''};
answer = inputdlg(prompt, dlgTitle, num_lines, def);

% If user clicks cancel -> return to main menu
if isempty(answer)
    return
end

ROI = str2num(answer{1}); cellIdx = str2num(answer{2});

if(isempty(cellIdx))
    cellIdx = findFirstNonAnalyzed(dataset, ROI);
end

[~, numberOfROIs] = size(dataset);

% Start looping the dataset fom the user-given ROI and cell
for ROIidx = ROI:numberOfROIs
    
    % Leave out empty cells in the end of each ROI column.
    notEmpty = find(~cellfun(@isempty,dataset(:,ROIidx)));
    
    while true
        
        
        obj = dataset{cellIdx, ROIidx};
        counter = 1;

        while true
            
            % Apply and plot bleach correction with the correctBleach and
            % plotBleachCorrection methods from intensityResponse.m
            obj = correctBleach(obj);

            figure('units','normalized','outerposition',[0 0 1 1]);
            subplot(1,2,1)
            plotBleachCorrection(obj);
            spaces = find(datasetName == '_');
            datasetName(spaces) = ' ';
            suptitle({datasetName; [' ROI ', num2str(obj.indices(1)), ' cell ', num2str(obj.indices(2))]})
            
            if counter == 1
                
                answer2 = menu('Accept the bleach correction?', 'Yes', 'No', 'Skip correction', 'Discard response', ...
                    'Previous cell', 'Next cell', 'Main menu');
            
            end
            
            if(answer2 == 7)
                % Return to main menu
                close
                return
            elseif(answer2 == 5 || answer2 == 6)
                close
                break
            elseif(answer2 == 2)
                % Ask user to input graphically the new bounds for baseline
                % fit
                [startBounds, ~] = ginput(2);
                % Convert from seconds to indices
                obj.fitIndices = round(2*startBounds);
                close
            elseif(answer2 == 4)
                % Discard the response, clear the variables if the response 
                % has been analyzed previously and move to next one
                obj.isDiscarded = true;
                obj.isAnalyzed = false;
                obj.isSkipped = false;
                
                obj.fitIndices = [1 round(length(obj.timeVector)/6)];
                obj.startmaxIndices = [0, 0];
                obj.halfwayIndices = [0, 0];
                obj.sparkInterval = [0, 0];
                obj.highSparkPeaks = []; 
                obj.lowSparkPeaks = [];
                
                obj.maxAmplitude = [];
                obj.rise50 = [];
                obj.time2max = [];
                obj.firstHalf = [];
                obj.decay50 = [];
                obj.duration50 = [];
                
                obj.sparkTime  = 0; 
                obj.sparkStartTime  = 0; 
                obj.avgSparkInterval  = 0;
                obj.avgSparkAmplitude = 0;
                obj.maxSparkAmplitude = 0;
                obj.numberOfSparks  = 0;
                
                close
                break
            elseif(answer2 == 1 || answer2 == 3)
                close
                % Use the average start point of the current dataset as an
                % estimate for the response start point.
                startPointGuess = findAverage(dataset, ROIidx, cellIdx);
                % Logicals to determine which points (start, halfway rise,
                % maximum, halfway decay) should be analyzed (true) or left
                % as is (false).
                if ~obj.isAnalyzed
                    whichPointsToAnalyze = [true, true, true, true];
                elseif obj.isAnalyzed
                    whichPointsToAnalyze = [false, false, false, false];
                end
                
                obj.isDiscarded = false;
                
                if(answer2 == 3)
                    % Option to discard the bleach correction and continue
                    % analyzing the data from the original raw data.
                    obj.isSkipped = true;
                    % Calculate the relative  and filtered data from the
                    % uncorrected raw data.
                    obj.relativeData = obj.rawData ./ (mean(obj.rawData(1:10))*ones(length(obj.timeVector),1));
                    obj.filteredData = smooth(obj.relativeData);
                end
                
                while true
                    
                    % First time, use the startPointGuess for the intensity
                    % start point and if user wants to adjust the points
                    % multiple times, use the value calculated in the
                    % previous iteration.
                    
                    if whichPointsToAnalyze(1) && ~obj.isAnalyzed
                        obj = analyzeData(obj, startPointGuess, whichPointsToAnalyze);
                    elseif ~whichPointsToAnalyze(1) && ~obj.isAnalyzed
                        obj = analyzeData(obj, obj.startmaxIndices(1), whichPointsToAnalyze);
                    end
                    
                    obj.isAnalyzed = true;
                    % After analysis, plot the bleach correction and the
                    % analyzed data side by side.
                    figure('units','normalized','outerposition',[0 0 1 1]);
                    subplot(1,2,1)
                    plotBleachCorrection(obj);
                    subplot(1,2,2)
                    %hold on
                    plotAnalyzedData(obj);
                    
                    suptitle({datasetName; ['ROI ', num2str(obj.indices(1)), ...
                        ' cell ', num2str(obj.indices(2))]})
                    
                    answer3 = menu('Accept calculated points?', 'Yes', ...
                        'No','Add/Change spark data', 'Delete spark data');
                    
                    % If user doesn't accept the calculated points, they
                    % can be reselected graphically from the plot. Left
                    % click selects the new value, right click keeps it the
                    % same. The values are selected in order: start,
                    % halfway (rise), maximum, halfway (decay).
                    if(answer3 == 2)
                        
                        [points, ~, button] = ginput(4);
                        
                        if button(1) == 1
                            obj.startmaxIndices(1) = round(points(1)/obj.samplingInterval);
                            % If user selects a new start point, it
                            % overrides the startPointGuess
                            whichPointsToAnalyze(1) = false;
                        end
                        
                        if button(2) == 1
                            % If user selects a new halfway point, it
                            % overrides the previously calculated one
                            obj.halfwayIndices(1) = round(points(2)/obj.samplingInterval);
                            whichPointsToAnalyze(2) = false;
                        end
                        
                        if button(3) == 1
                            obj.startmaxIndices(2) = round(points(3)/obj.samplingInterval);
                            % If user selects a new maximum point, it
                            % overrides the previously calculated one
                            whichPointsToAnalyze(3) = false;
                        end
                        
                        if button(4) == 1
                            obj.halfwayIndices(2) = round(points(4)/obj.samplingInterval);
                            % If user selects a new halfway point, it
                            % overrides the previously calculated one
                            whichPointsToAnalyze(4) = false;
                        end
                        
                        close
                        counter = counter + 1;
                        
                    elseif(answer3 == 3)

                        % User can select the sparking interval
                        % graphically
                        [peakTimeInterval, ~, ~] = ginput(2);
                        obj = calculateSparkData(obj, peakTimeInterval);
                        close
                        counter = counter + 1;
                        break
                        
                    elseif answer3 == 4
                        
                        % Clear all spark data
                        obj.sparkInterval = [0, 0];
                        obj.highSparkPeaks = [];
                        obj.lowSparkPeaks = [];
                        obj.sparkTime  = 0;
                        obj.sparkStartTime  = 0;
                        obj.avgSparkInterval  = 0;
                        obj.avgSparkAmplitude = 0;
                        obj.maxSparkAmplitude = 0;
                        obj.numberOfSparks  = 0;
                        obj.isSparking = 0;
                        close
                        counter = counter + 1;
                        break
                        
                    elseif answer3 == 1
                        
                        close
                        break
                    end
                end
            

            end
            
            if exist('answer3') 
                if answer3 == 1
                    answer3 = [];
                    break
                end
            end
            
            
            
        end
    
    % Save the analyzed intensityResponse object to the dataset and
    % database
    dataset{cellIdx, ROIidx} = obj;
    spaces = find(datasetName == ' ');
    datasetName(spaces) = '_';
    caDatabase.(datasetName) = dataset;
    save(databaseName,'caDatabase')
    
    
    if answer2 == 5
        if cellIdx > 1
            cellIdx = cellIdx - 1;
            continue
        end
    elseif answer2 == 6
        if cellIdx < length(notEmpty)
            cellIdx = cellIdx + 1;
            continue
        end
    elseif cellIdx < length(notEmpty)
        cellIdx = cellIdx + 1;
    else
        cellIdx = 1;
        break
    end
    
    end

% Reset the cell number to 1 after each ROI ends
cellIdx = 1;

end

function avgValue = findAverage(dataset, ROIidx, cellidx)

% Finds and returns the average of the starting indices before the
% current response to act as an estimate of the response starting index
sum = 0.0;

if isempty(dataset(1:cellidx,ROIidx))
    % If the previous cells are empty, return 0
    avgValue = 0;
elseif length(dataset(1:cellidx,ROIidx)) == 1
    avgValue = dataset{cellidx, ROIidx}.fitIndices(2);
    % If the response is the first one, use the end index of the
    % baseline fit from bleach correction
else
    % Else calculate the average of the preceding start indices
    for avgidx = 1:cellidx-1
        sum = sum + dataset{avgidx, ROIidx}.startmaxIndices(1);
    end
    avgValue = round(sum/length(dataset(1:cellidx-1,ROIidx)));
end

end

function cellIdx = findFirstNonAnalyzed(dataset, ROI)

% Loops through the current ROI of the dataset and returns the index of
% the first cell, that is not analyzed and not discarded
notEmpty = find(~cellfun(@isempty,dataset(:,ROI)));
for cellIdx = 1:length(notEmpty)
    
    if ~dataset{cellIdx, ROI}.isAnalyzed && ~dataset{cellIdx, ROI}.isDiscarded
        break;
    end
    
end

end

