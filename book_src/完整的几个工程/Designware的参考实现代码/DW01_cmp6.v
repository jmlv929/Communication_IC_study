

//--------------------------------------------------------------------------------------------------
//
// Title       : DW01_cmp6
// Design      : DW01_cmp6


//-------------------------------------------------------------------------------------------------
//
// Description : DW01_cmp6 is a two-input comparator. DW01_cmp6 compares two signed or 
// unsigned numbers (A and B) and produces the following six output conditions:
// 1. Less-than (LT),
// 2. Greater-than (GT),
// 3. Equal (EQ),
// 4. Less-than-or-equal (LE),
// 5. Greater-than-or-equal (GE), and
// 6. Not equal (NE).
// The input signal TC determines whether the two input numbers are compared as unsigned
// (TC=0) or signed (TC=1).
//
//-------------------------------------------------------------------------------------------------
`timescale 1ns/10ps
module DW01_cmp6 (A, B, TC, LT, GT, EQ, LE, GE, NE)/* synthesis syn_builtin_du = "weak" */;

parameter width = 16;

input [width - 1 : 0] A;
input [width - 1 : 0] B;
input  				  TC;  
output 				  LT;  
output 				  GT;  
output 				  EQ;  
output 				  LE;  
output 				  GE;  
output 				  NE;  

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
assign GT = ~(LT || EQ);

assign LE = LT | EQ;

assign GE = GT | EQ;

assign NE = ~ EQ;

endmodule
