01 function data_out=Main_fft(data_in,N,quantum_method,shift)
02 global fft_bit;
07 data_first=zeros(1,N);
09 data_first_temp=zeros(2,N/2);
10 data_second=zeros(2,N/2);
12 data_second_temp=zeros(4,N/4);
13 data_third=zeros(4,N/4);
15 % first stage，简单的蝶形变换
16 data_first=fft_s(data_in,N);
17  %按照基-4方法进行数据拆分，并进行预旋转
18 data_first_temp(1,:)=data_first(1:N/2);
19 data_first_temp(2,1:N/4)=data_first(N/2+1:N/2+N/4);
20 data_first_temp(2,N/4+1:N/2)=data_first(N/2+N/4+1:N)*(-j);
22 % second stage，再次对分段数据进行简单的蝶形变换
23 for m=1:1:2
24     data_second(m,:)=fft_s(data_first_temp(m,:),N/2);
25 end
27 %第二阶段的旋转处理，代码的目是对4点向量数据进行旋转
28 W=exp(-2*pi*j/N);
29 data_second_temp(1,:)=data_second(1,1:N/4);
30 data_second_temp(2,:)=data_second(1,N/4+1:N/2).*power(W,2*[0:1:(N-1)/4]);
32 data_second_temp(3,:)=data_second(2,1:N/4).*power(W,[0:1:(N-1)/4]);
34 data_second_temp(4,:)=data_second(2,N/4+1:N/2).*power(W,[0:1:(N-1)/4]+ 2*[0:1:(N-1)/4]);
72 data_out=zeros(1,N);
74 for m=1:4 % 输出本次分形的结果
75     data_out((m-1)*N/4+1:m*N/4)=data_second_temp(m,:);
76 end
