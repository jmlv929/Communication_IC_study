%% plot nco frequency
function plot_nco(f1)
% set frequency.
clc;
len=2000;
N=1:len;
delta_f=1/f1;
x=2*pi*delta_f.*N;
y=sin(x);
plot(y);

%% axis plot
max_x=len;
min_x=-25;
max_y=2;
min_y=-1.2;
grid on
%axis square;
%axis equal;

hold on
axis([min_x max_x min_y max_y]);
plot([0,0],[min_y,max_y],'k','LineWidth',2);
hold on
plot([min_x,max_x],[0,0],'k','LineWidth',2);

export_fig axis.png -m2 % 5 times resolution

