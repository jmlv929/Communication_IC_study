%% atan via cordic. Input is x,y, output is cordic_change
function [x_n,y_n]=cordic_atan(x,y,theta)
%theta_pi=theta/180*pi;
theta_pi=theta;
x_n=x*cos(theta_pi)+y*sin(theta_pi);
y_n=-1*x*sin(theta_pi)+y*cos(theta_pi);

