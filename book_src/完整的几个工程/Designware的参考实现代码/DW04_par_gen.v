
//--------------------------------------------------------------------------------------------------
//
// Title       : DW04_par_gen
// Design      : Parity generator and checker


//-------------------------------------------------------------------------------------------------
//
// Description : The DW04_par_gen is a parity generator and checker circuit that is designed for 
// systems such as computers, peripherals, and communications devices that require improved data
// integrity over unprotected systems.
//-------------------------------------------------------------------------------------------------
module DW04_par_gen (
                     datain,
					 parity
                    )/* synthesis syn_builtin_du = "weak" */;

parameter width = 16;
parameter par_type = 0;
//Input/output declaration
input [width -1 : 0] datain;
output               parity;

wire temp = ^(datain);
wire parity = par_type ? temp : ~temp;

endmodule
