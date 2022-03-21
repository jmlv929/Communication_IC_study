
module srash(a, sh, b)/* synthesis syn_builtin_du = "weak" */;
parameter A_width = 64; 
parameter SH_width = 6;
input signed [A_width:0] a;
input [SH_width-1:0] sh;
output wire [A_width:0] b;

assign b = a >>> sh;

endmodule
