

//--------------------------------------------------------------------------------------------------
//
// Title       : DW02_mult
// Design      : Multiplier

//-------------------------------------------------------------------------------------------------
//
// Description : DW02_mult is a multiplier that multiplies the operand A by B to produce the output,
// PRODUCT. The control signal TC determines whether the input and output data is interpreted as 
// unsigned (TC= 0) or signed (TC=1) numbers.
//
//-------------------------------------------------------------------------------------------------

module DW02_mult (A, B, TC, PRODUCT);

parameter A_width = 8;
parameter B_width = 16;	

/********* Internal parameter *************/
parameter width = A_width + B_width;
/*****************************************/

input [A_width - 1 : 0]              A;
input [B_width - 1 : 0]              B;
input                                TC;
output [width - 1 : 0] PRODUCT;

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

endmodule