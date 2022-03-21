function dataout=fft_s(data_in,N)
 dataout(1:N/2)=data_in(1:N/2)+data_in(N/2+1:N);
 dataout(N/2+1:N)=data_in(1:N/2)-data_in(N/2+1:N);
