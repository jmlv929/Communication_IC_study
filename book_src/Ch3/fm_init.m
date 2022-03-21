SR=80e6 ;%Sample rate variable
IF=103.9e6
% Create filters normalized to sample rate
cfir_passband_edge = 105e3/(SR/128)*2;
%mfir_pass_edge = 80e3/(SR/128)*2;
%mfir_stopb_strt = 100e3/(SR/128)*2;
mfir_pass_edge  = 100e3/(SR/128)*2;
mfir_stopb_strt = 130e3/(SR/128)*2;

%Create input stimulus and plot so we can see
%All are centered around a 7mhz carrier
%Two sin in middle and edge of passband
ddc_in = .8*sin(2*pi*(40e3+IF)/SR*(1:20e4)) + .6*sin(2*pi*(80e3+IF)/SR*(1:20e4));
%sin in adjacent channel
ddc_in = ddc_in + .9*sin(2*pi*(100e3+IF)/SR*(1:20e4)) + 1.2*sin(2*pi*(120e3+IF)/SR*(1:20e4))+ 3.9*sin(2*pi*(130e3+IF)/SR*(1:20e4));
%sin in distant channels
ddc_in = ddc_in + 1.1*sin(2*pi*(487e3+IF)/SR*(1:20e4)) + 2.1*sin(2*pi*(22e6+IF)/SR*(1:20e4)) ;
randn('state',171);
ddc_in = awgn(ddc_in,10,0);     %add some noise
fft_size=2^16;
fddc_in = fft(ddc_in(1:fft_size-1));  %need high resolution fft to resolve peaks
%sp_view_L=ceil(2*IF/SR*fft_size);
%sp_view_H=ceil(2*(IF+1e6)/SR*fft_size);
%plot(20*log(abs(fddc_in(sp_view_L:sp_view_H)/max(abs(fddc_in)))))%plot just the section we want to see
%grid;


