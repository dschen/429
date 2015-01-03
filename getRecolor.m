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
% corRGB: the corrected image
%
% Authors: Dorothy Chen and Carolyn Chen
function [rot, corRGB] = getRecolor(imgRGB, type)
%% Represent colors using Gaussian Mixture Model (GMM)
% translate RGB to L*a*b* 
rgb2lab = makecform('srgb2lab');
img = applycform(imgRGB, rgb2lab);

% Estimate a GMM for the data
k = 6;    % paper provided a range of 2 <= K <= 6

% Input matrix to GMM must be 2D
% just make each column one of the attributes?
L = img(:,:,1);
a = img(:,:,2);
b = img(:,:,3);
gmmInput = [L(:) a(:) b(:)];
dim = size(gmmInput);

% minimization idea from matlab docs for fitgmdist
AIC = zeros(1,k);
gmms = cell(1,k);
options = statset('MaxIter', 300);
for i = 1:k
    % CovType and Regularize options are to avoid "ill-conditioned
    % covariance matrices", whatever that means. --matlab docs 
    gmms{i} = gmdistribution.fit(gmmInput, i, 'CovType', 'diagonal', 'Regularize', 0.1, 'Options', options);
    AIC(i) = gmms{i}.AIC;
end

% find the best fitting gmm
[~, numComponents] = min(AIC);
bestGmm = gmms{numComponents};

%% Measure target distance using KL divergence
% from the paper: "The goal of the proposed re-coloring algorithm is that the symmetric
% KL divergence between each pair of Gaussians in the original image
% will be preserved in the recolored image when perceived by people
% with CVD."

% KL Divergences of original pairs
originalMus = bestGmm.mu;                 % mu is k x 3 (3 color dimensions)
originalSigmas = bestGmm.Sigma;           % sigmas is 1 x 3 x k (only diagonal of cov matrix stored)
numComponents = bestGmm.NComponents;      % number of gaussians
originalKLVals = KLDivergence(originalMus, originalSigmas, numComponents);
originalKLVals = originalKLVals/sum(originalKLVals);

%% Solve the optimization: minimize difference between original KL and new KL
% P(xj, i): probability that xj belongs to ith gaussian
[~, ~, P] = cluster(bestGmm, gmmInput);

% color feature weights
alphas = zeros(dim(1),1);
% must first translate back into RGB 
lab2rgb = makecform('lab2srgb');
labColor = cat(3, gmmInput(:,1), gmmInput(:,2), gmmInput(:,3));
rgbColor = applycform(labColor, lab2rgb);
% simulate
simRgb = double(simulate(rgbColor, type));
% translate back to L*a*b*
simLab = applycform(simRgb, rgb2lab);
sim = [simLab(:,:,1) simLab(:,:,2) simLab(:,:,3)];
for i = 1:size(alphas, 1)
    alphas(i) = sqrt(sum((gmmInput(i,:) - sim(i,:)).^2, 2));
end

% cluster weights
lambdas = zeros(numComponents, 1);
total = 0;
for i = 1:numComponents
    for j = 1:size(alphas, 1)
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

% the optimization
options = optimoptions(@lsqnonlin, 'Algorithm', 'levenberg-marquardt', 'MaxIter', 1000, 'Display', 'off');
f = @(x)findDiffs(originalKLVals, originalMus, originalSigmas, numComponents, objWeights, x, type);
% returns rotation angle (radians) each of the gaussians
x0 = atan2(originalMus(:,3), originalMus(:,2));
rot = lsqnonlin(f, x0, [], [], options);

% local minima thing
% r = sqrt(originalMus(:,2).^2 + originalMus(:,3).^2);
% rotMus = originalMus;
% rotMus(:,2) = r .* cos(rot);
% rotMus(:,3) = r .* sin(rot);
% labColor = cat(3, rotMus(:,1), rotMus(:,2), rotMus(:,3));
% rgbColor = applycform(labColor, lab2rgb);
% sim = double(simulate(rgbColor, type));
% for i = 1:numComponents
%     if (rotMus(i,2) > 0)
%         if (sqrt(sum((rgbColor(i,:) - sim(i,:)).^2, 2)))
%         end
%     end
% end

%% Gaussian mapping for Interpolation
%  recolor the image

% mapping works in the CIE LCH color space
% img is in LAB space
cform = makecform('lab2lch');
imgLCH = applycform(img, cform);

% M(mu) - mu  where M is mapping function, rot, all in Hue space
differenceMus = zeros(numComponents,1);
for i = 1:numComponents
    abMu = [originalMus(i,2); originalMus(i,3)];
    theta = rot(i);
    R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
    newabMu = R*abMu;
    newlabMu = [originalMus(i,1) newabMu(1) newabMu(2)];
    newlabMuLCH = applycform(newlabMu, cform);
    labMuLCH = applycform(originalMus(i,:), cform);
    differenceMus(i) = newlabMuLCH(3) - labMuLCH(3);
end

% Lightness L* and chroma C is unchanged
% Hue of the transformed color: H(xj)
H = imgLCH(:,:,3);

% calculate new hue for each pixel
for j = 1:dim(1)
    hj = H(j);
    for i = 1:numComponents
        hj = hj +  P(j, i)*differenceMus(i);
    end
    H(j) = hj;
end

% return to RGB space
imgLCH(:,:,3) = H;
cform = makecform('lch2lab');
imgLAB = applycform(imgLCH, cform);
cform = makecform('lab2srgb');

corRGB = applycform(imgLAB, cform);

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
        % i.e. the parameter is 1 x 3 x k. 
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

% optimization function. finds differences between the original KL
% divergence values and the simulated-rotated KL values
%
% too slow to pass in original image and rotate that--that involves
% refitting a GMM for each iteration, which is way too costly.
% instead, just rotate the mus and assume that the sigmas stay unchanged
function diffs = findDiffs(originalKLVals, originalMus, originalSigmas, numComponents, weights, rot, type)
% get new color: rotate original mu on a*b* plane
% mu is kx3: k groups, 3 color features: L* first, a* second, and b* third
% we're rotating in the a*b* plane, so mus(:,1) will not change
newMus = originalMus;
r = sqrt(newMus(:,2).^2 + newMus(:,3).^2);

newMus(:,2) = r .* cos(rot);
newMus(:,3) = r .* sin(rot);

% simulate the new color
% must first translate back into RGB 
lab2rgb = makecform('lab2srgb');
rgb2lab = makecform('srgb2lab');
labColor = cat(3, newMus(:,1), newMus(:,2), newMus(:,3));
rotRgbColor = applycform(labColor, lab2rgb);
simulatedRgb = simulate(rotRgbColor, type);
% then must translate back and reformat
simulatedLab = applycform(simulatedRgb, rgb2lab);
simulatedNewMus = [simulatedLab(:,:,1) simulatedLab(:,:,2) simulatedLab(:,:,3)];

% find KL divergence for CVD version of the new color
% we're assuming that original sigma (covariance matrix) is not changing
newKLVals = KLDivergence(simulatedNewMus, originalSigmas, numComponents);
newKLVals = newKLVals/sum(newKLVals);

% find difference + multiply by weight for each pair of gaussians
diffs = (newKLVals - originalKLVals).*weights;

end
