
//-------------------------------------------------------------------------------------------------
// Description : DW_mult_pipe is a universal stallable pipelined multiplier. DW_mult_pipe multiplies the
// operands a by b to produce a product with a latency of num_stages-1 clock cycles.
//
//-------------------------------------------------------------------------------------------------
module DW_mult_pipe( 
	clk, 	//Input clock
	rst_n,  //Reset, active-low
	en,     //Load enable
	tc,     //Two's complement control
	a,      //Multiplier
	b,	    //Multiplicand
	product	//Product a X b
	)/* synthesis syn_builtin_du = "weak" */;

parameter a_width = 16;
parameter b_width = 16;
parameter num_stages = 4;
parameter stall_mode = 1;
parameter rst_mode = 1;
parameter	op_iso_mode = 0;

/********* Internal parameter *************/
parameter width = a_width + b_width;
/*****************************************/

//Input/output declaration
input                              clk;	   
input                              rst_n;
input                              en;
input                              tc;
input [a_width - 1 : 0]            a;
input [b_width - 1 : 0]            b;

output [a_width + b_width - 1 : 0] product;

//Signal declration
reg [width-1:0] PRODUCT1 [0:(num_stages - 2)]/* synthesis syn_pipeline=1 */;
reg [width-1:0] PRODUCT2 [0:(num_stages - 2)]/* synthesis syn_pipeline=1 */;
reg [width-1:0] PRODUCT3 [0:(num_stages - 2)]/* synthesis syn_pipeline=1 */;
reg [width-1:0] PRODUCT4 [0:(num_stages - 2)]/* synthesis syn_pipeline=1 */;
reg [width-1:0] PRODUCT5 [0:(num_stages - 2)]/* synthesis syn_pipeline=1 */;
reg [width-1:0] PRODUCT6 [0:(num_stages - 2)]/* synthesis syn_pipeline=1 */;
reg [width - 1 : 0]                 temp_a;
reg [width - 1 : 0]                 temp_b;
reg [a_width + b_width - 1 : 0]     product/* synthesis syn_pipeline=1 */; 
integer	i;


//Sign extending the inputs based on tc
always @( a or b or tc )	
	begin
		temp_a =  tc ? {{width - a_width{a[a_width - 1]}},a} : {{width - a_width{1'b0}},a};
		temp_b =  tc ? {{width - b_width{b[b_width - 1]}},b} : {{width - b_width{1'b0}},b};
	end	


    //Product with a clock latency of num_stages-1, stall_mode = 0, rst_mode = 0
	always @ ( posedge clk ) 
		begin
			PRODUCT1[0] <= temp_a * temp_b;
			for ( i=0; i < num_stages-2; i = i + 1 )
				begin					
						PRODUCT1[i+1] <= PRODUCT1[i]; 
				end
		end	

	//Product with a clock latency of num_stages-1, stall_mode = 0, rst_mode = 1
	always @ ( posedge clk or negedge rst_n ) 
		if ( !rst_n ) 
		    for ( i=0; i < num_stages-1; i = i + 1 )
				PRODUCT2[i] <= 0; 
		else		
		  begin
			PRODUCT2[0] <= temp_a * temp_b;
			for ( i=0; i < num_stages-2; i = i + 1 )
			  PRODUCT2[i+1] <= PRODUCT2[i];
		  end		

	//Product with a clock latency of num_stages-1, stall_mode = 0, rst_mode = 2
	always @ ( posedge clk ) 
		if ( !rst_n ) 
		    for ( i=0; i < num_stages-1; i = i + 1 )
				PRODUCT3[i] <= 0; 
		else		
		  begin
			PRODUCT3[0] <= temp_a * temp_b;
			for ( i=0; i < num_stages-2; i = i + 1 )
			  PRODUCT3[i+1] <= PRODUCT3[i];
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
			PRODUCT4[0] <= temp_a * temp_b;
			for ( i=0; i < num_stages-2; i = i + 1 )
				PRODUCT4[i+1] <= PRODUCT4[i]; 
		end	


    //Product with a clock latency of num_stages-1, stall_mode = 1, rst_mode = 1
	always @ ( posedge clk or negedge rst_n ) 
		if ( !rst_n ) 
		    for ( i=0; i < num_stages-1; i = i + 1 )
				PRODUCT5[i] <= 0; 

		else		
		  begin
		     if ( en ) 
				 begin
			   PRODUCT5[0] <= temp_a * temp_b;
			   for ( i=0; i < num_stages-2; i = i + 1 )
			     PRODUCT5[i+1] <= PRODUCT5[i];
				 end
		  end		


    //Product with a clock latency of num_stages-1, stall_mode = 1, rst_mode = 2
	always @ ( posedge clk ) 
		if ( !rst_n ) 
		    for ( i=0; i < num_stages-1; i = i + 1 )
				PRODUCT6[i] <= 0; 
		else		
		  begin
		    if ( en == 1 )
				begin
			   PRODUCT6[0] <= temp_a * temp_b;
			   for ( i=0; i < num_stages-2; i = i + 1 )
			      PRODUCT6[i+1] <= PRODUCT6[i];
			   end
		  end		


//Updating output
always @(*)
	if ( stall_mode == 0 && rst_mode == 0 )
		product = PRODUCT1[num_stages-2];
	else if ( stall_mode == 0 && rst_mode == 1 ) 	
		product = PRODUCT2[num_stages-2];
	else if ( stall_mode == 0 && rst_mode == 2 ) 
		product = PRODUCT3[num_stages-2];
	else if ( stall_mode == 1 && rst_mode == 0 )
		product = PRODUCT4[num_stages-2];
	else if (stall_mode == 1 && rst_mode == 1 )	
		product = PRODUCT5[num_stages-2];
	else if ( stall_mode == 1 && rst_mode == 2 )
		product = PRODUCT6[num_stages-2];


endmodule
