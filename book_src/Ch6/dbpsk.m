function [Signal,State]=DBPSK(Data,State)
  A=[1 -1 1 1 -1 1 1 1 -1 -1 -1]; %������Ƶ�İͿ���
  for i=1:length(Data);
    State=xor(State,Data(i));     %�����Ʋ�ֱ���
    if State==0;
        b=1;                      %����ת��
    else
        b=-1;
    end
    Signal(1,(i-1)*11+1:i*11)=b*A;%��Ƶ
    Signal(2,(i-1)*11+1:i*11)=b*A;
  end
end
