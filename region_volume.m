function [vol, area, d_l, img2] = region_volume(img, h_px, d_px, base_mode, t)
%REGION_VOLUME calculates volume and surface area for region of interest
%
% The function has two modes; 
% MODE 'VOLUME'
%   input arguments:
%  
% MODE 'DIFFUSION'
%   output arguments:
%		t = [n_f t_d t_iso d_l_prev(2) d_v_prev(2), v_full]

% Determine if diffusion skin volume needs to be calculated
if nargin <= 3
    disp('Not enough input arguments')
    return
elseif nargin == 4
    mode = 'volume';
    d_l = NaN;
elseif nargin == 5
    mode = 'diffusion';
    img2 = NaN;
elseif nargin > 5
    disp('Too many input arguments')
    return
end

sz = size(img);

if strcmp(mode, 'volume') % Inner volume mode
   
    if base_mode
        % Shave off base
        
        ind1 = find(img(:, 1:5));
        ind2 = find(img(:, sz(2)-4:end));
        [i1, ~] = ind2sub([sz(1), 5], ind1);
        [i2, ~] = ind2sub([sz(1), 5], ind2);

        r = sort([i1;i2]);
        if length(r) < 5
           vol = NaN;
           area = NaN;
           img2 = img;
           return;
        end
        r = floor(mean(r(1:5)));

        img2 = img;
        img2(r:end, :) = 0;

        % removing base crap
        se = strel('disk', 1); % size of base pixels remainders
        img2 = imerode(img2, se);
        img2 = imdilate(img2, se);
     
    else
        img2 = img;
    end
    
    if 1
        a = regionprops(img2, 'Centroid');
        if length(a) > 1
            for i = 2:length(a)
                img2  = imcomplement(imfill(imcomplement(img2), flip(round(a(i).Centroid))));
            end
        end
    end
    
    % Calculating volume and area
   [vol, area] = calc_3d_dims_img(img2, h_px, d_px);
    d_flag = NaN;
    
elseif strcmp(mode, 'diffusion') % Diffusion skin mode
    
    % Diffusion length
    rs_f = 20; % resiszing parameter
%     if (sz(1) <=100) && (sz(2) <=100)
%        rs_f = 200;
%     elseif (sz(1) <=500) && (sz(2) <=500)
%         rs_f = 200;
%     elseif (sz(1) <=1000) && (sz(2) <=1000)
%         rs_f = 200;
%     else
%         rs_f = 200;
%     end
    img_rs = imresize(img, rs_f);
    d_px = d_px * rs_f;
    h_px = h_px * rs_f;

    n_f = t(1);
    t_d = t(2);
    t_iso = t(3);
%     d_l_prev = [t(4), t(5)]; % in mm
%     d_v_prev = [t(6), t(7)];
%     v_full = t(8);
    
    d_l_prev = [t(4)]; % in mm
    d_v_prev = [t(5)];
    v_full = t(6);
    
    T = (n_f + t_d)*10;
    if T >= 1000
        T = 1000;
    end
    T = T + 273.15;
    
    % diffusion value
    cw = 0.18;  P = 0.000101325; % diffusion parameters
    D = diff_val(T, cw, P);
%     D = 6.77e-13;
    

    % Diffusion length (no shear)
    d_l_iso = sqrt(D*n_f * 60)*1000;
    d_l_gap = sqrt(D*((n_f * 60)- t_iso))*1000;
    
    d_l(1) = (d_l_iso - d_l_gap) + d_l_prev(1); % in mm
    
    d_l_px = d_l(1)*d_px;    % in no. of pixels
    
    [vol(1), area(1), img2] = calc_diff_core(img_rs, d_l_px, h_px, d_px);
    
    % Diffusion length (with shear)
    if 0
    vol(2) = v_full;
    d_l(2) = 0;
    d_l_px = 0;
%     d_l_new = 0;
    d_flag = [false, false];
    
    if d_v_prev(2) ~= 0
        while d_v_prev(2) >= (v_full - vol(2))
            d_l_px = d_l_px + 1;
            [vol(2), area(2)] = calc_diff_core(img_rs, d_l_px, h_px, d_px);
        end
       
%         if ((v_full - vol(2)) / d_v_prev(2)) > 1.1
%             d_flag(1) = true;
%             d_l_px = d_l_px - 1;
%             [vol(2), area(2)] = calc_diff_core(img_rs, d_l_px, h_px, d_px);
%         end
%         if d_l_px ~= 0
%             d_l_new = d_l_px / d_px;
%         end
    
    end
%     
%     if (d_l_new > d_l_prev(2)) || (d_l_px == 0)
%         d_flag(2) = true;
%         d_l_diff = d_l_prev(2);
%     else
%         d_l_diff = d_l_new;
%     end
%     d_l(3) = d_l_diff;
%     vol(3) = vol(2);
    
    if d_l_px < 5
        
        d_l_diff = d_l_prev(2);
        d_l(3) = d_l_diff;
        d_l(2) = (d_l_iso - d_l_gap) + d_l_diff; % in mm
        d_l_px = d_l(2) * d_px;
        [vol(2), area(2)] = calc_diff_core(img_rs, d_l_px, h_px, d_px);
        vol(3) = NaN;
    else
        d_flag(1) = true;
        vol(3) = vol(2);
        d_l_diff = d_l_px / d_px;
        d_l(3) = d_l_diff;
        d_l(2) = (d_l_iso - d_l_gap) + d_l_diff; % in mm
        d_l_px = d_l(2) * d_px;
        [vol(2), area(2)] = calc_diff_core(img_rs, d_l_px, h_px, d_px);
    end
        
%     d_l(2) = (d_l_iso - d_l_gap) + d_l_diff; % in mm
%     
%     d_l_px = d_l(2) * d_px;
%     [vol(2), area(2)] = calc_diff_core(img_rs, d_l_px, h_px, d_px);
    end
    
    img2 = imresize(img2, 1/rs_f);
end

end

%% Helper functions
function [vol, area] = calc_3d_dims_img(img, h_px, d_px)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
  h = 0;
    v = [];
    for rr = 1:size(img, 1)
        if (find(img(rr, :)))
            h = h+1;
            d(h) = numel((find(img(rr, :))))/d_px;
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
end

function [vol, area, img_d] = calc_diff_core(img, d_l_px, h_px, d_px)

    se = strel('disk', round(d_l_px), 8);
    img_v = imerode(img, se);
    img_d = img - img_v;

    [vol, area] = calc_3d_dims_img(img_v, h_px, d_px);

end