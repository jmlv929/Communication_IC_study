function [Bit,In,Stateo]=DEB(Signal,Statei)
  A=[1 -1 1 1 -1 1 1 1 -1 -1 -1]; %�Ϳ���
  I=Signal(1,:)*A';   %�Ϳ�����ؼ���
  if abs(I)<5.5;      %��ط���
    In=1;
    Bit=-1;
    Stateo=Statei;
  else
    if I>0;           %��ط弫���о�
      d=0;            %�����о�
    else
      d=1;
    end
    In=10;
    Bit=xor(d,Statei);%�������
    Stateo=d;
  end
end
