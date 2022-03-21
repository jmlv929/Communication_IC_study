
//// RTL for DW02_sum starts here ////
module DW02_sum(
INPUT,
SUM
)/* synthesis syn_builtin_du = "weak" */; // DW02_sum

parameter num_inputs = 4;
parameter input_width = 32;
		
input [(input_width*num_inputs)-1 : 0] INPUT;
output [input_width-1 : 0] SUM;

reg [input_width-1 : 0] SUM;
integer i,j;
		
	always @(INPUT)
		begin : blk
			reg [input_width-1 : 0] temp;		//Temporary register to store the slice of the input
			reg [input_width-1 : 0] SUM1;
			SUM1 = INPUT[input_width-1:0];	//Get the first no.	
			//synthesis loop_limit 2000
			for (j=input_width;j<=((input_width*num_inputs)-1);j=j+input_width)
				begin 
					//synthesis loop_limit 2000
					for (i=(input_width-1);i>=0;i=i-1)
						temp[i]=INPUT[i+j];	 //Get the II to last nos.
						
					SUM1 = SUM1 + temp;						
				end
					
			SUM = SUM1;		   
		end
  endmodule
