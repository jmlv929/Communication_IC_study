

////RTL for DW01_addsub //////
module DW01_addsub(A, B, CI, ADD_SUB, SUM, CO)/* synthesis syn_builtin_du = "weak" */;
	
parameter width = 16;
	
input [width - 1 : 0] A;
input [width - 1 : 0] B;
input CI;
input ADD_SUB;
output [width - 1 : 0] SUM;
output CO;
		
wire [width:0] op_a;
wire [width:0] op_b;
wire [width:0] cin;
wire [width:0] SUM_INT;
assign op_a = {1'b0,A};
assign op_b = {1'b0,B}^({(width+1){ADD_SUB}});
assign cin  = {{(width){1'b0}},CI}^({(width+1){ADD_SUB}});
assign SUM_INT = op_a + op_b + cin + ADD_SUB + ADD_SUB;
		
assign SUM = SUM_INT[(width - 1):0];
assign CO = SUM_INT[width];
endmodule
