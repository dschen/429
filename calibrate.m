%% COS 429 final project: helping the colorblind see color
% Calibrates the user's degree of CVD
%
% User interface portion inspired by drag_drop.m, provided on the
% MathWorks forum. 
% 
% Middle portion follows along with algorithm described in paper:
% "A Quantitative Scoring Technique For Panel Tests of Color Vision"
% by Algis J. Vingrys and P. Ewen King-Smith 
%
% Turn on debug option to see graphs and force the ordering of the panels
% Otherwise, order the panels from left to right based on the left blue
% square
%
% Returns:
% type: string indicating what type of CVD
% confusionAxis: double val indicates angle of confusion line
% sIndex: double val describes randomness in placement, polarity of choices
% cIndex: double val error score
% 
% Authors: Dorothy Chen and Carolyn Chen
function [type, confusionAxis, sIndex, cIndex] = calibrate(dBug)
% debug option
switch nargin
    case 1
        debug = dBug;
    case 0
        debug = 0;
end

%% Ask user for input to rearrange 15 panels
numPanels = 16;
oP = load('./inputs/orderedPanels.mat');

positions = zeros(numPanels-1, 2);
f = figure('WindowButtonUpFcn',@dropObject,'units','normalized',...
    'WindowButtonMotionFcn',@moveObject);
img = imread('./inputs/d15background.png');
imshow(img);
[imheight, imwidth, ~] = size(img);

htext = uicontrol('Style', 'text', 'String', ...
    'Place the colors in the squares in order horizontally', ...
    'Position', [10, 10, 300, 15]);

width = 30;
height = 30;

% below is inspired code from the original drag_drop.m from the following
% source: http://www.mathworks.com/matlabcentral/answers/
% 94681-how-do-i-implement-drag-and-drop-functionality-in-matlab
% at first we used impositionrect, but the coloring was restricted to the 
% border, so that was no fun. 

dragging = [];
orPos = [];

for i=1:numPanels-1
    xrand = rand;
    yrand = rand;
    h = annotation('textbox', 'position', [xrand yrand 0.04 0.06], ...
        'BackgroundColor', im2double(oP.orderedPanels(i+1,:))/255, ...
        'ButtonDownFcn',@dragObject);
    squares(i) = h;
    positions(i,:) = [xrand yrand];
end

tempH = squares(1);

% function helpers, modified from source (mathworks page ^)
    function dragObject(hObject,eventdata)
          dragging = hObject;
          orPos = get(gcf,'CurrentPoint');
          % makes current position a global variable
          tempH = hObject;
      end
      function dropObject(hObject,eventdata)
          if ~isempty(dragging)
              newPos = get(gcf,'CurrentPoint');
              posDiff = newPos - orPos;              
              set(dragging,'Position',get(dragging,'Position') + [posDiff(1:2) 0 0]);
              dragging = [];
              
              % added this portion to update positions vector of squares
              I = find(squares==tempH, 1);
              positions(I,:) = newPos;
          end
      end
      function moveObject(hObject,eventdata)
          if ~isempty(dragging)
              newPos = get(gcf,'CurrentPoint');
              posDiff = newPos - orPos;
              orPos = newPos;
              set(dragging,'Position',get(dragging,'Position') + [posDiff(1:2) 0 0]);
          end
      end
  
waitfor(f);

[~, tempusr] = sort(positions(:,1));
% first panel is fixed
tempusr = tempusr+1;
usr = [1;tempusr];

%% Constants given in the paper for the REM Standard D-15 panel test
% U & V values of the 16 colors (15 ordered by user)
% Luminosity in this U'V'L space is held constant, so can simplify problem
% to a plane
u = [-21.54; -23.26; -22.41; -23.11; ...
    -22.45; -21.67; -14.08; ...
    -2.72; 14.84; 23.87; ...
    31.82; 31.42; 29.79; ...
    26.64; 22.92; 11.20];
v = [-38.39; -25.56; -15.53; -7.45; ...
    1.10; 7.35; 18.74; ...
    28.13; 31.13; 26.35; ...
    14.76; 6.99; 0.10; ...
    -9.38; -18.65; -24.61];
% The radius of the major axis calculated from the perfect d15 arrangement
maxR = 9.234669;

%% Order based on user input
% Correct input for debugging:
if (debug)
    %usr = (1:1:numPanels); % normal vision
    usr = [1 16 2 15 3 14 13 4 5 12 11 6 10 7 9 8];% protanope
    %usr = [1 2 16 3 4 15 14 5 13 6 12 7 8 11 10 9]; %deuteranope
    %usr = [1 2 3 4 5 6 7 8 16 9 15 10 11 14 13 12];%tritanope
end

% plot ordering of panels
for i=1:numPanels
    U(i) = u(usr(i));
    V(i) = v(usr(i));
end
if (debug)
    figure;
    plot(U, V);
end

diffU = zeros(numPanels-1, 1);
diffV = zeros(numPanels-1, 1);
for i=1:numPanels-1
    diffU(i) = U(i+1)-U(i);
    diffV(i) = V(i+1)-V(i);
end
if (debug)
    figure;
    compass(diffU, diffV);
    hold on;
end

%% Find the axis angles and corresponding principal moments of inertia

% Solve for A: tan(2A) = sum(2u*v)/sum(u^2-v^2) for [1,numPanels-1]
numer = 0;
denom = 0;
SU = U(1);
SV = V(1);
for i=1:numPanels-1
    numer = numer + (2*diffU(i)*diffV(i));
    denom = denom + (power(diffU(i), 2) - power(diffV(i), 2));
    SU = SU + U(i+1);
    SV = SV + V(i+1);
end

if (debug)
    fprintf('sum of Us = %f\n', SU);
    fprintf('sum of Vs = %f\n', SV);
end

A1 = atan(numer/denom)/2;
% find perpendicular angle A2 for other principle axis
if (A1 > 0)
    A2 = A1-(pi/2);
else
    A2 = A1+(pi/2);
end
if (debug)
    rad2deg(A1)
    rad2deg(A2)
end

% Solve for I: I = sum((v*cosA - u*sinA)^2)
I1 = 0;
I2 = 0;
for i=1:numPanels-1
    I1 = I1 + power(diffV(i)*cos(A1)-diffU(i)*sin(A1),2);
    I2 = I2 + power(diffV(i)*cos(A2)-diffU(i)*sin(A2),2);
end
I1
I2
R1 = sqrt(I1/(numPanels-1))
R2 = sqrt(I2/(numPanels-1))

if (R1>R2)
    majorA = A1;
    minorA = A2;
    majorR = R1;
    minorR = R2;
else
    majorA = A2;
    minorA = A1;
    majorR = R2;
    minorR = R1;
end
% S-index indicates the randomness of the placement.
% Higher value means stronger polarity, or less randomness. 
sIndex = majorR/minorR
% C-index stands for confusion index and indicates the severity of the CVD
cIndex = majorR/maxR

[X1, Y1] = pol2cart(majorA, minorR);
[X2, Y2] = pol2cart(minorA, majorR);
if (debug)
    compass([X1 X2], [Y1 Y2], 'r');
end

%% Diagnosis
delta = 10; % wiggle room

confusionAxis = rad2deg(minorA);
confusionAxis
if (confusionAxis < 62+delta && confusionAxis > 62-delta)
    type = 'normal';
elseif (confusionAxis < 9.7+delta && confusionAxis > 9.7-delta ...
        && confusionAxis > 0)
    type = 'protanopia';
elseif (confusionAxis < -8.8+delta && confusionAxis > -8.8-delta)
    type = 'deuteranopia';
elseif (confusionAxis < -86.8+delta && confusionAxis > -86.8-delta)
    type = 'tritanopia';
else
    type = 'normal'; % default...?
end

fprintf('Your type is %s\n', type);
end