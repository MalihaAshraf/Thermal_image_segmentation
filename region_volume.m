function [vol, area] = region_volume(img, h_px, d_px)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

h = 0;
for rr = 1:size(img, 1)
    if (find(img(rr, :)))
        h = h+1;
        d(h) = numel((find(img(rr, :))))/d_px;
        r(h) = d(h)/2;
        v(h) = pi*((r(h))^2);
        p(h) = 2*pi*r(h);
    end
end

vol = (sum(v)/h_px)/1000;

top = pi*r(1)^2/100;
bottom = pi*r(end)^2/100;
area = (sum(p)/h_px)/100;
area = area + top + bottom;

end

