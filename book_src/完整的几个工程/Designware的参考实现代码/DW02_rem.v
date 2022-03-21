

//--------------------------------------------------------------------------------------------------
//
// Title       : DW02_rem.v
// Design      : DW02_rem


//
//-------------------------------------------------------------------------------------------------
// Description :  DW02_rem is a combinational integer divider with REMAINDER output. This component 
// divides the dividend, a, by the divisor, b, to produce the quotient and REMAINDER. The control 
// signal, TC, determines whether the data of the inputs a and b and the outputs quotient and 
// REMAINDER are interpreted as unsigned ( TC is LOW) or signed ( TC is HIGH ) numbers, when the 
// parameter TC_mode is equal to 1.
//
// The REMAINDER output is defined as follows:
// REMAINDER = A - int (A/B) x B
//
//-------------------------------------------------------------------------------------------------

module DW02_rem (A, B, TC, REMAINDER)/* synthesis syn_builtin_du = "weak" */;
  parameter A_width = 14;
  parameter B_width = 9;
  parameter TC_mode = 1;

input [A_width - 1 : 0 ]   A;	
input                      TC;
input [B_width - 1: 0 ]    B;

output [B_width - 1: 0 ]   REMAINDER ;

wire  [A_width - 1 : 0 ]   A;
wire [B_width - 1: 0 ]     B;
wire [B_width - 1: 0 ]     mod;
reg [B_width - 1: 0 ]      REMAINDER;
wire  [A_width - 1 : 0 ]   param1;
wire [B_width - 1: 0 ]     param2;
wire [A_width - 1 : 0 ]    quot;
wire [A_width - 1 : 0 ]    quot_2s;
wire [A_width - 1 : 0 ]    temp ;

//Internal signal assignment
assign param1 = ( TC & TC_mode )? ( A[A_width - 1] ? (~A + 1'b1) : A ) : A; 
assign param2 = ( TC & TC_mode ) ? ( B[B_width - 1] ? (~B + 1'b1) : B ) : B;

`ifdef _synplify_asic_
     assign mod = param1 % param2; 			
`else 
	assign mod =  rem ( param1, param2 ); 

	/* Function to get the quotient. Shift/subtract non-restoring algorithm is implemented*/
function [ B_width - 1 : 0 ] rem;
input [A_width - 1 : 0 ] a;
input [B_width - 1: 0 ] b;

reg [B_width : 0 ] sum;//width = B_width + 1
reg [A_width - 1 : 0 ] dividend;
reg [B_width : 0 ] rem_adjust;
reg [B_width : 0 ] temp_b;
integer i;

begin		
	sum = {B_width{1'b0}};
	dividend = a;
	sum[0] = a[A_width - 1]; //MSB
	dividend = dividend << 1'b1;	 
	temp_b = ~b + 1'b1;
   	sum = sum + temp_b;
	dividend[0] = ~sum[B_width];
	// synthesis loop_limit 2000  
	for ( i = 0 ; i <  A_width - 1'b1 ; i = i + 1'b1 )
		begin
			if ( sum[B_width] )// 1 = -ve, 0 = +ve
				begin
					temp_b = b;
				end
			else
				begin
				    temp_b = ~b + 1'b1;
				end
		    sum = sum << 1'b1;
		    sum[0] = dividend[A_width - 1];
		    dividend = dividend << 1'b1;
		   	sum = sum + temp_b;
			dividend[0] = ~sum[B_width];
		end
	
	rem_adjust = sum[B_width] ? sum + b : sum;//If REMAINDER is -ve add divisor	
	rem = rem_adjust[B_width - 1: 0];
end

endfunction		

`endif 


//Output assignment								
always @( A or B or TC or mod )
	if ((TC == 1) && (TC_mode == 1) && (A[A_width-1] == 1) && (B != 0) && ( mod != 0 ))
	    REMAINDER = ~mod + 1'b1;  //The sign of the result is the sign of A input 
	else if (B == 0)
	    REMAINDER = 0;
	else
	    REMAINDER = mod;

endmodule
