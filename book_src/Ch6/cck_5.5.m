01 function Signal=CCK55(Data,state)  % stateλ��ʼ��λ
02   eo=0;
03   for i=1:4:length(Data);
04     a=2*Data(i)+Data(i+1);   %����ǰ�������ؽ��в�ֱ���
05     switch a;
06       case 1;x1=1;
07       case 2;x1=3 ;
08       case 3;x1=2;
09       otherwise x1=0;
10     end
11     x1=x1+eo*2;              %���������Ž�����λ��ת
12     x1=mod(x1+state,4);
13     x2=Data(i+2)*2+1;        %�Ե������ؽ��б���
14     x4=Data(i+3)*2;          %�Ե��ı��ؽ��б���
15     c(1,1)=mod(x1+x2+x4,4);  %����ÿһ��Ƭ����λ
16     c(1,2)=mod(x1+x4,4);
17     c(1,3)=mod(x1+x2+x4,4);
18     c(1,4)=mod(x1+x4+2,4);
19     c(1,5)=mod(x1+x2,4);
20     c(1,6)=mod(x1,4);
21     c(1,7)=mod(x1+x2+2,4);
22     c(1,8)=x1;
23     state=c(1,8);             %����I��Q����ź�
24     for j=1:8;
25       switch c(1,j);
26       case 0;Signal(1,(i-1)*2+j)=1;Signal(2,(i-1)*2+j)=0;
27       case 1;Signal(1,(i-1)*2+j)=0;Signal(2,(i-1)*2+j)=1 ;
28       case 2;Signal(1,(i-1)*2+j)=-1;Signal(2,(i-1)*2+j)=0;
29       otherwise Signal(1,(i-1)*2+j)=0;Signal(2,(i-1)*2+j)=-1;
30       end
31     end
32     eo=xor(eo,1);
33  end
34 end
35 