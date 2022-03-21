01 module cic_integrator #(parameter idw = 8 , odw = 9)(
02   input   clk,
03   input   reset_n,
04   input   signed [idw-1:0] data_in,
05   output  reg signed [odw-1:0] data_out );
06 always @(posedge clk)
07   if (!reset_n)
08     data_out <= 'h0;
09   else //ÀÛ¼Ó»ı·ÖÆ÷
10     data_out <= data_out + data_in;
11 endmodule
12