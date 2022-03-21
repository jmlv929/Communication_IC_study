module DFF1(
  input clk,
  input reset,
  input d,
  output reg q
);

always@(posedge clk or negedge reset)
  if(!reset)
    q <= 0; //异步清 0，低电平有效
  else
    q <= d;

endmodule
