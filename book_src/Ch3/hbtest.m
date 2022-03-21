clc  
% 半带滤波器  
fp=1600;   %　半带滤波器通带截止频率  
fs=2400;   %　半带滤波器阻带截止频率  
Fs=8000;   %　采样率  
[N,fo,mo,w] = remezord( [fp fs], [1 0], [0.01 0.01], Fs );      %　计算半带滤波器阶数  
h=fir1(N-1,0.5,Kaiser(N));    % 计算半带滤波器系数  
h   % 写出半带滤波器系数  
figure(1);  
freqz(h); title('半带滤波器频谱特性'); % 画出半带滤波器频率特性曲线  
figure(2);  
subplot(1,1,1), plot(abs(fft(h))), title('半带滤波器频谱');   % 画出半带滤波器频谱  
  
% 半带滤波器滤波过程  
t=0:1:1000;  % 设置时间轴长度  
f1=100;      % 输入调制信号频率        
f2=2200;     % 输入载波信号频率  
input=sin(2*pi*f1/Fs*t)+sin(2*pi*f2/Fs*t);        %  输入已调信号  
output=conv(input,h);     % 输出滤波后信号  
output      % 写出半带滤波器时域输出       
figure(3);  
subplot(2,2,1), plot(input), title('输入信号时域波形');    % 画出输入信号时域波形  
subplot(2,2,2), plot(output), title('输出信号时域波形');   % 画出输出信号时域波形  
subplot(2,2,3), plot(abs(fft(input))), title('输入信号频谱');   % 画出输入信号频谱  
subplot(2,2,4), plot(abs(fft(output))), title('输出信号频谱');  % 画出输出信号频谱 

