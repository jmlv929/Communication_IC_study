%% check atan process!
clc
x=10;
y=20;
N=6;

MAX_times=12;
x_n=zeros(MAX_times,1);
y_n=zeros(MAX_times,1);
a_n=zeros(MAX_times,1);
%% orignal data
fprintf('orignal is \t %f,%f\n',x,y);
%% first step
i=1;
angle(i)=atan(1/bitshift(2,i-2));
%[x_n(i),y_n(i)]=cordic_atan2(x_n(i-1),y_n(i-1),angle(i));
[x_n(i),y_n(i)]=cordic_atan2(x,y,angle(i));
fprintf('shift %d result is \t %f,%f,%f\n',i,x_n(i),y_n(i),angle(i));
%% loop step
for i=2:N
    if(y_n(i-1)>0)
        angle(i)=atan(1/bitshift(2,i-2));
    else
        angle(i)=-atan(1/bitshift(2,i-2));
    end
    [x_n(i),y_n(i)]=cordic_atan2(x_n(i-1),y_n(i-1),angle(i));
    fprintf('shift %d result is \t %f,%f,%f\n',i,x_n(i),y_n(i),angle(i));
end
%% get final angle
angle_rotate=sum(angle);
err_angle=angle_rotate-atan(y/x);
fprintf('total angle is %f,error angle %f\n',angle_rotate,err_angle);
 
%% plot the trace
plot_axis(x,y);
for i=1:N
    cordic_plot(x_n(i),y_n(i),i);
end
plot([x,x_n(1:N)'],[y,y_n(1:N)'],'g');
export_fig axis.png -m2 % 5 times resolution

