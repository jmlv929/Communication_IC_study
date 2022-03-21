

////// RTL for DW01_absval //////
module DW01_absval (A,ABSVAL)/* synthesis syn_builtin_du = "weak" */;

//parameter declaration
parameter width = 32;

//ports declaration
input [width-1:0] A;
output [width-1:0] ABSVAL;

assign ABSVAL = A[width-1] ? ~A + 1: A;

endmodule
