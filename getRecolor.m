%% COS 429 final project: helping the colorblind see color
% Returns a color transformation that makes a color image easier to view
% for a person with color vision deficiency
%
% Parameters:
% imgRGB: RGB values for a color image (m x n x 3 double)
% type: the type of CVD (protanopia, deuteranopia, or tritanopia)
%
% Returns:
% rotation: a mapping of the old color to the new color
%
% Authors: Dorothy Chen and Carolyn Chen

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
% There doesn't seem to be a matlab function for this
% crying

% from the paper: "The goal of the proposed re-coloring algorithm is that the symmetric
% KL divergence between each pair of Gaussians in the original image
% will be preserved in the recolored image when perceived by people
% with CVD."

% KL Divergences of original pairs
originalMus = bestGmm.mu;                 % mu is k x #dim
originalSigmas = bestGmm.Sigma;           % idk why, but sigmas is 1 x #dim x k
% jk figured it out. it's because covtype is set to diagonal, so only the
% diagonal items are stored. (if set to 'full', sigmas will be dim x dim x k
originalWeights = bestGmm.PComponents;    % weights is 1 x k
originalKLVals = KLDivergence(originalMus, originalSigmas, numComponents);

%% Solve the optimization 

end

% finds Symmetric KL divergence between all pairs of the k components
% uses closed form formula from the paper (+google. the one in the paper is
% weird and confusing)
function divergences = KLDivergence(mus, sigmas, k)

% create empty vector to store divergences in for each pair
% there are k choose 2 pairs = k!/(2!(k-2)!) = k(k-1)/2
divergences = zeros(k*(k-1)/2 ,1);

counter = 1;
for i = 1:k
    for j = i+1:k
        mu1 = mus(i,:);
        mu2 = mus(j,:);
        sigma1 = sigmas(:,:,i);
        sigma2 = sigmas(:,:,j);
        
        % this is gross but we're going to assume that sigmas is diagonal 
        % i.e. 1 x #dim x k. the inverse of a diagonal matrix is just 1/all
        % the elements 
        inv1 = 1./sigma1;
        inv2 = 1./sigma2;
        
        % the equation
        divergences(counter) = (mu1 - mu2).*(mu1 - mu2)*((inv1 + inv2).');
        divergences(counter) = divergences(counter) + sum((sigma1.*inv2 + inv1.*sigma2)-2);
        
        counter = counter + 1;
    end
end
end 
