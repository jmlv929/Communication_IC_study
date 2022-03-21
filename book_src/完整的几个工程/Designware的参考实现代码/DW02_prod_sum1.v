
//-----------------------------------------------------------------------------
//
// ABSTRACT:  Product Sum (1 product with an added vector)
//
//
// MODIFIED:
//
//
//------------------------------------------------------------------------------

module DW02_prod_sum1( A, B, C, TC, SUM );


// parameters
parameter A_width = 8;
parameter B_width = 8;
parameter SUM_width = 16;

localparam int_mac_width = (SUM_width < (A_width+B_width+2))? A_width+B_width+2 : SUM_width;

//-----------------------------------------------------------------------------
// ports
input [A_width-1 : 0]	A;
input [B_width-1 : 0]	B;
input [SUM_width-1 : 0]	C;
input			TC;
output [SUM_width-1:0]	SUM;

wire signed [A_width : 0]		a_int;
wire signed [B_width : 0]		b_int;
wire signed [SUM_width : 0]		c_int;
wire signed [int_mac_width+1 : 0]	prod_int;

  assign a_int = (TC == 1'b0)?
			$signed( {1'b0, A} ) :
			$signed( {A[A_width-1], A} ) ;


  assign b_int = (TC == 1'b0)?
			$signed( {1'b0, B} ) :
			$signed( {B[B_width-1], B} ) ;


  assign c_int = (TC == 1'b0)?
			$signed( {1'b0, C} ) :
			$signed( {C[SUM_width-1], C} ) ;

  assign prod_int = a_int * b_int + c_int;

  assign SUM = prod_int[SUM_width-1 : 0];

endmodule
