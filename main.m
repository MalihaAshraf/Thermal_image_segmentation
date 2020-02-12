%% Read file

addpath('FLIR_class');

% Read .ptw file
data = FlirMovieReader('7p5mm_1000C_48hr_002/Rec-000523-001_00_26_22_883.ptw');
% File information
vars = info(data);
i = 1;
rect = [194, 100, 74, 57];
rect2 = [24 35 28 23];

while ~isDone(data)
    [frame, metadata] = step(data);
    frame_r = imrotate(frame, 2);
    frame_c = frame_r(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3));
    frame_s = frame_c(rect2(2):rect2(2)+rect2(4), rect2(1):rect2(1)+rect2(3));
    
    timelapse_raw(:,:,i) = frame;
    timelapse_cropped(:,:,i) = frame_c;
    MaxTemp(i, 1) = max(max(frame));
    MaxTemp(i, 2) = max(max(frame_c));
    MaxTemp(i, 3) = max(max(frame_s));
    
    MeanTemp(i, 1) = mean(mean(frame));
    MeanTemp(i, 2) = mean(mean(frame_c));
    MeanTemp(i, 3) = mean(mean(frame_s));
    
    i = i+1;
end

%% Initialize variables

h_px = 29.89/7.41; % px/mm
d_px = 38.875/7.55; % px/mm

%% Process images

for i = 1:size(timelapse_cropped, 3)
   I = timelapse_cropped(:,:, i);
   if i <=45
       I_seg(:,:,i) = segment_image_low(I);
   elseif i <=150 && i > 45
       I_seg(:,:,i) = segment_image_mid(I);
   else
       I_seg(:,:,i) = segment_image_high(I);
   end
   [vol(i), area(i)] = region_volume(I_seg(:,:,i), h_px, d_px);
   
end

%% Calculate porosity

vol_init = 0.331;
t = 1:2861;
p = (vol-vol_init).*100./vol;

%% Identify outliers

% sel = (p < 80) | ((t <= 32) & (t > 80));
% sel = (p < 75) | ((t <= 32) & (t > 50));
sel = (p<75);
options = fitoptions('Method','SmoothingSpline',...
                     'SmoothingParam', 0.001);
f1 = fit(t(sel)', p(sel)','poly9', 'Normalize','on','Robust','Bisquare');
figure, plot(f1, t, p)

% identify outliers based on fits
fdata = feval(f1, t);
err = abs(fdata - p') > 1*std(p');
outliers = excludedata(t, p, 'indices', err);

f2 = fit(t', p', 'poly9', 'Normalize','on','Robust','Bisquare',...
    'Exclude', outliers);

figure, plot(f2, t, p)

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

