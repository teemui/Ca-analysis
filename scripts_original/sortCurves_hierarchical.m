%% sortCurves_hierarchical
% The script collects the data from the given ROI's cellData array and uses
% principal component analysis and hierarchical clustering to obtain groupings 
% of the intensity responses. The time parameters are normalized with the 
% response amplitude. The script calls the findCenterCurves functions located 
% at the bottom of the file, which finds the curve that has parameters closest 
% to the group averages.
%
% User has to navigate into the folder containing the mat-file with the 
% cellData array. The script saves the groupings as well as analytical 
% information of each ROI as .fig and .png (as default).
% 


clear

%% Load file info
mat = dir('*.mat');
load(mat.name)
str = pwd;
[~,pname] = fileparts(str);
nameidx = strfind(str, '\');
tp = str(nameidx(end-1)+1:nameidx(end)-1); % Timepoint name from the filename

names = fieldnames(allSheets); % ROI names
names2 = {'maxAmplitude', 'rise50', 'time2max', 'decay50', 'duration50'};
co = [0    0.4470    0.7410;
    0.6350    0.0780    0.1840;
    0.9290    0.6940    0.1250;
    0    0.5000         0]; % colors for the grouping plots

[q, p] = size(cellData);
nCells = 0; % Cell counter, to be displayed in the plots.

for m = 1:p
    %% Pick data from cellData
    array = zeros(5, q);
    h = figure('units','normalized','outerposition',[0 0 1 1]);
    set(h,'DefaultAxesColorOrder',co);
    
    for r = 1:q
        
        if isempty(cellData{r,m}) == 1
            
            % If the cell object is empty, mark all parameters as zero.
            array(1:5,r) = [0;0;0;0;0];
            
        elseif cellData{r,m}.isDiscarded == 1 || isempty(cellData{r,m}.maxAmplitude) == 1
            
            % If the data is discarded, mark all parameters as zero.
            array(1:5,r) = [0;0;0;0;0];
            
        else
            % Extract the parameters to an array.
            array(1,r) = cellData{r,m}.(names2{1});
            array(2,r) = cellData{r,m}.(names2{2});
            array(3,r) = cellData{r,m}.(names2{3});
            array(4,r) = cellData{r,m}.(names2{4});
            array(5,r) = cellData{r,m}.(names2{5});
            
            nCells = nCells + 1;
            
        end
        
        
    end
    
    data = array';
    toKeep = data(:,5) > 0; % Leave out the data marked as zero (empty and discarded cells).
    data = data(toKeep, :);
    data(:,6) = bsxfun(@minus, data(:,3), data(:,2)); %time2max-rise50, to
    maxAmplitude = data(:,1);                         %describe the left side of the peak
    % Normalize each time variable with the first column (amplitude)
    tmax = data(:,2)./data(:,1);
    rise50 = data(:,3)./data(:,1);
    decay50 = data(:,4)./data(:,1);
    duration50 = data(:,5)./data(:,1);
    tmaxRise50 = data(:,6)./data(:,1);
    % convert the array into a table
    scaledData = table(maxAmplitude, tmax, rise50, duration50, tmaxRise50, decay50);
    % Normalization with z-score
    func = @(x) zscore(x);
    Z = varfun(func, scaledData);
    % Rule out outliers over 4 SDs from the means.
    relevantZ = abs(Z{:,:}) <= 4;
    relevantZ = ~any(relevantZ(:,:) == 0, 2);
    Z = Z(relevantZ,:);
    Z.Properties.VariableNames = scaledData.Properties.VariableNames;
    
    colorlist = 'brgk';
    symbols = 'oooo';
    
    %% Principal component analysis (reduce data dimensions)
    % See Matlab documentation for pca for more info.
    % Convert the data into new coordinates to find out which ones
    % contribute the most to the variance.
    [coeff,Y,latent,tsquared,pexp] = pca(Z{:,:});
    
    
    %% Hierarchical clustering
    % See Matlab documentation for cluster for more info.
    
    % The clustering uses the data in the new coordinate space obtained
    % from the pca.
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
    gscatter(Y(:,1),Y(:,2),hgrp, co(1:nGroups,:), symbols(1:nGroups))
    title('pc1,pc2')
    xlabel(['pc1 (', num2str(round(pexp(1))), '%)'])
    ylabel(['pc2 (', num2str(round(pexp(2))), '%)'])
    
    % Scatter 2
    ax3 = subplot(2,4,3, 'align');
    gscatter(Y(:,2),Y(:,3),hgrp, co(1:nGroups,:), symbols(1:nGroups))
    title('pc2,pc3')
    xlabel(['pc2 (', num2str(round(pexp(2))), '%)'])
    ylabel(['pc3 (', num2str(round(pexp(3))), '%)'])
    
    % Scatter 3
    ax4 = subplot(2,4,4, 'align');
    gscatter(Y(:,1),Y(:,3),hgrp, co(1:nGroups,:), symbols(1:nGroups))
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
    
    suptitle([pname(8:end-9),' ',tp,' ','Hierarchical clustering (N_{tot} = ', num2str(length(hgrp)),')'])
    
    % Save the analytics plots to the current folder
    filename1 = [pname(8:end-9),'-',tp,'-','ROI',num2str(m),'-analytics'];
    savefig([filename1,'.fig'])
    saveas(gcf,[filename1,'.png'])
    
    
    %% Plot the grouped data
    
    h2 = figure('units','normalized','outerposition',[0 0.2 1 0.6]);
    
    indices = cell(nGroups,1);
    curves = cell(nGroups,1);
    
    for p = 1:nGroups
        
        % Indices of the original cells corresponding
        % to the current group in the loop.
        indices{p} = hgrp == p;
        
        % Match the actual curves to the indices.
        curves{p} = cellData(toKeep == 1,m);
        curves{p} = curves{p}(indices{p},:);
        
        subplot(1,4,p, 'align')
        [w, ~] = size(curves{p});
        % Find the best curve to describe the group averages. (See the
        % function below).
        bestCurveIdx = findCenterCurves(hgrp, Z{:,:}, p);
        bestCurve = curves{p}(bestCurveIdx(1),1);
        
        x = 1;
        
        while isempty(curves{p,1}{bestCurveIdx(x),1}.relativeData) == 1
            
            bestCurve = curves{p,1}{bestCurveIdx(x+1),1};
            x = x+1;
            
        end
        
        % Loop through and plot all the curves in the current group.
        for r = 1:w
            
            hold on
            box on
            plot(curves{p}{r,1}.timeVector,curves{p}{r,1}.relativeData, 'Color', co(p,:))
            ylim([0.9 1.9])
            xlim([0 600])
            ylabel('Relative intensity')
            xlabel('Time (s)')
            titleString1 = [tp,' ',pname(8:end-9)];
            titleString2 = ['ROI',num2str(m),' group ', num2str(p), ' (N = ', num2str(w), ')'];
            title({titleString1,titleString2})
            
        end
        
        % The best curve plotted in black
        plot(bestCurve{1,1}.timeVector, bestCurve{1,1}.relativeData, 'Color', [0 0 0], 'LineWidth', 1)
        hold off
        
    end
    
    % Save the grouping plot to the current folder.
    filename2 = [pname(8:end-9),'-',tp,'-','ROI',num2str(m)];
    savefig([filename2,'.fig'])
    saveas(gcf,[filename2,'.png'])
    clear('curves')
    
end

%% findCenterCurves
function [sortedIdx] = findCenterCurves(groups, coordinates, groupnumber)

% Finds the curve that is closest to the average values of the given group.
% Inputs: groups = the grouping produced by teh clustering algorithm
%         coordinates = the original grouping parameters
%         groupnumber = the current group number
% Returns a vector with the indices of the curves in ascending order of
% distance to the group averages.

coordIdx = groups == groupnumber; % The indices for current group's parameters.
group = coordinates(coordIdx,1:6); % The parameters for the current group.
avgCoordintates = mean(group,1, 'omitnan'); %#ok<*AGROW>
[h,~] = size(group);

for id2 = 1:h
    
    % For each group curve, calculate the distance to the group averages.
    dist(id2) = sqrt((avgCoordintates(1)-group(id2,1))^2+(avgCoordintates(2)-group(id2,2))^2 ...
        +(avgCoordintates(3)-group(id2,3))^2+(avgCoordintates(4)-group(id2,4))^2+...
        (avgCoordintates(5)-group(id2,5))^2 +(avgCoordintates(6)-group(id2,6))^2);
    
end

[~, sortedIdx] = sort(dist); % The indices of the best curves in ascending order.

end


