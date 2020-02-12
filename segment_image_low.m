function out = segment_image_low(img)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

se = strel('disk',1);
se2 = strel('disk',2);

I = imerode(imdilate(imfill(imfill(bwareaopen(imerode(imcomplement(imbinarize...
    (imadjust(medfilt2(im2double(img))), 'adapt', 'Sensitivity', 0.59)),... 
    se), 400), [40 40] ), [35, 45]), se2), se);

out = I;

end

