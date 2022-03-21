module decompose3 #(parameter width = 16)(
input                 CLK,
input [width-1:0]     A,
output reg[width-1:0] PRODUCT
);

reg [width - 1 : 0] temp_a;
reg [width - 1 : 0] temp_b;

parameter angle_width = width;
parameter sin_width = width;
parameter cos_width = width;
`include "DW_sqrt_function.inc"
`include "DW02_sin_function.inc"

function[width-1:0] nx;//nx=sin(x)
  input [width-1:0] x;
  begin
    nx=DWF_sin(x);// nx���ں˺���,���滻���⺯��
  end
endfunction

function[width-1:0] my;//my=sqrt(y)
  input [width-1:0] y;
  begin
    my=DWF_sqrt_tc(y);// my���ں˺���,���滻���⺯��
  end
endfunction

always @( A or temp_a )//��ϵ�·����������f(x)ʵ�ֹ���
begin
  temp_a <= nx(A); //fx�ɷֽ�Ϊ����Ƕ��f(x)=m(y),y=n(x)
  temp_b <= my(temp_a);
end

//Multiplier - product with a clock latency of one
always @ ( posedge CLK )
  PRODUCT <= temp_b; //�洢temp_b

endmodule
