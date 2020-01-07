% clusterAnalysis runs a clustering algorithm for the calculated values of
% an analyzed dataset. It first runs a principal component analysis to
% determine the paramters that cause the most variance in the data and then
% groups the responses accordsing to them. The script currently supports up
% to four groups and six grouping parameters, but it can be changed.


% editDatabase.m is used to load a single dataset from a database created 
% by readData.m and provide it's information
databaseInfo = editDatabase('load', 'single');
dataset = databaseInfo{1};
datasetName = databaseInfo{2};
caDatabase = databaseInfo{3};
databaseName = databaseInfo{4};

% Color coding for the cluster groups (each row corresponds one color)
groupColors =  [0        0.4470    0.7410;
                0.6350   0.0780    0.1840;
                0.9290   0.6940    0.1250;
                0        0.5000    0];

% Number of parameters            
nParameters = 6;
% Maximum standard deviation, values over this will be discarded from the
% principal component analysis
maxSD = 3;
[height, width] = size(dataset);
dataArray = zeros(height, nParameters);
discardedIdx = 1;
dataIdx = 1;
% Find max intensity value of the dataset (for plotting)
maxY = findMaxY(dataset);


for ROIidx = 1:width
    
    h = figure('units','normalized','outerposition',[0 0 1 1]);
    set(h,'DefaultAxesColorOrder',groupColors);
    % Exclude empty cells
    notEmpty = find(~cellfun(@isempty,dataset(:,ROIidx)));
    height = length(notEmpty);
    
    for cellIdx = 1:height   
        
        if(~dataset{cellIdx, ROIidx}.isDiscarded)
            
            % If the data is not discarded, the values to be analyzed are
            % read into the dataArray
            
            dataArray(cellIdx, 1) = dataset{cellIdx, ROIidx}.maxAmplitude;
            dataArray(cellIdx, 2) = dataset{cellIdx, ROIidx}.rise50;
            dataArray(cellIdx, 3) = dataset{cellIdx, ROIidx}.time2max;
            dataArray(cellIdx, 4) = dataset{cellIdx, ROIidx}.firstHalf;
            dataArray(cellIdx, 5) = dataset{cellIdx, ROIidx}.decay50;
            dataArray(cellIdx, 6) = dataset{cellIdx, ROIidx}.duration50;
            
        else
            
            % If the data is discarded, mark the parameters as zero and
            % save the curve in the discardedCurves array (for plotting
            % later)
            dataArray(cellIdx, 1) = NaN;
            dataArray(cellIdx, 2) = NaN;
            dataArray(cellIdx, 3) = NaN;
            dataArray(cellIdx, 4) = NaN;
            dataArray(cellIdx, 5) = NaN;
            dataArray(cellIdx, 6) = NaN;
            
            discardedCurves{discardedIdx} = dataset{cellIdx, ROIidx};
            discardedIdx = discardedIdx + 1;
            
        end
        
    end
    
    % Leave out rows of discarded cells from the analysis
    toKeep = ~isnan(dataArray(:,1));
    dataArray = dataArray(toKeep,:);
    
    % Normalize each time variable with the first column (amplitude) to
    % find the true differences independent of the amplitude
    maxAmplitude = dataArray(:,1);
    rise50 = dataArray(:,2)./dataArray(:,1);
    time2max = dataArray(:,3)./dataArray(:,1);
    firstHalf = dataArray(:,4)./dataArray(:,1);
    decay50 = dataArray(:,5)./dataArray(:,1);
    duration50 = dataArray(:,6)./dataArray(:,1);
    
    % convert the array into a table
    scaledData = table(maxAmplitude, rise50, time2max, firstHalf, decay50, duration50);
    
    % Normalization with z-score
    func = @(x) zscore(x);
    Z = varfun(func, scaledData);
    
    % Rule out outliers from the data
    relevantZ = abs(Z{:,:}) <= maxSD;
    relevantZ = ~any(relevantZ(:,:) == 0, 2);
    Z = Z(relevantZ,:);
    Z.Properties.VariableNames = scaledData.Properties.VariableNames;
    
    
    %% Principal component analysis (reduce data dimensions)
    % See Matlab documentation for pca for more info.
    % Convert the data into new coordinates to find out which ones
    % contribute the most to the variance.
    [coeff,Y,latent,tsquared,pexp] = pca(Z{:,:});
    
    %% Hierarchical clustering
    % See Matlab documentation for cluster for more info.
    % The clustering uses the data in the new coordinate space obtained
    % from the pca.
    
    symbols = 'oooo';
    links = linkage(Y, 'ward');
    distances = pdist(Y);
    c = cophenet(links, distances);
    clustev = evalclusters(Y,'linkage','silhouette','KList',1:4);
    nGroups = clustev.OptimalK;
    hgrp = cluster(links, 'maxclust', nGroups);
    
    % Plot the results of the pca analysis as a pareto chart.
    ax1 = subplot(2,4,1, 'align');
    varNames = {'pc1', 'pc2', 'pc3', 'pc4', 'pc5', 'pc6', 'pc7'};
    pareto(pexp, varNames)
    title('Best principal components')
    
    % Scatter plots of three different parameter spaces from the three best
    % principal components.
    
    % Scatter 1
    ax2 = subplot(2,4,2, 'align');
    gscatter(Y(:,1),Y(:,2),hgrp, groupColors(1:nGroups,:), symbols(1:nGroups))
    title('pc1,pc2')
    xlabel(['pc1 (', num2str(round(pexp(1))), '%)'])
    ylabel(['pc2 (', num2str(round(pexp(2))), '%)'])
    
    % Scatter 2
    ax3 = subplot(2,4,3, 'align');
    gscatter(Y(:,2),Y(:,3),hgrp, groupColors(1:nGroups,:), symbols(1:nGroups))
    title('pc2,pc3')
    xlabel(['pc2 (', num2str(round(pexp(2))), '%)'])
    ylabel(['pc3 (', num2str(round(pexp(3))), '%)'])
    
    % Scatter 3
    ax4 = subplot(2,4,4, 'align');
    gscatter(Y(:,1),Y(:,3),hgrp, groupColors(1:nGroups,:), symbols(1:nGroups))
    title('pc1,pc3')
    xlabel(['pc1 (', num2str(round(pexp(1))), '%)'])
    ylabel(['pc3 (', num2str(round(pexp(3))), '%)'])
    
    % Silhouette chart (clustering algorithm aims to minimize the
    % silhouette values of each cluster)
    ax5 = subplot(2,4,5, 'align');
    silhouette(Y, hgrp);
    title('Cluster silhouettes')
    
    % Heatmap showing the effect of the original parameters to the
    % principal components
    ax6 = subplot(2,4,6, 'align');
    imagesc(abs(coeff(:,1:3)))
    ax6.XTick = 1:3;
    ax6.XTickLabel = {'pc1', 'pc2', 'pc3'};
    ax6.YTickLabel = Z.Properties.VariableNames;
    colorbar('southoutside')
    ytickangle(45)
    title('Effect of original variables to pcs')
    
    % Plot showing the differences in each group's original parameters.
    ax7 = subplot(2,4,7, 'align'  );
    parallelcoords(Z{:,:},'Group', hgrp, 'labels', Z.Properties.VariableNames, 'quantile', 0.25)
    title('Original data variables')
    ylabel('Z-score')
    xtickangle(45)
    
    % Dendrogram showing the linkages used for clustering.
    ax8 = subplot(2,4,8, 'align'  );
    dendrogram(links)
    title('Dendrogram')
    xtickangle(60)
    
    suptitle([datasetName{1},' ROI ', num2str(ROIidx),' Hierarchical clustering (Ntot = ', num2str(length(hgrp)),')'])
    % Save the clusterinfo figure to the current folder
    savefig([datasetName{1},'_clusterInfo_ROI', num2str(ROIidx),'.fig'])
    
    %% Plot the grouped data
    
    h2 = figure('units','normalized','outerposition',[0 0.2 1 0.6]);
    
    indices = cell(nGroups,1);
    curves = cell(nGroups,1);
    coords = cell(nGroups,1);
    
    for groupIdx = 1:nGroups
        
        % Indices of the original cells corresponding
        % to the current group in the loop.
        indices{groupIdx} = hgrp == groupIdx;
        
        % Match the actual curves to the indices.
        curves{groupIdx, 1} = dataset(toKeep, ROIidx);
        curves{groupIdx, 1} = curves{groupIdx, 1}(relevantZ, 1);
        curves{groupIdx, 1} = curves{groupIdx, 1}(indices{groupIdx, 1},:);
        
         subplot(1,4,groupIdx, 'align')
        [nCellsInGroup, ~] = size(curves{groupIdx, 1});
        
        % Calculate the median curve
        for mId1 = 1:length(curves{groupIdx, 1}{1,1}.relativeData)
            for mId2 = 1:nCellsInGroup
                intArray(mId1,mId2) = curves{groupIdx, 1}{mId2,1}.relativeData(mId1);
            end
        end
        
        medianCurve{groupIdx} = median(intArray,2);
        
        % Plot all responses of the group in question
        for r = 1:nCellsInGroup
            
            hold on
            box on
            plot(curves{groupIdx}{r,1}.timeVector,curves{groupIdx}{r,1}.relativeData, 'Color', groupColors(groupIdx,:), 'HandleVisibility', 'off')
            ylim([0.9 maxY+0.1*(maxY-0.9)])
            xlength = length(curves{groupIdx}{r,1}.timeVector)*curves{groupIdx}{r,1}.samplingInterval;
            xlim([0 1.1*xlength])
            ylabel('Relative intensity')
            xlabel('Time (s)')
            titleString2 = ['ROI',num2str(ROIidx),' group ', num2str(groupIdx), ' (N = ', num2str(nCellsInGroup), ')'];
            title(titleString2)
            
            % Save group number to the properties of the intensityResponse
            % object
            origROI = curves{groupIdx}{r,1}.indices(1);
            origCell = curves{groupIdx}{r,1}.indices(2);
            dataset{origCell, origROI}.groupNumber = groupIdx;
            
        end
        
        % Plot the median curve on top of the group curves
        plot(curves{1,1}{1,1}.timeVector, medianCurve{groupIdx},'Color', [0 0 0], 'LineWidth', 1)
        legend('Median curve')
        legend('boxoff')
        hold off 
        
        % Reset intArray
        intArray = [];

    end
    
    suptitle([datasetName{1},' ROI ', num2str(ROIidx),' Hierarchical clustering (Ntot = ', num2str(length(hgrp)),')'])
    % Save the grouping figure to the current folder
    savefig([datasetName{1},'_grouping_ROI', num2str(ROIidx),'.fig'])
    
    % Reset dataArray
    dataArray = zeros(height, nParameters);
    
end

% Save the dataset to the database with the new grouping info
caDatabase.(datasetName{1}) = dataset;
save(databaseName, 'caDatabase');
clear

function maxY = findMaxY(data)

% Loops through the given dataset and finds the maximum relative intensity

maxY = 0;
[~, width] = size(data);

    for ROIidx = 1:width

        notEmpty = find(~cellfun(@isempty,data(:,ROIidx)));
        height = length(notEmpty);
        
        for cellIdx = 1:height
           
            if max(data{cellIdx, ROIidx}.relativeData) > maxY
                
                maxY = max(data{cellIdx, ROIidx}.relativeData);
                
            end
            
        end

    end

end
