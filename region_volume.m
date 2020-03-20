function [img2, vol, area, vol_d, area_d] = region_volume(img, h_px, d_px, t)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% Shave off base
sz = size(img);
ind1 = find(img(:,1:5));
ind2 = find(img(:, sz(2)-4:end));
[i1, ~] = ind2sub([sz(1), 5], ind1);
[i2, ~] = ind2sub([sz(1), 5], ind2);
r = sort([i1;i2]);
r = round(mean(r(1:5)));

img2 = img;
img2(r:end, :) = 0;


% Calculating volume and area
h = 0;
v = [];
for rr = 1:size(img2, 1)
    if (find(img2(rr, :)))
        h = h+1;
        d(h) = numel((find(img2(rr, :))))/d_px;
        r(h) = d(h)/2;
        v(h) = pi*((r(h))^2);
        p(h) = 2*pi*r(h);
    end
end

if ~isempty(v)
    vol = (sum(v)/h_px)/1000;
    top = pi*r(1)^2/100;
    bottom = pi*r(end)^2/100;
    area = (sum(p)/h_px)/100;
    area = area + top + bottom;
else
    vol = NaN;
    area = NaN;
end

% Diffusion length
rs_f = 10;
img_rs = imresize(img2, rs_f);
d_px = d_px * rs_f;
h_px = h_px * rs_f;

n_f = t(1);
t_d = t(2);
D = 6.77e-13;

if n_f >= round(98 - t_d)
    n_f(2) = n_f - round(98 - t_d) + 1;
%     d_l(1) = sqrt((n_f*60)*D)*1000; % in mm
%     d_l_px(1) = d_l*d_px;
end

d_l = sqrt((n_f*60)*D)*1000; % in mm
d_l_px = d_l*d_px;

for j = 1:length(d_l)
    se = strel('disk', round(d_l_px(j)), 8);
    img_v{j} = imerode(img_rs, se);
    img_d{j} = img_rs - img_v{j};
    h_d = 0;
    v_d = [];
    
    for rr = 1:size(img_v{j}, 1)
        if (find(img_v{j}(rr, :)))
            h_d = h_d+1;
            d_d(h_d) = numel((find(img_v{j}(rr, :))))/d_px;
            r_d(h_d) = d_d(h_d)/2;
            v_d(h_d) = pi*((r_d(h_d))^2);
            p_d(h_d) = 2*pi*r_d(h_d);
        end
    end
    
    if ~isempty(v_d)
        vol_d(j) = (sum(v_d)/h_px)/1000;
        top = pi*r_d(1)^2/100;
        bottom = pi*r_d(end)^2/100;
        area_d(j) = (sum(p_d)/h_px)/100;
        area_d(j) = area_d(j) + top + bottom;
    else
        vol_d(j) = NaN;
        area_d(j) = NaN;
    end
end

if length(d_l) < 2
    vol_d(2) = NaN;
    area_d(2) = NaN;
end

end

