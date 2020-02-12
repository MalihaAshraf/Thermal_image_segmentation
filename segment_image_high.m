function out = segment_image_high(img)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

se = strel('disk',1);
se2 = strel('disk',2);

I = imerode(imerode(imdilate(imfill(imdilate(bwareaopen(imbinarize(imadjust(medfilt2(im2double(img))),... 
    'adapt', 'Sensitivity', 0.59), 200), se), [40 40] ), se2), se2), se);

out = I;

end

