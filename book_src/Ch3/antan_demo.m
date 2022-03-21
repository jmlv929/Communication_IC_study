%% check atan process!
clc
x=10;
y=20;
x_n=zeros(12,1);
y_n=zeros(12,1);
%% orignal data
fprintf('orignal is \t %f,%f\n',x,y);
%% first step
i=1;
[x_n(i),y_n(i)]=cordic_atan(x,y,pi/(bitshift(2,i)));
fprintf('shift %d result is \t %f,%f\n',i,x_n(i),y_n(i));
%% loop step
N=4;
for i=2:N
    if(y_n(i-1)>0)
        [x_n(i),y_n(i)]=cordic_atan(x_n(i-1),y_n(i-1),pi/(bitshift(2,i)));
    else
        [x_n(i),y_n(i)]=cordic_atan(x_n(i-1),y_n(i-1),-pi/(bitshift(2,i)));
    end
    fprintf('shift %d result is \t %f,%f\n',i,x_n(i),y_n(i));
end
%% plot the trace
plot_axis(x,y);
for i=1:N
    cordic_plot(x_n(i),y_n(i),i);
end
plot([x,x_n(1:N)'],[y,y_n(1:N)'],'g');

