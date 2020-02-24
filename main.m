%% Read file

addpath('FLIR_class');

% Browse to file
[file,path] = uigetfile('*.*');

% Read .ptw file
data = FlirMovieReader([path file]);

% File information
vars = info(data);
i = 1;
% rect = [194, 100, 74, 57];
% rect2 = [24 35 28 23];

% Choose rotation angle
[frame, metadata] = read(data, 1);
sprintf('Please click on any two points on the horizontal reference surface\nPress Enter to continue...')
pause()
figure, imshow(frame, [])
[x, y] = ginput(2);
close all
angle = get_slope(x, y);
clear x y

% Choose region of interest
frame_r = imRotateCrop(frame, angle);
sprintf('Please drag rectangle across area of interest\nPress Enter to continue...')
pause()
figure, imshow(imadjust(im2double(frame_r)))
rect = getrect();
rect = round(rect);
close all
clear frame metadata frame_r

data = FlirMovieReader([path file]);

%% Read frames

while ~isDone(data)
    [frame, metadata] = step(data);
    frame_r = imrotate(frame, angle);
    d = 18;         % Adjust this number to fix cropping in x direction
    frame_c = frame_r(rect(2):rect(2)+rect(4), rect(1)+d:rect(1)+rect(3));
%     frame_s = frame_c(rect2(2):rect2(2)+rect2(4), rect2(1):rect2(1)+rect2(3));
    
    timelapse_raw(:,:,i) = frame;
    timelapse_cropped(:,:,i) = frame_c;
    MaxTemp(i, 1) = max(max(frame));
    MaxTemp(i, 2) = max(max(frame_c));
%     MaxTemp(i, 3) = max(max(frame_s));
    
    MeanTemp(i, 1) = mean(mean(frame));
    MeanTemp(i, 2) = mean(mean(frame_c));
%     MeanTemp(i, 3) = mean(mean(frame_s));
    
    i = i+1;
end

%% Initialize variables

sprintf('Please click the top and bottom points of the sample\nPress Enter to continue...')
pause()
n = 1;          % Select the frame with correct initial height and width
figure, imshow(timelapse_cropped(:,:,n), [])
[x, y] = ginput(2);
close all
h = abs(y(2)-y(1));

sprintf('Please click the right and left points of the sample\nPress Enter to continue...')
pause()
n = 1;          % Select the frame with correct initial height and width
figure, imshow(timelapse_cropped(:,:,n), [])
[x, y] = ginput(2);
close all
d = abs(x(2)-x(1));

clear n x y

h_px = h/7.41; % px/mm; Enter measured height
d_px = d/7.55; % px/mm; Enter measured diameter

%% Process images

for i = 60:size(timelapse_cropped, 3)
   I = timelapse_cropped(:,:, i);
   I_seg(:,:,i) = segment_image_high(I);
   [vol(i), area(i)] = region_volume(I_seg(:,:,i), h_px, d_px);
   
end

%% plot porosity

vol_init = 0.331;
t = 1:2861;
figure, scatter(t, (vol-vol_init).*100./vol, 3)
% figure, scatter(t, vol, 3)

xlabel('Time in minutes')
ylabel('Porosity %')

%% plot surface area

t = 1:2861;
figure, scatter(t, area, 3)
% figure, scatter(t, vol, 3)

xlabel('Time in minutes')
ylabel('Surface area cm^2')

