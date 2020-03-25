function [vol, area, d_l, img2] = region_volume(img, h_px, d_px, t)
%REGION_VOLUME calculates volume and surface area for region of interest
%
% The function has two modes; 
% MODE 'VOLUME'
%   input arguments:
%  
% MODE 'DIFFUSION'
%   

% Determine if diffusion skin volume needs to be calculated
if nargin <=2 
    disp('Not enough input arguments')
    return
elseif nargin == 3
    mode = 'volume';
    d_l = NaN;
elseif nargin == 4
    mode = 'diffusion';
    img2 = NaN;
elseif nargin > 4
    disp('Too many input arguments')
    return
end

sz = size(img);

if strcmp(mode, 'volume') % Inner volume mode
   
    % Shave off base
    
    ind1 = find(img(:, 1:5));
    ind2 = find(img(:, sz(2)-4:end));
    [i1, ~] = ind2sub([sz(1), 5], ind1);
    [i2, ~] = ind2sub([sz(1), 5], ind2);
    r = sort([i1;i2]);
    r = floor(mean(r(1:5)));

    img2 = img;
    img2(r:end, :) = 0;
    
    % removing base crap
    se = strel('disk', 1);
    img2 = imerode(img2, se);
    img2 = imdilate(img2, se);
    
    
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
    if (sz(1) <=100) && (sz(2) <=100)
       rs_f = 20;
    elseif (sz(1) <=500) && (sz(2) <=500)
        rs_f = 4;
    elseif (sz(1) <=1000) && (sz(2) <=1000)
        rs_f = 2;
    else
        rs_f = 1;
    end
    img_rs = imresize(img, rs_f);
    d_px = d_px * rs_f;
    h_px = h_px * rs_f;

    n_f = t(1);
    t_d = t(2);
    d_l_prev = t(3); % in mm
    
    T = (n_f + t_d)*10;
    if T >= 1000
        T = 1000;
    end
    T = T + 273.15;
    
    % diffusion value
    cw = 0.18;  P = 0.000101325; % diffusion parameters
    D = diff_val(T, cw, P);
%     D = 6.77e-13;
    
    % Diffusion length
    d_l_iso = sqrt(D*n_f*60)*1000;
    d_l_min = sqrt(D*((n_f*60)-60))*1000;
    d_l = (d_l_iso - d_l_min) + d_l_prev; % in mm
    
    d_l_px = d_l*d_px;    % in no. of pixels

    
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


end

end

