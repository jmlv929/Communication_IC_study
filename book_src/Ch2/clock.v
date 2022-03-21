01 module clock_div_new #(parameter cfactor=2,parameter cnt_len=8)(
02   input clk_in,
03   input rst,
04   output clk_out
05 );
06 reg clk_loc; 
07 reg [cnt_len-1:0] cnt;//allowed maximum clock division factor is 256
08 assign clk_out = (cfactor==1)? clk_in : clk_loc;
09 always@(posedge clk_in)
10   if(rst==1) begin
11     cnt <= 'd0;
12     clk_loc = 1;
13   end else begin
14     cnt <= cnt + 1'b1;
15     if(cnt==cfactor/2-1) 
16       clk_loc = 0;
17     else if(cnt==cfactor-1) begin 
18       cnt <= 'd0;
19       clk_loc = 1;
20     end
21   end
22 endmodule