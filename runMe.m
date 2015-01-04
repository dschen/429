%% COS 429 final project: helping the colorblind see color
% Based on calibration, which determines the user's CVD,
% returns four images.
%
% Parameters:
% imgPath: String value, gives path of image
%
% Saves:
% outputImages: Top left is original image, top right is original image
% viewed by person with CVD, bottom left is corrected image, and bottom
% right is corrected image viewed by person with CVD. 
%
% Authors: Dorothy Chen and Carolyn Chen
function runMe(imgPath)

% Calibration
[type, confusionAxis, sIndex, cIndex] = calibrate(1); %do calibrate(1) to debug
type = 'deuteranopia';

% customization based on severity of CVD: an experiment
maxSIndex = 1;
switch type
    % values taken from "Quantitative Scoring of Color-Vision Panel Tests"
    case 'protanopia'
        maxSIndex = 6.12;
    case 'deuteranopia'
        maxSIndex = 4.82;
    case 'tritanopia'
        maxSIndex = 4.74;
end

cIndex
calib.severity = 1.0;
calib.severity = sIndex/6.12;

% Get recoloring
imgRGB = imread(imgPath);
% convert RGB range (0-255) to (0-1)
imgRGB = im2double(imgRGB);
[~, corRGB] = getRecolor(imgRGB, type, calib);

% Display images
Fig = figure;
subplot(2,2,1);
imshow(imgRGB);
title(sprintf('Original Image'));
subplot(2,2,2);
imshow(simulate(imgRGB, type));
title(sprintf('Original Image, %s View', type));
subplot(2,2,3);
imshow(corRGB);
title(sprintf('Corrected Image'));
subplot(2,2,4);
imshow(simulate(corRGB, type));
title(sprintf('Corrected Image, %s View', type));
saveas(Fig, sprintf('Visualization'));
print(sprintf('./outputs/Visualization.jpg'),'-djpeg');
    