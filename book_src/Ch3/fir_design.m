01 Fp=0.4;Fs=1-Fp;Wp=Fp*pi;Ws=Fs*pi; %指定半带滤波器带宽，属于可调参数
02 dp=0.001; %指定半带滤波器带内纹波，属于可调参数
03 [M,fo,ao,w]= remezord([Fp Fs],[1 0],[dp dp]); %估计半带滤波器阶数
04 n=mod(M+1,4);%保证半带的系数格式为奇数，且为4n+3
05 M=M+3-n;
06 h= remez(M,fo,ao,w);%设计半带滤波器系数
07 h_half=zeros(1,M+1);
08 h_half(1:2:M+1)=h(1:2:M+1);
09 h_half(M/2+1)=1/2;
10 K=M/2;k=-K:K;
11 [Mk,Wc,beta,ftype] = kaiserord([Fp Fs],[1 0],[dp dp]);%对半带设计窗系数
12 hk =sinc(k/2)/2.*kaiser(M+1,beta)';%生成加窗后的半带系数，硬件所需
13 w=linspace(0,pi,512); %后面部分为加窗前后频率响应对比
14 hk=20*log10(abs(freqz(hk,[1],w)));
15 H_half=20*log10(abs(freqz(h_half,[1],w)));
16 plot(w/pi,H_half,w/pi,hk);
17 grid on;figure;
18 plot(hk);hold on; %给出半带系数的轮廓以及对应的直方图
19 stem(hk,'r');grid on
