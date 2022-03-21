
//
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------------
//
// ABSTRACT:  Duplex Multiplier
//
//	Parameters		Valid Values
//	==========		============
//	width			>= 4
//	p1_width		2 to (width-2)
//
//	Input Ports	Size	Description
//	===========	====	===========
//	a		width	Input data
//	b		width	Input data
//	tc		1 bit	Two's complement select (active high)
//	dplx		1 bit	Duplex mode select (active high)
//
//	Output Ports	Size	Description
//	===========	====	===========
//	product		2*width	Output data
//
// MODIFIED:
//      RPH      Aug 21, 2002       
//              Added parameter checking and cleaned up 
//----------------------------------------------------------------------


module DW_mult_dx (a, b, tc, dplx, product );

parameter width = 16;
parameter p1_width = 8;

localparam p2_width = width - p1_width;
localparam p2_width_p_1 = width - p1_width + 1;

input [width-1 : 0]    a;
input [width-1 : 0]    b;
input 		       tc;
input 		       dplx;
output [2*width-1 : 0] product;

wire signed [width : 0]       a_padded;
wire signed [width : 0]       b_padded;
wire signed [p2_width : 0]    a_2_padded;
wire signed [p2_width : 0]    b_2_padded;
wire signed [2*width+1 : 0]   smplx_prod;
wire signed [2*p2_width+1 : 0] dplx_subprod;

  assign a_padded = ((tc==1'b0) && (dplx==1'b0))?
			$signed({1'b0, a}) :
		    ((tc==1'b1) && (dplx==1'b0))?
			$signed({a[width-1],a}) :
		    ((tc==1'b0) && (dplx==1'b1))?
			$signed({{p2_width_p_1{1'b0}}, a[p1_width-1:0]}) :
			$signed({{p2_width_p_1{a[p1_width-1]}}, a[p1_width-1:0]}) ;

  assign b_padded = ((tc==1'b0) && (dplx==1'b0))?
			$signed({1'b0, b}) :
		    ((tc==1'b1) && (dplx==1'b0))?
			$signed({b[width-1],b}) :
		    ((tc==1'b0) && (dplx==1'b1))?
			$signed({{p2_width_p_1{1'b0}}, b[p1_width-1:0]}) :
			$signed({{p2_width_p_1{b[p1_width-1]}}, b[p1_width-1:0]}) ;

  assign a_2_padded = (tc==1'b0)?
			$signed({1'b0, a[width-1:p1_width]}) :
			$signed({a[width-1], a[width-1:p1_width]}) ;

  assign b_2_padded = (tc==1'b0)?
			$signed({1'b0, b[width-1:p1_width]}) :
			$signed({b[width-1], b[width-1:p1_width]}) ;

  assign smplx_prod = a_padded * b_padded;

  assign dplx_subprod = a_2_padded * b_2_padded;

  assign product = (dplx==1'b0)?
			smplx_prod[2*width-1 : 0] :
			{dplx_subprod[2*p2_width-1:0],smplx_prod[2*p1_width-1:0]} ;
  
endmodule
