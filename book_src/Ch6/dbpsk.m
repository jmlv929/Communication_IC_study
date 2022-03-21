function [Signal,State]=DBPSK(Data,State)
  A=[1 -1 1 1 -1 1 1 1 -1 -1 -1]; %用于扩频的巴克码
  for i=1:length(Data);
    State=xor(State,Data(i));     %二进制差分编码
    if State==0;
        b=1;                      %码型转换
    else
        b=-1;
    end
    Signal(1,(i-1)*11+1:i*11)=b*A;%扩频
    Signal(2,(i-1)*11+1:i*11)=b*A;
  end
end
