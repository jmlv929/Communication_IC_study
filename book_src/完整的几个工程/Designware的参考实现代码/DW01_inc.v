
//// RTL for DW01_inc starts here /////
module DW01_inc(A, SUM)/* synthesis syn_builtin_du = "weak" */;

parameter width = 12;

input [(width - 1):0] A;
output [(width - 1):0] SUM;

assign SUM = A + 1'b1;

endmodule
