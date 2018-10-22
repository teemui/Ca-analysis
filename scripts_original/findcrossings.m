%% findCrossings
% Finds the data points, where the data vector crosses the treshold value.
% Gets inputs (data vector and treshold value) from the ca_response method 
% ca_analysis. The function is called from the ca_analysis in
% ca_response.m and takes the data vector and the treshold value as inputs.
% The output is a vector of indices of the data vector, where the crossings
% are located.

function [crossVector] = findcrossings(data, treshold)

idx2 = 1; % The output vector index

if length(data) < 3
    
    % For cases, where the data vector is only one or two data points.
    crossVector(idx2) = min(data);
    
    return
    
end

for idx = 1:length(data)-2
    
    if data(idx) < treshold && data(idx+2) > treshold
        
        % Crossings for intensity rise
        crossVector(idx2) = idx+1;
        idx2 = idx2+1;
        
    elseif data(idx) > treshold && data(idx+2) < treshold
        
        % Crossings for intensity decrease
        crossVector(idx2) = idx+1;     
        idx2 = idx2+1;
        
    else
        
        % For cases, where the intensity doesn't fall below 50% and the
        % loop reaches the end of the vector.
        [~, crossVector(idx2)] = min(data);
        crossVector(idx2) = crossVector(idx2) - 1;

    end
    
end