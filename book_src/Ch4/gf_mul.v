module  GfMul #(parameter  m  =  4)(
input   [0:m-1]  a , // �˷�����a
input   [0:m-1]  b , // �˷�����b
input   [0:m-1]  p , // ���ɶ���ʽ
output  [0:m-1]  y   // �˷����
);
wire    [0:m-1]  s  [0:m-1] ;
// ���м������г�ʼ��
assign  s[0]  =  {m{a[0]}} & b;
// �������ÿ��bit���ν��е���
genvar  i ;
generate
begin
  for  ( i  =  1 ;  i  <=  (m-1) ;  i  =  i + 1 )
    begin  :  rows
      assign  s[i]  = ({(m){a[i]}} & b) ^ ({(m){s[i-1][0]}} & p)^({ s[i-1][1:m-1] , 1'b0 });
    end
end
endgenerate
// ��m-1�еĽ�����ۼ���m-1�Σ�����Ϊ�˷����
assign  y  =  s[m-1] ;
endmodule
