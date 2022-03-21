01function data_out=fft_64(data_in)
02  fftbit=[10 10 12]; %为芯片设计时，进行定标运算
03  data_16=zeros(1,64); %声明存储空间
04  data_64_temp=Main_fft(data_in,64,1); %第一次分形，形成4个16点数据
05  data_64=num2fixpt(data_64_temp,sfix(fftbit(1)),1,'nearest','on');
06   %index相当于输入输出位置顺序调整参数，CP起始位置可以通过这个调整。
07  index=[0,-4,-2,-6,-1,-5,-3,-7];
08  %第一次分形，这4个FFT完全并行，而且可以原位存储
09  for m=1:1:4
10      data_16_temp((m-1)*16+1:m*16)=Main_fft(data_64((m-1)*16+1:m*16)
11                   ,16,2,[index(m),index(m)]);
12  end  %结果定点化，方便统计误差以及芯片进行数据比对，
13  data_16=num2fixpt(data_16_temp,sfix(fftbit(2)),1,'nearest','on');
14  %第二次分形，这16个FFT完全并行，而且可以原位存储
15  for m=1:1:16
16      data_4((m-1)*4+1:m*4)=Main_fft(data_16((m-1)*4+1:m*4),4,3);
17  end
18  data_out=num2fixpt(data_4,sfix(fftbit(3)),1,'nearest','on');
19  %由于分形为64个1点FFT，无需进一步计算，所以直接输出结果
20