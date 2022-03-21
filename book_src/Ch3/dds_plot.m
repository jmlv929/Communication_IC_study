%% find specturm of signal
close all;
clc;
%%
N=10000;
duty=0.1;

n_num=5*(1:N)/N;
y = square(2*pi*n_num,duty);
fy=fft(y);
subplot(211)
plot(n_num,y); 
subplot(212)
plot(abs(fy));