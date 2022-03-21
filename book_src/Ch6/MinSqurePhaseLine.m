 1 function [Phase, k, a, b, PhasePilot] = MinSqurePhaseLine(ang, w)
 2 if sum(w) == 0
 3   w = [1 1 1 1];
 4 end
 5 [wMax, I] = max(w);
 6 for i=1:4
 7   delta = ang(i) - ang(I);
 8   if delta > pi
 9     ang(i) = ang(i) - 2*pi;
10   else
11     if delta < - pi
12       ang(i) = ang(i) + 2*pi;
13     end
14   end
15 end
16 % phase = k*(x-b)+a
17 x = [-3 -1 1 3];
18 b = sum(x.*w)/sum(w);
19 a = sum(ang.*w)/sum(w);
20 x2 = x - b;
21 wx2x2 = sum(w.*x2.*x2);
22 if wx2x2 == 0
23   k = 0;
24 else
25   k = sum(w.*ang.*x2)/wx2x2;
26 end
27 Phase = a + ([(-26:-1) (1:26)]-7*b)*k/7;
28 PhasePilot = a + (x-b)*k;
