%% atan via cordic. Input is x,y, output is cordic_change
function [x_n,y_n]=cordic_atan2(x,y,theta_pi)
x_n=x+y*tan(theta_pi);
y_n=-1*x*tan(theta_pi)+y;


