01 // Gmsk BS synchronize core verilog
02 // Author: Mr Li Qinghua
03 // DDC_GMSK Rev.0.1 2009-02-24
04 module reset_sync(
05 	input clk,
06 	input  rst_x_in, //
07 	output reg rst_x_out //
08 );
09 reg rst_x1,rst_x2,rst_x3;
10 wire rst_x_pulse;
11 
12 always @(posedge clk)begin
13   rst_x1<=rst_x_in;
14   rst_x2<=rst_x1;
15   rst_x3<=rst_x2;
16 end
17 
18 assign rst_x_pulse=rst_x2|rst_x3;
19 always @(posedge clk)
20   rst_x_out<=rst_x_pulse;
21 
22 endmodule
23 