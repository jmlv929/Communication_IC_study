01 function  Signal=CCK11(Data,state)
02   eo=0;
03   x=ones(1,4);
04   c=ones(1,8);
05   for i=1:8:length(Data);
06     a=2*Data(i)+Data(i+1);
07     switch a;
08       case 1;x(1)=1;
09       case 2;x(1)=3 ;
10       case 3;x(1)=2;
11       otherwise x(1)=0;
12     end
13     x(1)=x(1)+eo*2;
14     x(1)=rem(x(1)+state,4);
15     for k=2:4;
16       x(k)=2*Data(i+k*2-2)+Data(i+k*2-1);
17     end
18     c(1)=rem(x(1)+x(2)+x(3)+x(4),4);
19     c(2)=rem(x(1)+x(3)+x(4),4);
20     c(3)=rem(x(1)+x(2)+x(4),4);
21     c(4)=rem(x(1)+x(4)+2,4);
22     c(5)=rem(x(1)+x(2)+x(3),4);
23     c(6)=rem(x(1)+x(3),4);
24     c(7)=rem(x(1)+x(2)+2,4);
25     c(8)=rem(x(1),4);
26     state=c(8);
27     for j=1:8;
28       switch c(j);
29         case 0;Signal(1,i+j-1)=1;Signal(2,i+j-1)=0;
30         case 1;Signal(1,i+j-1)=0;Signal(2,i+j-1)=1;
31         case 2;Signal(1,i+j-1)=-1;Signal(2,i+j-1)=0;
32         otherwise Signal(1,i+j-1)=0;Signal(2,i+j-1)=-1;
33       end
34     end
35     eo=xor(eo,1);
36  end
37 end