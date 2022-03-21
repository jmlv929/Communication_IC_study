function cordic_plot(x,y,time_N)
% x,y is rotate result. It will hold on.
if  nargin==0
  fprintf('error in parameter!\n');
  error('go!');
elseif nargin==2
  time_N=0;
  no_display=1;
else
  no_display=0;
end

x0=0;
y0=0;
base_len=abs(max(x,y))*1.2;
cir_len=sqrt(x^2+y^2);
fprintf('length & angle is :%f %f %f \n',cir_len,atan(y/x*1.0),atan(y/x*1.0)*180/pi);
plot([0 x],[0 y]);
hold on
scatter(x,y);

if no_display
    msg=sprintf('(%4.2f,%4.2f)',x,y);
 else
    msg=sprintf('(%4.2f,%4.2f,N=%1d)',x,y,time_N);
 end
text(x+0.5,y+0.5,msg);

hold on
% theta=0:pi/100:2*pi;
% x=x0+cir_len*cos(theta);
% y=y0+cir_len*sin(theta);
% plot(x,y,'-',x0,y0,'.','color','red');
% axis square; 
% axis([0 base_len 0 base_len]);
% grid on
%export_fig axis.png -m2 % 5 times resolution

