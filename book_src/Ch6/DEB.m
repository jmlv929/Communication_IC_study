function [Bit,In,Stateo]=DEB(Signal,Statei)
  A=[1 -1 1 1 -1 1 1 1 -1 -1 -1]; %巴克码
  I=Signal(1,:)*A';   %巴克码相关计算
  if abs(I)<5.5;      %相关峰检测
    In=1;
    Bit=-1;
    Stateo=Statei;
  else
    if I>0;           %相关峰极性判决
      d=0;            %符号判决
    else
      d=1;
    end
    In=10;
    Bit=xor(d,Statei);%差分译码
    Stateo=d;
  end
end
