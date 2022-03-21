function pre = genPreamble
%function pre = genPreamble
% create the preamble fields

% ----------- short preamble ---------------------
% short OFDM traning symbol
S = sqrt(13/6) * ...
    [0, 0, 1+j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, -1-j, ...
    0, 0, 0, -1-j, 0, 0, 0,  1+j, 0, 0, 0, 0, ...
    0, 0, 0, -1-j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, 1+j, ...
    0, 0, 0,  1+j, 0, 0, 0, 1+j, 0, 0];

% assume a sampling rate of 20 Msamples/s
% therefore one sample represents 50 ns

% subcarrier spacing : f = 0.3125 MHz
% Therefore the IFFT period is calculated as 1/f
% or 3.2 micro sec. At 20Msamp/s this translates to a 64 tap IFFT.

% perform 64 tap discreet fast IFFT on S
stemp = difft64(S);

% cyclicly extend the result to a 161 point vector
s = extend(stemp(1:32),161);

% apply the windowing function to the sequence
s = fastwindow(s);

% ---------------- long preamble ------------------

L = [1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, ...
     -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 0, ...
     1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, ...
     1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1];

% perform 64 tap discreet fast IFFT on L
ltemp = difft64(L);

% assemble the long preamble sequence
% [ guard interval, long preamble 1, long preamble 2, buffer point ]
l = [ltemp(33:64), ltemp, ltemp, ltemp(1)]; 

l = fastwindow(l);

pre = mix(s,l,1);
% ------------------- preamble complete ------------

