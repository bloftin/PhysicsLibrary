% Author Ben Loftin
% This is so obvious it should not be copyrighted...
% but consider this under the GPL

% example of linear Least Squares

% the example measurements
z = [-1.0 -0.25 0.0 0.25 0.4 0.7 1.0 1.1 1.4 1.8]';

% the variables to be estimated that has a linear relationship to 
% the measurements (z)
x = [-3.0 -2.5 -2.0 -1.5 -1.0 -0.5 0.0 0.5 1.0 1.5]';

% For convenience, define an identity vector the size of vectors above
Iv = ones(size(z));

A = [Iv x];

% The easy matrix form of linear least squares fit
xls = (A'*A)^-1*A'*z;

% To see this plot the data
plot(x,z,'+');
hold;
% the fitted line of data
fitls = xls(2)*x + xls(1)
% plot the fitted line
plot(x,fitls,'k');

% add titles
xlabel('x');
ylabel('z');