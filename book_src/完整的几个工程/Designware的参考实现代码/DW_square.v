

//// RTL for DW_square starts here
module DW_square (a, tc, square)/* synthesis syn_builtin_du = "weak" */;

parameter width = 8;
//Input/output declaration
input [width - 1 : 0]        a;
input                        tc;
output [(2 * width) - 1 : 0] square;

//Signal declaration
reg [width - 1 : 0]          temp_a;

//Generate square value
assign square = temp_a * temp_a;

//Checking for sign 
always @(tc or a)
 if ( tc && a[width - 1])
     temp_a = ~a + 1'b1;
   else
     temp_a = a;

endmodule
