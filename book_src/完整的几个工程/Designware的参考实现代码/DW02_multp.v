

//-----------------------------------------------------------------------------
//
// ABSTRACT:  Multiplier, parital products
//
//
// MODIFIED:
//
//
//------------------------------------------------------------------------------

module DW02_multp( a, b, tc, out0, out1 );


// parameters
parameter a_width = 8;
parameter b_width = 8;
parameter out_width = 18;
parameter verif_en = 1;		// verif_en ignored by synthesis

localparam upperhalf = out_width/2;
localparam lowerhalf = out_width - (out_width/2);


//-----------------------------------------------------------------------------
// ports
input [a_width-1 : 0]	a;
input [b_width-1 : 0]	b;
input			tc;
output [out_width-1:0]	out0, out1;

wire signed [a_width : 0]	a_int;
wire signed [b_width : 0]	b_int;
wire signed [out_width : 0]	prod_int;

  assign a_int = (tc == 1'b0)?
			$signed( {1'b0, a} ) :
			$signed( {a[a_width-1], a} ) ;

  assign b_int = (tc == 1'b0)?
			$signed( {1'b0, b} ) :
			$signed( {b[b_width-1], b} ) ;

  assign prod_int = a_int * b_int;

  assign out0 = { { upperhalf {1'b0} }, prod_int[lowerhalf-1 : 0] };
  assign out1 = { prod_int[out_width-1 : lowerhalf], { lowerhalf {1'b0} } };

endmodule
