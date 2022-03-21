module count#(parameter N=8)(
input clk,
input clear,
output[N-1:0] cnt_Q
);
reg[N-1:0] cnt;
assign cnt_Q = cnt;

always@(posedge clk)
  if(clear)
    cnt <= 'h0;      //同步清 0，高电平有效
  else
    cnt <= cnt+1'b1; //减法计数

endmodule
