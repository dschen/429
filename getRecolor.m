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

function getRecolor(imgRGB)%, type)
%% Represent colors using Gaussian Mixture Model (GMM)
% translate RGB to L*a*b* 
cform = makecform('srgb2lab');
img = applycform(imgRGB, cform);

% Estimate a GMM for the data
k = 6;    % paper provided a range of 2 <= K <= 6

% Input matrix to GMM must be 2D
gmmInput = [img(:,:,1); img(:,:,2); img(:,:,3)];

% minimization idea from matlab docs for fitgmdist
AIC = zeros(1,k);
gmms = cell(1,k);
for i = 1:k
    % fitgmdist seems to use the option names of gmdistribution.fit (e.g.
    % 'CovType' instead of 'CovarianceType') ? confusion
    gmms{i} = fitgmdist(gmmInput, i, 'CovType', 'diagonal', 'Regularize', 0.1);
    AIC(i) = gmms{i}.AIC;
end

[~, numComponents] = min(AIC);
bestGmm = gmms{numComponents};

%% Measure target distance using KL divergence

%% Solve the optimization 

end