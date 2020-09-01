%% Read file

clear all; close all
addpath('FLIR_class');

file_type = 'ptw'; % options: jpg, ptw

if strcmp(file_type, 'jpg')
    % Browse to directory
    path = uigetdir('*.*');
elseif strcmp(file_type, 'ptw')
    % Browse to file
    [file,path] = uigetfile('*.*');
end


%% Read files

if strcmp(file_type, 'jpg')
    files = dir([path '/*.' file_type]);
    nframes = double(length(files));
    ref = 1; % reference index of frame number
    frame = rgb2gray(imread(fullfile(files(ref).folder, files(ref).name)));
    clear ref
    
elseif strcmp(file_type, 'ptw')
    % Read .ptw file
    data = FlirMovieReader([path file]);

    % File information
    vars = info(data);
    nframes = double(vars.numFrames);
    clear vars
    
    [frame, ~] = read(data, 20);
end


i = 1;
% rect = [194, 100, 74, 57];
% rect2 = [24 35 28 23];

% Choose rotation angle
sprintf('Zoom in or out of the image using scroll. Press Enter to exit');
sprintf('Please click on any two points on the horizontal reference surface\nPress Enter to continue...')
pause()
figure, imshow(frame, []), title('Scroll to zoom. Press Enter to exit')
zoom on
waitfor(gcf, 'CurrentCharacter', char(13))
zoom reset
zoom off
title('Click on any two points on the horizontal reference surface')
[x, y] = ginput(2);
close all
angle = get_slope(x, y);
clear x y

% Choose region of interest
frame_r = imRotateCrop(frame, angle);
sprintf('Zoom in or out of the image using scroll. Press Enter to exit');
sprintf('Please drag rectangle across area of interest top-left to bottom-right\nPress Enter to continue...')
pause()
figure, imshow(imadjust(im2double(frame_r))), title('Scroll to zoom. Press Enter to exit')
zoom on
waitfor(gcf, 'CurrentCharacter', char(13))
zoom reset
zoom off
title('Drag rectangle across area of interest top-left to bottom-right')
rect = getrect();
rect = round(rect);
close all
clear frame metadata frame_r

%% show uncropped images
idx = 2000;
if strcmp(file_type, 'jpg')
    frame = rgb2gray(imread(fullfile(files(idx).folder, files(idx).name)));
    clear ref
elseif strcmp(file_type, 'ptw')
    data = FlirMovieReader([path file]);
    [frame, ~] = read(data, idx);    
end 
figure, imshow(imRotateCrop(frame, angle), [])
hold on
rectangle('Position',rect,...
    'EdgeColor', 'r','LineWidth',0.5,'LineStyle','-')

%% Read frames

clear i timelapse_cropped
if strcmp(file_type, 'jpg')
    for i = 1:nframes
        frame = (imread(fullfile(files(i).folder, files(i).name)));
        frame = frame(:,:,2);
        frame_r = imRotateCrop(frame, angle);
        frame_c = frame_r(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3));
        
        timelapse_cropped(:,:,i) = frame_c;
        MaxTemp(i, 1) = max(max(frame));
        MaxTemp(i, 2) = max(max(frame_c));
    %     MaxTemp(i, 3) = max(max(frame_s));

        MeanTemp(i, 1) = mean(mean(frame));
        MeanTemp(i, 2) = mean(mean(frame_c));
    end
else
    data = FlirMovieReader([path file]);
    i = 1;
    while ~isDone(data)
        [frame, metadata] = step(data);
        frame_r = imRotateCrop(frame, angle);
        d = 0;         % Adjust this number to fix cropping in x direction
        frame_c = frame_r(rect(2):rect(2)+rect(4), rect(1)+d:rect(1)+rect(3));
    %     frame_s = frame_c(rect2(2):rect2(2)+rect2(4), rect2(1):rect2(1)+rect2(3));

        timelapse_raw(:,:,i) = frame;
        timelapse_cropped(:,:,i) = frame_c;
%         MaxTemp(i, 1) = max(max(frame));
%         MaxTemp(i, 2) = max(max(frame_c));
%     %     MaxTemp(i, 3) = max(max(frame_s));
% 
%         MeanTemp(i, 1) = mean(mean(frame));
%         MeanTemp(i, 2) = mean(mean(frame_c));
    %     MeanTemp(i, 3) = mean(mean(frame_s));

        i = i+1;
    end
end


% if repeat, uncomment following
% clear timelapse_raw timelapse_cropped MaxTemp MeanTemp
% i = 1


figure, imshow(timelapse_cropped(:,:,500), [])

%% Remove unwanted frames (optional)

sel = [];                       % Enter frame indices to be removed, e.g., [1:50, 200, 500:890]
timelapse_raw(:,:, sel) = [];
timelapse_cropped(:,:, sel) = [];
MaxTemp(:,:,sel) = [];
MeanTemp(:,:,sel) = [];


%% Initialize variables (sample dimensions)

clear timelapse_raw
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

h_px = h/11.27; % px/mm; Enter measured height
d_px = d/10.10; % px/mm; Enter measured diameter


%% Fine-tune segmentation

if strcmp(file_type, 'ptw')
    % low
    close all
    I =  timelapse_cropped(:,:, 45);
    var_low = [0.63, 1, 150];
    [~, var_low(4), var_low(5)] = segment_image_low(I, 'debug', var_low);

    %%
    % mid
    close all
    I =  timelapse_cropped(:,:, 100);
    var_mid = [0.6, 2, 1000, var_low(4), var_low(5)];
    [~, var_mid] = segment_image_mid(I, 'debug', var_mid);

    %%
    % high
    close all
    I =  timelapse_cropped(:,:, 500);
    var_high = {0.5905, 6, 200, var_low(4), var_low(5)};
    [~, var_high] = segment_image_high(I, 'debug', var_high);

elseif strcmp(file_type, 'jpg')
    close all
    I =  timelapse_cropped(:,:, 500);
    var = {0.59, 2, 1000};
    figure, imshow(I);
    sprintf('Please click the centre of the sample\nPress Enter to continue...')
    pause()
    [x, y] = ginput(1);
    var{4} = y; var{5} = x;
    [img, var{6}, var{7}] = segment_image_high(I, 'debug', var);
%     figure, imshow(img);
%     clear img
end


%% Process images and calculate outer volume and surface area

remove_base = true;

if strcmp(file_type, 'ptw')
    for i = 1:size(timelapse_cropped, 3)
       I = timelapse_cropped(:,:, i);
       if i <=45        % Frame where the sample and bck is the same temp. Gray image
           I_seg(:,:,i) = segment_image_low(I, 'normal', var_low);
       elseif i <=140 && i > 45         % 
           I_seg(:,:,i) = segment_image_mid(I, 'normal', var_mid);
       else
           I_seg(:,:,i) = segment_image_high(I, 'normal', var_high);
       end
       [vol(i), area(i), ~, I_seg(:,:,i), ax_l(i, :)] = region_volume(I_seg(:,:,i), h_px, d_px, remove_base);

    end
elseif strcmp(file_type, 'jpg')
    for i = 1:size(timelapse_cropped, 3)
        I = timelapse_cropped(:,:, i);
        I_seg(:,:,i) = segment_image_high(I, 'normal', var);
        [vol(i), area(i), ~, I_seg(:,:,i), ax_l(i,:)] = region_volume(I_seg(:,:,i), h_px, d_px, remove_base);
    end 
end


% figure, imshow(I_seg(:,:, 150))


%% Check rubbish images

flag = 1;
i = 1;
sel = []; 
sel2 = [];
sprintf('Please press y or n for acceptable or not acceptable segmentation\nPress Esc to exit\n...')
% sprintf('\nPress Enter to continue...')

figure,
while(flag)
    clf
    imshow(I_seg(:,:,i));
    title(['Frame: ' num2str(i)])
    [~,~, button] = ginput(1);
    switch button
        case 110 % no
            sel = [sel i];
        case 121 % yes
            sel2 = [sel2 i];
        case 27
            break
    end
    i = i+1;
end
% close all
clear flag i
close all

%% Calculate porosity

vol_pyc = 0.8959;
vol_init = mean(vol(sel2));
area_init = mean(area(sel2));
display(['Calculated volume: ' num2str(vol_init)]);

t = 1:nframes;
p_pyc = (vol-vol_pyc).*100./vol;
p = (vol-vol_init).*100./vol;

%% Identify outliers

% sel = (p < 80) | ((t <= 32) & (t > 80));
% sel = (p < 75) | ((t <= 32) & (t > 50));
% sel = (p<75);

% sel3 = ~find(t, sel)
options = fitoptions('Method','SmoothingSpline',...
                     'SmoothingParam', 0.00001);
bp = [250, 275, 300]; % breaking point between the two curves
bp = [170, 175, 180]; % breaking point between the two curves

idx1 = (t <= bp(3)) & ~isnan(p) & (p > 0);
idx2 = (t >= bp(1)) & ~isnan(p) & (p > 0);
            
f1 = fit(t(idx1)', p(idx1)','exp1', 'Normalize','on','Robust','Bisquare');
f2 = fit(t(idx2)', p(idx2)','poly9', 'Normalize','on','Robust','Bisquare');

% f1 = fit(t(~isnan(p))', p(~isnan(p))',...
%     'cubicsp', options);

fdata = p;
fdata(1:bp(2)) = feval(f1, t(1:bp(2)));
fdata(bp(2)+1:end) = feval(f2, t(bp(2)+1:end));

figure, scatter(t, p, 3, 'b', 'filled')
hold on
plot(t, fdata, 'r', 'LineWidth', 1)
title('Fit with outliers')
ylim([0 100])


% identify outliers based on fits
[~,distance,~] = distance2curve( cat(2, t', fdata'), cat(2, t', p'));
e = 2.5; % error tolerance
err = distance > e;
err(isnan(distance)) = 1;
outliers = excludedata(t, p, 'indices', err);

figure, scatter(t(~outliers), p(~outliers), 3, 'b', 'filled')
hold on
plot(t, fdata, 'r', 'LineWidth', 1)
title('Fit without outliers')
ylim([0 100])

% Model values
% p2 = feval(f2, t);
p2 = fdata;
v2 = 100*vol_init./(100-p2);

%% Calculating diffusion skin and inner core volume etc

t_d = 2.5; % Initial temperature/10
tic
t_iso = 60;

% vol_d = NaN*ones(nframes, 1);
% vol_c = NaN*ones(nframes, 1);
% area_c = NaN*ones(nframes, 1);
% d_l = NaN*ones(nframes, 4);
% strain = NaN*ones(nframes, 1);
% img_d = cell(nframes, 1);

for i =1:size(I_seg, 3)
    i
    if isnan(vol(i)) || outliers(i)
        t_iso = t_iso + 60;
        vol_d(i, :) = NaN;
        vol_c(i, :) = NaN;
        area_c(i, :) = NaN;
        d_l(i, :)= [NaN, NaN , NaN, NaN];
        strain(i, :) = NaN;
        img_d{i} = NaN;
        continue
    else
        t_iso_prev = t_iso;
        t_iso = 60;
        n = t_iso_prev/60;
    end
   
    if (i == 1) || ( i-n <= 1)
        d_l_prev = 0;
        d_v_prev = 0;
        area_prev = area_init;
        v_prev = vol_init;
    else
        d_l_prev = d_l(i-n, 1);
        d_v_prev = vol_d(i-n);
        area_prev = area(i-n);
        v_prev = vol(i-n);
    end
    
    if 1 % previous method
        [vol_c(i, :), area_c(i, :), d_l(i, :), img_d{i}, ~] =... 
            region_volume(I_seg(:,:,i), h_px, d_px, 'diffusion',... 
            [i, t_d, t_iso_prev, d_l_prev, d_v_prev, v_prev]);
     vol_d(i, :) = vol(i) - vol_c(i, :);
    else
    % think skin method
   [vol_c(i, :), area_c(i, :), d_l(i, :), strain(i, :), img_d{i}] =... 
       region_diff_skin( I_seg(:,:,i), 'cyl', h_px, d_px,... 
       [i, t_d, t_iso_prev, d_v_prev, area_prev, area(i)]);
    vol_d(i, :) = vol(i) - vol_c(i, :);
    end
end
toc

%% Plots

figure, scatter(t(~outliers), (ax_l(~outliers,1)), 3)
hold on
scatter(t(~outliers), ax_l(~outliers,2), 3)
xlabel('Time in minutes')
ylabel('Axes length')
hold off

figure, scatter(t, (vol_d'), 3)
hold on
scatter(t, vol, 3)
scatter(t, (vol_d'), 3)
xlabel('Time in minutes')
ylabel('Volume')
hold off

figure, scatter(t, p, 3)
xlabel('Time in minutes')
ylabel('Porosity %')
ylim([0 100]);

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

% Path for exported data
path = uigetdir('*.*');

% Data with outliers
ds1 = dataset();
ds1.Time = t';
ds1.Volume = vol';
ds1.Porosity = p';
ds1.Surface_Area = area';
ds1.Core_Volume = vol_d';
ds1.Core_Surf_Area = area_c';
ds1.Diffusion_Length = d_l';
export(ds1, 'file', fullfile(path, 'Furnace_data_with_outliers.csv'), 'Delimiter', ',');

% Data without outliers
ds2 = dataset();
ds2.Time = t(~outliers)';
ds2.Volume = vol(~outliers)';
ds2.Porosity = p(~outliers)';
ds2.Surface_Area = area(~outliers)';
ds2.Core_Volume = vol_d(~outliers)';
ds2.Core_Surf_Area = area_c(~outliers)';
ds2.Diffusion_Length = d_l(~outliers)';
export(ds2, 'file', fullfile(path,'Furnace_data_without_outliers.csv'), 'Delimiter', ',');

% Furnace data model fits
ds3 = dataset();
ds3.Time = t';
ds3.Volume = v2;
ds3.Porosity = p2;
export(ds3, 'file', fullfile(path,'Furnace_data_model.csv'), 'Delimiter', ',');


%% Write movie

diff_skin = true; % movie should have diffusion skin or not

if diff_skin
    vid_frames = cell(2, 1);
    vid_frames{1} = I_seg;
    vid_frames{2} = img_d;
else
    vid_frames = cell(1, 1);
    vid_frames{1} = I_seg;
end

writeMovie(vid_frames, timelapse_cropped, outliers, 'test_skin2.mp4');

clear diff_skin vid_frames

%% save workspace

clear d_flag distance err f1 f2 fdata I idx1 idx2 metadata options p2 p_pyc v2 
save('workspace_test.mat')


