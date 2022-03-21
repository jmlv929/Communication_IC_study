
//--------------------------------------------------------------------------------------------------
//
// Title       : DW02_divide.v
// Design      : DW02_divide


//
//-------------------------------------------------------------------------------------------------
// Description :  DW02_divide is a combinational integer divider with quotient as output. 
// This component divides the dividend a by the divisor b to produce the quotient.
//
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps

module DW02_divide ( A, B, TC, QUOTIENT, DIVIDE_BY_0 )/* synthesis syn_builtin_du = "weak" */;
parameter A_width = 14;
parameter B_width = 9;
parameter TC_mode = 1;

input [A_width - 1 : 0 ]   A;	
input                      TC;
input [B_width - 1: 0 ]    B;

output [A_width - 1 : 0 ]  QUOTIENT ;  
output                     DIVIDE_BY_0;

wire  [A_width - 1 : 0 ]   A;
wire [B_width - 1: 0 ]     B;
reg [A_width - 1 : 0 ]     QUOTIENT ;

wire  [A_width - 1 : 0 ]   param1;
wire [B_width - 1: 0 ]     param2;
wire [A_width - 1 : 0 ]    quotient;
wire [A_width - 1 : 0 ]    quotient_2s;
wire [A_width - 1 : 0 ]    temp;

//Output assignment
assign DIVIDE_BY_0 = ~|B;

//Internal signal assignment
assign param1 = ( TC & TC_mode )? ( A[A_width -1] ? (~A + 1'b1) : A ) : A; 
assign param2 = ( TC & TC_mode ) ? ( B[B_width -1] ? (~B + 1'b1) : B ) : B; 

`ifdef _synplify_asic_
     assign quotient = param1/param2;
`else 
	assign quotient =  div ( param1, param2 ); 	  

/* Function to get the quotient. Shift/subtract non-restoring algorithm is implemented*/
function [ A_width - 1 : 0 ] div;
input [A_width - 1 : 0 ] a;
input [B_width - 1: 0 ] b;

reg [B_width : 0 ] sum;//width = B_width + 1
reg [A_width - 1 : 0 ] dividend;
reg [B_width : 0 ] temp_b;
integer i;

begin		
	sum = {B_width + 1{1'b0}};
	dividend = a;
	sum[0] = a[A_width - 1]; //MSB
	dividend = dividend << 1'b1;	 	  
	temp_b = ~b + 1'b1;
   	sum = sum + temp_b;
	dividend[0] = ~sum[B_width];
	// synthesis loop_limit 2000  
	for ( i = 0; i < A_width - 1'b1; i = i + 1'b1 )
		begin
			if ( sum[B_width] )// 1 = -ve, 0 = +ve
				begin
					temp_b = b;
				end
			else
				begin
				    temp_b = ~b + 1'b1;
				end
            {sum,dividend} = {sum,dividend} << 1'b1;
            sum = sum + temp_b;
			dividend[0] = ~sum[B_width];
		end
	
	div = dividend ;	
end

endfunction	

`endif 

assign quotient_2s = ~quotient + 1'b1;
assign temp = (A[A_width -1] ^ B[B_width - 1]) ?
                                {1'b1,quotient_2s} : {1'b0,quotient};
							
//Output assignment								
always @( A or B or TC or temp or quotient )
	begin
		if ( B )
		begin
			case ( TC & TC_mode )
				1'b1 : if ( (B == { B_width {1'b1}}) && ( A == {1'b1,{A_width - 1 {1'b0}}} ) ) //-A(max)/-1 = +A(max)
					      QUOTIENT = {1'b0, {(A_width - 1) {1'b1}}};
					   else
						  QUOTIENT = temp;  
					      
				1'b0 : 	QUOTIENT = quotient;		
			endcase				
		 
		end	
		else
			begin 
				/* In the SIGNED case, if A is +ve, the max. +ve value is given as the Quotient.
					                   if A is -ve, the max. -ve value is given as the Quotient.
				   In the UNSIGNED case, a binary ALL 1s is given as the Quotient
					
					Max and Min values
					For a signed BYTE ( MSB:sign, 7-bits:magnitude )
						Smallest +ve:0000 0000
						largest +ve :0111 1111 = 127
						largest -ve :1111 1111 = -1
						smallest -ve:1000 0000 = -128
					   */	   
				case ( TC & TC_mode )
					1'b1 : QUOTIENT = A[A_width - 1] ?  {1'b1,{(A_width - 1){1'b0}}} : {1'b0, { (A_width - 1) {1'b1}}};
					1'b0 : QUOTIENT = {A_width{1'b1}}; 					  
				endcase
			end
	end					 

endmodule
