001  function [phydata, psdu] = phy(msg, rate)
002   %function phydata = phy(msg, rate)
003   % msg = incoming data message as a vector of integer octets
004   % rate = data rate
005   % valid choices: 6 9 12 18 24 36 48 54
006   % set required parameters based on data rate
007   switch rate
008       case 6,
009       Ncbps = 48; Ndbps = 24;
010       modmethod = 1; % bpsk
011       codingrate = 1; % 1/2
012       case 9,
013       Ncbps = 48; Ndbps = 36;
014       modmethod = 1; % bpsk
015       codingrate = 2; % 3/4
016       case 12,
017       Ncbps = 96; Ndbps = 48;
018       modmethod = 2; % qpsk
019       codingrate = 1; % 1/2
020       case 18,
021       Ncbps = 96; Ndbps = 72;
022       modmethod = 2; % qpsk
023       codingrate = 2; % 3/4
024       case 24,
025       Ncbps = 192;  Ndbps = 96;
026       modmethod = 3; % 16qam
027       codingrate = 1; % 1/2
028       case 36,
029       Ncbps = 192;  Ndbps = 144;
030       modmethod = 3; % 16qam
031       codingrate = 2; % 3/4
032       case 48,
033       Ncbps = 288;   Ndbps = 192;
034       modmethod = 4; % 64qam
035       codingrate = 3; % 2/3
036       case 54,
037       Ncbps = 288;    Ndbps = 216;
038       modmethod = 4; % 64qam
039       codingrate = 2; % 3/4
040       otherwise
041       err1 = sprintf('%d is an invalid data rate.', rate);
042       err2 = sprintf('\nValid rates are 6 9 12 18 24 36 48 54.
043       ');
044       error(strcat(err1,err2));
045   end
046 
047   [m, n] = size(msg);
048   if (m ~= 1) error('msg must be a row vector of dimension [1,n].'); end
049   % ------------------ PREAMBLE field ------------
050   % generate the short and long preamble fields
051   preambleT = genPreamble;
052 
053   % ------------------ SIGNAL field ------------
054   datalen = length(msg);
055   % generate the signal field bits
056   signalBits = genSignalfield(rate, datalen);
057   % encode the signal field with the convolutional encoder at
058   a rate of 1/2
059   enSignalBits = encode(signalBits, 1);
060   % perform interleaving on the signal bits
061   inEnSignalBits = interleave(enSignalBits, 48);
062   % modulate the signal bits with BPSK mapping
063   signalFreq = mapper(inEnSignalBits, 1);
064   % perform the IFFT on the signal bits
065   signalT = FreqToTim(signalFreq, 1);
066   % ------------------ DATA field ------------
067   % convert the data bytes to a bit stream
068   bits = de2bi(msg,8,'right-msb');
069   psdu = reshape(bits',1,prod(size(bits)));
070   dataFieldBits = genDatafield(psdu, Ndbps);
071 
072   scDataFieldBits = scramble(dataFieldBits, [1 0 1 1 1 0 1]);
073   % reset the pad bits to zero after scrambling
074   padstart = length(psdu)+ 17;
075   scDataFieldBits(padstart:(padstart+5)) = zeros(1,6);
076 
077   % encode the data bits at the specified coding rate
078   enScDataFieldBits = encode(scDataFieldBits, codingrate);
079   % perform interleaving on the data bits
080   inEnScDataFieldBits = interleave(enScDataFieldBits, Ncbps);
081   % map the data to I and Q channels
082   dataFieldFreq = mapper(inEnScDataFieldBits, modmethod);
083   % create the ofdm data symbols for the data
084   dataFieldT = FreqToTim(dataFieldFreq, 2);
085 
086   % assemble the entire packet
087   phydata = mix(preambleT, mix(signalT, dataFieldT,1),1);
088  end
089
090 % preambleÐòÁÐ¹ý³Ì
091 function pre = genPreamble
092  % assume a sampling rate of 20 Msamples/s
093  % short OFDM traning symbol
094  S = sqrt(13/6) * ...
095      [0, 0, 1+j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, -1-j,...
096      0, 0, 0, -1-j, 0, 0, 0,  1+j, 0, 0, 0, 0, ...
097      0, 0, 0, -1-j, 0, 0, 0, -1-j, 0, 0, 0, 1+j, 0, 0, 0, 1+j,...
098      0, 0, 0,  1+j, 0, 0, 0, 1+j, 0, 0];
099  % perform 64 tap discreet fast IFFT on S
100  stemp = difft64(S);
101  % cyclicly extend the result to a 161 point vector
102  s = extend(stemp(1:32),161);
103  % apply the windowing function to the sequence
104  s = fastwindow(s);
105
106  % ---------------- long preamble ------------------
107  L = [1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, ...
108       -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 0, ...
109       1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, ...
110       1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1];
111  % perform 64 tap discreet fast IFFT on L
112  ltemp = difft64(L);
113  % assemble the long preamble sequence
114  % [ guard interval, long preamble 1, long preamble 2, buffer
115  point ]
116  l = [ltemp(33:64), ltemp, ltemp, ltemp(1)];
117  l = fastwindow(l);
118  pre = mix(s,l,1);
119 end