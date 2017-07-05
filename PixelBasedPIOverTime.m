% Katie Shakman - 5/26/2017

% Note: Can open either avi or ufmf file.  If ufmf is selected, the
% function ufmf2avi (from JAABA) will be used to convert the file.
% Janelia's JAABA package is available from http://jaaba.sourceforge.net/

% Begin by clearing variables and closing any open figures.  
clear; close all; 

%% Specify parameters as desired
maxImDepth = 3; % Maximum number of colors/channels in each frame of movie.
sampleEveryNFrames = 200; % At what intervals should PI be computed?  Use a lower number for faster runtime.
radiusRangeLarge = [490 510]; % For detection of circular arena border. 
diskSize = 25; 
%% Set up the path to include JAABA's ufmf2avi and its dependencies
A = exist('ufmf2avi','file'); 
while A == 0 
    try
        addpath(genpath('JAABA-master/')); % guesses there may be a JAABA subfolder within the current folder
        A = 2; 
    catch
        disp('Could not find the JAABA package.  If you have JAABA installed, please add it to the search path.  If not, install JAABA from http://jaaba.sourceforge.net/ or select an avi file for processing. ');  
        A = -1; 
    end
end

%% Select Movie File (avi or ufmf)
[filename,pathname] = uigetfile({'*.avi';'*.ufmf'});
addpath(pathname); % add the containing folder for the movie to the path

if strcmp(filename(end-2:end), 'avi')
    type = 1; % avi
elseif strcmp(filename(end-3:end), 'ufmf')
    type = 2; % ufmf, requires the ufmf2avi function from JAABA
else
    type = 0; % unknown type
end

%% Convert the movie if necessary 
% Check if need to convert to avi format: 
if type == 1
    aviName = filename; % No need to convert. 
elseif type == 2
    aviName = strrep(filename,'ufmf','avi'); 
    ufmf2avi(filename, aviName); % Convert to avi with JAABA.  
end
 
%% Read the movie (FIRST FRAME ONLY)
v = VideoReader(aviName); 
sumV = zeros(v.Height, v.Width, maxImDepth);
frNum = 0; 

fr = im2double(read(v,1));
frNum = frNum + 1; % Add to the count of total frames read.
sumV = sumV + fr; % Add to the running sum.

figure; imshow(fr); title('fr');
I = fr(:,:,1); 
%% Get circular edge of arena
figure; imshow(I);
[centerL,radiiL] = imfindcircles(I, radiusRangeLarge, 'Sensitivity', 0.98); 
hold on
viscircles(centerL,radiiL); 
hold off
% Get arena edge (circular)
cx=centerL(2);cy=centerL(1); % center of large circle
ix=1024;iy=1280; % size of image
r = radiiL; % radius of large circle
[x,y]=meshgrid(-(cx-1):(ix-cx),-(cy-1):(iy-cy));
c_mask=((x.^2+y.^2)<=r^2);
imshow(c_mask); xlim([0 1200]); ylim([0 1200]); 
% Apply mask (roi) to mean image: 
roiI = I.*c_mask'; 
figure; imshow(roiI); 

%% Process the movie to get binarized images with flies in white: 
imBin = flies_detect(roiI,diskSize); 

%% Make and apply mask for AD quadrants: 
[xq, yq] = meshgrid(1:ix, 1:iy); 
Dq_mask = (xq > cx) & (yq > cy);
Aq_mask = (xq<cx & yq <cy); 
Cq_mask = (xq>cx & yq<cy); 
Bq_mask = (xq<cx & yq>cy); 
AD_mask = Aq_mask+Dq_mask;
ADcirc_mask = c_mask.*AD_mask; 
% figure; imshow(ADcirc_mask); title('ADcirc mask')
BC_mask = Bq_mask+Cq_mask; 
BCcirc_mask = c_mask.*BC_mask; 
% figure; imshow(BCcirc_mask); title('BCcirc mask')
% Background mean image dotted with each mask: 
meanADcirc = imBin.*ADcirc_mask'; 
meanBCcirc = imBin.*BCcirc_mask'; 
figure; imshow(meanADcirc); title('mean AD circ')

%% Compute average dark pixels in AD vs BC over time
numFrames = v.Duration*v.FrameRate; 
numFramesSubsampled = floor(numFrames/sampleEveryNFrames); 
PIfrPx = nan(size(numFramesSubsampled,1)); % Initialize; will hold pixelwise PI at each frame
PIfrCnt = 0; % counts for how many frames we have calculated the PI 

% check on existence of/create pool for parallel computing 
poolObj = gcp('nocreate'); 
if isempty(poolObj) % check if pool is already open
    poolObj = parpool; 
end
tic
parfor frIndx = 1:numFrames 
    thisFrame = read(v,frIndx);
    if mod(frIndx,sampleEveryNFrames) == 0
        thisFrame = im2double(thisFrame(:,:,1));
        thisFrame = flies_detect(thisFrame, diskSize);
        thisFrameAD = thisFrame.*ADcirc_mask';
        thisFrameBC = thisFrame.*BCcirc_mask';
        sumAD = sum(sum(thisFrameAD));
        sumBC = sum(sum(thisFrameBC));
        PIfrCnt = PIfrCnt + 1;
        PIfrIndx(frIndx) = frIndx; 
        PIfrPx(frIndx) = (sumAD-sumBC)/(sumAD+sumBC);
        if frIndx == numFrames
            figure; imshow(thisFrameAD); title('thisFrameAD')
            figure; imshow(thisFrameBC); title('thisFrameBC')
        end
    else
        PIfrIndx(frIndx) = nan; 
        PIfrPx(frIndx) = nan; 
    end
end
toc
%% Show final images and plot 
PIfrIndx = PIfrIndx(~isnan(PIfrIndx)); 
PIfrPx = PIfrPx(~isnan(PIfrPx)); 
figure; plot(PIfrIndx,PIfrPx); title('PIfrPx'); 
title('PI Over Time'); xlabel('Frame Number'); ylabel('PI'); 
% Save PI values and the frames at which they were calculated: 
matFilename = strcat(filename(7:end-4),'_PI.mat');
save(matFilename, 'PIfrIndx', 'PIfrPx','filename'); 
% Save the PI over Time plot as a jpg: 
jpgFilename = strcat(filename(7:end-4),'_PI.jpg'); 
saveas(gcf,jpgFilename); 
figFilename = strcat(filename(7:end-4),'_PI.fig'); 
saveas(gcf,figFilename); 
try 
    saveas(gcf,figFilename); 
catch
    disp('Could not save fig.'); 
end
