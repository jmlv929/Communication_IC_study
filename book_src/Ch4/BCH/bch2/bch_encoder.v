//***********************************************************************************
// encode parity for enc BCH code
// Version 1.0
// Modified 2013.05.12
//***********************************************************************************

module bch_encoder #(
  parameter P_D_WIDTH   = 21
) (
	input wire[P_D_WIDTH-1:0]                     data_org_in,
//	output wire[fn_ecc_synd_width(P_D_WIDTH)-1:0] data_ecc_out
	output wire[9:0] data_ecc_out
);

//**********************************************************************					 

`include "bch_func.inc"

//**********************************************************************					 
//wire [fn_ecc_synd_width(P_D_WIDTH)-1:0] p_o;
wire [9:0] p_o;
//enc_synd_calc #(
enc_synd_calc_enc #(
  .P_D_WIDTH  (P_D_WIDTH),
  .P_SYND_GEN (0)
) U_enc_synd_calc(
  .d_i (data_org_in),
  .p_o (p_o)
);

assign data_ecc_out=p_o;

endmodule 
