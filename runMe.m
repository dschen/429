%% COS 429 final project: helping the colorblind see color
% Based on calibration, which determines the user's CVD,
% returns four images.
%
% Parameters:
% imgPath: String value, gives path of image
%
% Saves:
% outputImages: ...
%
% Authors: Dorothy Chen and Carolyn Chen
function runMe(imgPath)

% Calibration
type = 'deuteranopia';

% Get recoloring
imgRGB = imread(imgPath);
% convert RGB range (0-255) to (0-1)
imgRGB = im2double(imgRGB);
[~, corRGB] = getRecolor(imgRGB, type);

% Display images
Fig = figure;
subplot(2,2,1);
%subplot('Position',[0 0 0.8 0.8]);
imshow(imgRGB);
title(sprintf('Original Image'));
subplot(2,2,2);
%subplot('Position',[0 0 0.8 0.8])
imshow(simulate(imgRGB, type));
title(sprintf('Original Image, %s View', type));
subplot(2,2,3);
%subplot('Position',[0 0 0.8 0.8])
imshow(corRGB);
title(sprintf('Corrected Image'));
subplot(2,2,4);
%subplot('Position',[0 0 0.8 0.8])
imshow(simulate(corRGB, type));
title(sprintf('Corrected Image, %s View', type));
saveas(Fig, sprintf('Visualization'));
print(sprintf('./outputs/Visualization.jpg'),'-djpeg');
    