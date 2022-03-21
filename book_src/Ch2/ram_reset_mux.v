01 module ram_reset_mux(
02   input  rst_n, clk, WEN,
03   input [7:0] Addr,
04   input [15:0] MEMIn,
05   output [15:0] MEMOut
06 );
07 reg [15:0] MEM [255:0];
08 reg [15:0] MEMOut_tmp;
09
10 always @(posedge clk)begin
11   if(WEN) 
12     MEM[Addr] <= MEMIn;
13   MEMOut_tmp <= MEM[Addr];
14 end
15
16 assign MEMOut = rst_n ? MEMOut_tmp : 0; // 0 is reset value
17 endmodule