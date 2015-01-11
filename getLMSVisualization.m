function getLMSVisualization(imgRGB, type)
% Constants
% LMS Tristimulus Values for the Red, Green, and Blue Primaries
% as described in the paper, Table 1, pg. 2648
T = [0.1992 0.4112 0.0742; ...
     0.0353 0.2226 0.0574; ...
     0.0185 0.1231 1.3550];
 imgRGB = im2double(imgRGB);
[height, width, ~] = size(imgRGB);
LMS = zeros(height*width, 3);
count = 1;

R = imgRGB(:,:,1);
G = imgRGB(:,:,2);
B = imgRGB(:,:,3);
R = R(:);
G = G(:);
B = B(:);
 
 for i=1:width
    for j=1:height
        V = [imgRGB(j,i,1); imgRGB(j,i,2); imgRGB(j,i,3)];
        % Compute the LMS specification Q fom the original pixel values V
        % by means of Q = T*V
        Q = T*V;
        LMS(count,:) = Q;
        count = count+1;
    end
 end
 [R G B]
 scatter3(LMS(:, 1), LMS(:,2), LMS(:,3), 1, [R G B]);
 xlabel('Long');
 ylabel('Middle');
 zlabel('Short');