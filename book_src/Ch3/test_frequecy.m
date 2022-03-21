F=input('����ָ���ź�Ƶ�ʷֱ���F='); 
fh=input('�ź����Ƶ��fh='); 
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
xlabel('����Ƶ��fs'); 
ylabel('|X(K)|'); 
title('ָ���ź���ɢ��Ƶͼ'); 
subplot(2,1,2); 
stem(fs,angle(y)); 
xlabel('����Ƶ��fs'); 
ylabel('��(K)'); 
title('ָ���ź���ɢ��Ƶͼ'); 
  
  
F=input('�����źŷֱ���F='); 
fh1=input('��һ�������ź�Ƶ��fh1='); 
fh2=input('�ڶ��������ź�Ƶ��fh2='); 
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
xlabel('����Ƶ��fs'); 
ylabel('|X(K)|'); 
title('�����ź���ɢ��Ƶͼ'); 
subplot(2,1,2); 
stem(fs,angle(z)); 
xlabel('����Ƶ��fs'); 
ylabel('��(K)'); 
title('�����ź���ɢ��Ƶͼ'); 
  
  
F=input('���ǲ��ֱ���F='); 
fh=input('���ǲ��ź����Ƶ��fh='); 
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
title('���ǲ���ɢ��Ƶͼ'); 
subplot(2,1,2); 
stem(fs,angle(y)); 
xlabel('fs'); 
ylabel('��(K)'); 
title('���ǲ���ɢ��Ƶͼ'); 
  
  
F=input('�����ֱ���F='); 
fh=input('�����ź����Ƶ��fh='); 
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
title('������ɢ��Ƶͼ'); 
subplot(2,1,2); 
stem(fs,angle(y)); 
xlabel('fs'); 
ylabel('��(K)'); 
title('������ɢ��Ƶͼ'); 


