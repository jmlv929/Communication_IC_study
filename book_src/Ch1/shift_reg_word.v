01 module shift_reg #(parameter taps=8,parameter width=16)(
02   input clk,
03   input rst_n,
04   input [width-1:0] d_in,
05   output[width-1:0] d_out
06 );
07  
08 generate 
09 genvar i;
10 for(i=0; i<width; i=i+1) begin:shift_reg
11   reg  [taps-1:0] r_reg;
12   wire [taps-1:0] r_next;
13   always@(posedge clk, negedge rst_n)
14     if(!rst_n)
15       r_reg <= 0;
16     else
17       r_reg <= r_next;
18    
19   assign r_next = {d_in[i], r_reg[taps-1:1]};
20   assign d_out[i] = r_reg[0];
21 end
22 endgenerate
23 
24 endmodule