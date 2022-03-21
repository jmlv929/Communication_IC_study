clc;
close all;
N=10000;
sn=(-1:N)/N;
t=4*pi.*sn;
%%x=sinc(40*t).*cos(140*2*pi*t);
x=sinc(t);
y=x./t;
i=find(y<2.0&y>-1.0);
m=y(i)

plot(m);
figure
subplot(2,1,1)
plot(t,x)
%axis([-0.01 t(N+100) -2 2]);
grid on
y=fft(x);
subplot(2,1,2)
plot(t,abs(y))
grid on

%%
figure
clear;
fs=10000;
t0=0.1;
t=0:0.0001:t0;
m=sinc(200*t);
mk=fft(m,50000);                                        %Í¨¹ýfft¼ÆËãÆµÆ×
mw=2*pi/1000*abs(fftshift(mk));                         %ÆµÆ×°áÒÆ
fw=[-25000:24999]/50000*fs;
plot(fw,mw);grid;
xlim([-500,500]);
%% matlab
[X,Y] = meshgrid(-8:.5:8); R = sqrt(X.^2 + Y.^2) + eps; Z = sin(R)./R; mesh(X,Y,Z,'EdgeColor','black') 

