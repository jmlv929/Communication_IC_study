				 			 
//--------------------------------------------------------------------------------------------------
//
// Title       : DW_div_rem.v
// Design      : DW_div_rem

//
//-------------------------------------------------------------------------------------------------
// Description :  DW_div_rem is a combinational integer divider	with both quotient and remainder 
// outputs. This component divides the dividend, a, by the divisor, b, to produce the quotient 
// and remainder. The control signal, tc, determines whether the data of the inputs a and b and 
// the outputs quotient and remainder are interpreted as unsigned ( tc is LOW) or signed ( tc 
// is HIGH ) numbers, when the parameter tc_mode is equal to 1.
//
// The quotient and remainder outputs are defined as follows:
// quotient = int (a/b)
// remainder = a | int (a/b) x b
//
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps

module DW_div_rem ( a ,b , tc, quotient, divide_by_0, remainder )/* synthesis syn_builtin_du = "weak" */;
parameter a_width = 14;
parameter b_width = 9;
parameter tc_mode = 1;

input [a_width - 1 : 0 ]   a;	
input                      tc;
input [b_width - 1: 0 ]    b;

output [a_width - 1 : 0 ]  quotient ;  
output                     divide_by_0;
output [b_width - 1: 0 ]   remainder ;

wire  [a_width - 1 : 0 ]   a;
wire [b_width - 1: 0 ]     b;
wire [b_width - 1: 0 ]     mod;
reg [a_width - 1 : 0 ]     quotient;
reg [b_width - 1: 0 ]      remainder;
wire  [a_width - 1 : 0 ]   param1;
wire [b_width - 1: 0 ]     param2;
wire [a_width - 1 : 0 ]    quot;
wire [a_width - 1 : 0 ]    quot_2s;
wire [a_width - 1 : 0 ]    temp ;

//Output assignment
assign divide_by_0 = ~|b;

//Internal signal assignment
assign param1 = ( tc & tc_mode )? ( a[a_width - 1] ? (~a + 1'b1) : a ) : a; 
assign param2 = ( tc & tc_mode ) ? ( b[b_width - 1] ? (~b + 1'b1) : b ) : b; 	

`ifdef _synplify_asic_
     assign quot = param1/param2;
     assign mod = param1 % param2; 			
`else
	assign {quot,mod} = div ( param1, param2 ); 

/* Function to get the quotient and remainder. Shift/subtract non-restoring algorithm is implemented*/
function [ a_width + b_width - 1 : 0 ] div;
input [a_width - 1 : 0 ] a;
input [b_width - 1: 0 ] b;

reg [b_width : 0 ] sum;//width = B_width + 1
reg [a_width - 1 : 0 ] dividend;
reg [b_width : 0 ] rem_adjust;
reg [b_width : 0 ] temp_b;
reg [b_width - 1: 0 ] rem;
integer i;

begin		
	sum = {b_width{1'b0}};
	dividend = a;
	sum[0] = a[a_width - 1]; //MSB
	dividend = dividend << 1'b1;	 
	temp_b = ~b + 1'b1;
   	sum = sum + temp_b;
	dividend[0] = ~sum[b_width];
	for ( i = 0 ; i <  a_width - 1'b1 ; i = i + 1'b1 )
		begin
			if ( sum[b_width] )// 1 = -ve, 0 = +ve
				begin
					temp_b = b;
				end
			else
				begin
				    temp_b = ~b + 1'b1;
				end
		    sum = sum << 1'b1;
		    sum[0] = dividend[a_width - 1];
		    dividend = dividend << 1'b1;
		   	sum = sum + temp_b;
			dividend[0] = ~sum[b_width];
		end
	
	rem_adjust = sum[b_width] ? sum + b : sum;//If remainder is -ve add divisor	
	rem = rem_adjust[b_width - 1: 0];
	div = {dividend, rem} ;
end

endfunction					 
`endif 
	
assign quot_2s =  ~quot	+ 1'b1;
assign temp = (a[a_width -1] ^ b[b_width - 1]) ?
                                {1'b1,quot_2s} : {1'b0,quot};
							
//Updating output quotient 
always @( a or b or tc or temp or quot )
	begin
		if ( b )
		begin
			case ( tc & tc_mode )
				1'b1 : if ( (b == { b_width {1'b1}}) && ( a == {1'b1,{a_width - 1{1'b0}}} ) ) //-a(max)/-1 = +a(max)
					      quotient = {1'b0, {(a_width - 1) {1'b1}}};
					   else
						  quotient = temp;  
					      
				1'b0 : quotient = quot;		
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
						
					But -A/0 is given as -128 as it is close to -infinity 	
					   */	   
				case ( tc & tc_mode )
					1'b1 : quotient = a[a_width - 1] ?  {1'b1,{(a_width - 1){1'b0}}} : {1'b0, { (a_width - 1) {1'b1}}};
					1'b0 : quotient = {a_width{1'b1}}; 					  
				endcase
			end
	end	

//Updating output remainder
always @( a or b or tc or mod )
	if ((tc == 1) && (tc_mode == 1) && (a[a_width-1] == 1) && (b != 0) && ( mod != 0 ))
	    remainder = ~mod + 1'b1;  //The sign of the result is the sign of A input (dividend) 
	else if (b == 0)
	    remainder = 0;
	else
	    remainder = mod;  

endmodule
