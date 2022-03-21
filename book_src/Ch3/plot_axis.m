function plot_axis(x,y)
close all;
x0=0;
y0=0;
%base_len=abs(max(x,y));
cir_len=sqrt(x^2+y^2);
fprintf('length & angle is :%f %f %f \n',cir_len,atan(y/x*1.0),atan(y/x*1.0)*180/pi);
plot([0 x],[0 y]);
hold on
scatter(x,y);
text(x+0.5,y+0.5,['(' num2str(x) ','  num2str(y) ')']);
hold on
theta=0:pi/100:2*pi;
x=x0+cir_len*cos(theta);
y=y0+cir_len*sin(theta);
plot(x,y,'-',x0,y0,'.','color','red');
% rectangle('Position',[0,0,cir_len,cir_len],'Curvature',[1,1])
% axis equal
max_x=cir_len*2;
min_x=cir_len*-0.15;
max_y=cir_len*1.1;
min_y=cir_len*-0.3;
grid on
%axis square;
axis equal;

axis([min_x max_x min_y max_y]);
plot([0,0],[min_y,max_y],'k','LineWidth',2);
plot([min_x,max_x],[0,0],'k','LineWidth',2);

export_fig axis.png -m2 % 5 times resolution

