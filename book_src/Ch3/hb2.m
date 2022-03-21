%2���İ���˲� 
function h_band_2=hb2() 
reg=[0 0 0 0 0 0 0 0 0 0 0 1]; 
x=Rcos_squ_4(reg); 
y(1,1:8192)=upsample(x(1,1:4096),2);   %I·�ź�2���ڲ� 
y(2,1:8192)=upsample(x(2,1:4096),2);    %Q·�ź�2���ڲ� 
 
half_band_2=[-0.031303406,0.000000000,0.281280518,0.499954224,0.281280518,0.0000000000,-0.031303406]; % 2�װ���˲�����ϵ������ 
h_band_2_I=filter(half_band_2,1,y(1,1:8192)); 
h_band_2_Q=filter(half_band_2,1,y(2,1:8192)); 
 
h_band_2=[h_band_2_I;h_band_2_Q]; 
H_BAND_2_I=fft(h_band_2_I); 
H_BAND_2_Q=fft(h_band_2_Q); 
 
figure(4); 
subplot(2,2,1); 
stem([1:8192],h_band_2_I);axis([1 600 -0.7 0.7]); 
xlabel('n');ylabel('h__band__2__I');title('I·�ź�2���ڲ�����˲�');grid; 
 
subplot(2,2,2); 
stem([1:8192],h_band_2_Q);axis([1 600 -0.7 0.7]); 
xlabel('n');ylabel('h__band__2__Q');title('Q·�ź�2���ڲ����˲�');grid; 
 
subplot(2,2,3); 
n=[1:8192]; 
plot(2*n/8192,abs(H_BAND_2_I));axis([0 2 -20 170]); 
xlabel('frequency(*pi)');ylabel('H__BAND__2__I');title('I·�ź�2���ڲ����˲�Ƶ��');grid; 
 
subplot(2,2,4); 
n=[1:8192]; 
plot(2*n/8192,abs(H_BAND_2_Q));axis([0 2 -20 170]); 
xlabel('frequency(*pi)');ylabel('H__BAND__2__Q');title('Q·�ź�2���ڲ����˲�Ƶ��');grid; 


