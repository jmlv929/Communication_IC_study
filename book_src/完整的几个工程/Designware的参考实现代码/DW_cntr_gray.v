
//--------------------------------------------------------------------------------------------------
//
// Title       : DW_cntr_gray
// Design      : Gray code counter

// 			 
//-------------------------------------------------------------------------------------------------
//
// Description : DW_cntr_gray is a Gray code counter. The counter is width bits wide and has 2 pow(width)
//               states. The counter is clocked on the positive edge of the clk input. Because the count 
//               sequence is Gray code, only one counter bit changes value between successive states.
//
//-------------------------------------------------------------------------------------------------

module DW_cntr_gray (  clk, rst_n, init_n, load_n, data, cen, count  )/* synthesis syn_builtin_du = "weak" */;
	parameter width = 8; //parameter for specifying the register width
	
	//Input/output declaration
	input							     clk;//clock input
	input							     rst_n; //Reset, async. active low
	input							     init_n;//Reset, sync active low
	input							     load_n; //Enable data load to counter, active low
	input [width - 1 : 0]                data;//data input to be loaded to reg
	input							     cen;//Counter enable, active high
	
	output [width - 1 : 0 ] 		     count;//gray code counter output

	//internal register decleration
	reg	[ width - 1 : 0 ] 		         count;
	reg [ width - 1 : 0 ]		         tog_bit; 
	integer	i,j,k;
				
	//Register the output gray count
	always	@ ( posedge  clk  or  negedge  rst_n )
		if( !rst_n ) 		 
			count <= 0;
		else
			count <= init_n ? (load_n ? (cen ? count ^ tog_bit : count) : data) : 0; 

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
	
    endmodule		
