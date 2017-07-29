% Batch_PixelBasedPI

% Path should contain PixelBasedPI folder and JAABA folder. 

% Begin by clearing variables and closing figures. 
clear; close all; 

%% Describe prefix to use to find movie files
fileFinderToken = 'movie_Test*.ufmf'; 
%% Select folder in which to do batch processing on subfolders. 
startDir = pwd; % So we can start and end in the same place.

masterDir = uigetdir(); 
cd(masterDir); 
itemList = dir(); 
dirNames = {itemList.name}; 
dirNames = dirNames([itemList.isdir]);
dirNames = dirNames( cellfun(@(x) length(x)>4, dirNames) );

for dirIdx = 1:length(dirNames)
    cd(dirNames{dirIdx}); 
    pathname = pwd; 
    filenameList = dir(fileFinderToken); 
    for fileIdx = 1:length(filenameList)
        close all; % Close all figures that were generated previously.
        filename = filenameList(fileIdx).name; 
        disp('Filename:'); disp(filename); 
        disp('Pathname:'); disp(pathname); 
        PixelBasedPIOverTime_func(filename,pathname); 
    end
    cd(masterDir);  
end


