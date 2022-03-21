Fp=0.4;Fs=1-Fp;Wp=Fp*pi;Ws=Fs*pi;
dp=0.001;
[M,fo,ao,w]= remezord([Fp Fs],[1 0],[dp dp]);
n=mod(M+1,4);
M=M+3-n;
h= remez(M,fo,ao,w);
h_half=zeros(1,M+1);
h_half(1:2:M+1)=h(1:2:M+1);
h_half(M/2+1)=1/2;
K=M/2;k=-K:K;
[Mk,Wc,beta,ftype] = kaiserord([Fp Fs],[1 0],[dp dp]);
hk =sinc(k/2)/2.*kaiser(M+1,beta)';
w=linspace(0,pi,512);
Hk=20*log10(abs(freqz(hk,[1],w)));
H_half=20*log10(abs(freqz(h_half,[1],w)));
plot(w/pi,H_half,w/pi,Hk);
grid on;figure;
plot(hk);
hold on
stem(hk,'r');grid on
