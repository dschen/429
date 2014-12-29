%% COS 429 final project: helping the colorblind see color
% Returns a color transformation that makes a color image easier to view
% for a person with color vision deficiency
%
% This is translated from the code found at this site:
% http://www.efg2.com/Lab/ScienceAndEngineering/Spectra.htm
%
% Parameters:
% wavelength: want to convert this to [R G B]
%
% Returns:
% [R G B]: approximated RGB coordinates corresonding to 
% wavelength
%
% Authors: Dorothy Chen and Carolyn Chen
function RGB = spectrum2RGB(wavelength)

gamma = 2.2; % standard
intensityMax = 255;

if (wavelength <= 379)
    R = 0.0;
    G = 0.0;
    B = 0.0;
elseif (wavelength <= 439)
    R = -(wavelength - 440) / (440 - 380);
    G = 0.0;
    B = 1.0;
elseif (wavelength <= 489)
    R = 0.0;
    G = (wavelength - 440) / (490 - 440);
    B = 1.0;
elseif (wavelength <= 509)
    R = 0.0;
    G = 1.0;
    B = -(wavelength - 510) / (510 - 490);
elseif (wavelength <= 579)
%     R = (wavelength - 510) / (580 - 510);
%     G = 1.0;
%     B = 0.0;
    R = 1.0;
    G = (wavelength - 510) / (580 - 510);
    B = 0.0;
elseif (wavelength <= 644)
    R = 1.0;
    G = -(wavelength - 645) / (645 - 580);
    B = 0.0;
elseif (wavelength <= 780)
    R = 1.0;
    G = 0.0;
    B = 0.0;
else
    R = 0.0;
    G = 0.0;
    B = 0.0;
end

if (wavelength >= 380 && wavelength <= 419)
    factor = 0.3+0.7*(wavelength - 380) / (420 - 380);
elseif (wavelength >= 420 && wavelength <= 700)
    factor = 1.0;
elseif (wavelength >= 701 && wavelength <= 780)
    factor = 0.3+0.7*(780 - wavelength) / (780 - 700);
else 
    factor = 0.0;
end

if (R ~= 0)
    R = round(intensityMax*power(R*factor, gamma));
end
if (G ~= 0)
    G = round(intensityMax*power(G*factor, gamma));
end
if (B ~= 0)
    B = round(intensityMax*power(B*factor, gamma));
end

RGB = [R G B];