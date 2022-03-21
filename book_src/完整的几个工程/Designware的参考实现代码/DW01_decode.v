
//// RTL for DW01_decode starts here /////
module DW01_decode(A, B)/* synthesis syn_builtin_du = "weak" */;

parameter width = 8;

input [width-1:0] A;
output [(1<<width)-1:0] B;

assign B = 1'b1 << A;

endmodule
