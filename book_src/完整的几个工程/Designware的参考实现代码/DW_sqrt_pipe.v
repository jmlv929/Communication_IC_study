
//--------------------------------------------------------------------------------------------------
//
// Title       : DW_sqrt_pipe
// Design      : squareroot

// Company     : 
// Fixes			 : 1. Extra parameter op_iso_mode in DW model causing func mismatch
//							 	  Changed the internal params to local and added this parameter -- Nithin
//-------------------------------------------------------------------------------------------------
//
// Description : DW_sqrt_pipe is a universal stallabe pipelined square root generator. 
// DW_sqrt_pipe computes the square root of operand a with a latency on num_stages - 1 clock cycles.
//
//-------------------------------------------------------------------------------------------------
`timescale 1ns / 10ps

module DW_sqrt_pipe (
	clk,           //Clock
	rst_n, 	       //Reset, active low
	en, 	       //Load enable
	a, 	       //Radicand
	root 	       //Square root
	)/* synthesis syn_builtin_du = "weak" */;
	
	parameter width = 8;
	parameter tc_mode = 0;
	parameter num_stages = 2;
	parameter stall_mode = 1;
	parameter rst_mode = 2'b01;
	parameter	op_iso_mode = 0;
	/***********************************/
	//Internally generated parameters
//	parameter	count   = width / 2;
	localparam	count     = width / 2;
	localparam   add     = width % 2;
	localparam   part    = count + add;
	/***********************************/

	//Input/output declaration
	input 			clk;    
	input 			rst_n;  
	input 			en;   
	input [width-1 : 0] 	a; 
	
	output [part-1 : 0]    root;
	
	//Internal signal declaration	  
	reg [part-1 : 0]  root;

	integer	i;
	integer	j;	 
	
	reg [(num_stages == 2 ? part : ((num_stages-1)*part))-1:0]  root_r;
	reg [(num_stages == 2 ? part : ((num_stages-1)*part))-1:0]  root_rt;
	reg [(num_stages == 2 ? part : ((num_stages-1)*part))-1:0]  root_ra;
	reg [(num_stages == 2 ? part : ((num_stages-1)*part))-1:0]  root_rat;
	reg [(num_stages == 2 ? part : ((num_stages-1)*part))-1:0]  root_rs;
	reg [(num_stages == 2 ? part : ((num_stages-1)*part))-1:0]  root_rst;
	wire [part-1 : 0]  root_c;

	//Instantiate DW_sqrt
	DW_sqrt #(width, tc_mode) UUT(.a(a), .root(root_c));
	
	/**************** rst_mode = 0; stall_mode = 0  *******************/
	
	//Inserting pipeline registers for root
	always @(posedge clk )
		begin 
			root_r[part-1:0] <= root_c;
			for ( i=0; i < num_stages-2; i = i + 1 )
				begin					
					for ( j=0; j < part; j = j + 1 )
						root_r[(part*(i+1))+j] <= root_r[(part*i)+j];
				end	
		end	  
		
	/**************** rst_mode = 0; stall_mode = 1  *******************/
	
	//Inserting pipeline registers for root 
	always @(posedge clk )
		begin 
			root_rt[part-1:0] <= en ? root_c : root_rt[part-1:0];
			for ( i=0; i < num_stages-2; i = i + 1 )
				begin					
					for ( j=0; j < part; j = j + 1 )
						root_rt[(part*(i+1))+j] <= en ? root_rt[(part*i)+j] : root_rt[(part*(i+1))+j];
				end	
		end	  
		
	/**************** rst_mode = 1; stall_mode = 0  *******************/
	
	//Inserting pipeline registers for root
	always @(posedge clk or negedge rst_n )		
		if ( !rst_n )
			begin 
				root_ra[part-1:0] <= 0;
				for ( i=0; i < num_stages-2; i = i + 1 )
				begin					
					for ( j=0; j < part; j = j + 1 )
						root_ra[(part*(i+1))+j] <= 0;
				end	
			end	 
		else
			begin 
				root_ra[part-1:0] <= root_c;
				for ( i=0; i < num_stages-2; i = i + 1 )
					begin					
						for ( j=0; j < part; j = j + 1 )
							root_ra[(part*(i+1))+j] <= root_ra[(part*i)+j];
					end	
			end	  
		
	/**************** rst_mode = 1; stall_mode = 1  *******************/
	
	//Inserting pipeline registers for root 
	always @(posedge clk or negedge rst_n )
		if ( !rst_n )
			begin 
				root_rat[part-1:0] <= 0;
				for ( i=0; i < num_stages-2; i = i + 1 )
				begin					
					for ( j=0; j < part; j = j + 1 )
						root_rat[(part*(i+1))+j] <= 0;
				end	
			end	 
		else
		begin 
			root_rat[part-1:0] <= en ? root_c : root_rat[part-1:0];
			for ( i=0; i < num_stages-2; i = i + 1 )
				begin					
					for ( j=0; j < part; j = j + 1 )
						root_rat[(part*(i+1))+j] <= en ? root_rat[(part*i)+j] : root_rat[(part*(i+1))+j];
						
				end	
		end	  
		
	/**************** rst_mode = 2; stall_mode = 0  *******************/
	
	//Inserting pipeline registers for root 
	always @(posedge clk )		
		if ( !rst_n )
			begin 
				root_rs[part-1:0] <= 0;
				for ( i=0; i < num_stages-2; i = i + 1 )
				begin					
					for ( j=0; j < part; j = j + 1 )
						root_rs[(part*(i+1))+j] <= 0;
				end	
			end	 
		else
			begin 
				root_rs[part-1:0] <= root_c;
				for ( i=0; i < num_stages-2; i = i + 1 )
					begin					
						for ( j=0; j < part; j = j + 1 )
							root_rs[(part*(i+1))+j] <= root_rs[(part*i)+j];
					end	
			end	  
		
	/**************** rst_mode = 2; stall_mode = 1  *******************/
	
	//Inserting pipeline registers for root 
	always @(posedge clk )
		if ( !rst_n )
			begin 
				root_rst[part-1:0] <= 0;
				for ( i=0; i < num_stages-2; i = i + 1 )
				begin					
					for ( j=0; j < part; j = j + 1 )
						root_rst[(part*(i+1))+j] <= 0;
				end	
			end	 
		else
		begin 
			root_rst[part-1:0] <= en ? root_c : root_rst[part-1:0];
			for ( i=0; i < num_stages-2; i = i + 1 )
				begin					
					for ( j=0; j < part; j = j + 1 )
						root_rst[(part*(i+1))+j] <= en ? root_rst[(part*i)+j] : root_rst[(part*(i+1))+j];
				end	
		end	  
	
	//Updating the output
	always	@( root_r or root_rt or root_ra or root_rat or root_rs or root_rst )
		if ( rst_mode == 2'b00 && stall_mode == 0 )	
			for ( j=0; j < part; j = j + 1 ) 
				root[j] = root_r[(num_stages-2)*part+j];
		else if ( rst_mode == 2'b00 && stall_mode == 1 )
			for ( j=0; j < part; j = j + 1 ) 
				root[j] = root_rt[(num_stages-2)*part+j];
		else if ( rst_mode == 2'b01 && stall_mode == 0 )
			for ( j=0; j < part; j = j + 1 ) 
				root[j] = root_ra[(num_stages-2)*part+j];
		else if ( rst_mode == 2'b01 && stall_mode == 1 )
			for ( j=0; j < part; j = j + 1 ) 
				root[j] = root_rat[(num_stages-2)*part+j];
		else if ( rst_mode == 2'b10 && stall_mode == 0 )		
			for ( j=0; j < part; j = j + 1 ) 
				root[j] = root_rs[(num_stages-2)*part+j];
		else		
			for ( j=0; j < part; j = j + 1 ) 
				root[j] = root_rst[(num_stages-2)*part+j];
		
		
endmodule
