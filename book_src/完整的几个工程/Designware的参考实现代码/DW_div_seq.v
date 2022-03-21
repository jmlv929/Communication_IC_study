





//--------------------------------------------------------------------------------------------------
//
// Title       : DW_div_seq
// Design      : DW_div

// 
//
//-------------------------------------------------------------------------------------------------
// Description : DW_div_seq is a sequential divider designed for low area,area-time trade-off, or 
// high frequency (small cycle time) applications. DW_div_seq is an integer divider with both
// quotient and remainder outputs. 
// Fixes			 : 1. Fixes included in DW_div 
//							 2. complete signal gated by start signal (otherwise extra for one clock along with	
//									next start)	 --Nithin
//-------------------------------------------------------------------------------------------------
module DW_div_seq (
	clk,           //Clock
	rst_n, 		   //Reset, active low
	hold, 		   //Hold current operation (=1)
	start, 		   //A new operation is started by setting start=1 for one clock cycle.
	a, 			   //Dividend
	b, 			   //Divisor
	complete, 	   //Operation completed (=1)
	divide_by_0,   //Indicates if b equals 0
	quotient, 	   //Quotient
	remainder	   //Remainder
	)/* synthesis syn_builtin_du = "weak" */;

	parameter a_width = 8;
	parameter b_width = 8;
	parameter tc_mode = 0;
	parameter num_cyc = 3;
	parameter rst_mode = 0;
	parameter input_mode = 1;
	parameter output_mode = 1;
	parameter early_start = 0;
	//Internal parameter
	parameter actual_num_cycles = num_cyc - ( 1 - output_mode ) - ( 1 - input_mode ) - early_start;
	
	//Input/output declaration
	input 				   	clk;    
	input 					rst_n;  
	input 					hold;   
	input 					start;  
	input [a_width-1 : 0] 	a; 
	input [b_width-1 : 0] 	b; 	 
	
	output 					complete;    
	output 					divide_by_0; 
	output [a_width-1 : 0]  quotient;
	output [b_width-1 : 0]  remainder;
	
	//Internal register declaration
	wire 				  				   div_0;            
	wire [a_width-1 : 0]  				   q;                
	wire [b_width-1 : 0]  				   rem;              
	wire [a_width-1 : 0]  				   a_in;             
	wire [b_width-1 : 0]  				   b_in;             
	reg [a_width-1 : 0]   				   a_r;              
	reg [b_width-1 : 0]   				   b_r;              
	reg [(actual_num_cycles == 1 ? a_width : ((actual_num_cycles-input_mode)*a_width))-1:0]  q_r /* synthesis syn_pipeline=1 */;
	reg [(actual_num_cycles == 1 ? b_width : ((actual_num_cycles-input_mode)*b_width))-1:0]  rem_r /* synthesis syn_pipeline=1 */;
    integer                     		   i, j, k;         
	reg                         		   first_start_s;   
	reg                         		   first_start_a;   
	wire                        		   first_start;     
	reg [actual_num_cycles-1:0] 		   complete_rs;     
	reg [actual_num_cycles-1:0] 		   complete_ra;     
	wire [actual_num_cycles-1:0]		   complete_r;     
	reg [actual_num_cycles-input_mode-1:0] div_0_r;         
	reg [a_width-1 : 0]         		   quotient;        
	reg [b_width-1 : 0]         		   remainder;       
	reg 					    		   divide_by_0;     
	
	//Instantiate DW_div with rem_mode = 1
	DW_div #(a_width, b_width, tc_mode, 1) UUT(.a(a_in), .b(b_in), .quotient(q), .remainder(rem), .divide_by_0(div_0));
	
	//selecting the input for the divider
	assign a_in = input_mode ? a_r : a;
	assign b_in = input_mode ? b_r : b;

	//Implementation of input registers
	always @(posedge clk)
		if ( start )
			begin
				a_r <= a;
				b_r <= b;			
			end	
	
	//Implementation of complete -- sync registers
	always @(posedge clk)
		if ( !rst_n )
			begin
				first_start_s <= 0;
				complete_rs <= 0; 
			end	
		else
			begin			   	
				if ( start )
					first_start_s <= 1;
				
				if ( first_start_s )
					if ( start )
						complete_rs[0] <= 0;
					else if ( hold )
						complete_rs[0] <= complete_rs[0];
					else	
						complete_rs[0] <= 1;
				else
					complete_rs[0] <= 0;   
					
				for ( i=0; i < actual_num_cycles-1; i = i + 1 )
					case ({start,hold})
						2'b00: complete_rs[i+1] <= complete_rs[i];
						2'b01: complete_rs[i+1] <= complete_rs[i+1];
						2'b10: complete_rs[i+1] <= 0;
						2'b11: complete_rs[i+1] <= 0;
					endcase
			end
		
		//Async. registers	
		always @(posedge clk or negedge rst_n)
		if ( !rst_n )
			begin
				first_start_a <= 0;
				complete_ra <= 0; 
			end	
		else
			begin			   	
				if ( start )
					first_start_a <= 1;
				
				if ( first_start_a )
					if ( start )
						complete_ra[0] <= 0;
					else if ( hold )
						complete_ra[0] <= complete_ra[0];
					else	
						complete_ra[0] <= 1;
				else
					complete_ra[0] <= 0;   
					
				for ( i=0; i < actual_num_cycles-1; i = i + 1 )
					case ({start,hold})
						2'b00: complete_ra[i+1] <= complete_ra[i];
						2'b01: complete_ra[i+1] <= complete_ra[i+1];
						2'b10: complete_ra[i+1] <= 0;
						2'b11: complete_ra[i+1] <= 0;
					endcase
			end	
			
	 	assign first_start = rst_mode ? first_start_s : first_start_a; 
	 	assign complete_r = rst_mode ? complete_rs : complete_ra; 
			
			
	//Inserting pipeline registers for quotient and remainder		
	always @(posedge clk )
		begin 
			q_r[a_width-1:0] <= q;
			rem_r[b_width-1 : 0] <= rem; 
			div_0_r[0] <= div_0;
			for ( i=0; i < actual_num_cycles-1-input_mode; i = i + 1 )
				begin					
					for ( j=0; j < a_width; j = j + 1 )
						q_r[(a_width*(i+1))+j] <= q_r[(a_width*i)+j];
					for ( k = 0; k < b_width; k = k + 1 )
						rem_r[(b_width*(i+1))+k] <= rem_r[(b_width*i)+k]; 
						
					if ( hold )
						div_0_r[i+1] <= div_0_r[i+1];
					else							
						div_0_r[i+1] <= div_0_r[i]; 
				end	
		end
		
	//Updating the output
	always	@( q or q_r )
		if (input_mode == 1 && actual_num_cycles == 1)
			quotient = q;
		else
			for ( j=0; j < a_width; j = j + 1 )
				quotient[j] = q_r[(actual_num_cycles-1-input_mode)*a_width+j];
				
	always	@( rem or rem_r )
		if (input_mode == 1 && actual_num_cycles == 1)
			remainder = rem;
		else
			for ( j=0;j < b_width; j = j + 1 )
				remainder[j] = rem_r[(actual_num_cycles-1-input_mode)*b_width+j];
				
	always @ ( div_0_r or div_0 )			
		if (input_mode == 1 && actual_num_cycles == 1)
			divide_by_0 = div_0;
		else  
			divide_by_0 = div_0_r[actual_num_cycles-1-input_mode];
	
	assign complete = complete_r[actual_num_cycles-1] & ~start;
	
endmodule
