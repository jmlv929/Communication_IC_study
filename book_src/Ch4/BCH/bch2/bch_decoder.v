//***********************************************************************************
// Decoder top for DEC BCH code
// Version 1.0
// Modified 2013.05.12
//***********************************************************************************

`define ECC_31 1

                   
module bch_decoder #(parameter P_D_WIDTH = 21) 
(
input  clk,
input  en,
input  wire[P_D_WIDTH-1:0]                     d_i,
//input  wire[fn_ecc_synd_width(P_D_WIDTH)-1:0]  ecc_i, 
input  wire[9:0]  ecc_i, 
output wire[P_D_WIDTH-1:0]                     msk_o, 
output wire                                    err_det_o
);

//**********************************************************************					 
`include "bch_func.inc"
         
//**********************************************************************					 

//**********************************************************************					 
				 
//wire[fn_ecc_synd_width(P_D_WIDTH)-1:0]           syndromes;
wire[9:0]           syndromes;

//**********************************************************************

//enc_synd_calc #(
enc_synd_calc_dec #(
.P_D_WIDTH   (P_D_WIDTH),
.P_SYND_GEN  (1)           // 0 -> parity generator, 1-> syndrome generator 
)U_enc_synd_calc(
  .d_i ({d_i,ecc_i}),
  .p_o (syndromes)
);

//***************************************************************************
//                      Error pattern decoder
//***************************************************************************							
							
//err_detect_rom #(
//	.P_D_WIDTH   (P_D_WIDTH)
//)  U_err_detect_rom(
//  .syndromes_i (syndromes),
//  .msk_o 	   (msk_o)
//);



// Internal mask bus
//localparam LP_INT_MASK_BUS_WIDTH = fn_int_width(P_D_WIDTH);
localparam LP_INT_MASK_BUS_WIDTH = 31;
wire [LP_INT_MASK_BUS_WIDTH-1:0] msk_int;

    `ifdef ECC_31
    //if(LP_INT_MASK_BUS_WIDTH == 31) begin : enc_dcd_gf5
			err_func_31_rom U_err_func_31_rom(.clk(clk),.en(en),.syndromes(syndromes),.errs(msk_int));
    //end // enc_dcd_gf5
    `endif
    
    `ifdef ECC_63
    //if(LP_INT_MASK_BUS_WIDTH == 63) begin : enc_dcd_gf6
			err_func_63_rom U_err_func_63_rom(.clk(clk),.en(en),.syndromes(syndromes),.errs(msk_int));
    //end // enc_dcd_gf6
    `endif
    
    `ifdef ECC_127
    //if(LP_INT_MASK_BUS_WIDTH == 127) begin : enc_dcd_gf7
			err_func_127_rom U_err_func_127_rom(.clk(clk),.en(en),.syndromes(syndromes),.errs(msk_int));
    `endif // enc_dcd_gf7
    // Comment the following lines if you have a problems
    // with the synthisizer(due to the size of err_patt_dcd_fn_255.vh)
    `ifdef ECC_255
    //if(LP_INT_MASK_BUS_WIDTH == 255) begin : enc_dcd_gf8
			err_func_255_rom U_err_func_255_rom(.clk(clk),.en(en),.syndromes(syndromes),.errs(msk_int));
    `endif // enc_dcd_gf8



        //  assign msk_o = msk_int[P_D_WIDTH-1:0];
assign msk_o = msk_int[LP_INT_MASK_BUS_WIDTH-1:LP_INT_MASK_BUS_WIDTH-P_D_WIDTH];

assign err_det_o = |syndromes;

endmodule
		