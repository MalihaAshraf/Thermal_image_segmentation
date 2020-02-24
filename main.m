%% Read file

clear all; close all
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



%% Read frames

data = FlirMovieReader([path file]);
while ~isDone(data)
    [frame, metadata] = step(data);
    frame_r = imrotate(frame, angle);
    d = 25;         % Adjust this number to fix cropping in x direction
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

% if repeat, uncomment following
% clear timelapse_raw timelapse_cropped MaxTemp MeanTemp
% i = 1


% figure, imshow(timelapse_cropped(:,:,500), [])

%% Remove unwanted frames

sel = [];                       % Enter frame indices to be removed, e.g., [1:50, 200, 500:890]
timelapse_raw(:,:, sel) = [];
timelapse_cropped(:,:, sel) = [];
MaxTemp(:,:,sel) = [];
MeanTemp(:,:,sel) = [];

%% Initialize variables

sprintf('Please click the top and bottom points of the sample\nPress Enter to continue...')
pause()
n = 50;          % Select the frame with correct initial height and width
figure, imshow(timelapse_cropped(:,:,n), [])
[x, y] = ginput(2);
close all
h = abs(y(2)-y(1));

sprintf('Please click the right and left points of the sample\nPress Enter to continue...')
pause()
n = 50;          % Select the frame with correct initial height and width
figure, imshow(timelapse_cropped(:,:,n), [])
[x, y] = ginput(2);
close all
d = abs(x(2)-x(1));

clear n x y

h_px = h/7.41; % px/mm; Enter measured height
d_px = d/7.55; % px/mm; Enter measured diameter

%% Process images

for i = 1:size(timelapse_cropped, 3)
   I = timelapse_cropped(:,:, i);
   if i <=45        % Frame where the sample and bck is the same temp. Gray image
       I_seg(:,:,i) = segment_image_low(I);
   elseif i <=150 && i > 45         % 
       I_seg(:,:,i) = segment_image_mid(I);
   else
       I_seg(:,:,i) = segment_image_high(I);
   end
   [vol(i), area(i)] = region_volume(I_seg(:,:,i), h_px, d_px);
   
end

% figure, imshow(I_seg(:,:, 150))


%% Check rubbish images

flag = 1;
i = 1;
sel = []; 
sel2 = [];
sprintf('Please press y or n for acceptable or not acceptable segmentation\nPress Esc to exit\n...')
% sprintf('\nPress Enter to continue...')

while(flag)
    figure, imshow(I_seg(:,:,i));
    [~,~, button] = ginput(1);
    switch button
        case 110
            sel = [sel i];
        case 121
            sel2 = [sel2 i];
        case 27
            break
    end
    i = i+1;
end
close all
clear flag i

%% Calculate porosity

vol_init = 0.331;
% vol_init = mean(vol(sel2(find(sel2 < 80))));
t = 1:2861;
p = (vol-vol_init).*100./vol;

%% Identify outliers

% sel = (p < 80) | ((t <= 32) & (t > 80));
% sel = (p < 75) | ((t <= 32) & (t > 50));
% sel = (p<75);

% sel3 = ~find(t, sel)
options = fitoptions('Method','SmoothingSpline',...
                     'SmoothingParam', 0.001);
f1 = fit(t', p','poly9', 'Normalize','on','Robust','Bisquare');
figure, plot(f1, t, p)
ylim([0 100])

% identify outliers based on fits
fdata = feval(f1, t);
err = abs(fdata - p') > 1*std(p');
outliers = excludedata(t, p, 'indices', err);

f2 = fit(t', p', 'poly9', 'Normalize','on','Robust','Bisquare',...
    'Exclude', outliers);

figure, plot(f2, t, p)
ylim([0 100])

% Model values
p2 = feval(f2, t);
v2 = 100*vol_init./(100-p2);


%% Plots

figure, scatter(t, p, 3)
xlabel('Time in minutes')
ylabel('Porosity %')

figure, scatter(t, area, 3)
xlabel('Time in minutes')
ylabel('Surface area cm^2')

% Plots without outliers
figure, scatter(t(~outliers), p(~outliers), 3)
hold on,
plot(t, p2);
xlabel('Time in minutes')
ylabel('Porosity %')

figure, scatter(t(~outliers), area(~outliers), 3)
xlabel('Time in minutes')
ylabel('Surface area cm^2')

%% Save data as CSV

% Data with outliers
ds1 = dataset();
ds1.Time = t';
ds1.Volume = vol';
ds1.Porosity = p';
ds1.Surface_Area = area';
export(ds1, 'file', 'Furnace_data_with_outliers.csv', 'Delimiter', ',');

% Data without outliers
ds2 = dataset();
ds2.Time = t(~outliers)';
ds2.Volume = vol(~outliers)';
ds2.Porosity = p(~outliers)';
ds2.Surface_Area = area(~outliers)';
export(ds2, 'file', 'Furnace_data_without_outliers.csv', 'Delimiter', ',');

% Furnace data model fits
ds3 = dataset();
ds3.Time = t';
ds3.Volume = v2;
ds3.Porosity = p2;
export(ds3, 'file', 'Furnace_data_model.csv', 'Delimiter', ',');

