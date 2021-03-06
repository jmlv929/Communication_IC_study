01 sqrt2=sqrt(1/2);
02 x=rand(1,8)+j*rand(1,8);
03 t(1) = x(1) + x(5) ;
04 t(2) = x(2) + x(6) ;
05 t(3) = x(3) + x(7) ;
06 t(4) = x(4) + x(8) ;
07 t(5) = x(1) - x(5) ;
08 t(6) = x(2) - x(6) ;
09 t(7) = x(3) - x(7) ;
10 t(8) = x(4) - x(8) ;
11 % 第二轮蝶形变换
12 q(1) = t(1) + t(3) ;
13 q(2) = t(2) + t(4) ;
14 q(3) = t(1) - t(3) ;
15 q(4) = t(2) - t(4) ;
16 q(5) = t(5) ;
17 q(6) = t(6) + t(8) ;
18 q(7) = t(7) ;
19 q(8) = t(6) - t(8) ;
20 % 第三轮蝶形变换
21 s(1) =    q(1) +         q(2) ;
22 s(2) =    q(1) -         q(2) ;
23 s(3) =    q(3) -       j*q(4) ;
24 s(4) =    q(3) +       j*q(4) ;
25 s(5) =    q(5) - sqrt2*j*q(6) ; % 常系数乘法实现
26 s(6) =    q(5) + sqrt2*j*q(6) ; % 常系数乘法实现
27 s(7) = -j*q(7) + sqrt2*  q(8) ; % 常系数乘法实现
28 s(8) =  j*q(7) + sqrt2*  q(8) ; % 常系数乘法实现
29 % 第四轮蝶形变换
30 y(1) = s(1); 
31 y(2) = s(5) + s(7); 
32 y(3) = s(3);  
33 y(4) = s(5) - s(7); 
34 y(5) = s(2); 
35 y(6) = s(6) - s(8); 
36 y(7) = s(4) ;
37 y(8) = s(6) + s(8);
38 % 确定与浮点运算差异
39 k=fft(x);
40 error=sum(k-y);
