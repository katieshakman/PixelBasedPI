% PlotPIsTogether

clear; close all; 

%% Describe prefix to use to find PI data files
fileFinderToken = 'OdorLightPattern1_*PI.mat'; % e.g. 'movie_*.mat'

%% Specify plot parameters
yspecs = [-1 1]; 
xLabel = 'Frames'; 
yLabel = 'PI'; 
%% Select folder in which to do batch processing on subfolders. 
startDir = pwd; % So we can start and end in the same place.

masterDir = uigetdir(); 
cd(masterDir); 
itemList = dir(); % Get list of possible subfolders
dirNames = {itemList.name}; 
dirNames = dirNames([itemList.isdir]);
dirNames = dirNames( cellfun(@(x) length(x)>4, dirNames) ); % Cleaned up list of subfolders
 
fig = figure;
xdat = [];
ydat = []; 
plot(1,1); 
hold on; 
for dirIdx = 1:length(dirNames)
    cd(dirNames{dirIdx}); % Go into the specified subfolder
    pathname = pwd; 
    filenameList = dir(fileFinderToken); 
    for fileIdx = 1:length(filenameList)
        filename = filenameList(fileIdx).name; 
        disp('Filename:'); disp(filename); 
        disp('Pathname:'); disp(pathname); 
        load(filename); 
        xdat = PIfrIndx; 
        ydat = PIfrPx; 
        plot(xdat,ydat); 
        disp(xdat); 
        disp(ydat); 
    end
    cd(masterDir);  
end
hold off; 
xlabel(xLabel); 
ylabel(yLabel); 
ylim(yspecs); 

cd(startDir); % So we can start and end in the same place.