function [Signal,State]=DQPSK(Data,State)
  A=[1 -1 1 1 -1 1 1 1 -1 -1 -1];   %扩频巴克码
  for i=1:2:length(Data);
    a=2*Data(i)+Data(i+1);
    switch a;                      %四进制差分编码
      case 1; State=State+1;
      case 2; State=State+3 ;
      case 3; State=State+2;
      otherwise State=State+0;
    end
    State=rem(State,4);
    switch State;                  %码型转换
      case 0;a=1;b=0;
      case 1;a=0;b=1 ;
      case 2;a=-1;b=0;
      otherwise a=0;b=-1;
    end
    Signal(1,(i-1)*11/2+1:(i-1)*11/2+11)=a*A;%巴克码扩频
    Signal(2,(i-1)*11/2+1:(i-1)*11/2+11)=b*A;
  end
end