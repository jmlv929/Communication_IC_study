module DFF1(
  input clk,
  input reset,
  input d,
  output reg q
);

always@(posedge clk)
  if(!reset)
    q <= 0; //ͬ���� 0���͵�ƽ��Ч
  else
    q <= d;

endmodule
