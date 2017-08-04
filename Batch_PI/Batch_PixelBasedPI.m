% Batch_PixelBasedPI

% Path should contain PixelBasedPI folder and JAABA folder. 

% Begin by clearing variables and closing figures. 
clear; close all; 

%% Describe prefix to use to find movie files
fileFinderToken = 'movie_*.ufmf'; 
%% Select folder in which to do batch processing on subfolders. 
startDir = pwd; % So we can start and end in the same place.

masterDir = uigetdir(); 
cd(masterDir); 
itemList = dir(); % Get list of possible subfolders
dirNames = {itemList.name}; 
dirNames = dirNames([itemList.isdir]);
dirNames = dirNames( cellfun(@(x) length(x)>4, dirNames) ); % Cleaned up list of subfolders

for dirIdx = 1:length(dirNames)
    cd(dirNames{dirIdx}); % Go into the specified subfolder
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

cd(startDir); % So we can start and end in the same place.
