
//
// Description :  DW02_sin is a combinational cosine. This component takes the input angle A and
// calculates sin(pi x A). The input angle A is treated as a binary fixed point number which is
// converted to radians when multiplied by pi.
//
//-------------------------------------------------------------------------------------------------

module DW02_sin ( 
	A, //Angle in Binary 
	SIN //Sine value of A
	)/* synthesis syn_builtin_du = "weak" */;

parameter A_width = 16;
parameter sin_width = 32;

//Input/output declaration
input [ A_width - 1 : 0 ] A;
output [ sin_width - 1 : 0 ] SIN;

//Internal signal declaration
wire [sin_width - 1:0]    SIN;
wire [1:0]                msb_2s;
reg  [A_width - 1 : 0]    new_A;

assign msb_2s = A[A_width-1:A_width-2] - 1;

always @ ( A or msb_2s )
	new_A = {msb_2s, A[A_width-3:0]};//Sine of pi x A


DW02_cos #(A_width, sin_width) rtl( 
	          .A(new_A),   
	          .COS(SIN)  
			 );	  
			 
endmodule			 
