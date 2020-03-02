function out = segment_image_high(img, mode, var)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% nominal values:
%       sesnitivity = 0.59
%       erosion = 1;
%       no. of pixels = 400
% var = [sensitivity, erosion, no. of pixels

y = round(var(4)); x = round(var(5));
se = strel('disk', var(2));
se2 = strel('disk',2);

if (strcmp(mode, 'debug'))
    figure, imshow(img, [])
    I1 = imbinarize(imadjust(medfilt2(im2double(img))), 'adapt', 'Sensitivity', var(1));
    figure, imshow(I1), title('1. binarize')
    I2 = bwareaopen(I1, var(3));
    figure, imshow(I2), title('2. area open')
    I3 = imdilate(I2, se);
    figure, imshow(I3), title('3. dilate')
    I4 = imfill(I3, [y x]);
    figure, imshow(I4), title('4. fill');
    I5 = imdilate(I4, se2);
    I6 = imerode(I5, se2);
    I7 = imerode(I6, se);
    
    out = I7;
    figure, imshow(out), title('final')
    
else
    
    I = imerode(imerode(imdilate(imfill(imdilate(bwareaopen(imbinarize(imadjust(medfilt2(im2double(img))),... 
        'adapt', 'Sensitivity', var(1)), var(3)), se), [y x] ), se2), se2), se);

    out = I;

end

end

