function [out, y, x] = segment_image_low(img, mode, var)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% nominal values:
%       sesnitivity = 0.59
%       erosion = 1;
%       no. of pixels = 400
% var = [sensitivity, erosion, no. of pixels

se = strel('disk', var(2));
se2 = strel('disk',2);

if (strcmp(mode, 'debug'))
    figure, imshow(img, [])
    I1 = imbinarize(imadjust(medfilt2(im2double(img))), 'adapt', 'Sensitivity', var(1));
    figure, imshow(I1), title('1. binarize')
    I2 = imcomplement(I1);
    figure, imshow(I2), title('2. complement')
    I3 = imerode(I2, se);
    figure, imshow(I3), title('3. erode')
    I4 = bwareaopen(I3, var(3));
    figure, imshow(I4), title('4. area open')
    
    sprintf('Please click the centre of the sample\nPress Enter to continue...')
    pause()
    [x, y] = ginput(1);
    
    I5 = imfill(I4, round([y x]));
    figure, imshow(I5), title('5. fill')
%     I6 = imfill(I5, [35, 45]);
%     figure, imshow(I6), title('6. fill')
    I6 = imdilate(I5, se);
%     I8 = imerode(I7, se2);
    I = I6;
    figure, imshow(I), title('final');
    out = I;
else
    y = round(var(4)); x = round(var(5));
    I = imdilate(imfill(imfill(bwareaopen(imerode(imcomplement(imbinarize...
    (imadjust(medfilt2(im2double(img))), 'adapt', 'Sensitivity', var(1))),... 
    se), var(3)), [y, x] ), [y, x]), se);
    
    
    out = I;
end


end

