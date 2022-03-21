
//-------------------------------------------------------------------------------------------------
// Description :DW_prod_sum_pipe is a universal stallable pipelined generalized sum of products
// generator.
//-------------------------------------------------------------------------------------------------	
`timescale 1ns / 10ps

module DW_prod_sum_pipe (
    clk, 
    rst_n,
		en,
		tc,
    a, 
		b,
		sum
		)/* synthesis syn_builtin_du = "weak" */;
	
	parameter a_width = 3;
	parameter b_width = 5;
	parameter num_inputs = 2;
	parameter sum_width = 8;
	parameter num_stages = 2;
	parameter stall_mode = 1;
	parameter rst_mode = 1;				 
	parameter	op_iso_mode = 0;
	
	localparam width = a_width + b_width;  

	//Input/output declaration
	input clk;
	input rst_n;
	input en;
	input tc;
	input [a_width*num_inputs-1 : 0] a;
	input [b_width*num_inputs-1 : 0] b;
	output [sum_width-1 : 0]         sum;  

	
	//Internal signal declaration  
	integer	i, j, k;
	reg [a_width-1 : 0] tmp_a;
	reg [b_width-1 : 0] tmp_b; 
	reg [a_width-1 : 0] temp_a [0:num_inputs-1];
	reg [b_width-1 : 0] temp_b [0:num_inputs-1]; 
	reg [width - 1 : 0] t_a [0:num_inputs-1];
	reg [width - 1 : 0] t_b [0:num_inputs-1];
	reg [width-1:0] PRODUCT1 [0:(num_inputs*(num_stages - 1))-1]/* synthesis syn_pipeline=1 */;
	reg [width-1:0] PRODUCT2 [0:(num_inputs*(num_stages - 1))-1]/* synthesis syn_pipeline=1 */;
	reg [width-1:0] PRODUCT3 [0:(num_inputs*(num_stages - 1))-1]/* synthesis syn_pipeline=1 */;
	reg [width-1:0] PRODUCT4 [0:(num_inputs*(num_stages - 1))-1]/* synthesis syn_pipeline=1 */;
	reg [width-1:0] PRODUCT5 [0:(num_inputs*(num_stages - 1))-1]/* synthesis syn_pipeline=1 */;
	reg [width-1:0] PRODUCT6 [0:(num_inputs*(num_stages - 1))-1]/* synthesis syn_pipeline=1 */;
	reg [sum_width-1 : 0]         sum;  
	reg [width-1:0]               msb;

	reg	[num_stages-2:0]	tc_pipe1;	
	reg	[num_stages-2:0]	tc_pipe2;	
	reg	[num_stages-2:0]	tc_pipe3;	
	reg	[num_stages-2:0]	tc_pipe4;	
	reg	[num_stages-2:0]	tc_pipe5;	
	reg	[num_stages-2:0]	tc_pipe6;	

	//Save a and b as memory elements, so that we can apply syn_pipeline
	always @ ( a or b )
		for ( i = 0; i < num_inputs; i = i + 1 ) 
			begin 
				for (j = 0; j < a_width; j = j + 1 )
				  tmp_a[j] = a[a_width*i + j];
				for (k = 0; k < b_width; k = k + 1 )
				  tmp_b[k] = b[b_width*i + k];	
				temp_a[i] = tmp_a;		    
				temp_b[i] = tmp_b;
			end	
	//Sign extending the inputs based on tc		
	always @* 
//	always @(temp_a or temp_b or tc) //for simulation
		for ( i = 0; i < num_inputs; i = i + 1 )
			begin:b1 
				reg [a_width-1 : 0] loc_a;
				reg [b_width-1 : 0] loc_b;
				loc_a = temp_a[i];
				loc_b = temp_b[i];
				t_a[i] = tc ? {{width - a_width{loc_a[a_width - 1]}},loc_a} : {{width - a_width{1'b0}},loc_a};
				t_b[i] = tc ? {{width - b_width{loc_b[b_width - 1]}},loc_b} : {{width - b_width{1'b0}},loc_b};
			end
			
    //Product with a clock latency of num_stages-1, stall_mode = 0, rst_mode = 0
	always @ ( posedge clk ) 
		begin								 
			for ( j = 0; j < num_inputs; j = j + 1 )
				PRODUCT1[j] <= t_a[j] * t_b[j];
				
			for ( i=0; i < num_stages-2; i = i + 1 )
				for ( k = 0; k < num_inputs; k = k + 1 )
					PRODUCT1[num_inputs+(num_inputs*i+k)] <= PRODUCT1[num_inputs*i+k]; 			

			tc_pipe1[0] <= tc;
			for ( i=0; i < num_stages-2; i = i + 1 )
				tc_pipe1[i+1] <= tc_pipe1[i];
		end	

	//Product with a clock latency of num_stages-1, stall_mode = 0, rst_mode = 1
	always @ ( posedge clk or negedge rst_n ) 
		if ( !rst_n )
			begin
        // synthesis loop_limit 2000              
		    for ( i=0; i < num_inputs*(num_stages-1); i = i + 1 )
				PRODUCT2[i] <= 0; 
			for ( i=0; i < num_stages-1; i = i + 1 )
				tc_pipe2[i] <= 0;
			end
		else		
		  begin
			for ( j = 0; j < num_inputs; j = j + 1 )
				PRODUCT2[j] <= t_a[j] * t_b[j];
				
			for ( i=0; i < num_stages-2; i = i + 1 )
				for ( k = 0; k < num_inputs; k = k + 1 )
					PRODUCT2[num_inputs+(num_inputs*i+k)] <= PRODUCT2[num_inputs*i+k]; 		
	
			tc_pipe2[0] <= tc;
			for ( i=0; i < num_stages-2; i = i + 1 )
				tc_pipe2[i+1] <= tc_pipe2[i];
	
		  end		

	//Product with a clock latency of num_stages-1, stall_mode = 0, rst_mode = 2
	always @ ( posedge clk ) 
		if ( !rst_n )
			begin
        // synthesis loop_limit 2000              
		    for ( i=0; i < num_inputs*(num_stages-1); i = i + 1 )
				PRODUCT3[i] <= 0;
			for ( i=0; i < num_stages-1; i = i + 1 )
				tc_pipe3[i] <= 0;
			end
		else		
		  begin
			for ( j = 0; j < num_inputs; j = j + 1 )
				PRODUCT3[j] <= t_a[j] * t_b[j];
				
			for ( i=0; i < num_stages-2; i = i + 1 )
				for ( k = 0; k < num_inputs; k = k + 1 )
					PRODUCT3[num_inputs+(num_inputs*i+k)] <= PRODUCT3[num_inputs*i+k]; 		
	
			tc_pipe3[0] <= tc;
			for ( i=0; i < num_stages-2; i = i + 1 )
				tc_pipe3[i+1] <= tc_pipe3[i];
		  end		

// reg [width-1:0] prod [0:(num_stages - 2)];    

//	always @ (*)
//	   begin
//	      prod[0] = en ?  temp_a * temp_b : PRODUCT4[0];
//		for ( i=0; i < num_stages-2; i = i + 1 )
//		  prod[i+1] = en ? PRODUCT4[i] : PRODUCT4[i+1];
//	   end
//
//	always @ ( posedge clk ) 
//		  begin
//			   PRODUCT4[0] <= prod[0];
//			   for ( i=0; i < num_stages-2; i = i + 1 )
//			     PRODUCT4[i+1] <= prod[i];
//		  end		
//

    //Product with a clock latency of num_stages-1, stall_mode = 1, rst_mode = 0
	always @ ( posedge clk ) 
	  if (en)
		begin
			for ( j = 0; j < num_inputs; j = j + 1 )
				PRODUCT4[j] <= t_a[j] * t_b[j];
				
			for ( i=0; i < num_stages-2; i = i + 1 )
				for ( k = 0; k < num_inputs; k = k + 1 )
					PRODUCT4[num_inputs+(num_inputs*i+k)] <= PRODUCT4[num_inputs*i+k]; 		
	
			tc_pipe4[0] <= tc;
			for ( i=0; i < num_stages-2; i = i + 1 )
				tc_pipe4[i+1] <= tc_pipe4[i];
		end	


    //Product with a clock latency of num_stages-1, stall_mode = 1, rst_mode = 1
	always @ ( posedge clk or negedge rst_n ) 
		if ( !rst_n )
			begin 
        // synthesis loop_limit 2000              
		    for ( i=0; i < num_inputs*(num_stages-1); i = i + 1 )
				PRODUCT5[i] <= 0;  
		
				for ( i=0; i < num_stages-1; i=i+1) 
					tc_pipe5[i] <= 0;
			end
		else if (en)
		begin
			for ( j = 0; j < num_inputs; j = j + 1 )
				PRODUCT5[j] <= t_a[j] * t_b[j];
				
			for ( i=0; i < num_stages-2; i = i + 1 )
				for ( k = 0; k < num_inputs; k = k + 1 )
					PRODUCT5[num_inputs+(num_inputs*i+k)] <= PRODUCT5[num_inputs*i+k]; 				

			tc_pipe5[0] <= tc;
			for ( i=0; i < num_stages-2; i=i+1)
				tc_pipe5[i+1] <= tc_pipe5[i];
		end	


    //Product with a clock latency of num_stages-1, stall_mode = 1, rst_mode = 2
	always @ ( posedge clk ) 
		if ( !rst_n ) 
			begin
        // synthesis loop_limit 2000              
		    for ( i=0; i < num_inputs*(num_stages-1); i = i + 1 )
				PRODUCT6[i] <= 0;

				for ( i=0; i < num_stages-1; i=i+1) 
					tc_pipe6[i] <= 0;
			end
		else if (en)
		begin
			for ( j = 0; j < num_inputs; j = j + 1 )
				PRODUCT6[j] <= t_a[j] * t_b[j];
				
			for ( i=0; i < num_stages-2; i = i + 1 )
				for ( k = 0; k < num_inputs; k = k + 1 )
					PRODUCT6[num_inputs+(num_inputs*i+k)] <= PRODUCT6[num_inputs*i+k]; 			

			tc_pipe6[0] <= tc;
			for ( i=0; i < num_stages-2; i=i+1)
				tc_pipe6[i+1] <= tc_pipe6[i];
		end	
		  
    //Updating output
//    always @ (PRODUCT1 or PRODUCT2 or PRODUCT3 or PRODUCT4 or PRODUCT5 or PRODUCT6)	 //(*)
 always @ (*)
	if ( stall_mode == 0 && rst_mode == 0 )
		begin
			sum = 0;
			for ( i = 0; i < num_inputs; i = i + 1 )
				begin
					msb = PRODUCT1[num_inputs*(num_stages-2)+ i];
					if ( sum_width == width )
					  sum = sum + msb;
					else if ( sum_width > width )
					  sum = sum + (tc_pipe1[num_stages-2] ? {{sum_width-width{msb[width-1]}},msb}:msb);
					else
					  sum = sum + msb;
				end	
		end	
	else if ( stall_mode == 0 && rst_mode == 1 ) 	
		begin
			sum = 0;
			for ( i = 0; i < num_inputs; i = i + 1 )
				begin
					msb = PRODUCT2[num_inputs*(num_stages-2)+ i];
					if ( sum_width == width )
					  sum = sum + msb;
					else if ( sum_width > width )
					  sum = sum + (tc_pipe2[num_stages-2] ? {{sum_width-width{msb[width-1]}},msb}:msb);
					else
					  sum = sum + msb;
				end	
		end	
	else if ( stall_mode == 0 && rst_mode == 2 ) 
		begin
			sum = 0;
			for ( i = 0; i < num_inputs; i = i + 1 )
				begin
					msb = PRODUCT3[num_inputs*(num_stages-2)+ i];
					if ( sum_width == width )
					  sum = sum + msb;
					else if ( sum_width > width )
					  sum = sum + (tc_pipe3[num_stages-2] ? {{sum_width-width{msb[width-1]}},msb}:msb);
					else
					  sum = sum + msb;
				end	
		end	
	else if ( stall_mode == 1 && rst_mode == 0 )
		begin
			sum = 0;
			for ( i = 0; i < num_inputs; i = i + 1 )
				begin
					msb = PRODUCT4[num_inputs*(num_stages-2)+ i];
					if ( sum_width == width )
					  sum = sum + msb;
					else if ( sum_width > width )
					  sum = sum + (tc_pipe4[num_stages-2] ? {{sum_width-width{msb[width-1]}},msb}:msb);
					else
					  sum = sum + msb;
				end	
		end	
	else if (stall_mode == 1 && rst_mode == 1 )	
		begin
			sum = 0;
			for ( i = 0; i < num_inputs; i = i + 1 )
				begin
					msb = PRODUCT5[num_inputs*(num_stages-2)+ i];
					if ( sum_width == width )
					  sum = sum + msb;
					else if ( sum_width > width )
						  sum = sum + (tc_pipe5[num_stages-2] ? {{sum_width-width{msb[width-1]}},msb}:msb);
					else
					  sum = sum + msb;
				end	
		end	
	else if ( stall_mode == 1 && rst_mode == 2 )
		begin
			sum = 0;
			for ( i = 0; i < num_inputs; i = i + 1 )
				begin
					msb = PRODUCT6[num_inputs*(num_stages-2)+ i];
					if ( sum_width == width )
					  sum = sum + msb;
					else if ( sum_width > width )
					  sum = sum + (tc_pipe6[num_stages-2] ? {{sum_width-width{msb[width-1]}},msb}:msb);
					else
					  sum = sum + msb;
				end	
		end	

endmodule
