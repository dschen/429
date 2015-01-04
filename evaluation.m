%% COS 429 final project: quantitative evaluation metric 
%
% Parameters:
% imgPath: a path to the image
%
% Returns:
% metric: the difference in the number of GMM clusters between the
% simulated original image and the simulated recolored image
%
% larger metric = more color clusters added after recolorization = more 
% differentiation between areas of the image = better
%
% Authors: Carolyn Chen and Dorothy Chen

function metric = evaluation(imgPath, type)
img = imread(imgPath);
imgRGB = im2double(img);

origSimImg = simulate(imgRGB, type);
[~, newImg] = getRecolor(imgRGB, type);
newSimImg = simulate(newImg, type);

figure;
subplot(1,2,1); imshow(origSimImg);
subplot(1,2,2); imshow(newSimImg);

% convert to L*a*b* space. not necessary for evaluation purposes, but this
% will help stay consistent with the GMM fitting that we do during
% recolorization
rgb2lab = makecform('srgb2lab');
origLab = applycform(origSimImg, rgb2lab);
newLab = applycform(newSimImg, rgb2lab);

% input to gmdistribution.fit must be 2d
origL = origLab(:,:,1); origA = origLab(:,:,2); origB = origLab(:,:,3);
newL = newLab(:,:,1); newA = newLab(:,:,2); newB = newLab(:,:,3);
origInput = [origL(:) origA(:) origB(:)];
newInput = [newL(:) newA(:) newB(:)];

% max number of GMM clusters
k = 6;

% fit a GMM to the original and new images
origAIC = zeros(1,k);
origGmms = cell(1,k);
newAIC = zeros(1,k);
newGmms = cell(1,k);
options = statset('MaxIter', 300);
for i = 1:k 
    origGmms{i} = gmdistribution.fit(origInput, i, 'CovType', 'diagonal', 'Regularize', 0.1, 'Options', options);
    origAIC(i) = origGmms{i}.AIC;
    
    newGmms{i} = gmdistribution.fit(newInput, i, 'CovType', 'diagonal', 'Regularize', 0.1, 'Options', options);
    newAIC(i) = newGmms{i}.AIC;
end

% find the best fitting GMMs
[~, origNum] = min(origAIC);
origBest = origGmms{origNum};

[~, newNum] = min(newAIC);
newBest = newGmms{newNum};

% find the difference in the number of components
metric = newBest.NComponents - origBest.NComponents;
end