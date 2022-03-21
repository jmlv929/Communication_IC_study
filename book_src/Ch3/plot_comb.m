clc;
close all;
D=10;                                         
r=D;
fs=1e5;	
S1_cic=ones(1,D);
[h1,f1]=freqz(ones(1,D),1,1000,fs);hold on;
plot(f1/(fs/2),20*log10(abs(h1))-max(20*log10(abs(h1))));
grid on;

M=15;
fir_coe=zeros(1,M);
fir_coe(1)=1;
fir_coe(M)=-1;
[h,w]=freqz(fir_coe);
fvtool(fir_coe,1);

export_fig axis.png -m2

