 1 function [SoftDecide] = DecideASymbol(SIGNAL, modmethod, Ncbps, codingrate, W)
 2 switch modmethod
 3 case 4, %64QAM
 4     Kmod = sqrt(42)/8;
 5 case 3, % 16QAM
 6     Kmod = sqrt(10)/4;
 7 case 2, % QPSK
 8     Kmod = sqrt(2)/2;
 9 case 1, % BPSK
10     Kmod = 1/2;
11 otherwise
12     Kmod = 1/2;
13 end
15
16 DeMaped = demap(SIGNAL, modmethod, W/Kmod); % demap
18 DeIntered(deinterlvindex(Ncbps)) = DeMaped; % deinter
20 DePunctured = depuncture(DeIntered, codingrate); % depuncture
22 SoftDecide = DePunctured; % SoftDecide
