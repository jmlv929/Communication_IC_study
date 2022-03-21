

//--------------------------------------------------------------------------------------------------
//
// Title       : DW_vhd_mod
// Design      : DW_vhd_mod

// 
//
//-------------------------------------------------------------------------------------------------
// Description : DW_vhd_mod performs a combinational modulus as defined in IEEE Standard 1076-1993
// VHDL Language Reference Manual (LRM). The control signal TC determines whether the input and output 
// data is interpreted as unsigned ( TC LOW) or signed ( TC HIGH) numbers.
//
// The sign of the result is the sign of the B input. The modulus definition uses integer division.
//
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps

module DW_vhd_mod ( A, B, TC, MODULUS )/* synthesis syn_builtin_du = "weak" */;
parameter A_width = 14;
parameter B_width = 9;
parameter TC_mode = 1;

input [A_width - 1 : 0 ]   A;//Dividend	                 
input                      TC;//Two's Complement Control     
input [B_width - 1: 0 ]    B;//Divisor                      
							                                 
output [B_width - 1 : 0 ]  MODULUS;//Modulus output   

wire [A_width - 1 : 0 ]    A;
wire [B_width - 1: 0 ]     B;
reg  [B_width - 1 : 0 ]    MODULUS;

wire [A_width - 1 : 0 ]    param1;
wire [B_width - 1: 0 ]     param2;
wire [B_width - 1 : 0 ]    modulus;
wire [A_width - 1 : 0 ]    temp;

//Internal signal assignment
assign param1 = ( TC & TC_mode )? ( A[A_width -1] ? (~A + 1'b1) : A ) : A; 
assign param2 = ( TC & TC_mode ) ? ( B[B_width -1] ? (~B + 1'b1) : B ) : B;    

`ifdef _synplify_asic_
     assign modulus = param1 % param2; 			
`else
	assign modulus =  rem ( param1, param2 ); 

/* Function to get the remainder. Shift/subtract non-restoring divider is implemented */
function [ B_width - 1 : 0 ] rem;
input [A_width - 1 : 0 ] a;
input [B_width - 1: 0 ] b;

reg [ B_width : 0 ] sum;//width = B_width + 1
reg [ B_width : 0 ] rem_adjust;
reg [A_width - 1 : 0 ] dividend;
reg [ B_width : 0 ] temp_b;
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
	
	rem_adjust = sum[B_width] ? sum + b : sum;//If remainder is -ve add divisor	
	rem = rem_adjust[B_width - 1: 0];
end

endfunction	

`endif 

//Output assignment								
always @( A or B or TC or modulus )
	if (B == 0)
	    MODULUS = 0;   
	else
		begin
			if ( TC_mode )
				begin
					case ({A[A_width-1],B[B_width-1]})
						2'b00: MODULUS = modulus; 
						2'b01: if ( TC && modulus != 0)
							MODULUS = B + modulus;				 
						else				 
							MODULUS = modulus;
							
						2'b10: if ( TC && modulus != 0) 
							MODULUS = B - modulus; 
						else 
							MODULUS = modulus;	
							
						2'b11: if ( TC && modulus != 0)	
							MODULUS = ~modulus + 1'b1; 
						else 
							MODULUS = modulus;				
					endcase	
				end
			else 
				MODULUS = modulus;	
		end		
				
endmodule
