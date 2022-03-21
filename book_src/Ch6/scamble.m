function y=scramble(Data,flag)
  if flag==1;           % flag为帧类型标志
    A=[1 1 0 1 1 0 0];  %设置寄存器初始状态
  else
    A=[0 0 1 1 0 1 1];
  end
  for i=1:length(Data);
    a=xor(A(4),A(7));
    a=xor(a,Data(i));
    Data(i)=a;
    A(2:7)=A(1:6);     %寄存器移位
    A(1)=a;
  end
  y=Data;
end
