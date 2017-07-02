% Detect flies or grains in image.  
% Approach adapted from Matlab's help page "Correct Nonuniform Background
% Illumination and Analyze Foreground Objects" found at
% https://www.mathworks.com/help/images/image-enhancement-and-analysis.html

function outputIm = flies_detect(Im,diskSize)

% % Subtract background
% figure; imshow(Im); title('original'); 
% % Invert colors
roiI2 = imcomplement(Im);
background = imopen(roiI2,strel('disk',diskSize));
% figure; imshow(background); title('background')
% % Subtract background approximation image
I2 = roiI2- background; 
% figure; imshow(I2); title('I2')
% adjust by saturating 1% of the data at low and high intensities: 
I3 = imadjust(I2); 
% figure; imshow(I3); title('I3'); 
% % Binarize and remove background noise
level = graythresh(I3); 
bw = im2bw(I3,level); 
% figure; imshow(bw); title('Before background noise removal'); 
bw = bwareaopen(bw,50); 
% figure; imshow(bw); title('Background noise removed'); 

outputIm = bw; 
