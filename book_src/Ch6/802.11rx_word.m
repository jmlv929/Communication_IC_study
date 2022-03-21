i = 1;
while ~LongDetect & i< 160
    LongSync(i)  = a_abs(4 * Signal3( 2*(N+i-63):2:2*(N+i)) * ([LongPreample(33:64) LongPreample(1:32)])');
   if (LongSync(i) > SignalAbs(FCStart)*1.5) & (LongSync(i) > LongPeak)%64
        LongPeak = LongSync(i);
        maxI = i;
        Count = 0;
    else
        if LongPeak > 0
            Count = Count + 1;
        end
    end
    if Count == 48
        LongDetect = 1;
    end
    i = i + 1;
end

function Che_filter = Che_filter3(Che)
  B2 = [1 6 1]/8;
  P = [Che(1:26)  Che(27:52)];
  F = conv(P , B2);
  Che_filter = [F(2:29) F(30:53)];
  Che_filter(1) = Che(1);
  Che_filter(52) = Che(52);
end


Che_FFT=(SignalA0+SignalA1)/2;
CheA1=FFT(Che_FFT);
CheA=CheA1*[LongS(1:26) LongS(28:53)];

if Diversity == 1
  Fs = (-angle(PlateuMax) - angle(PlateuMaxB))/2/pi;  % coarse freq. offset
else
  Fs = -angle(PlateuMax) /pi;
end
Fsc=Fs/32;



 1 function ret = data_angle(data)
 2 real_abs = abs(real(data));
 3 imag_abs = abs(imag(data));
 4 real_less_0 = (real(data) < 0);
 5 imag_less_0 = (imag(data) < 0);
 6 real_less_imag = (real_abs < imag_abs);
 7 if real_less_imag
 8     dividend = real_abs;
 9     divider  = imag_abs;
10 else
11     dividend = imag_abs;
12     divider  = real_abs;
13 end
14
15 addr = round(dividend/divider*512);
16 if addr == 512
17     s = 512;
18 else
19 switch addr
20 case    0,       s = addr(t) +  0  ;
21  case    1,      s = addr(t) +  0  ;
22  case    2,      s = addr(t) +  1  ;
…………………………………………
530  case  510,     s =  addr(t) +   1 ;
531  case  511,     s =  addr(t) +   0 ;
532    end
533 end
534 switch imag_less_0 * 4 + real_less_0 * 2 + real_less_imag
535   case  0,  ret =  s;
536   case  1,  ret = 512*2 - s;
537   case  2,  ret = 512*4 - s;
538   case  3,  ret = 512*2 + s;
539   case  4,  ret = 512*8 - s;
540   case  5,  ret = 512*6 + s;
541   case  6,  ret = 512*4 + s;
542   case  7,  ret = 512*6 - s;
543 end


%%
for t=1:100
  x=rand(1,1);
  input=2*pi*x;
  fangl_name = sprintf('e:\\angle.txt');
  fsin_name = sprintf('e:\\sinout.txt');
  fcos_name = sprintf('e:\\cosout.txt');
  Qinput = num2fixpt(x, ufix(12), 2^(-12), 'Nearest', 'on');
  Qinput=Qinput*4096;
  [sinout, cosout]=sincos(input);
  sinout  =  num2fixpt(sinout, sfix(10), 2^(0), 'Nearest', 'on');
  cosout  =  num2fixpt(cosout, sfix(10), 2^(0), 'Nearest', 'on');
  WRITETOFILE(fangl_name, Qinput, 12, 0);
  WRITETOFILE(fsin_name, sinout, 9, 0);
  WRITETOFILE(fcos_name, cosout, 9, 0);
end
%%
function [sinout, cosout]=sincos(input)
input=4.075;
input=mod(input,2*pi);
input=num2fixpt(input*4/pi, ufix(12), 2^(-9), 'Nearest', 'on');
input=input*512
divded=floor(input/512)
switch divded
case 7
   sinout=-sinx(8*512-input);
   cosout=cosx(8*512-input) ;
case 6
   sinout=-cosx(input-6*512);
   cosout=sinx(input-6*512) ;
case 5
   sinout=-cosx(6*512-input);
   cosout=-sinx(6*512-input);
case 4
    sinout=-sinx(input-4*512);
    cosout=-cosx(input-4*512);
case 3
  sinout=sinx(4*512-input);
  cosout=-cosx(4*512-input);
case 2
 sinout=cosx(input-2*512);
 cosout=-sinx(input-2*512);
case 1
    sinout=cosx(512-input);
    cosout=sinx(512-input);
case 0
    sinout=sinx(input);
    cosout=cosx(input);
end
%%
function s=sinx(x)
  if x==512
      s=106;
  else
      switch x
      case   0;  s =   0;
      case   1;  s =   1;
      ……………………………
      case   509;  s = 106;
case   510;  s = 106;
case   511； s= 106;
      end
  end
s=s-floor(x/2);


 1 function DeMaped = demap(Signal, modmethod, W)
 2 switch modmethod
 3 case 4, %64QAM
 4     Kmod = 8/sqrt(42);
 5 otherwise % 16QAM QPSK BPSK
 6     Kmod = 4/sqrt(10);
 7 end
 8 [DeMaped Len] = demap1(Signal, modmethod, W*Kmod);
 9
10 function [DeMap, Len] = demap1(Signal, modmethod, K)
11 switch modmethod
12 case 4, %64QAM
13     a0=real(Signal);
14     a1=0.5*K-sign(a0).*a0;
15     b0=imag(Signal);
16     b1=0.5*K-sign(b0).*b0;
17     inde=find(a0<= -0.5*K);
18     a2(inde)=(a0(inde) + 0.75*K(inde));
19     inde2=find(a0<=0&a0>-0.5*K);
20     a2(inde2)=(-0.25*K(inde2) - a0(inde2));
21     inde3=find(a0>0&a0<= 0.5*K);
22     a2(inde3)=(a0(inde3) - 0.25*K(inde3));
23     inde4=find(a0>0.5*K);
24     a2(inde4)=( 0.75*K(inde4) - a0(inde4));
25     inde=find(b0<= -0.5*K);
26     b2(inde)=(b0(inde) + 0.75*K(inde));
27     inde2=find(b0<=0&b0>-0.5*K);
28     b2(inde2)=(-0.25*K(inde2) - b0(inde2));
29     inde3=find(b0>0&b0<= 0.5*K);
30     b2(inde3)=(b0(inde3) - 0.25*K(inde3));
31     inde4=find(b0>0.5*K);
32     b2(inde4)=( 0.75*K(inde4) - b0(inde4));
33     DeMap(1:6:length(Signal)*6) = a0 ;
34      DeMap(2:6:length(Signal)*6) = a1 ;
35       DeMap(3:6:length(Signal)*6) = a2 ;
36        DeMap(4:6:length(Signal)*6) = b0 ;
37         DeMap(5:6:length(Signal)*6) = b1 ;
38          DeMap(6:6:length(Signal)*6) = b2 ;
39     Len = 6;
40 case 3, % 16QAM
41     a0=real(Signal);
42     a1=0.5*K-sign(a0).*a0;
43     b0=imag(Signal);
44     b1=0.5*K-sign(b0).*b0;
45     DeMap(1:4:length(Signal)*4) = a0 ;
46      DeMap(2:4:length(Signal)*4) = a1 ;
47       DeMap(3:4:length(Signal)*4) = b0 ;
48        DeMap(4:4:length(Signal)*4) = b1 ;
49      Len = 4;
50 case 2, % QPSK
51     a0=real(Signal);
52     a1= imag(Signal);
53     DeMap(1:2:length(Signal)*2) = a0 ;
54      DeMap(2:2:length(Signal)*2) = a1 ;
55     Len = 2;
56 otherwise % BPSK and other
57     DeMap = [real(Signal)];
58     Len = 1;
59 end


function ret = a_abs(x)
    re = abs(real(x));
    im = abs(imag(x));
    big = max(re, im);
    small = min(re, im);
    ret = big + floor(small/4) + floor(small/8);
end

H(1)=a_abs(BMF(1))+a_abs(BMF(23)) +a_abs(BMF(45))+a_abs(BMF(67))+ a_abs(BMF(89)) +a_abs(BMF(111)) +a_abs(BMF(133))+a_abs(BMF(155));
H(2)＝a_abs(BMF(2))+a_abs(BMF(24)) +a_abs(BMF(45))+a_abs(BMF(68)) + a_abs(BMF(90)) +a_abs(BMF(112)) +a_abs(BMF(134))+a_abs(BMF(156));
…         …        …         …        …         …
H(22)＝a_abs(BMF(22))+a_abs(BMF(44)) +a_abs(BMF(66))+a_abs(BMF(88)) + a_abs(BMF(110)) +a_abs(BMF(132)) +a_abs(BMF(154))+a_abs(BMF(176))

if IsLongP %如果IsLongP=1循环68次，否则循环17次。
  CheL=68;
else
  CheL=17;
end

for k=1:CheL
  if State(k)==0
    ChannelFilter1=ChannelFilter1+BarkerCorrel(k)(1:22);
  else
    ChannelFilter1=ChannelFilter1-BarkerCorrel(k)(1:22);
  end
end


if IsLongP
  CheDen=64;
else
  CheDen=16;
end
ChannelFilter_tp=ChannelFilter1(LabelFT-3:LabelFT+4)/CheDen;

01 H=zeros(1,22);
02 CheDEN=64;
03 for K=1:68
04      if K<15+1
05        SUMD=SUMD+D(Pi);
06      end
07      if State==0
08         H=H+Temp;
09     else
10         H=H-Temp;
11     end
12     if K==17 & SUMD<8
13        break;
14     end
15     Index=Index+11*ss;
16 end
17 if K==17
18     CheDEN=16;
19 end
20 [A,N]= max(H);
21 hr=H(N-floor(Nf/2)+1:N+ceil(Nf/2))/CheDEN;
22
23 for I = 1:8
24     for J = 1:8
25         if I == J
26             S(I,J) = 11/128;
27         else if I == J+4 |  I == J-4
28                 S(I,J) = 1/128;
29             else
30                 S(I,J) = 0;
31             end
32         end
33     end
34 end
35 hr=hr*S;
36 filter=hr;
37 filter = num2fixpt(filter, sfix(7), 2^(-6), 'nearest', 'on');
38 for I = 1:3
39     hoc(I) = filter(1+I*2:8)*filter(1:8-I*2)';
40 end
41 hoc = num2fixpt(hoc, sfix(6), 2^(-6), 'nearest', 'on');
42

 1 for I=1:22(或16)
 2 % 第一步：找出本样点的由频偏引起的相偏Ps。注意：一个符号的第1个样点还要计算出本符号的Fs，此外该处Ps的计算也较特殊。
 3   if I==1
 4     Fs=Fs+F*Pe;
 5     Ps=Ps+P*Pe+Fs*%累加过程去掉高位
 6     Ps=Ps+Fs %将累加结果的高位去掉 。
 7     if Ps>=1
 8       Ps=Ps-2;
 9     end %将Ps用[-1,1]之间的数表示
10   else
11     Ps=Ps+Fs %累加过程去掉高位。
12     if Ps>=1
13       Ps=Ps-2;
14     end %将Ps用[-1,1]之间的数表示
15   end
16 % 第二步：将第一步得到的Ps四舍五入，保留高10位（包括符号位）得Ps1，用Ps1查表求出Ps对应的正余弦值，分别用COSPs，SINPs表示。
17   Ps1=Ps;
18   Ps1=num2fixpt(Ps,sfix(10),2^(-9),'nearest','on');
19   [ExpPsSIN, ExpPsCOS]=sincos(Ps1)
20
21 % 第三步:  频偏补偿
22   FCSignal=LPFSignal*(COSPs - jSINPs)
23 %  =Re(LPFSignal)*COSPs + Im(LPFSignal)*SINPs+ j[Im(LPFSignal)*COSPs – Re(LPFSignal)*SINPs]
24 end

if CoeffSel=0  %Header段之前
    P = 1/2;
    F=1/128;
else          %Header段及以后
    P = 1/8;
    F = 1/2048;
end

SyncF=0;
Sync0=0;
Sync1=0;
for I=0:3
	SyncF = SyncF + a_abs(16*BarkerCorrel(Np-1)); % 峰值前面一个相关值
	Sync0 = Sync0 + a_abs(16*BarkerCorrel(Np)); % 巴克码相关峰值处
	Sync1 = Sync1 + a_abs(16*BarkerCorrel(Np+1));% 峰值后面一个相关值
	Np=Np+22; %指向下一个符号（每符号22个样点）；
end

SyncF=0;
Sync0=0;
Sync1=0;
for I=0:3
  SyncF=SyncF+ a_abs(16*ChfSignal(Index+1:2:Index+15)*(exp(j*pi/2*CCKremodData))');
  Sync0 = Sync0 + a_abs(16*ChfSignal(Index+2::2:Index+16)*(exp(j*pi/2*CCKremodData))');
  Sync1=Sync1+a_abs(16*ChfSignal(Index+3:2:Index+17)*(exp(j*pi/2*CCKremodData))');
  Index=Index+16;%指向下一个CCK符号（每个CCK符号16个样点）
end

PN=4;
 if T < -1/2/PN*9/8
     T = T + 1/PN;
     if PH < PN-1
         PH = PH + 1;  %PH用以指示4组不同的LPF滤波器系数
     else
         PH = 0;
         Index = Index - 1; %向前调整定时脉冲
         Ps = Ps - Fs;  %由FC模块自动完成
     end
 end

 if T >  1/2/PN*9/8
     T = T - 1/PN;
     if PH > 0
         PH = PH - 1;   %LPF系数指示
     else
         PH = PN-1;
         Index = Index + 1;  %向后调整定时脉冲
         Ps = Ps + Fs;       %由FC模块自动完成
     end
 end

 1 function ret = div(data, C)
 2   data = data + floor(C/16);
 3   b0 = (data < 0);
 4   if b0
 5     C1 = -floor(C/2) - 1;
 6   else
 7     C1 =  C/2;
 8   end
 9   b1 = (data > C1);
10   if b1
11     C2_4 = floor(C/4);
12   else
13     C2_4 = -floor(C/4) - 1;
14   end
15   C2 = C1 + C2_4;
16   b2 = (data > C2);
17   if b2
18     C3_8 = floor(C/8);
19   else
20     C3_8 = -floor(C/8) - 1;
21   end
22   C3 = C2 + C3_8;
23   b3 = (data > C3);
24
25   ret = (-b0*8 + b1*4 + b2*2 + b3)/8;

function [T_new] = smooth_k( Te, T)
  T_new  = T + (Te - T)/8;
end

LPFCoeffSel=0:
LPFFilter= [2     0    -7    21    44    11    -7     2]/64;
LPFCoeffSel=1:
LPFFilter = [3    -3    -4    31    39     2    -6     3]/64;
LPFCoeffSel=2:
LPFFilter= [3    -6     2    39    31    -4    -3     3]/64;
LPFCoeffSel=3:
LPFFilter = [2    -7    11    44    21    -7     0     2]/64;

01 function [PeakJ,PeakK,PeakL,PeakFWT]=FWT(Signal,Hoc,Is55)
02 %FWT    FWT Algorithm during decoding CCK11 or CCK55
03 %Signal   Equalized or nonequalized match-filted signal
04 %Hoc    Auto-correlation of channel filter estimated
05 %Is55       If it is CCK55, Is55=1; if it is CCK11 Is55=0.
06 %PeakJ          Decoded Phi2
07 %PeakK          Decoded Phi3
08 %PeakL          Decoded Phi4
09 %PeakFWT        FWT value when the difference reached to peak
10 Peak = 0;
11 P=0;
12 PeakFWT = 0;
13 PeakJ = 0;
14 PeakK = 0;
15 PeakL = 0;
16 a=zeros(1,4);
17 b=zeros(1,4);
18 fwt=zeros(1,8);
19 auto=zeros(1,4);
20 fwt_m=zeros(1:8);
21
22 for L=0:3
23     ExpL=exp(-j*pi/2*L);
24     a(1)= Signal(1)*ExpL+Signal(5);
25     a(2)= Signal(3)*ExpL-Signal(7);
26     a(3)= Signal(2)*ExpL+Signal(6);
27     a(4)=-Signal(4)*ExpL+Signal(8);
28     for K2=0:1
29         ExpK2=exp(-j*pi/2*K2);
30         b(1)= a(1)*ExpK2+a(2);
31         b(2)= a(3)*ExpK2+a(4);
32         b(3)=-a(1)*ExpK2+a(2);
33         b(4)=-a(3)*ExpK2+a(4);
34         fwt(1)=b(1)+b(2);
35         fwt(3)=b(1)*(-j)+b(2);
36         fwt(5)=-b(1)+b(2);
37         fwt(7)=b(1)*( j)+b(2);
38         fwt(2)=b(3)+b(4);
39         fwt(4)=b(3)*(-j)+b(4);
40         fwt(6)=-b(3)+b(4);
41         fwt(8)=b(3)*( j)+b(4);
42         for i=1:8
43             if abs(real(fwt(i))) > abs(imag(fwt(i)))
44                 fwt_m(i) = abs(real(fwt(i)));
45             else
46                 fwt_m(i) = abs(imag(fwt(i)));
47             end
48         end
49         R2=2*exp(j*(L)*pi/2);
50         R3=exp(j*(L-K2)*pi/2);
51         R1=-R3;
52         R1_i = real(R1*Hoc(1));
53         R1_q = imag(R1*Hoc(1));
54         R2_i = real(R2*Hoc(3));
55         R2_q = imag(R2*Hoc(3));
56         R3_i = real(R3*Hoc(3));
57         R3_q = imag(R3*Hoc(3));
58
59         auto(1)=   R1_i + R2_i + R3_i;
60         auto(2)= - R1_i + R2_i - R3_i;
61         auto(3)=   R1_q + R2_q - R3_q;
62         auto(4)= - R1_q + R2_q + R3_q;
63
64         A=fwt_m(1:4)-auto;
65         B=fwt_m(5:8)+auto;
66
67         if Is55
68             if (K2==0 & mod(L,2)==0)
69                 [P,N]=max([A(3) B(3)]);
70                 if N==1
71                     N = 3;
72                 else
73                     N = 7;
74                 end
75             end
76         else
77             [P,N]=max([A B]);
78         end
79
80         if Peak < P
81             Peak = P;
82             PeakJ =mod(N-1,8);
83             PeakK =K2;
84             PeakL =L;
85             PeakFWT = fwt(PeakJ+1);
86         end
87
88     end
89 end % L
90 if mod(PeakJ,2) == 1
91     PeakK = PeakK+2;
92 end
93 PeakJ = floor(PeakJ/2);
94
95
96
97

function [ISIBF]=ISI(X,H)
  FixPt=0;
  X=exp(j*X*pi/2);
  ISIBF=zeros(1,3);
  ISIBF(1) = X(1)*H(3)+X(2)*H(2)+X(3)*H(1);
  ISIBF(2) = X(2)*H(3)+X(3)*H(2);
  ISIBF(3) = X(3)*H(3);
  if FixPt
    ISIBF=num2fixpt(ISIBF,sfix(8),2^(-7),'nearest','on');
end


if real(Peak)<imag(Peak)  %
  d0=1;
else
  d0=0;
end
if real(Peak)+imag(Peak)<0  %
  d1=1;
else
  d1=0;
end
d0_1 = xor(d0, d1); %


ChannelAuto(1)=ChannelFilter(3)×conj(ChannelFilter(1))
+ChannelFilter(4)×conj(ChannelFilter(2))
+ChannelFilter(5)×conj(ChannelFilter(3))
+ChannelFilter(6)×conj(ChannelFilter(4))
+ChannelFilter(7)×conj(ChannelFilter(5))
+ChannelFilter(8)×conj(ChannelFilter(6));
ChannelAuto(2)=ChannelFilter(5)×conj(ChannelFilter(1))
+ChannelFilter(6)×conj(ChannelFilter(2))
+ChannelFilter(7)×conj(ChannelFilter(3))
+ChannelFilter(8)×conj(ChannelFilter(4));
ChannelAuto(3)=ChannelFilter(7)×conj(ChannelFilter(1))
+ChannelFilter(8)×conj(ChannelFilter(2))。

ChannelFilter(1)=ChannelFilter_tp(1)*11/128+ChannelFilter_tp(5)/128;
ChannelFilter(2)=ChannelFilter_tp(2)*11/128+ChannelFilter_tp(6)/128;
ChannelFilter(3)=ChannelFilter_tp(3)*11/128+ChannelFilter_tp(7)/128;
ChannelFilter(4)=ChannelFilter_tp(4)*11/128+ChannelFilter_tp(8)/128;
ChannelFilter(5)=ChannelFilter_tp(5)*11/128+ChannelFilter_tp(1)/128;
ChannelFilter(6)=ChannelFilter_tp(6)*11/128+ChannelFilter_tp(2)/128;
ChannelFilter(7)=ChannelFilter_tp(7)*11/128+ChannelFilter_tp(3)/128;
ChannelFilter(8)=ChannelFilter_tp(8)*11/128+ChannelFilter_tp(4)/128;


ExpAng4=exp(-j*pi/2*Ang4);
a(1)=  CCKModSignal(1)*ExpAng4 + CCKModSignal(5);
a(2)=  CCKModSignal(2)*ExpAng4 + CCKModSignal(6);
a(3)=  CCKModSignal(3)*ExpAng4 - CCKModSignal(7);
a(4)= - CCKModSignal(4)*ExpAng4 + CCKModSignal(8);

ExpAng3M2=exp(-j*pi/2*Ang3M2);
b(1)=  a(1)*ExpAng3M2+a(3);
b(2)=  a(2)*ExpAng3M2+a(4);
b(3)= - a(1)*ExpAng3M2+a(3);
b(4)= - a(2)*ExpAng3M2+a(4);
%如果Is55=1，则仅计算b(1),b(2)。

fwt(1)=  b(1)+b(2);
fwt(3)=  b(1)*(-j)+b(2);
fwt(5)= - b(1)+b(2);
fwt(7)=  b(1)*( j)+b(2);
fwt(2)=  b(3)+b(4);
fwt(4)=  b(3)*(-j)+b(4);
fwt(6)= - b(3)+b(4);
fwt(8)=  b(3)*( j)+b(4);
%如果Is55=1，则仅计算fwt(3),fwt(7)。

ABSfwt(1) ＝ max(abs(real(fwt(1))),abs(imag(fwt(1))));
ABSfwt(2)  = max(abs(real(fwt(2))),abs(imag(fwt(2))));
ABSfwt(3) ＝ max(abs(real(fwt(3))),abs(imag(fwt(3))));
ABSfwt(4)  = max(abs(real(fwt(4))),abs(imag(fwt(4))));
ABSfwt(5) ＝ max(abs(real(fwt(5))),abs(imag(fwt(5))));
ABSfwt(6)  = max(abs(real(fwt(6))),abs(imag(fwt(6))));
ABSfwt(7) ＝ max(abs(real(fwt(7))),abs(imag(fwt(7))));
ABSfwt(8)  = max(abs(real(fwt(8))),abs(imag(fwt(8))));
%如果Is55=1，则仅计算ABSfwt(3),ABSfwt(7)

R3=exp(j*(Ang4-Ang3M2)*pi/2);
R2=2*exp(j*(Ang4)*pi/2);
R1=-R3;

R1_i = real(R1*ChannelAuto(1));
R1_q = imag(R1*ChannelAuto(1));
R2_i = real(R2*ChannelAuto(3));
R2_q = imag(R2*ChannelAuto(3));
R3_i = real(R3*ChannelAuto(3));
R3_q = imag(R3*ChannelAuto(3));
%如果Is55=1，则仅计算R1_i, R2_i,R3_i。
CCKauto(1)=   R1_i + R2_i + R3_i;  
CCKauto(2)= - R1_i + R2_i - R3_i;  
CCKauto(3)=   R1_q + R2_q - R3_q;  
CCKauto(4)= - R1_q + R2_q + R3_q;  
%如果Is55=1，则仅计算CCKauto(3)。


if Peak < Peak_tmp
    Peak = Peak_tmp;
    CCKPeakAng2= N; 
    CCKPeakAng3=Ang3M2;
    CCKPeakAng4=Ang4;
    PeakFWT = fwt(CCKPeakAng2+1);
end

CCKremodData=exp(j*CCKremodData*pi/2);
ISI(1) = CCKremodData(1)*ChannelAuto(3)+CCKremodData(2)*ChannelAuto(2) + CCKremodData(3)*ChannelAuto(1);
ISI(2) = CCKremodData(2)*ChannelAuto(3)+CCKremodData(3)*ChannelAuto(2);
ISI(3) = CCKremodData(3)*ChannelAuto(3);

switch Stateo
  case 0  PeakPe = Peak;
  case 2  PeakPe = -Peak;
end

function x=ahead_lpf(y);
h=[-2 -2 4 4 -8 -8 9 11 -16 -22 37 115 115 37 -22 -16 11 9 -8 -8 4 4 -2 -2]/256;
yy=[ y ];
len=length(y);
for i=12:2:len-12
    y_mup=yy(i-11:i+12).*h;
    x(i-11)=sum(y_mup);
    x(i+1-11)=x(i-11);
end

S_i = real(Signal) - RGB_ANG*imag(Signal)*RGB_AMP;
S_q = imag(Signal)* RGB_AMP - RGB_ANG*real(Signal);
Signal = S_i + j*S_q;

sum_conv=s_conv_i^2+ s_conv_q^2;
sum(k)=sum1(k-48)+sum1(k-32)+sum1(k-16)+sum1(k);

nearabs(i)=a_abs(32*Signal(i));
fix2=floor(absreg/32);
SignalAbs = (absreg + ( nearabs-(fix2)));
SignalAbs=num2fixpt(SignalAbs,ufix(11),2^-4,'floor','on');

if sum(k)>SignalAbs(k)*SignalAbs(k)* OFDM_PD_THRES
  if sum(k)>4
     pd_flag=1;
  end
end


 1 if  AGC_START
 2     read in RMS
 3     if RMS<200
 4       look up LOGTABLE, get RMS _DB
 5       Gain change= RGB_Target_DB- RMS_DB;
 6       if VGA_GAIN_SEL==1'b1 // 'H'
 7         VGA_AGC = floor((VGA_GAIN*2+ RMS_DB - RGB_Target_DB)/2);
 8       else
 9         VGA_AGC=floor((VGA_GAIN*2- RMS_DB + RGB_Target_DB)/2)
10       end
11     else
12       RX_RF_AGC = 1
13       VGA_AGC = RGB_VGA_2ND;
14         // VGA gain =11
15     end
16     
17     wait RGB_AGC_TIM
18     read in RMS
19     look up LOGTABLE, get RMS _DB
20     Gain change= RGB_Target_DB- RMS_DB;
21 
22     if  RGB_RF_SEL=1'b1 // 'H'
23       if  Gain change>16dB
24         RX_RF_AGC=2;
25         Gain change= RGB_Target_DB- RMS_DB-16;
26       end
27     end 
28     if  VGA_GAIN_SEL==1'b1 // 'H'
29       VGA_AGC = floor((VGA_GAIN*2+Gain change)/2);
30     else
31       VGA_AGC=floor((VGA_GAIN*2- Gain change)/2)
32     end
33 
34     Wait RGB_AGC_TIM;
35     AGC_LOCK
36 end

S_i = real(Signal)  - RGB_ANG*imag(Signal);
S_q = imag(Signal)* RGB_AMP – RGB_ANG*real(Signal)*RGB_AMP;
Signal = S_i + j*S_q;

index= (TX_i^2+Tx_q^2)/128; // 做取整处理
dpd_i = H11(index)*TX_i+ H12(index)*TX_q;//做饱和溢出处理
dpd_q = H21(index)*TX_i+ H22(index)*TX_q;//做饱和溢出处理
Signal_out = dpd_i + j*dpd_q;

if   (Sk(kk)>Sk(kk+1))
  if   kk-Shift_index>Ncp*Oversample
     SymOffset_est = round((kk-N_FFT-Shift_index-1)/3);
  else
     SymOffset_est = round((kk-Shift_index-1)/3);
  end
end


