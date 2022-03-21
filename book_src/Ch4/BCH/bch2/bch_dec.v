//***********************************************************************************
// Decoder top for DEC BCH code
// Version 1.0
// Modified 2013.05.12
//***********************************************************************************

module bch_dec #(parameter P_D_WIDTH = 32) 
(
input  wire[P_D_WIDTH-1:0]                     d_i,
input  wire[fn_ecc_synd_width(P_D_WIDTH)-1:0]  ecc_i, 
output wire[P_D_WIDTH-1:0]                     msk_o, 
output wire                                    err_det_o
);
					 
//**********************************************************************					 

`include "bch_func.inc"

//**********************************************************************					 
				 
wire[fn_ecc_synd_width(P_D_WIDTH)-1:0]           syndromes;

//**********************************************************************

enc_synd_calc #(
.P_D_WIDTH   (P_D_WIDTH),
.P_SYND_GEN  (1)           // 0 -> parity generator, 1-> syndrome generator 
)U_enc_synd_calc(
  .d_i ({d_i,ecc_i}),
  .p_o (syndromes)
);

//***************************************************************************
//                      Error pattern decoder
//***************************************************************************							
							
err_detect_rom #(
	.P_D_WIDTH   (P_D_WIDTH)
)  U_err_detect_rom(
  .syndromes_i (syndromes),
  .msk_o 	   (msk_o)
);

assign err_det_o = |syndromes;

endmodule // bch_dec
