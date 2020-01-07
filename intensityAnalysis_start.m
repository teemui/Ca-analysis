% Master file for intensity analysis that starts the program and runs the
% main menu. 

clc

while(true)
   
    mainMenuResponse = menu('INTENSITY ANALYSIS - MAIN MENU',...
        'Read data from Excel',...
        'Analyze intensity data',...
        'Browse or plot response curves',...
        'Cluster analysis',...
        'Location data',...
        'Statistical visualizations',...
        'Exit');

    if(mainMenuResponse == 1)
        
        % Data reading block, used for importing excel data.
        clc
        readData
        continue
        
    elseif(mainMenuResponse == 2)
        
        % Analysis block that runs the intensity analysis.
        clc
        analysisLoop
        continue
        
    
    elseif(mainMenuResponse == 3)
        
        % Browsing block, used for viewing already analyzed data.
        clc
        curveBrowser
        continue        
    
    elseif(mainMenuResponse == 4)
        
        % Cluster analysis block, for running grouping algorithms for
        % analyzed data.
        clc
        clusterAnalysis
        continue
    
    
    elseif(mainMenuResponse == 5)
        
        % Location block, used for adding locations of the grouped
        % responses to the original image.
        clc
        plotLocationData
        clc
    
    elseif(mainMenuResponse == 6)
        
        % Block for making scatter and box plot of the analyzed data.
        clc
        statisticsBlock
        clc
    
    elseif(mainMenuResponse == 7)
        
        break;
        
    end

end

clc
clear