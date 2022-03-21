close all;
clear;
%% signal gen
Fs = 1000;                    % Sampling frequency
T = 1/Fs;                     % Sample time
L =1000;                     % Length of signal
t = (0:L-1)*T;                % Time vector
% Sum of a 50 Hz sinusoid and a 120 Hz sinusoid
% x = 0.7*sin(2*pi*10*t) + sin(2*pi*200*t); 
x = sin(2*pi*2*t) ;
y=zeros(size(x));

%%
y=x;

%% first
for j=1:length(y)
    if x(j)>0
        y(j)=0.5;
    else
        y(j)=-0.5;
    end
end

%% second
for j=1:length(y)
    if x(j)==1
        y(j)=0.5;
    else
        y(j)=0;
    end
end

%% third 
for j=1:length(y)
   y=asin(x);
end
%% grid
subplot(2,1,1);
plot(Fs*t,y);grid;
title('Signal Corrupted with Zero-Mean Random Noise')
xlabel('time (milliseconds)')

%%
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
subplot(2,1,2);
plot(f,2*abs(Y(1:NFFT/2+1)),'r') ;grid;
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')

%%