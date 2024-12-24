function y = WienConstant()
% This function uses Newton's Method to iteratively solve
% for the constant used in Wien's Displacement Law
%
% Author: Ben Loftin
% License: GPL

x_i = 2;
x_k = 0;
tolerance = 1E-8;
check = 1;
while  check > tolerance
    x_k = x_i - (fWien(x_i)/dfWien(x_i));
    check = abs(x_k - x_i);
    x_i = x_k;
end 

y = x_k;