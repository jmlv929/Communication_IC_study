

//--------------------------------------------------------------------------------------------------
//
// Title       : DW01_sub
// Design      : DW01_sub


//
//-------------------------------------------------------------------------------------------------
//
// Description : Basic subtractor
//
//-------------------------------------------------------------------------------------------------

module DW01_sub( A, B, CI, DIFF, CO)/* synthesis syn_builtin_du = "weak" */;

parameter width = 18;

//Input/output declaration
input [width - 1 : 0]  A;
input [width - 1 : 0]  B;
input                  CI;

output                 CO;
output [width - 1 : 0] DIFF;

//signal declaration
wire                   CO;
wire [width - 1 : 0]   DIFF; 

assign {CO, DIFF} = A - B - CI; 

endmodule
