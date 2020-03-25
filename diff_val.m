function D = diff_val(T, cw, P)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% Zhang and Ni Paper

k = -18.1 + 1.888.*P - (9699 + 3626.*P)./T;
D = cw.*exp(k);

end

