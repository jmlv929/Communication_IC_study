
/*########################################################################################*/
//This module checks for saturation 
	
module sat (sat_carry, sat_sum, out_10, out_01, out_00, out_11, carry, a, b, sum, sat, tc, addsub)/* synthesis syn_builtin_du = "weak" */;
	
	parameter width	= 4;	
	
	//Input/output declaration
	input  					carry;     
	input  					a;         
	input  					b;	      
	input  [width - 1 : 0 ] sum;
	input  					sat;     
	input  					tc;      
	input  					addsub;  
	
	output 					sat_carry;    
	output 					out_10;       
	output 					out_01;       
	output 					out_00;       
	output 					out_11;       
	output [width - 1 : 0 ] sat_sum;
	
	//Internal signal declaration
	reg	 				 t_co;	      
	reg	 				 sat_carry;   
	wire 				 out_10;      
	wire 				 out_01;      
	reg [width - 1 : 0 ] sat_sum;
	
	assign out_10 = (sat & addsub & tc & a & ~b & ~sum[width-1]) | (sat & ~addsub & tc & a & b & ~sum[width -1]);
	assign out_01 = (sat & addsub & tc & ~a & b & sum[width-1]) | ( sat & ~addsub & tc & ~a & ~b & sum[width -1]);
	assign out_00 =	sat & addsub & ~tc & carry;
	assign out_11 =	sat & ~addsub & ~tc & carry;
	
	//Input Sum and carry are changed based on inputs tc and sat
	always@( sat or sum or carry or addsub or tc or a or b or carry )
	begin						
		t_co = carry;
		if(tc)
			t_co = a ^ b ? ~carry : carry; 

		//If sat is enabled, check for it 
		sat_sum = sum; 
		sat_carry = sat & !tc & carry ? 1'b0 : t_co;
		if(sat)	
			begin
				if ( addsub )
					begin
						if ( tc )
							begin
								if ( a & ~b & ~sum[width-1] )
									sat_sum = {1'b1,{width-1{1'b0}}};
								else if ( ~a & b & sum[width-1] ) 	
									sat_sum = {1'b0,{width-1{1'b1}}};
							end	// if ( tc )
						else
							begin
								if ( carry )
										sat_sum = 0;
							end	
					end	// if ( addsub )
				else
					begin					
						if ( tc )
							begin
								if ( ~a & ~b & sum[width -1] )
									sat_sum = {1'b0,{width-1{1'b1}}};
								else if ( a & b & ~sum[width -1] ) 	
									sat_sum = {1'b1,{width-1{1'b0}}};
							end	// if ( tc )
						else
							begin
								if ( carry )
										sat_sum = {width{1'b1}};
							end	 
					end	// else ( addsub )	
			end	//if (sat) 
	end	//always	
					
	 
endmodule
