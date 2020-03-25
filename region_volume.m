function [vol, area, img2] = region_volume(img, h_px, d_px, t)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% Determine if diffusion skin volume needs to be calculated
if nargin <=2 
    disp('Not enough input arguments')
    return
elseif nargin == 3
    mode = 'volume';
elseif nargin == 4
    mode = 'diffusion';
    img2 = NaN;
elseif nargin > 4
    disp('Too many input arguments')
    return
end



if strcmp(mode, 'volume') % Inner volume mode
   
    % Shave off base
    sz = size(img);
    ind1 = find(img(:, 1:5));
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
    
      
    
elseif strcmp(mode, 'diffusion') % Diffusion skin mode
    
    % Diffusion length
    rs_f = 10; % resiszing parameter
    img_rs = imresize(img, rs_f);
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
        h = 0;
        v = [];

        for rr = 1:size(img_v{j}, 1)
            if (find(img_v{j}(rr, :)))
                h = h+1;
                d(h) = numel((find(img_v{j}(rr, :))))/d_px;
                r(h) = d(h)/2;
                v(h) = pi*((r(h))^2);
                p(h) = 2*pi*r(h);
            end
        end

        if ~isempty(v)
            vol(j) = (sum(v)/h_px)/1000;
            top = pi*r(1)^2/100;
            bottom = pi*r(end)^2/100;
            area(j) = (sum(p)/h_px)/100;
            area(j) = area(j) + top + bottom;
        else
            vol(j) = NaN;
            area(j) = NaN;
        end
    end
    
    if length(d_l) < 2
        vol(2) = NaN;
        area(2) = NaN;
    end


end

end

