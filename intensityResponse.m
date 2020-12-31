classdef intensityResponse < dynamicprops

    % Class definition file for the intensity responses. Contains all the
    % properties and methods of the intensityResponse class.
    
    %% properties
    properties
        
        datasetInfo % dataset information from user input
        samplingInterval % in seconds
        indices % [sheetNumber (ROI), cellNumber]
        coordinates %[X, Y, radius] cell location in  the image
        groupNumber % Group number from cluster analysis
        
        timeVector %time data for each intensity response
        rawData %raw intensity data without any processing
        correctedData %data with bleach correction applied
        relativeData %normalized intensity data
        filteredData %relative data with filtering applied
        interpolatedData %slot for possible interpolated data (not used now)
        baselineModel % baseline fitted model from bleach correction
        
        fitIndices % [fitStart, fitEnd] for the baseline correction
        startmaxIndices = [0, 0] % [startIdx, maxIdx]
        halfwayIndices = [0, 0] % [rise50idx, decay50idx]
        sparkInterval = [0, 0] % [peakStart, peakEnd] interval for Ca-spark peak detection
        highSparkPeaks % Indices for the Ca-spark maxima
        lowSparkPeaks % Indices for the Ca-spark minima
        
        calcData % [maxAmplitude, rise50, firstHalf, time2max, decay50, duration50]
        maxAmplitude % max relative amplitude
        rise50 % rise time from response start to 50% of the max intensity (s)
        time2max % time from response start to max intensity (s)
        firstHalf % time2max - rise50
        decay50 % decay time from max intensity to 50%
        duration50 % time between the 50% intensity points
        
        sparkTime  = 0; % duration of Ca-sparking
        sparkStartTime  = 0; % time value when the Ca-sparking starts
        avgSparkInterval  = 0; % average time between the Ca-spark peaks (max values)
        avgSparkAmplitude = 0; % average amplitude of the spark peaks
        maxSparkAmplitude = 0; % max amplitude of the spark peaks
        numberOfSparks  = 0; % total number of Ca-spark peaks in the sparking interval
        
        isAnalyzed = 0; %logical index whether the cell is analyzed
        isDiscarded = 0; %logical index for possible discarding
        isSkipped  = 0; %logical index for possible skipping
        isSparking = 0; % logical index whether the response has Ca-sparks
        
    end
    
    %% methods
    methods
        
        function [obj] = correctBleach(obj)
            
            % Takes the original raw intensity data and applies a
            % a fit to it on the user-given baseline interval. The function
            % then corrects the whole response data for bleaching based on
            % the fit, so that the baseline becomes horizontal. The method
            % is called from the analysisLoop.m.
            
            % Extract part of the baseline for the fit. Current fit uses
            % single-exponential function. See Matlab documentation for
            % "fit" for other fitting options if needed. 
            baselineFit = fit(obj.timeVector(obj.fitIndices(1):obj.fitIndices(2)), ...
                obj.rawData(obj.fitIndices(1):obj.fitIndices(2)), 'exp1');
            
            % calculate a model according to the fit
            obj.baselineModel = baselineFit.a.*exp(baselineFit.b.*obj.timeVector);
                
            % Start value for the corrected baseline (averaged due to noise).
            baselineStart = mean(obj.rawData(1:10));
            % Reference baseline for the correction
            baseVector = baselineStart*ones(length(obj.timeVector),1);
            % correct the data according to the model and the baseline
            difference = baseVector - obj.baselineModel;
            obj.correctedData = obj.rawData + difference;
            
            % calculate the relative intensity normalized by the baseline start value
            obj.relativeData = obj.correctedData ./ baseVector;
            
            % filter the relative data to smooth out noise
            obj.filteredData = smooth(obj.relativeData);
            
        end
        
        function [] = plotBleachCorrection(obj)
            
            % Method for plotting the bleach corrected data in comparison
            % to the original. Also shows the fitting interval and the
            % fitted model. The method is called from analysisLoop.m.
            
            % Calculate the baseline to be plotted for reference
            baseVector = mean(obj.rawData(1:10))*ones(length(obj.timeVector),1);
            
            % Plot the original intensity data, bleach corrected data,
            % baseline fitted model and reference baseline
            hold on
            plot(obj.timeVector, obj.rawData, 'b')
            plot(obj.timeVector(obj.fitIndices(1):obj.fitIndices(2)), ...
                obj.rawData(obj.fitIndices(1):obj.fitIndices(2)), 'r')
            plot(obj.timeVector, obj.baselineModel, 'k--')
            plot(obj.timeVector, obj.correctedData, 'g')
            plot(obj.timeVector, baseVector, 'k-.')
            hold off
            
            title('Corrected data', 'Interpreter', 'none')
            legend('original data', 'data used in fitting', 'fitted model',...
                'corrected data', 'baseline', 'Location', 'best')
            legend('boxoff')
            xlabel('Time [s]')
            ylabel('Intensity')
            
            correctedPlot = gcf;
            
        end
        
        function obj = analyzeData(obj, startId, whichPointsToAnalyze)
            
            % Analyzes the data that is fed from the analysisLoop.m and
            % saves the calculated data as properties of the
            % intensityResponse object.
            
            % if startId is empty, use the fit end point as a start value
            % for the intensity response
            if(isempty(startId) || startId == 0)
                startId = obj.fitIndices(2);
            end
            
            % Response start index
            obj.startmaxIndices(1) = startId;
            % Response start intensity value
            startIntensity = obj.filteredData(startId); 
            
            if(whichPointsToAnalyze(3))
                
                % If max value is to be analyzed, find the maximum value
                % and it's index
                [maxIntensity, obj.startmaxIndices(2)] = ...
                    max(obj.filteredData);
                  
                if obj.startmaxIndices(2) > length(obj.filteredData)
                    % For cases where the max index would exceed the length of
                    % the data vector
                    obj.startmaxIndices(2) = obj.startmaxIndices(end) - 2;
                end
                
                if obj.startmaxIndices(2) <= obj.startmaxIndices(1)
                    % If the max intensity appears before the starting
                    % point guess, move the starting point before the max
                    % index.
                    if obj.startmaxIndices(2) > 2
                        obj.startmaxIndices(1) = obj.startmaxIndices(2) - 2;
                    else
                        obj.startmaxIndices(1) = 1;
                    end
                end
                
            else
                % If max index is not to be analyzed, use a previously
                % calculated value
                maxIntensity = obj.filteredData(obj.startmaxIndices(2));
            end
            
            % Normalize the max intensity with the response start intensity
            % to get the amplitude
            obj.maxAmplitude = maxIntensity/startIntensity;
            
            % Calculate the halfway value
            halfwayValue = 0.5*(startIntensity + maxIntensity);
             
            % Pick the indices, where the intensity crosses the halfway for
            % the first time
            if(whichPointsToAnalyze(2))
                
                % Contains all crossings of the halfway value before the
                % maximum
                riseCrossings = findHalfway(obj, halfwayValue, 'rise');
                
                if isempty(riseCrossings)
                    % If no crossings are found, use the start index
                    obj.halfwayIndices(1) = obj.startmaxIndices(1);
                else
                    % If crossings are found, use one of the center ones
                    obj.halfwayIndices(1) = riseCrossings(round(median(1:1:length(riseCrossings))));
                end
            end
            
            if(whichPointsToAnalyze(4))
                
                % Contains all crossings of the halfway value after the
                % maximum                
                decayCrossings = findHalfway(obj, halfwayValue, 'decay');
                
                if isempty(decayCrossings)
                    % If no crossings are found, use the max index
                    obj.halfwayIndices(2) = obj.startmaxIndices(2);
                else
                    % If crossings are found, use one of the center ones
                    obj.halfwayIndices(2) = decayCrossings(round(median(1:1:length(decayCrossings))));
                end   
            end


            % Calculate the time variables and save them as intensityResponse
            % object properties
            obj.rise50 = obj.timeVector(obj.halfwayIndices(1)) - obj.timeVector(obj.startmaxIndices(1));
            obj.time2max = obj.timeVector(obj.startmaxIndices(2)) - obj.timeVector(obj.startmaxIndices(1));
            obj.firstHalf = obj.timeVector(obj.startmaxIndices(2)) - obj.timeVector(obj.halfwayIndices(1));
            obj.decay50 = obj.timeVector(obj.halfwayIndices(2)) - obj.timeVector(obj.startmaxIndices(2));
            obj.duration50 = obj.timeVector(obj.halfwayIndices(2)) - obj.timeVector(obj.halfwayIndices(1));
            
            % Change the object status to analyzed
            obj.isAnalyzed = 1;
            
        end
        
        function halfwayIndices = findHalfway(obj, treshold, riseOrDecay)
            
            % Finds and returns the indices corresponding to the treshold
            % value. If riseOrDecay is set to "rise", the algorithm seeks
            % for treshold crossings before the maximum, and after the
            % maximum if it is set to "decay".
            
            vectorIdx = 1;
            halfwayIndices = [];
            
            % Crossings for intensity rise
            if(strcmp(riseOrDecay, 'rise'))
                
                % Loop between start and max indices
                for idx = obj.startmaxIndices(1):obj.startmaxIndices(2)
                    
                    % If value at idx is less than treshold and value at
                    % idx+2 is over the treshold, the value at idx+1 is
                    % chosen as the crossing index
                    if obj.filteredData(idx) < treshold && obj.filteredData(idx+2) > treshold

                            halfwayIndices(vectorIdx) = idx+1;
                            % Switch to the next index at halfwayIndices
                            vectorIdx = vectorIdx+1;

                    end
                    
                end
                
            end
            
            % Crossings for intensity decay
            if(strcmp(riseOrDecay, 'decay'))
                
                if(length(obj.filteredData) - obj.startmaxIndices(2) <= 2)
                    
                    halfwayIndices(1) = length(obj.filteredData);
                    return;
                end
                
                % Loop between the max index and length of the data vector  
                for idx = obj.startmaxIndices(2):length(obj.filteredData)-2
                    
                    % If value at idx is more than treshold and value at
                    % idx+2 is under the treshold, the value at idx+1 is
                    % chosen as the crossing index
                    if obj.filteredData(idx) > treshold && obj.filteredData(idx+2) < treshold
                        
                        halfwayIndices(vectorIdx) = idx+1;
                        % Switch to the next index at halwayIndices
                        vectorIdx = vectorIdx+1;
                        
                    end
                    
                    % For cases where the decay doesn't fall below 50% the
                    % last index of the data is returned
                    if(idx == length(obj.filteredData)-2 && isempty(halfwayIndices))     
                       halfwayIndices(1) = length(obj.filteredData); 
                       return; 
                    end
                    
                end
                
            end
            
        end
        
        function [] = plotAnalyzedData(obj)
           
            % Plots the analyzed data marked with the calculated start, max
            % and halfway values
            
            time = obj.timeVector;
            responseBaseline = mean(obj.relativeData(1:10))*ones(length(time),1);
            halfwayValue = 0.5*(obj.filteredData(obj.startmaxIndices(1)) + obj.filteredData(obj.startmaxIndices(2)));
            halfwayVector = halfwayValue*ones(length(time),1);
            
            hold on
            plot(time, obj.filteredData, 'HandleVisibility', 'off')
            plot(time, responseBaseline, '--k')
            plot(time, halfwayVector, '-.r')
            plot(time(obj.startmaxIndices(1)), obj.filteredData(obj.startmaxIndices(1)), 'rx', 'LineWidth', 2)
            plot(time(obj.startmaxIndices(2)), obj.filteredData(obj.startmaxIndices(2)), 'kx', 'LineWidth', 2)
            plot(time(obj.halfwayIndices(1)), obj.filteredData(obj.halfwayIndices(1)), 'gx', 'LineWidth', 2)
            plot(time(obj.halfwayIndices(2)), obj.filteredData(obj.halfwayIndices(2)), 'yx', 'LineWidth', 2)
            plot(obj.timeVector(obj.highSparkPeaks), obj.filteredData(obj.highSparkPeaks), 'rv','MarkerFaceColor','b', 'MarkerSize', 4)
            %plot(obj.timeVector(obj.lowSparkPeaks), obj.filteredData(obj.lowSparkPeaks), 'rs','MarkerFaceColor','b', 'HandleVisibility', 'off')
            title('Analyzed data', 'Interpreter', 'none')
            legend('Baseline', 'Halfway value', 'Response start', 'Response maximum', 'Halfway (rise)', 'Halfway (decay)', 'Spark peaks', 'Location', 'best')
            legend('boxoff')
            xlabel('time [s]')
            ylabel('Normalized intensity')
            
            hold off
                  
        end
        
        function obj = calculateSparkData(obj, peakTimeInterval)
            
            % Calculates the intensity sparking data from the
            % peakTimeInterval chosen by the user in analysisLoop.m and
            % saves them as intensityResponse object properties
            
            % Mark the response to have sparking
            obj.isSparking = 1;
            % Change the peak time interval to index interval using the
            % data sampling interval
            peakIdxInterval = round(peakTimeInterval ./ obj.samplingInterval);
            % Save the interval as object properties
            obj.sparkInterval(1) = peakIdxInterval(1);
            obj.sparkInterval(2) = peakIdxInterval(2);
            
            % Find high and low peaks using the findpeaks function. See
            % Matlab documentation for details in adjusting its
            % sensitivity
            [~, highPeakIdx] = findpeaks(obj.filteredData(peakIdxInterval(1):peakIdxInterval(2)), 'MinPeakProminence', 0.01);
            [~, lowPeakIdx] = findpeaks(-obj.filteredData(peakIdxInterval(1):peakIdxInterval(2)), 'MinPeakProminence', 0.01);
            
            % Trim the peak vectors to same length for amplitude
            % calculation
            if(length(highPeakIdx) ~= length(lowPeakIdx) && highPeakIdx(end) > lowPeakIdx(end))
                highPeakIdx(end) = [];
            elseif(length(highPeakIdx) ~= length(lowPeakIdx) && highPeakIdx(end) < lowPeakIdx(end))
                lowPeakIdx(end) = [];
            end
            
            % Save high and low peak indices as object properties
            obj.highSparkPeaks = highPeakIdx + peakIdxInterval(1) - 1;
            obj.lowSparkPeaks = lowPeakIdx + peakIdxInterval(1) - 1;

            % Calculate and save the spark data as object properties
            obj.avgSparkInterval = mean(diff(obj.highSparkPeaks));
            obj.avgSparkAmplitude = mean(obj.filteredData(obj.highSparkPeaks) - obj.filteredData(obj.lowSparkPeaks)) + 1;
            obj.maxSparkAmplitude = max(obj.filteredData(obj.highSparkPeaks) - obj.filteredData(obj.lowSparkPeaks)) + 1;
            obj.sparkTime = obj.timeVector(obj.sparkInterval(2)) - obj.timeVector(obj.sparkInterval(1));
            obj.sparkStartTime = round(peakTimeInterval(1), 1);
            obj.numberOfSparks = length(obj.highSparkPeaks);
            
        end
    
    end

end