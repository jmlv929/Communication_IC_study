


//--------------------------------------------------------------------------------------------------
//
// Title       : DW_inc_gray
// Design      : Gray incrementer
//
//-------------------------------------------------------------------------------------------------
// Description : DW_inc_gray adds input at ci to gray coded input a and produces coded output z.
//
//-------------------------------------------------------------------------------------------------

module DW_inc_gray ( 
                     a, 
					 ci,
					 z 
					 )/* synthesis syn_builtin_du = "weak" */;

parameter width = 8;
input [width - 1: 0] a;
input                ci;
output [width - 1:0] z;

//Input/output declaration
wire [width - 1:0] z;
wire [width - 1:0] bin;
wire [width - 1:0] add_out;

//Convert gray to bin first and then add 1. Convert the result back to gray
DW_gray2bin  #(width) r2b( .g(a), .b(bin));
assign add_out = bin + ci;
DW_bin2gray #(width) b2g ( .b(add_out), .g(z) );
endmodule
