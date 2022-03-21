//***********************************************************************************
// encode parity for enc BCH code
// Version 1.0
// Modified 2013.05.12
//***********************************************************************************

module bch_enc_parity #(
  parameter P_D_WIDTH   = 16
) (
	input wire[P_D_WIDTH-1:0]                     d_i,
	output wire[fn_ecc_synd_width(P_D_WIDTH)-1:0] p_o
);

//**********************************************************************					 

`include "bch_func.inc"

//**********************************************************************					 

enc_synd_calc #(
  .P_D_WIDTH  (P_D_WIDTH),
  .P_SYND_GEN (0)
) U_enc_synd_calc(
  .d_i (d_i),
  .p_o (p_o)
);

endmodule 
