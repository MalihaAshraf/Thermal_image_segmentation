function angle = get_slope( x, y )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

s = (y(2) - y(1))./(x(2) - x(1));
angle = atand(s);

end

