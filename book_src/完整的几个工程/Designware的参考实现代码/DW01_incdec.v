
//// RTL for DW01_incdec starts here /////
module DW01_incdec (A, INC_DEC, SUM)/* synthesis syn_builtin_du = "weak" */;

parameter width = 14;  

input  [width - 1 : 0] A;
input                  INC_DEC;
output [width - 1 :0]  SUM;
reg    [width - 1 :0]  SUM;

always @(INC_DEC or A)
	begin
		if (INC_DEC == 0)
			SUM = A + 1;
		else
			SUM = A - 1;
	end
endmodule
