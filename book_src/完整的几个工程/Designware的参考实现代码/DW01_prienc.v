
//--------------------------------------------------------------------------------------------------
//
// Title       : DW01_prienc
// Design      : DW01_prienc
 
// Company     : 
//-------------------------------------------------------------------------------------------------
//
// Description : DW01_prienc encodes the input port A to a binary value on output port INDEX. The
// encoded value of A is determined by the bit position of the most significant '1' bit. All bits
// on A lower than the most significant '1' bit are "don't care".
//
//-------------------------------------------------------------------------------------------------

module DW01_prienc ( A, INDEX )/* synthesis syn_builtin_du = "weak" */;
	parameter	A_width = 8;
	parameter	INDEX_width	= 4;

	//Input/output declaration
	input	[A_width : 1]		    A;
	output	[INDEX_width - 1 : 0]	INDEX;
	
	//Internal decleration
	integer i;
	reg	[INDEX_width - 1 : 0] position;
	
	always@(A)
	begin			   
		position = 0;
		// synthesis loop_limit 2000  
		for(i = 1;i <= A_width; i = i + 1)
		begin
			if( A[i] )
			begin
				position = i;
			end
		end	
	end	 
	
assign INDEX = position ;	

endmodule
