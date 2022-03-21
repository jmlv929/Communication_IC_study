01function data_out=fft_64(data_in)
02  fftbit=[10 10 12]; %ΪоƬ���ʱ�����ж�������
03  data_16=zeros(1,64); %�����洢�ռ�
04  data_64_temp=Main_fft(data_in,64,1); %��һ�η��Σ��γ�4��16������
05  data_64=num2fixpt(data_64_temp,sfix(fftbit(1)),1,'nearest','on');
06   %index�൱���������λ��˳�����������CP��ʼλ�ÿ���ͨ�����������
07  index=[0,-4,-2,-6,-1,-5,-3,-7];
08  %��һ�η��Σ���4��FFT��ȫ���У����ҿ���ԭλ�洢
09  for m=1:1:4
10      data_16_temp((m-1)*16+1:m*16)=Main_fft(data_64((m-1)*16+1:m*16)
11                   ,16,2,[index(m),index(m)]);
12  end  %������㻯������ͳ������Լ�оƬ�������ݱȶԣ�
13  data_16=num2fixpt(data_16_temp,sfix(fftbit(2)),1,'nearest','on');
14  %�ڶ��η��Σ���16��FFT��ȫ���У����ҿ���ԭλ�洢
15  for m=1:1:16
16      data_4((m-1)*4+1:m*4)=Main_fft(data_16((m-1)*4+1:m*4),4,3);
17  end
18  data_out=num2fixpt(data_4,sfix(fftbit(3)),1,'nearest','on');
19  %���ڷ���Ϊ64��1��FFT�������һ�����㣬����ֱ��������
20