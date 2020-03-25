function D = diff_val(T, cw, P)
%DIFF_VAL calculates diffusion value from temperature, water component, and
%pressure
%
% Details in Zhang and Ni Paper
%
% T is temperature in Kelvins


k = -18.1 + 1.888.*P - (9699 + 3626.*P)./T;
D = cw.*exp(k);

end

