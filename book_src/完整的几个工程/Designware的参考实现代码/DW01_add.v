

//--------------------------------------------------------------------------------------------------
//
// Title       : DW01_add
// Design      : DW01_add


//
//-------------------------------------------------------------------------------------------------
//
// Description : Basic adder
//
//-------------------------------------------------------------------------------------------------

module DW01_add ( A, B, CI, SUM, CO )/* synthesis syn_builtin_du = "weak" */;
	
parameter	width = 32;

input [width - 1 : 0]  A;
input [width - 1 : 0]  B;
input                  CI;

output                 CO ;
output [width - 1 : 0] SUM ;
wire                   CO ;
wire [width - 1 : 0]   SUM ;

assign { CO, SUM } = A + B + CI;


endmodule
