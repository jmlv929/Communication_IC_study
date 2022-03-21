function data_out=fft_64(data_in)

fftbit=[10 10 12];
data_16=zeros(1,64);
data_16_org=zeros(1,64);

data_64_temp=Main_fft(data_in,64,1);
data_64=num2fixpt(data_64_temp,sfix(fftbit(1)),1,'nearest','on');

index=[0,-4,-2,-6,-1,-5,-3,-7];

for m=1:1:4
    data_16_temp((m-1)*16+1:m*16)=Main_fft(data_64((m-1)*16+1:m*16),16,2,[index(m),index(m)]);
end

data_16=num2fixpt(data_16_temp,sfix(fftbit(2)),1,'nearest','on');

for m=1:1:16
    data_4((m-1)*4+1:m*4)=Main_fft(data_16((m-1)*4+1:m*4),4,3,[0,0]);
end

data_out=num2fixpt(data_4,sfix(fftbit(3)),1,'nearest','on');

