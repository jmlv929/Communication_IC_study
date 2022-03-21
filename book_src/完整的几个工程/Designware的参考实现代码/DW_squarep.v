////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
//                January 30, 2012
//
// VERSION:   Verilog FPGA Synthesis Model for DW_squarep
//
// DesignWare_version: b4a0b906
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------------
//
// ABSTRACT:  Square, parital products
//
//
// MODIFIED:
//
//
//------------------------------------------------------------------------------

module DW_squarep( a, tc, out0, out1 );


// parameters
parameter width = 8;
parameter verif_en = 1;		// verif_en ignored by synthesis


//-----------------------------------------------------------------------------
// ports
input [width-1 : 0]	a;
input			tc;
output [2*width-1:0]	out0, out1;

wire signed [width : 0]		a_int;
wire signed [width*2-1 : 0]	prod_int;

  assign a_int = (tc == 1'b0)?
			$signed( {1'b0, a} ) :
			$signed( {a[width-1], a} ) ;

  assign prod_int = a_int * a_int;

  assign out0 = { { width {1'b0} }, prod_int[width-1 : 0] };
  assign out1 = { prod_int[2*width-1 : width], { width {1'b0} } };

endmodule
