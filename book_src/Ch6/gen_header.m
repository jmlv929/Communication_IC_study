function y=header(R,S,C,L)
  Data=zeros(1,48);
  a=dec2bin(10*R,8);  %����SIGNAL
  B=num2str(a);
  for i=1:8
      Data(i)=str2num(B(9-i));
  end
  Data(11)=S;         %�����ز������ͬ��
  Data(12)=C;         %���õ��Ʒ�ʽ
  If C=1
      l=L*8/R;        %����LENGTH��
  else
      l=(L+1)*8/R;
  end

  a=ceil(l);
  Data(16)=ge(a-l,8/11);
  B=dec2bin(a,16);
  B=num2str(B);

  for i=1:16;
      Data(33-i)=str2num(B(17-i));
  end

  B=Data(1:32);
  Data(33:48)=crc16(B);%ѭ������У��
  y=Data;
end
