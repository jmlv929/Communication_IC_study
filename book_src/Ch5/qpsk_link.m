N = 1000; % number of data
mlevel = 4; % size of signal constellation
k = log2(mlevel); % number of bits per symbol
x = randi([0 1],N,1); % signal generation in bit stream

xsym = bi2de(reshape(x,k,length(x)/k).','left-msb'); % convert the bit stream into symbol stream
Tx_x  = qammod(xsym,mlevel);% modulation
SNR = 5;
Tx_awgn = awgn(Tx_x,SNR,'measured'); % % adding AWGN 
Rx_x = Tx_awgn;
Rx_x_demod = qamdemod(Rx_x,mlevel); %demodulation
z = de2bi(Rx_x_demod,'left-msb'); % Convert integers to bits.
Rx_x_BitStream = reshape(z.',prod(size(z)),1); % Convert z from a matrix to a vector.
[number_of_errors,bit_error_rate] = biterr(x,Rx_x_BitStream) %Calculate BER
