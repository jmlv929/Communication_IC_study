
////////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------------
//
// ABSTRACT:  Unsigned multiplier
//
//
// MODIFIED:
//
//
//------------------------------------------------------------------------------

module DW_mult_uns( a, b, product );


// parameters
parameter a_width = 8;
parameter b_width = 8;


//-----------------------------------------------------------------------------
// ports
input [a_width-1 : 0]	a;
input [b_width-1 : 0]	b;
output [a_width+b_width-1:0]	product;

  assign product = a * b;

endmodule
