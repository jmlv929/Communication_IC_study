01 function  [Data,Signal]=transmit(F,R,S,C,L)
02   State=0;                         %参考相位
03   Lp=72*(1+F);                     %PREAMBLE比特长度
04   Ld=L*8;                          %数据包比特长度
05   Lh=24*(1+F);
06   Data=round(rand(1,Lp+Ld+48));    %产生随机数据作为数据包
07   P=preamble(F);                   %产生PREAMBLE
08   Data(1,1:Lp)=P;
09   H=header(R,S,C,L);               %产生HEADER
10   Data(1,Lp+1:Lp+48)=H;
11   Datas=scramble(Data,F);          %对所有发射数据进行扰码
12   P=Datas(1,1:Lp);                 %扰码后的
13   H=Datas(1,Lp+1:Lp+48);           %扰码后的HEADER
14   C=Datas(1,Lp+49:Lp+Ld+48);       %扰码后的数据包
15   [Signal(:,1:Lp*11),State]=DBPSK(P,State); %调制PREAMBLE
16   if F==1;                         %调制HEADER
17       [Signal(:,Lp*11+1:(Lp+Lh)*11),State]=DBPSK(H,State);
18   else
19       State=State*2;
20       [Signal(:,Lp*11+1:(Lp+Lh)*11),State]=DQPSK(H,State);
21   end
22   if (F==1)&(R>1);
23       State=State*2;
24   end
25   switch R;                        %调制数据包
26   case 1
27       Signal(:,(Lp+Lh)*11+1:(Lp+Lh+Ld)*11)=DBPSK(C,State);
28   case 2
29       Signal(:,(Lp+Lh)*11+1:(Lp+Lh+Ld/2)*11)=DQPSK(C,State);
30   case 5.5
31       Signal(:,(Lp+Lh)*11+1:(Lp+Lh)*11+Ld*2)=CCK55(C,State);
32   otherwise
33       Signal(:,(Lp+Lh)*11+1:(Lp+Lh)*11+Ld)=CCK11(C,State);
34   end
35 end
36 