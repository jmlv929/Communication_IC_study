

//--------------------------------------------------------------------------------------------------
//
// Title       : DW03_cntr_gray
// Design      : parameterized Gray counter

// 			 
// Date		   : 06-10-03				   
//-------------------------------------------------------------------------------------------------
//
// Description : A parameterized gray counter is implemented.
//
//				 Gray encoded output (cout)
//               Decoded output ( decode_out )
//				 Async reset 
//				 Count enable	(cen)
//
//-------------------------------------------------------------------------------------------------

module DW03_cntr_gray (  clk, reset, cen, count, decode_out )/* synthesis syn_builtin_du = "weak" */;
	parameter width = 8; //parameter for specifying the register width
	
	//Input/output declaration
	input							     cen;//active high
	input							     clk;//clock input
	input							     reset; //active low
	
	output	[ width - 1 : 0 ] 		     count;//gray code counter output
	output [((1'b1 << width) - 1 ) : 0]  decode_out;//data input to be loaded to reg

	//internal register decleration
	reg	[ width - 1 : 0 ] 		         count;
	reg	[ width - 1 : 0 ] 		         bin;
	reg [ width - 1 : 0 ]		         tog_bit; 
	integer	i,j,k;
	
	//Register the output gray count
	always	@ ( posedge  clk  or  negedge  reset )
		if( !reset ) 		 
			count <= 0;
		else
			count <= cen ? count ^ tog_bit : count; 

	//Generation of toggle bit		
	always @ ( count )
		begin
			tog_bit = 0;
			// synthesis loop_limit 2000  
			for (i = 0; i < width; i = i + 1) 
				begin 
					// synthesis loop_limit 2000  
					for (j = i; j < width; j = j + 1) 
						tog_bit[i] = tog_bit[i] ^ count[j];
						bin[i] = tog_bit[i];	
						tog_bit[i] = !tog_bit[i];  
						// synthesis loop_limit 2000  
						for (k = 0; k < i; k = k + 1) 
							tog_bit[i] = tog_bit[i] && !tog_bit[k];
				end //i loop  
				if ( width == 1 )
					tog_bit = 1;			
				else
					begin
						if (tog_bit[width-2:0]==0)
							tog_bit[width-1] = 1; 
					end
					
		end		

	assign decode_out =  1'b1 << bin;
	
    endmodule		
