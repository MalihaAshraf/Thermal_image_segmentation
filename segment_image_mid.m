function out = segment_image_mid(img, mode, var)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here


% nominal values:
%       sesnitivity = 0.59
%       erosion = 1;
%       no. of pixels = 400
% var = [sensitivity, erosion, no. of pixels

y = round(var(4)); x = round(var(5));
se = strel('disk', var(2));

if (strcmp(mode, 'debug'))
    figure, imshow(img, [])
    I1 = imbinarize(imadjust(medfilt2(im2double(img))), 'adapt', 'Sensitivity', var(1));
    figure, imshow(I1), title('1. binarize')
    I2 = imerode(I1, se);
    figure, imshow(I2), title('2. erode')
    I3 = bwareaopen(I2, var(3));
    figure, imshow(I3), title('3. area open')
    I4 = imdilate(I3, se);
    figure, imshow(I4), title('4. dilate')
    I5 = imfill(I4, [y x]);
    figure, imshow(I5), title('5. fill');
    I6 = imdilate(I5, se);
    I7 = imerode(I6, se);
%     I8 = imerode(I7,se);
    out = I7;
    figure, imshow(out), title('final')
else
    
    I = imerode(imdilate(imfill(imdilate(bwareaopen(imerode(imbinarize(imadjust(medfilt2(im2double(img))),... 
    'adapt', 'Sensitivity', var(1)), se), var(3)), se), [y x] ), se), se);

    out = I;
end


end

