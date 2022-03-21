

//--------------------------------------------------------------------------------------------------
//
// Title       : DW02_mac
// Design      : Multiplier-Accumulator

// Company     :  Software India Pvt. Ltd
//-------------------------------------------------------------------------------------------------
//
// Description : DW02_mac is a multiplier-accumulator. It multiplies a number A by
// a number B, and adds the result to a number C to produce a result	MAC.
// The input control signal TC determines whether the inputs and outputs are interpreted as
// unsigned (TC = 0) or signed (TC = 1) numbers.
//
//-------------------------------------------------------------------------------------------------

module DW02_mac ( A, B, C, TC, MAC )/* synthesis syn_builtin_du = "weak" */;	 
	
parameter A_width = 16;
parameter B_width = 16;

/********* Internal parameter *************/
parameter width = A_width + B_width;
/*****************************************/

//Input/output declaration
input                     TC;
input [A_width - 1 : 0]   A;
input [B_width - 1 : 0]   B;
input [width - 1 : 0]     C;

output [(A_width + B_width) - 1 : 0] MAC;

//Internal signal declaration
reg [width - 1 : 0] temp_a;
reg [width - 1 : 0] temp_b;
reg [width - 1 : 0] PRODUCT;

//Multplying the inputs -- using signed multiplier
always @( A or B or TC )
	begin
		temp_a =  TC ? {{width - A_width{A[A_width - 1]}},A} : {{width - A_width{1'b0}},A};
		temp_b =  TC ? {{width - B_width{B[B_width - 1]}},B} : {{width - B_width{1'b0}},B};
		PRODUCT = temp_a * temp_b;
	end	

assign MAC =  PRODUCT + C;

endmodule
