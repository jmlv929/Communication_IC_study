module updown_count#(parameter N=8)(
input clk,
input clear,
input load,
input up_down,
input [N-1:0] preset_D,
output[N-1:0] cnt_Q
);
reg[N-1:0] cnt;
assign cnt_Q = cnt;

always@(posedge clk)
  if(clear)
    cnt <= 'h0;      //同步清 0，高电平有效
  else if(load)
    cnt <= preset_D; //同步预置
  else if(up_down)
    cnt <= cnt+1;    //加法计数
  else
    cnt <= cnt-1;    //减法计数

endmodule
