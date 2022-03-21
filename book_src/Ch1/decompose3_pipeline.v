module decompose3_pipeline #(parameter width = 16)(
input                   CLK,
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

//function [(width+1)/2-1 : 0] DWF_sqrt_tc;
function[width-1:0] nx;
  input [width-1:0] x;
  begin
    nx=DWF_sqrt_tc(x);// nx���ں˺���,���滻���⺯��
  end
endfunction

function[width-1:0] my;
  input [width-1:0] y;
  begin
    my=DWF_sin(y);// my���ں˺���,���滻���⺯��
  end
endfunction

//
always @ ( posedge CLK )//ʱ���·��������ˮ�߼Ĵ���
begin
  temp_a <= nx(A); //��fx�ֽ�Ϊ����Ƕ��f(x)=m(y),y=n(x)
  temp_b <= my(temp_a);
end

//Multiplier - product with a clock latency of one
always @ ( posedge CLK )
  PRODUCT <= temp_b; //�洢temp_b

endmodule
