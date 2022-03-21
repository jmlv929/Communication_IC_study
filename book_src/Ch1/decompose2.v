module decompose2 #(
parameter A_width = 16,
parameter B_width = 16
)(
input                    CLK,
input [A_width - 1 : 0]  A,
input [B_width - 1 : 0]  B,
output reg[A_width+B_width-1:0] PRODUCT
);
localparam width = A_width + B_width;
reg [width - 1 : 0] temp_a;
reg [width - 1 : 0] temp_b;

parameter angle_width = A_width;
parameter sin_width = width;
parameter cos_width = width;
`include "DW02_cos_function.inc"
`include "DW02_sin_function.inc"

function[width-1:0] gx1;
  input [A_width-1:0] x;
  begin
    gx1=DWF_cos(x);// gx1���ں˺���
  end
endfunction

function[width-1:0] gx2;
  input [B_width-1:0] x;
  begin
    gx2=DWF_sin(x);// gx2���ں˺���
  end
endfunction

//Sign extending
always @( A or B) //��ϵ�·
begin
  temp_a = gx1(A); //��fx���Ϊgx1��gx2�ĳ˻�
  temp_b = gx2(B);
end

//Multiplier - product with a clock latency of one
always @ ( posedge CLK )
  PRODUCT <= temp_a * temp_b; //�˷���ɺ�洢

endmodule
