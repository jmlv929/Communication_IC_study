

//--------------------------------------------------------------------------------------------------
//
// Title       : DW01_cmp2
// Design      : 2-function comparator

// Company     : 
//-------------------------------------------------------------------------------------------------
//
// Description : DW01_cmp2 is a two-input comparator. DW01_cmp2	compares two signed or 
// unsigned numbers A and B and produces two output conditions LT_LE and GE_GT as
// results.
//
//-------------------------------------------------------------------------------------------------

module DW01_cmp2 (A, B, LEQ, TC, LT_LE, GE_GT)/* synthesis syn_builtin_du = "weak" */;

parameter width = 32;

input [width - 1 : 0] A;
input [width - 1 : 0] B;
input                 TC;
input                 LEQ;
output                LT_LE;
output                GE_GT;

//Internal data type declaration
reg  [width - 1:0]     pa;
reg  [width - 1:0]     pb;

always @( A or B or TC )
	if ( TC )
	begin
			pa = {~A[width - 1],A[width - 2 : 0]};
			pb = {~B[width - 1],B[width - 2 : 0]};
		end
	else
		begin 
			pa = A;
			pb = B;
		end
		
wire LT = pa < pb;
wire EQ = A == B;
assign LT_LE = LEQ ? LT | EQ : LT; 
assign GE_GT = ~LT_LE;

endmodule
