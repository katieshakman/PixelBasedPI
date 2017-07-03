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
        addpath(genpath('/Users/katherineshakman/Documents/MATLAB/JAABA-master/')); % for iMac
        A = 2; 
    catch
        disp('Could not find the JAABA package.');  
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

fr = im2double(readFrame(v));
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
frCnt = 0; % initialize counter for frames reached
PIfrPx = nan(size(numFramesSubsampled,1)); % Initialize; will hold pixelwise PI at each frame
PIfrCnt = 0; % counts for how many frames we have calculated the PI 
xTickLabels = cell(size(1,numFramesSubsampled)); 
% Start again from beginning of video: 
v.CurrentTime = 0; 
while hasFrame(v) % 
    thisFrame = readFrame(v);
    frCnt = frCnt + 1; 
    if mod(frCnt,sampleEveryNFrames) == 0
        thisFrame = im2double(thisFrame(:,:,1));
        thisFrame = flies_detect(thisFrame, diskSize);
        thisFrameAD = thisFrame.*ADcirc_mask';
        thisFrameBC = thisFrame.*BCcirc_mask';
        sumAD = sum(sum(thisFrameAD));
        sumBC = sum(sum(thisFrameBC));
        PIfrCnt = PIfrCnt + 1;
        PIfrPx(PIfrCnt) = (sumAD-sumBC)/(sumAD+sumBC);
        xTickLabels{PIfrCnt} = frCnt; 
    end
end
%% Show final images and plot 
figure; imshow(thisFrameAD); title('thisFrameAD')
figure; imshow(thisFrameBC); title('thisFrameBC')
figure; plot(1:length(PIfrPx),PIfrPx); title('PIfrPx'); 
ax = gca; 
ax.XTickLabel = xTickLabels; 
title('PI Over Time'); xlabel('Frame Number'); ylabel('PI'); 
