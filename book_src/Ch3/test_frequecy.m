F=input('输入指数信号频率分辨率F='); 
fh=input('信号最高频率fh='); 
Ts=1./(2*fh); 
t=1./F; 
N=t./Ts; 
fs=(0:N-1)*2*fh/N; 
n=linspace(0,t,N); 
x=exp(-n); 
y=fft(x); 
figure; 
subplot(2,1,1); 
stem(fs,abs(y)); 
xlabel('抽样频率fs'); 
ylabel('|X(K)|'); 
title('指数信号离散幅频图'); 
subplot(2,1,2); 
stem(fs,angle(y)); 
xlabel('抽样频率fs'); 
ylabel('φ(K)'); 
title('指数信号离散相频图'); 
  
  
F=input('叠加信号分辨率F='); 
fh1=input('第一个正弦信号频率fh1='); 
fh2=input('第二个正弦信号频率fh2='); 
if fh1>fh2 
     fh=fh1; 
else 
     fh=fh2; 
end 
w1=2*pi*fh1; 
w2=2*pi*fh2; 
Ts=1./(2*fh); 
t=1./F; 
N=t./Ts; 
fs=(0:N-1)*(2*fh)/N; 
n=linspace(0,t,N); 
y1=sin(w1*n); 
y2=sin(w2*n); 
y=y1+y2; 
z=fft(y); 
figure; 
subplot(2,1,1); 
stem(fs,abs(z)); 
xlabel('抽样频率fs'); 
ylabel('|X(K)|'); 
title('叠加信号离散幅频图'); 
subplot(2,1,2); 
stem(fs,angle(z)); 
xlabel('抽样频率fs'); 
ylabel('φ(K)'); 
title('叠加信号离散相频图'); 
  
  
F=input('三角波分辨率F='); 
fh=input('三角波信号最高频率fh='); 
T=1./(2*fh); 
t=1./F; 
N=t./T; 
fs=(0:N-1)*2*fh/N; 
n=linspace(0,t,N); 
x=sawtooth(n,0.5); 
y=fft(x); 
figure; 
subplot(2,1,1); 
stem(fs,abs(y)); 
xlabel('fs'); 
ylabel('|X(K)|'); 
title('三角波离散幅频图'); 
subplot(2,1,2); 
stem(fs,angle(y)); 
xlabel('fs'); 
ylabel('φ(K)'); 
title('三角波离散相频图'); 
  
  
F=input('方波分辨率F='); 
fh=input('方波信号最高频率fh='); 
T=1./(2*fh); 
t=1./F; 
N=ceil(t./T); 
fs=(0:N-1)*2*fh/N; 
n=linspace(0,t,N); 
x=square(n); 
y=fft(x); 
figure; 
subplot(2,1,1); 
stem(fs,abs(y)); 
xlabel('fs'); 
ylabel('|X(K)|'); 
title('方波离散幅频图'); 
subplot(2,1,2); 
stem(fs,angle(y)); 
xlabel('fs'); 
ylabel('φ(K)'); 
title('方波离散相频图'); 


