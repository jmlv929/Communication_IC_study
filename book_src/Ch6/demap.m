 1 function DeMaped = demap(Signal, modmethod, K)
 2 for i=1:48
 3   [Demap Len] = demap1(Signal(i), modmethod, K(i));
 4   DeMaped((i-1)*Len+1:i*Len) = Demap(1:Len);
 5 end
 6 
 7 function [DeMap, Len] = demap1(Signal, modmethod, K)
 8 [a0, a1, a2] = demap0(real(Signal), K);
 9 [b0, b1, b2] = demap0(imag(Signal), K);
10 switch modmethod
11 case 4, %64QAM
12   DeMap = [a0 a1 a2 b0 b1 b2];
13   Len = 6;
14 case 3, % 16QAM
15   DeMap = [a0 a1 b0 b1];
16   Len = 4;
17 case 2, % QPSK
18   DeMap = [a0 b0];
19   Len = 2;
20 case 1, % BPSK
21   DeMap = [a0];
22   Len = 1;
23 otherwise
24   DeMap = [a0];
25   Len = 1;
26 end
27 
28 function [b0, b1, b2] = demap0(data, K)
29   b0 = data;
30   if data <= 0
31     b1 = 0.5*K + data;
32   else
33     b1 = 0.5*K - data;
34   end
35   if data <= -0.5*K
36     b2 = (data + 0.75*K);
37   else if data <= 0
38       b2 = (-0.25*K - data);
39     else if data <= 0.5*K
40         b2 = (data - 0.25*K);
41       else
42         b2 = ( 0.75*K - data);
43       end
44     end
45   end
