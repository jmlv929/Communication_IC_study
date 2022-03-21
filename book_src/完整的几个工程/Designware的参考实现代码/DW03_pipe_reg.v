
//// RTL for DW03_pipe_reg starts here ///////
// RTL fixed for delaying input depth-1 clock cycles -- Nithin
module DW03_pipe_reg(A, clk, B)/* synthesis syn_builtin_du = "weak" */;

parameter depth = 8;
parameter width = 8;


input [width - 1 : 0] A;
input clk;
output [width - 1 : 0] B;

//reg [width - 1 : 0] B;
reg [width - 1 : 0] temp [depth - 1 : 0];
integer i;	
/*
always @(posedge clk)
begin: example
integer i;	
	if (depth > 1 )
    begin
	 	temp[0] <= A;
    //synthesis loop_limit 2000
		for (i = 1; i < depth; i = i + 1)
			temp[i] <= temp[i-1];
	
			B <= temp[depth-1];
    end
	else
	  	B <= A;
end
*/
always @(posedge clk)
	begin
	 	temp[0] <= A;
    //synthesis loop_limit 2000
		for (i = 1; i < depth; i = i + 1)
			temp[i] <= temp[i-1];
	end

assign B = (depth == 1)	? temp[0] : temp[depth-1];

endmodule	
