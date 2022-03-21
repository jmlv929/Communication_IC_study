module pll_circuit(
   input         clk,
   input         reset,
   input [7:0]   fmin,
   output [11:0] dmout);
   
   wire [11:0]   d1;
   wire [11:0]   d2;
   wire [7:0]    dout;
   wire [7:0]    Filter_in;
   
   fir U_filter(.clock(clk), .reset(reset), .data_in(d1), .data_out(dmout));

   nco U_NCO(.clk(clk), .reset(reset), .din(d2), .dout(dout));

   multiplier U_PD(.clk(clk), .reset(reset), .input1(fmin), .input2(dout), .mult_out(Filter_in));
   
   loop_filter U_loop_filter(.clk(clk), .reset(reset), .c(Filter_in), .d1(d1), .d2(d2));
endmodule
