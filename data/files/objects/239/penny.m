function ydot = penny(y, t)

ydot = zeros (2,1);

ydot(1) = y(2);
ydot(2) = 0.0817*y(2)^2 - 9.8;

endfunction