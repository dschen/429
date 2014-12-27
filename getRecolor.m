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
dim = size(gmmInput);

% minimization idea from matlab docs for fitgmdist
AIC = zeros(1,k);
gmms = cell(1,k);
for i = 1:k
    % fitgmdist seems to use the option names of gmdistribution.fit (e.g.
    % 'CovType' instead of 'CovarianceType') ? confusion
    %
    % CovType and Regularize options are to avoid "ill-conditioned
    % covariance matrices", whatever that means. --matlab docs 
    gmms{i} = fitgmdist(gmmInput, i, 'CovType', 'diagonal', 'Regularize', 0.1);
    AIC(i) = gmms{i}.AIC;
end

% find the best fitting gmm
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
originalWeights = bestGmm.PComponents;    % mixing weights is 1 x k
originalKLVals = KLDivergence(originalMus, originalSigmas, numComponents);

%% Solve the optimization: minimize difference between original KL and new KL

% objective = originalKLVals - simulated-rotated-KLVals
% need to find simulation of CVD function. let's pretend it's called sim() for now

% opt using lsqnonlin? so that would involve writing a function to find the
% obj fnc and calling lsqnonlin on that

% P(xj, i): probability that xj belongs to ith gaussian
[~, ~, P] = cluster(bestGmm, gmmInput);

% color feature weights
alphas = zeros(dim(1),1);
for i = 1:alphas.length
    alphas(i) = sqrt(sum((gmmInput(i,:) - sim(gmmInput(i,:))).^2, 2));
end

% cluster weights
lambdas = zeros(numComponents, 1);
total = 0;
for i = 1:numComponents
    for j = 1:alphas.length
        lambdas(i) = lambdas(i) + alphas(j) * P(j, i);
    end
    total = total + lambdas(i);
end
lambdas = lambdas ./ total;

% weights used in objective function
objWeights = zeros(numComponents*(numComponents-1)/2, 1);
counter = 1;
for i = 1:numComponents
    for j = i+1:numComponents
        objWeights(counter) = lambdas(i) + lambdas(j);
        counter = counter + 1;
    end
end

end

% finds Symmetric KL divergence between all pairs of the k components
% uses closed form formula from the paper (+google. the one in the paper is
% weird and confusing and possibly not technically correct?)
function divergences = KLDivergence(mus, sigmas, k)

% create empty vector to store divergences in for each pair
% there are k choose 2 pairs = k!/(2!(k-2)!) = k(k-1)/2
divergences = zeros(k*(k-1)/2, 1);

counter = 1;
for i = 1:k
    for j = i+1:k
        mu1 = mus(i,:);
        mu2 = mus(j,:);
        sigma1 = sigmas(:,:,i);
        sigma2 = sigmas(:,:,j);
        
        % this is gross but we're going to assume that sigmas is diagonal 
        % i.e. the parameter is 1 x #dim x k. 
        % the inverse of a diagonal matrix is just 1/all
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

function diffs = findDiffs(originalKLVals, originalMus, originalSigmas, weights, rot, type)
% get new color
% rotate original mu on a*b* plane
% we're assuming that original sigma is not changing 

% find KL divergence for new color

% find difference + multiply by weight for each pair of gaussians

end
