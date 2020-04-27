function [vol, area, d_l, strain, img_d] = region_diff_skin(img, shape, h_px, d_px, t)
%REGION_VOLUME calculates volume and surface area for region of interest
%
%   input arguments:
%		t = [n_f t_d t_iso d_l_prev(2) d_v_prev(2), v_full]

% Determine if diffusion skin volume needs to be calculated
% if nargin <= 3
%     disp('Not enough input arguments')
%     return
% elseif nargin == 4
%     mode = 'volume';
%     d_l = NaN;
% elseif nargin == 5
%     mode = 'diffusion';
%     img2 = NaN;
% elseif nargin > 5
%     disp('Too many input arguments')
%     return
% end

sz = size(img);

% Diffusion length
rs_f = 150; % resiszing parameter
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
d_v_prev = t(4)*1000; % in mm^3
A0 = t(5)*100;
A = t(6)*100;

d_l = [NaN, NaN, NaN];

strain = (A - A0 )./A0;

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

% Diffusion length (with shear)

if strcmp(shape, 'cyl')
    f2 = d_v_prev./(4*pi);
    R = sqrt((6*A*(strain+1))/pi)/6;
elseif strcmp(shape, 'sph')
    f2 = 3*d_v_prev./(8*pi);
    R = sqrt((A*(strain+1))/pi)/2;
end
f1 = (R.^3)./2;

f = -f1 + f2;
d = abs(nthroot(abs(f)+f, 3)+...
    nthroot(-abs(f)+f, 3) + R);

d_l(2) = d;
d_l(3) = (d_l_iso - d_l_gap);
d_l(1) =  d_l(3) + d;
d_l_px = (d_l(1) * d_px);
d_l(4) = (d_l_px);

if 0%~mod(n_f, 20)
    [vol, area, img_c] = calc_diff_core(img_rs, d_l(1), h_px, d_px, 'img');
    img_d = imresize(img_rs - img_c, 1/rs_f);
else
    [vol, area, ~] = calc_diff_core(img_rs, d_l(1), h_px, d_px, '');
    img_d = NaN;
end

end

%% Helper functions
function [vol, area] = calc_3d_dims_img(img, h_px, d_px, d_l)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
  h = 0;
    v = [];
    for rr = 1:size(img, 1)
        if (find(img(rr, :)))
            h = h+1;
            d(h) = numel((find(img(rr, :))))/d_px;
            r(h) = (d(h)/2) - d_l;
            v(h) = pi*((r(h))^2);
            p(h) = 2*pi*r(h);
        end
    end

    if ~isempty(v)
        % accounting for top and bottom
        d_l_px = d_l*d_px;
        h_d = round(d_l_px);
        
        vol = (sum(v(h_d+1:end-h_d))/h_px)/1000;
        top = pi*r(h_d+1)^2/100;
        bottom = pi*r(end-h_d)^2/100;
        area = (sum(p(h_d+1:end-h_d))/h_px)/100;
        area = area + top + bottom;
    else
        vol = NaN;
        area = NaN;
    end
end

function [vol, area, img_v] = calc_diff_core(img, d_l, h_px, d_px, mode)

    [vol, area] = calc_3d_dims_img(img, h_px, d_px, d_l);
    
    if strcmp(mode, 'img')
        d_l_px = d_l * d_px;
        se = strel('disk', floor(d_l_px), 8);
        img_v = imerode(img, se);
    else 
        img_v = NaN;
    end    

end