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
    nx=DWF_sin(x);// nx的内核函数,可替换任意函数
  end
endfunction

function[width-1:0] my;//my=sqrt(y)
  input [width-1:0] y;
  begin
    my=DWF_sqrt_tc(y);// my的内核函数,可替换任意函数
  end
endfunction

always @( A or temp_a )//组合电路，用于描述f(x)实现过程
begin
  temp_a <= nx(A); //fx可分解为函数嵌套f(x)=m(y),y=n(x)
  temp_b <= my(temp_a);
end

//Multiplier - product with a clock latency of one
always @ ( posedge CLK )
  PRODUCT <= temp_b; //存储temp_b

endmodule
