01function [Wk, Wa, b, MaxI] = MinSqurePara(Weight_p)
02 [wMax, MaxI] = max(w);
03 sumW = sum(w);
04 sumW_inv = 1/sumW;
05 Wa = w * sumW_inv;
06 Wa  = num2fixpt(Wa, ufix(9), 2^(-9), 'nearest', 'on'); 
07 x = [-3 -1 1 3];
08 b = sum(x.*Wa);
09 b = num2fixpt(b, sfix(10), 2^(-7), 'nearest', 'on');
10 b2=b*b;
11 b2=num2fixpt(b2,ufix(13),2^(-9),'nearest','on');
12 wx2x2 = 1 + 8*(Wa(1)+Wa(4)) - b2;
13 fake_wx22 = wx2x2/8;
14 fake_wx22 = num2fixpt(fake_wx22,ufix(14),2^(-9),'floor','on');
15 wx2x2_7 = (wx2x2 - fake_wx22) * 8;
16 wx2x2_7=num2fixpt(wx2x2_7,ufix(12),2^(-6),'nearest','on');
17 x2 = x - b;
18 if wx2x2_7 == 0
19     Wk = 0;
20 else
21     Wk1 = (Wa.*x2);
22     Wk1=num2fixpt(Wk1,sfix(14),2^(-11),'nearest','on');
23     for i=1:4
24      Wk(i)=data_divider(Wk1(i), wx2x2_7);
25  	end
26 end
27 Wk  = num2fixpt(Wk, sfix(10), 2^(-13), 'Nearest', 'on');
