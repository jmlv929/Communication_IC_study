01 function tx_only
02 %this is the formal version to test the performance of Matlab Model
03 path( strcat(pwd,'/script/'), path  );
04 path( pwd,path  );
05 times=0;
06 multipath_model = 2; % A
07 sampling_rate = 20e6;
08 Rate = [54];
09 snr = [30];% 26 28 30
10 % data_length = [1024]; % number of bytes to send in PSDU12
11 % adc_backoff = [-8]; % ad backoff in dB
12
13 for  RateIndex = 1: length(Rate); % data_rate = [6];  % data
14 rate [6 9 12 18 24 36 48 54] 120 250 12 14 16
15     data_rate = Rate(RateIndex);
16     data_length = min(data_rate*100, 4095);
17     data_length = 500;
18     for SNR = snr(RateIndex, :);
19         for offset = [500]% 300
20             State = 1000;
21             rand('state',State);
22             randn('state',State);
23             for run_times=[1:100] %:500
24                 % noise_level  = [EbNo + 10*log10((64/52)
25                 *data_rate/16.6)];  % SNR in dB
26                 noise_level    = SNR;
27                 frequency_offset  = offset; % frequency
28                 offset in KHz
29                 % Generate Test Data ------------------------
30                 psdu    = floor( rand( 1, data_length )*256 );
31                 %generate the
32                 [phydata, psdu] = phy( psdu, data_rate );
33                 phydata = 2*phydata;
34                 data40 = tx_lpf_11a_2(phydata);
35                 ft = fft(data40);
36                 aft = conv(abs(fftshift(ft)), ones(1, 16)/16) ;
37
38                 plot(20*log10((aft)+0.1))
39                 data40 = tx_lpf_11a(phydata);
40                 ft = fft(data40);
41                 aft = conv(abs(ft), ones(1, 256)/256);
42                 plot(20*log10(aft+0.1))
43                 plot(real(phydata));
44                 plot(imag(phydata));
45                 disp(sprintf('%d, rate: %d  length: %d  SNR:
46                 %.1f  freq off: %d multipath: %d',run_times,
47                 data_rate, data_length, SNR,
48                 frequency_offset,multipath_model));
49             end%run_times
50         end%frequency offset
51     end%EbNo
52 end%data_rate
53
54 function out = tx_lpf_11a(in)
55 reg = zeros(1, 10);
56 for i = 1:length(in)
57     reg = [in(i) reg(1:9)];
58     d = (reg(1) + reg(10))*6 + ...
59         (reg(2) + reg(9))*(-11) + ...
60         (reg(3) + reg(8))*(15) + ...
61         (reg(4) + reg(7))*(-27) + ...
62         (reg(5) + reg(6))*(81);
63     d = d/128;
64
65     out(2*i-1) = d;
66     out(2*i) = reg(5);
67 end