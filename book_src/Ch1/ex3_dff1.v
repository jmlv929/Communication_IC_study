module DFF1(
  input clk,
  input reset,
  input d,
  output reg q
);

always@(posedge clk or negedge reset)
  if(!reset)
    q <= 0; //�첽�� 0���͵�ƽ��Ч
  else
    q <= d;

endmodule
