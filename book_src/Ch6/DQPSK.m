function [Signal,State]=DQPSK(Data,State)
  A=[1 -1 1 1 -1 1 1 1 -1 -1 -1];   %��Ƶ�Ϳ���
  for i=1:2:length(Data);
    a=2*Data(i)+Data(i+1);
    switch a;                      %�Ľ��Ʋ�ֱ���
      case 1; State=State+1;
      case 2; State=State+3 ;
      case 3; State=State+2;
      otherwise State=State+0;
    end
    State=rem(State,4);
    switch State;                  %����ת��
      case 0;a=1;b=0;
      case 1;a=0;b=1 ;
      case 2;a=-1;b=0;
      otherwise a=0;b=-1;
    end
    Signal(1,(i-1)*11/2+1:(i-1)*11/2+11)=a*A;%�Ϳ�����Ƶ
    Signal(2,(i-1)*11/2+1:(i-1)*11/2+11)=b*A;
  end
end