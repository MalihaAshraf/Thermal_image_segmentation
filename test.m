
%%

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

h_px = 29.89/7.41; % px/mm
d_px = 38.875/7.55; % px/mm

%%
I_orig = timelapse_cropped(:,:, 1);
I = im2double(I_orig);
I2 = medfilt2(I_orig);
% figure, imshow(I, [])


I3 = imadjust(I2);
% figure, imshow(I3)

cont = mean(mean(I3(rect2(2):rect2(2)+rect2(4), rect2(1):rect2(1)+rect2(3))));
I4 = imbinarize(I3);

figure, subplot(1, 3, 1), imshow(I, [])
subplot(1, 3, 2), imshow(I3)
subplot(1, 3, 3), imshow(I4)

%% Mid and high

I_orig = timelapse_cropped(:,:, 1549);
I = im2double(I_orig);
I2 = medfilt2(I);
% figure, imshow(I, [])


I3 = imadjust(I2);
% figure, imshow(I3)

% cont = mean(mean(I3(rect2(2):rect2(2)+rect2(4), rect2(1):rect2(1)+rect2(3))));
I4 = imbinarize(I3, 'adapt', 'Sensitivity', 0.595);

se = strel('disk',1);
I5 = bwareaopen(I4, 500);
% I6 = imerode(I5, se);
se2 = strel('disk',2);
I6 = imdilate(I5, se);
I7 = imfill(I6, [40 40] );
I8 = imerode(imerode(imdilate(I7, se2), se2), se);

% I6 = bwareaopen(I5, 5);

% se = strel('disk',1);
% I6 = imerode(I5, se);

num = 8;
figure, subplot(1, num, 1), imshow(I, [])
subplot(1, num, 2), imshow(I3)
subplot(1, num, 3), imshow(I4)
subplot(1, num, 4), imshow(I5)
subplot(1, num, 5), imshow(I6)
subplot(1, num, 6), imshow(I7)
subplot(1, num, 7), imshow(I8)

%%

I_orig = timelapse_cropped(:,:, 38);
I = im2double(I_orig);
I2 = medfilt2(I);
% figure, imshow(I, [])


I3 = imadjust(I2);
% figure, imshow(I3)

% cont = mean(mean(I3(rect2(2):rect2(2)+rect2(4), rect2(1):rect2(1)+rect2(3))));
I4 = imcomplement(imbinarize(I3, 'adapt', 'Sensitivity', 0.59));

se = strel('disk',1);
I5 = imerode(I4, se);

I6 = bwareaopen(I5, 400);
% I6 = imerode(I5, se);
se2 = strel('disk',2);
% I6 = imdilate(I5, se);
% I7 = (imfill(I6, [40 40] ));

I7 = imfill(imfill(I6, [35 45] ), [40 40]);
I8 = (imerode(imdilate(I7, se2), se));
% I8 = imerode(imerode(imdilate(I7, se2), se2), se);

% I6 = bwareaopen(I5, 5);

% se = strel('disk',1);
% I6 = imerode(I5, se);

num = 8;
figure, subplot(1, num, 1), imshow(I, [])
subplot(1, num, 2), imshow(I3)
subplot(1, num, 3), imshow(I4)
subplot(1, num, 4), imshow(I5)
subplot(1, num, 5), imshow(I6)
subplot(1, num, 6), imshow(I7)
subplot(1, num, 7), imshow(I8)

%%
se = strel('disk',3);
I4 = imerode(I3, se);
figure, imshow(I4)

%%
rect3 = [6 13 66 45];
mask = zeros(size(I));
mask(rect3(2):rect3(2)+rect3(4), rect3(1):rect3(1)+rect3(3)) = 1;
% figure, imshow(mask)
bw = activecontour(I3,mask,300);
figure
imshow(bw)


%%
I = timelapse_raw(:,:, 1);
I = im2double(I);
K = wiener2(I,[5 5]);
figure, imshow(I, [])
figure, imshow(K, [])

%%

g = imgradient(I, 'intermediate');
figure, imshow(g, [])

%%
I2 = imgaussfilt(I, 3);
figure, imshow(I2, [])
I3 = imbinarize(I2);
figure, imshow(I3, [])


%%
bw = edge(I, 'log');
figure, imshow(bw)

%%
I2 = imtophat(I, strel('disk', 2));
figure, imshow(I2, [])

%%
 s = strel('square', 5);
 I3 = imclose(I, s);
 figure, imshow(I3, [])
I4 = imopen(I3, s);
figure, imshow(I4, [])

%%
mask = zeros(size(frame));
mask(10:57, 10:80) = 1;
figure, imshow(mask)
bw = activecontour(I2,mask,300);
figure
imshow(bw)

%%

I_f = fft2(I);
%f_mask = circ_mask(I_f, 50);
rect_mask = ones(size(I_f));
rect_mask(1:20, 1:30) = 0;
I3 = ifft2(I_f.*~rect_mask);

figure, imshow(I3, [])
% figure, imshow(fftshift(real(I_f)));

%%
I2 = wdenoise2(I);
figure, imshow(I2, [])

%%
bw = imbinarize(I2, mean(mean(I2)).*1.001);
figure, imshow(bw)

%%
se = strel('square',7);
bw3 = imclose(bw,se);
figure, imshow(bw3)

bw4 = imopen(bw3, se);
figure, imshow(bw4)

%%
last = timelapse_raw(:,:,end);
l2 = imgradient(last);
figure, imshow(l2, [])



%%
frame1 = im2double(frame);
frame2 = imadjust(frame1);
figure, imshow(frame2)
