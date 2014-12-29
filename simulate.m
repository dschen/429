%% COS 429 final project: helping the colorblind see color
% Returns an image simulated to match what a color blind person sees
% 
% Code follows along with algorithm described in paper:
% "Computerized simulation of color appearance for dichromats"
% by Hans Brettel, Françoise Viénot, and John D. Mollon
%
% Parameters:
% imgRGB: RGB values for a color image (m x n x 3 double)
% type: the type of CVD (protanopia, deuteranopia, or tritanopia)
%
% Returns:
% simgRGB: an imageRGB simulated under "type" of CVD
%
% Authors: Dorothy Chen and Carolyn Chen
% Code to convert wavelength to RGB from MathWorks in 
% spectral_color_1

function [simgRGB] = simulate(imgRGB, type)

% Constants
% LMS Tristimulus Values for the Red, Green, and Blue Primaries
% as described in the paper, Table 1, pg. 2648
T = [0.1992 0.4112 0.0742; ...
     0.0353 0.2226 0.0574; ...
     0.0185 0.1231 1.3550];
% LMS2RGB
invT = inv(T);
% useful numbers
[height, width, ~] = size(imgRGB);
nsimgRGB = zeros(height, width, 3);
% E represents the brightest possible metamer of an equal-energy
% stimulus on the monitor. We take it as white, or [1;1;1] in RGB
E = T*[1;1;1];

% constants for protanopia and deuteranopia
if (strcmp('protanopia', type) || strcmp('deuteranopia', type))
    % monochromatic anchor stimulus, convert from wavelength to LMS
    % http://www.cvrl.org/cones.htm: provides a table to convert 
    % NOTE: there is not a unique solution to this, rather it is an
    % approximation. Therefore, results will vary based on this conversion
    % wavelength using Stockman & Sharpe functions
    Aless = T*[0.9923; 0.7403; 0.0002]; % corresponds to 575 nm
    Amore = T*[0.1188; 0.2054; 0.5164]; % corresponds to 475 nm
    
    % constant specific to protanopia
    if (strcmp('protanopia',type))
        OELine = E(3)/E(2);
    else %constant specific to deuteranopia
        OELine = E(3)/E(1);
    end

% constants for tritanopia
elseif (strcmp('tritanopia', type))
    % monochromatic anchor stimulus, convert from wavelength to LMS
    % http://www.cvrl.org/cones.htm: provides a table to convert 
    % wavelength using Stockman & Sharpe functions
    Aless = T*[0.0930; 0.0073; 0.0000]; % corresponds to 660 nm
    Amore = T*[0.1640; 0.2681; 0.2903]; % corresponds to 485 nm
    
    % constant specific to protanopia
    if (strcmp('protanopia',type))
        OELine = E(3)/E(2);
    else %constant specific to deuteranopia
        OELine = E(3)/E(1);
    end

% for now, if no condition
else
    simgRGB = imgRGB;
    return
end

% constants for all types
aless = E(2)*Aless(3) - E(3)*Aless(2);
bless = E(3)*Aless(1) - E(1)*Aless(3);
cless = E(1)*Aless(2) - E(2)*Aless(1);
amore = E(2)*Amore(3) - E(3)*Amore(2);
bmore = E(3)*Amore(1) - E(1)*Amore(3);
cmore = E(1)*Amore(2) - E(2)*Amore(1);

for i=1:width
    for j=1:height
    % (1)
    % Compute the LMS specification Q fom the original pixel values V
    % by means of Q = T*V
    R = double(imgRGB(j,i,1));
    G = double(imgRGB(j,i,2));
    B = double(imgRGB(j,i,3));
    V = ([R;G;B]/255);
    Q = T*V;
    
    % (2) 
    % Apply the simulation algorithm (Q -> Q') 
    
    newQ = Q;
    % Protanopic simulation
    if (strcmp('protanopia', type))
        if (Q(3)/Q(2) < OELine)
            a = aless; b = bless; c = cless;
        else 
            a = amore; b = bmore; c = cmore;
        end
        newQ = [-(b*Q(2)+c*Q(3))/a; Q(2); Q(3)];
            
    % Deuteranopic simulation
    elseif (strcmp('deuteranopia', type))
        if (Q(3)/Q(1) < OELine)
            a = aless; b = bless; c = cless;
        else
            a = amore; b = bmore; c = cmore;
        end
        newQ = [Q(1); -(a*Q(1)+c*Q(3))/b; Q(3)];
        
    % Tritanopic simulation
    elseif (strcmp('tritanopia', type))
        if (Q(2)/Q(1) < OELine)
            a = aless; b = bless; c = cless;
        else
            a = amore; b = bmore; c = cmore;
        end
        newQ = [Q(1); Q(2); -(a*Q(1)+b*Q(2))/c];
    end
        
    % (3)
    % Compute the resulting pixel values according to
    % V' = T^-1*Q'
    newV = uint8(invT*newQ*255);
    nsimgRGB(j,i,:) = uint8(newV(:));
    end
end

simgRGB = uint8(nsimgRGB);

% for debugging
imshow(simgRGB);

end