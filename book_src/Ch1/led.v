module led#(parameter N=4,parameter TIMEOUT=32'hfff_ffff)(
  input clk,
  input reset,
  output reg[N-1:0] led //
);
reg[31:0]cnt;
always@(posedge clk)
  if(reset==1'b1)begin
    cnt<='h0;
    led<='b1; //
  end else begin
    cnt<=cnt+1'b1;
    if(cnt==TIMEOUT)begin
      led = led<<1; //
      if(led==4'b0000) led='b1;
    end
  end

endmodule
