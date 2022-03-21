

//--------------------------------------------------------------------------------------------------
// Title       : DW02_mult_5_stage
// Design      : Multiplier

//-------------------------------------------------------------------------------------------------
// Description : DW02_mult_5_stage is a five-stage pipelined multiplier. DW02_mult_5_stage multiplies
//the operand A by B to produce a product (PRODUCT) with a latency of four clock (CLK) cycle.
//
//-------------------------------------------------------------------------------------------------
module DW02_mult_5_stage(A,B,TC,CLK,PRODUCT)/* synthesis syn_builtin_du = "weak" */;

parameter A_width = 16;
parameter B_width = 16;

/********* Internal parameter *************/
parameter width = A_width + B_width;
/*****************************************/

//Input/output declaration
input [A_width - 1 : 0]			   A; 
input [B_width - 1 : 0]			   B; 
input 							   CLK;  
input 							   TC;   
output [A_width + B_width - 1 : 0] PRODUCT;

//Internal signal declaration
reg [width - 1 : 0] 			temp_a;
reg [width - 1 : 0] 			temp_b;
reg [A_width + B_width - 1 : 0] prod /* synthesis syn_pipeline=1 */;
reg [A_width + B_width - 1 : 0] prod1 /* synthesis syn_pipeline=1 */;
reg [A_width + B_width - 1 : 0] prod2 /* synthesis syn_pipeline=1 */;
reg [A_width + B_width - 1 : 0] PRODUCT /* synthesis syn_pipeline=1 */;


//Sign exrtending the inputs based on TC
always @( A or B or TC )	
	begin
		temp_a =  TC ? {{width - A_width{A[A_width - 1]}},A} : {{width - A_width{1'b0}},A};
		temp_b =  TC ? {{width - B_width{B[B_width - 1]}},B} : {{width - B_width{1'b0}},B};
	end	

    //Multiplier - product with a clock latency of Four
	always @ ( posedge CLK )
		begin
			prod <= temp_a * temp_b;
			prod1 <= prod;
			prod2 <= prod1;
		    PRODUCT <= prod2;
		end	
  
endmodule
