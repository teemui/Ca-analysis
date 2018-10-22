%% ca_response
% Creates a ca_response object for each time-intensity data pair 
% (e.g. individual cell) with properties listed below. The methods
% contain the ca_analysis function, which calculates the data variables
% for each ca_response object.

classdef ca_response

    properties
        
        timeVector %time data for each intensity response
        rawData %raw intensity data without any processing
        correctedData %data with bleach correction applied
        relativeData %normalized intensity data
        filteredData %relative data with filtering applied
        interpolatedData %slot for possible interpolated data (not used now)
        ATPtype %ATP stimulus type (e.g. first or second ATP stimulus)
        surface %cell culture surface
        timepoint %timepoint for Ca-imaging
        cellLine %cell line used
        ROI %ROI number
        maxAmplitude %max relative amplitude
        rise50 %rise time to halfway intensity
        time2max %rise time to max intensity
        decay50 %decay time from max to halfway
        duration50 %duration between 50% intensity points
        startFit %index for the start of fitting for bleach correction
        startId %index for the start of response
        idx50_1 %index for first halfway point (rise50)
        idx50_2 %index for second halfway point (decay50)
        maxId %index for maximum intensity
        isDiscarded %logical index for possible discarding
        isSkipped %logical index for possible skipping
        
    end
    
    %% methods
    methods
        
        %% ca_analysis
        % The function performs bleach correction, calculates the
        % amplitude and time variables from each intensity curve and adds 
        % them as properties to the ca_response object. The function is
        % called from the readCaData function in readData.m.
        function obj = ca_analysis(obj,ROI,cell)
            %% Bleach correction
            
            % Exctract raw data from the ca_response object.
            time = obj.timeVector;
            A = obj.rawData;
            ansId = 0;
            
            % Pick the interval used in searching for the minimum before the response.
            if ~isempty(obj.startId) == 1
                
                %In case the object already has fit data
                bounds = [obj.startFit, obj.startId];
                
            else
                
                %Adjust if needed
                bounds = [1, 400];
                
            end
            
            counter = 1;
            
            while ansId == 0
                
                B = A(bounds(1):bounds(2));
                
                if counter > 1 || ~isempty(obj.startId) == 1
                    
                    %In case the object already has a start index
                    obj.startId = bounds(2);
                              
                else
                    
                    %Finds the minimum value between fit start and end points
                    [~, obj.startId] = min(B);
                    
                    if obj.startId < 100
                        
                        %If the index is too close to start of the data,
                        %adds a certain amount of data points
                        obj.startId = obj.startId + 200;
                        
                    end
                    
                    obj.startId = round((obj.startId + (bounds(1)-1)));
                    
                end
                
                % Fit an exp model to the baseline and calculate corrected data.
                data2fit = A((bounds(1):obj.startId));
                fittedData = fit(time(bounds(1):obj.startId), data2fit, 'exp1');
                model = fittedData.a.*exp(fittedData.b.*time);
                baseline = mean(A(1:10)); % Start value for the corrected baseline.
                basevec = baseline*ones(length(time));
                difference = baseline - model;
                correctedA = A + difference;
                
                % Plot the original and corrected data
                figure('units','normalized','outerposition',[0 0 1 1]);
                subplot(1,2,1)
                hold on
                plot(time, A, 'b')
                plot(time(bounds(1):obj.startId), data2fit, 'r')
                plot(time, model, 'k--')
                plot(time, correctedA, 'g')
                plot(time, basevec, 'k-.')
                hold off
                
                title('Corrected data', 'Interpreter', 'none')
                legend('original data', 'data used in fitting', 'fitted model',...
                    'corrected data', 'baseline')
                xlabel('Time (s)')
                ylabel('Intensity')

                correctAnswer = 0;
                
                % Ask for user input and correction for the fit boundaries
                while correctAnswer == 0
                    prompt = 'Accept correction (y),skip correction (s),\nselect new boundaries (n) or discard response (d): ';
                    answer = input(prompt, 's');
                    
                    if strcmp(answer, 'y')
                        
                        obj.correctedData = correctedA;
                        obj.startFit = bounds(1);
                        bounds(2) = obj.startId; % The fit end point is taken 
                        % as the response start point (can be changed later by the user)
                        ansId = 1;
                        correctAnswer = 1;
                        
                    elseif strcmp(answer, 'n')
                        
                        % In case of 'n', give user the possibility to
                        % select new boundaries graphically with the mouse
                        disp('Select the boundaries for fitting with the mouse cursor.')
                        [bounds, ~] = ginput(2);
                        bounds = round(2*bounds); %Convert time data to index
                        counter = counter + 1;
                        correctAnswer = 1;
                        close
                        
                    elseif strcmp(answer, 's')
                        
                        % Possibility to skip bleach correction, e.g. if
                        % the baseline is too fluctuating for fitting.
                        obj.correctedData = obj.rawData;
                        bounds(2) = obj.startId;
                        data2fit = A(bounds(1):bounds(2));
                        obj.isSkipped = 1;
                        correctAnswer = 1;
                        ansId = 1;
                        
                    elseif strcmp(answer, 'd')
                        
                        % Possibility to discard the response if the data
                        % is not analyzable.
                        obj.correctedData = correctedA;
                        obj.isDiscarded = 1;
                        return
                        
                    else
                        
                        disp('Please enter y (yes), n (no), s (skip) or d (discard).');
                        
                    end
                    
                end
                
            end
            
            %% Calculate curve parameters
            
            % Calculate relative intensity and filter out noise
            obj.relativeData = obj.correctedData/mean(obj.correctedData(1:10));
            obj.filteredData = smooth(obj.relativeData, 'moving');
            
            % Find the points that are used in the calculations in case
            % the object parameters are empty.
            if isempty(obj.maxId) == 1
                
                [~, obj.maxId] = max(obj.filteredData); 
                halfway = (obj.filteredData(obj.maxId)+obj.filteredData(obj.startId))/2;
                % Find the points where the curve crosses the halfway value
                % (see findcrossings.m)
                crossings1 = findcrossings(obj.filteredData(obj.startId:obj.maxId),halfway);
                crossings2 = findcrossings(obj.filteredData(obj.maxId:end),halfway);
                % The first crossings are taken as the halfway points. Can
                % be changed e.g. to last crossings etc.
                obj.idx50_1 = crossings1(1) + obj.startId;
                obj.idx50_2 = crossings2(1) + obj.maxId;
                
                % Calculate the amplitude and time parameters
                obj.maxAmplitude = obj.filteredData(obj.maxId) - obj.filteredData(obj.startId) + 1;
                obj.time2max = time(obj.maxId) - time(obj.startId);
                obj.rise50 = time(obj.idx50_1) - time(obj.startId);
                obj.decay50 = time(obj.idx50_2) - time(obj.maxId);
                obj.duration50 = time(obj.idx50_2) - time(obj.idx50_1);
                
            end
           
            %% Plot the calculated parameters
            
            baseline2 = mean(obj.filteredData(1:10));
            basevec2 = baseline2*ones(length(time),1);
            halfway = (obj.filteredData(obj.maxId)+obj.filteredData(obj.startId))/2;
            halfvec = halfway*ones(length(time));
            
            subplot(1,2,2)
            hold on
            plot(time, obj.filteredData, 'HandleVisibility', 'off')
            plot(time, basevec2, 'HandleVisibility', 'off')
            plot(time, halfvec, 'HandleVisibility', 'off')
            plot(time(obj.startId), obj.filteredData(obj.startId), 'rx', 'LineWidth', 2)
            plot(time(obj.maxId), obj.filteredData(obj.maxId), 'kx', 'LineWidth', 2)
            plot(time(obj.idx50_1), obj.filteredData(obj.idx50_1), 'gx', 'LineWidth', 2)
            
            
            % In case the intensity doesn't fall back under 50%, the second halfway point 
            % is plotted in yellow (adjust the tolerance as needed) and decay50 and duration50
            % are marked as NaN, as they can't be calculated. This can happen also 
            % when the 50% points are too far apart in intensity, due to rapid changes in 
            % intensity and too small sampling interval.    
            if abs(obj.filteredData(obj.idx50_1) - obj.filteredData(obj.idx50_2)) > 0.03
                
                obj.decay50 = NaN;
                obj.duration50 = NaN;
                plot(time(obj.idx50_2), obj.filteredData(obj.idx50_2), 'yx', 'LineWidth', 2)
                
            else
                
                plot(time(obj.idx50_2), obj.filteredData(obj.idx50_2), 'cx', 'LineWidth', 2)
                
            end
            
            title('Analyzed data', 'Interpreter', 'none')
            legend('Response start point', 'Curve maximum', 'Halfway (rise)', 'Halfway (decay)')
            xlabel('time (s)')
            ylabel('Relative intensity')
            
            hold off
            
            suptitle([obj.cellLine, ' ', obj.surface, ' ', obj.timepoint,' ROI ', num2str(ROI), ' cell ', num2str(cell)])
            
            correctAnswer2 = 0;

            while correctAnswer2 == 0
                
                % Ask user input whether the calculated points are correct.
                prompt = 'Accept calculated points (y/n): ';
                answer = input(prompt, 's');
                
                if strcmp(answer, 'y')
                    
                    obj.correctedData = correctedA;
                    correctAnswer2 = 1;
                    
                elseif strcmp(answer, 'n')
                    
                    % In case corrections are needed. Points are selected
                    % in order (start, 50% rise, maximum, 50% decay) with
                    % mouse (left click -> new value, right click (or any 
                    % other input) -> keep old value)
                    disp('Select the points with the mouse cursor in the following order: start, halfway (rise), maximum, halfway(decay)')
                    [points, ~, button] = ginput(4);
                    
                    if button(1) == 1
                        obj.startId = round(2*points(1));
                    end
                    
                    if button(2) == 1
                        obj.idx50_1 = round(2*points(2));
                    end
                    
                    if button(3) == 1
                        obj.maxId = round(2*points(3));
                    end
                    
                    if button(4) == 1
                        obj.idx50_2 = round(2*points(4));
                    end
                    
                    % Calculate new points with the user input
                    obj.maxAmplitude = obj.filteredData(obj.maxId) - obj.filteredData(obj.startId) + 1;
                    obj.time2max = time(obj.maxId) - time(obj.startId);
                    obj.rise50 = time(obj.idx50_1) - time(obj.startId);
                    obj.decay50 = time(obj.idx50_2) - time(obj.maxId);
                    obj.duration50 = time(obj.idx50_2) - time(obj.idx50_1);
                    
                    halfway = (obj.filteredData(obj.maxId)+obj.filteredData(obj.startId))/2;
                    halfvec = halfway*ones(length(time));
                    
                    % Close the old figure and draw a new one
                    close
                    
                    figure('units','normalized','outerposition',[0 0 1 1]);
                    subplot(1,2,1)
                    hold on
                    plot(time, A, 'b')
                    plot(time(bounds(1):bounds(2)), data2fit, 'r')
                    plot(time, model, 'k--')
                    plot(time, correctedA, 'g')
                    plot(time, basevec, 'k-.')
                    
                    
                    title('Corrected data', 'Interpreter', 'none')
                    legend('original data', 'data used in fitting', 'fitted model', 'corrected data', 'baseline')
                    xlabel('Time (s)')
                    ylabel('Intensity')
                    hold off
                    
                    subplot(1,2,2)
                    hold on
                    plot(time, obj.filteredData, 'HandleVisibility', 'off')
                    plot(time, basevec2, 'HandleVisibility', 'off')
                    plot(time, halfvec, 'HandleVisibility', 'off')
                    plot(time(obj.startId), obj.filteredData(obj.startId), 'xr', 'LineWidth', 2)
                    plot(time(obj.maxId), obj.filteredData(obj.maxId), 'xk', 'LineWidth', 2)
                    plot(time(obj.idx50_1), obj.filteredData(obj.idx50_1), 'xg', 'LineWidth', 2)
                    
                    % In case the intensity doesn't fall back under 50%, the second halfway point 
                    % is plotted in yellow (adjust the tolerance as needed) and decay50 and duration50
                    % are marked as NaN, as they can't be calculated. This can happen also 
                    % when the 50% points are too far apart in intensity, due to rapid changes in 
                    % intensity and too small sampling interval.   
                    if abs(obj.filteredData(obj.idx50_1) - obj.filteredData(obj.idx50_2)) > 0.03
                        
                        obj.decay50 = NaN;
                        obj.duration50 = NaN;
                        plot(time(obj.idx50_2), obj.filteredData(obj.idx50_2), 'xy', 'LineWidth', 2)
                        
                    else
                        
                        plot(time(obj.idx50_2), obj.filteredData(obj.idx50_2), 'xc', 'LineWidth', 2)
                        
                    end
                    
                    title('Analyzed data', 'Interpreter', 'none')
                    legend('Response start point', 'Curve maximum', 'Halfway (rise)', 'Halfway (decay)')
                    xlabel('Time (s)')
                    ylabel('Relative intensity')
                    
                    hold off
                    
                    suptitle([obj.cellLine, ' ', obj.surface, ' ', obj.timepoint,' ROI ', num2str(ROI), ' cell ', num2str(cell)])
                    
                else
                    
                    disp('Please enter y or n.');
                    
                end
                
            end
            
            close
            
        end

    end
 
end