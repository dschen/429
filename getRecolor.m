%% COS 429 final project: helping the colorblind see color
% Returns a color transformation that makes a color image easier to view
% for a person with color vision deficiency
%
% Parameters:
% imgRGB: RGB values for a color image
% type: the type of CVD (protanopia, deuteranopia, tritanopia)
%
% Returns:
% rotation: a mapping of the old color to the new color

function [] = getRecolor(imgRGB, type)
%% Represent colors using Gaussian Mixture Model (GMM)
% translate RGB to L*a*b* 
img = rgb2lab(imgRGB);

% Estimate a GMM for the data

% todo: is there a better way to pick k?
k = 4;    % paper provided a range of 2 <= K <= 6
gmm = gmdistribution.fit(img, k, 'CovType', 'diagonal', 'Regularize', 1);

%% Measure target distance using KL divergence

%% Solve the optimization 

end