         

//--------------------------------------------------------------------------------------------------
//
// Title       : DW01_csa
// Design      : Carry Save Adder

// Company     : 
//-------------------------------------------------------------------------------------------------
//
// Description : DW01_csa adds three operands a, b, and c with a carry-in (ci) to produce the outputs 
//               sum and carry with a carry-out (co.)
//
//-------------------------------------------------------------------------------------------------

module DW01_csa ( a, b, c, ci, carry, sum, co )/* synthesis syn_builtin_du = "weak" */;
	parameter	width	= 14;//parameter specifying number of bits 
	//Input/output declaration
	input [width - 1 : 0]	a; //input line 1
	input [width - 1 : 0]	b; //input line 2
	input [width - 1 : 0]	c; //input line 3
	input					ci;//input carry in
	
	output	[width - 1 : 0]	sum;//output sum
	output	[width - 1 : 0]	carry;//output carry
	output					co;//output carry_out 
	//Register declaration
	reg		[width - 1 : 0]	sum;//output sum
	reg		[width - 1 : 0]	carry;//output carry
	reg 					co;
	integer					i;
	
	//Carry Save adder with carry_in
	//For width > 1, carry[0] = c[0]
	always@( a or b or c or ci )
	begin
		{carry[0], sum[0]} = csa(a[0], b[0], ci);
		// synthesis loop_limit 2000  
		for( i = 1 ; i < width ; i = i + 1 )
			{carry[i], sum[i]} = csa(a[i], b[i], c[i]);

		co = carry[ width - 1 ];
		carry = carry << 1 ;
		carry[0] = c[0] ;
	end	 					   

	//Carry Save adder with carry_in
	//For width > 1, carry[0] = cin. Functionally both are same
//	always@( a or b or c or ci )
//		if( width == 1 )
//		begin
//			{co, sum} = csa( a, b, c );
//			carry = ci;
//		end
//		else
//		begin
//			for( i = 0 ; i < width ; i = i + 1 )
//				{ carry[i], sum[i] } =	csa( a[i], b[i], c[i]);
//			
//			co = carry[ width - 1 ];
//			carry = carry << 1;
//			carry[0] = ci;
//		end
	
	
	//single bit carry save adder function 
	function [1:0] csa; 
		input	a, b, c;
		begin	   
			csa [1:0] = a + b + c;
		end
	endfunction
	
endmodule
