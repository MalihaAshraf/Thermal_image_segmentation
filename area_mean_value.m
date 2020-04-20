function val = area_mean_value(img, msg)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 2
   msg = 'Select required area'; 
end

figure
imshow(img, [])
title(msg)

rect = getrect();
rect = round(rect);

area = img(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3));
val = mean(mean(area));

close all

end

