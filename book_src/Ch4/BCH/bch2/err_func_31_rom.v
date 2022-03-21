
//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// GF(5) Error pattern ROM
//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

module err_func_31_rom
(
	input clk, 
	input en,
	input[9:0] syndromes, 
  output reg[30:0] errs
);
`include "err_func_31.inc"

always @(posedge clk)
	if(en)
		errs<=fn_err_pat_dcd_gf5_rom(syndromes);

endmodule
