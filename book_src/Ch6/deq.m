01 function [Bibit,In,Stateo]=DEQ(Signal,Statei)
02   A=[1 -1 1 1 -1 1 1 1 -1 -1 -1];
03   a=Signal*A'; %巴克码相关计算
04   if(abs(a(1,1))<5.5)&(abs(a(2,1))<5.5);%相关峰判决
05     In=1;
06     Bibit=[-1,-1];
07     Stateo=Statei;
08   else
09     if a(1,1)>=5.5;           %相位判决
10         d=0;
11     elseif a(1,1)<=-5.5;
12         d=2;
13     elseif a(2,1)>=5.5;
14         d=1;
15     else
16         d=3;
17     end
18     In=10;
19     e=mod(d-Statei,4);        %相位判决（差分译码）
20     Stateo=d;
21     switch e;                 相位比特映射
22       case 0;Bibit=[0 0];
23       case 1;Bibit=[0 1];
24       case 2;Bibit=[1 1];
25       otherwise Bibit=[1 0];
26     end
27   end
28 end