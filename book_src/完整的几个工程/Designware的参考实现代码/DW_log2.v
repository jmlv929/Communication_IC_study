
//-------------------------------------------------------------------------------
//
// ABSTRACT: Fixed-point base-2 logarithm (DW_log2)
//           Computes the base-2 logarithm of a fixed point value in the 
//           range [1,2). 
//
//           The number of fractional bits to be used is controlled by
//           a parameter. 
//           This implementation uses a different architectures depending on 
//           the precision of the input.
//
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              op_width        operand size,  >= 2
//                              includes the integer bit
//              arch            implementation select
//                              0 - area optimized 
//                              1 - speed optimized
//                              2 - 2007.12 implementation (default)
//              err_range       error range of the result compared to the
//                              true result. Default is used when arch=2.
//                              1 - 1 ulp max error (default)
//                              2 - 2 ulp max error
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               main input with op_width fractional bits
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               op_width fractional bits + plus one int (sign)
//                              to represent log2(a) in two's complement
//
// MODIFIED:
//           This version of the code includes a modification to reduce the 
//           multipliers and adders in the polynomial approximation section of
//           the code. For this, the table that contains the polynomial coeffs
//           was also modified.
//
//-------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_log2 (

// ports
                   a,
                   z

    // Embedded dc_shell script
    // set_local_link_library {dw01.sldb dw02.sldb}
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

//----------------------------------------------------------------------------
// main module parameters
parameter op_width = 4;               // RANGE 2 to 60 bits
parameter arch=2;                     // RANGE 0 to 2
parameter err_range=1;                // RANGE 1 to 2 ulps

//----------------------------------------------------------------------------
//  declaration of inputs and outputs
input  [op_width-1:0] a;  // all bits of the input are fractional bits
output [op_width-1:0] z;


//------------------------------------------------------------------
// General setting
`define min_op_width_linear 13
`define min_op_width_quadratic 19
`define min_op_width_cubic 29
`define min_op_width_normalization 39

// The following information is used to generate the output using
// lookup a table
// Read the header of inluded file log2_lookup2_rom.tbl
`define lookuptable_nrows 2048
`define lookuptable_wordsize 15
`define lookuptable_addrsize 11
`define lookupint_bits 2

reg  [`lookuptable_addrsize-1:0] tblu_addr;
wire [`lookuptable_wordsize-1:0] rom_out;
wire [op_width:0] z_extended;
wire [op_width-1:0] z_lookup;

always @ (a)
begin
  // when the number of bits being passed it larger than the address space
  // of the table, this result of this method to compute log2 is useless 
  // anyway
  if (`lookuptable_addrsize-op_width+1 > 0)
     tblu_addr = a[op_width-2:0]<<(`lookuptable_addrsize-op_width+1);
  else
     tblu_addr = a[op_width-2:0];
end

//////////////////////////////////////// 


    assign rom_out[14] = 0;

    assign rom_out[13] = 0;

    assign rom_out[12] = tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] |
			tblu_addr[10];

    assign rom_out[11] = ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] |
			tblu_addr[9] & ~tblu_addr[8] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] |
			tblu_addr[10] & tblu_addr[9];

    assign rom_out[10] = tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8];

    assign rom_out[9] = tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6];

    assign rom_out[8] = tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6];

    assign rom_out[7] = tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3];

    assign rom_out[6] = tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3];

    assign rom_out[5] = ~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0];

    assign rom_out[4] = tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1];

    assign rom_out[3] = tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0];

    assign rom_out[2] = ~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0];

    assign rom_out[1] = tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0];

    assign rom_out[0] = tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0];


assign z_extended = (`lookuptable_wordsize-1-`lookupint_bits-op_width >= 0)?
                     rom_out[`lookuptable_wordsize-1-`lookupint_bits:
                             `lookuptable_wordsize-1-`lookupint_bits-op_width]+1:
                     0;
assign z_lookup = z_extended[op_width:1];

//----------------------------------------------------------------------
// The following commands describe the computation of log2 using 
// polynomial approximation.
//
// Extra bits are added to the LS positions
// Besides that, some integer bits were generated in the table.
// This information is collected based on the table size
// created using Matlab, espresso and pla2ver programs.
// Check the file header of log2_gen_poly_rom.h
`define table_nrows 256
`define table_wordsize 423
`define table_addrsize 8
`define coef_max_size (`table_wordsize/9)
// 4 integer bits and 3 bits of slack
`define int_bits 4
`define extra_LSBs 4
`define bits 1
`define coef3_size (op_width+`int_bits+`extra_LSBs+`bits) 
`define coef2_size (op_width+`int_bits+`extra_LSBs) 
`define coef1_size (op_width+`int_bits+`extra_LSBs) 
`define coef0_size (op_width+`int_bits+`extra_LSBs) 
`define prod3_MSB (op_width+`coef3_size-1)
`define prod2_MSB (op_width+`coef2_size-1)
`define prod1_MSB (op_width+`coef1_size-1)
`define z_int_size (op_width+`extra_LSBs)
`define chain 2
`define z_round_MSB (op_width-1+`chain)
// Definition of signals
  // internal format is used as xxxx.xxxxx <== check table
  // the cubic polynomial approximation consists in calculating
  // the value C3*a^3+C2*a^2+C1*a+C0
  // where each coefficient is in the internal format and has a
  // total of table_wordsize/4 bits.
  wire signed [`coef3_size-1:0] Coef3;
  wire signed [`coef2_size-1:0] Coef2;
  wire signed [`coef1_size-1:0] Coef1;
  wire signed [`coef0_size-1:0] Coef0;
  wire signed [`prod1_MSB:0] p1; 
  wire signed [`prod2_MSB:0] p2; 
  wire signed [`prod3_MSB:0] p3;
  wire signed [`prod1_MSB:0] p1_aligned;
  wire signed [`prod2_MSB:0] p2_aligned;
  wire signed [`prod3_MSB:0] p3_aligned;
  wire [`z_int_size-1:0] z_int;
  reg  [`table_addrsize-1:0] addr;
  wire [op_width-1:0] z_poly;
  wire [`z_round_MSB:0] z_round;
  wire [7:0] coef3_sh_dist, coef2_sh_dist, coef1_sh_dist, coef0_sh_dist;
  // Declare the table outputs and include the table output definitions 
  reg [`coef_max_size-1:0] C3, // cubic approx. coefficients
		            C2,
                            C1,
                            C0,
                            Q2, // quadratic approx. coefficients
                            Q1,
                            Q0,
                            L1, // linear approx. coefficients
                            L0;

  // fill in zeros when a is smaller than the table address field
  always @ (a)
  begin
    if (`table_addrsize-op_width+1 > 0)
       addr = a[op_width-2:0] << (`table_addrsize-op_width+1);
    else
       addr = a[op_width-2:op_width-2-`table_addrsize+1];

     case (addr)
      8'd0: begin
              C3=47'h03D3229B8ECF;C2=47'h6EC14A028597;C1=47'h228EA7DA0DF4;C0=47'h6ADCEB87DDAF;
              Q2=47'h7A406E892E54;Q1=47'h1709C45512A1;Q0=47'h6EB5CD21EF77;
              L1=47'h0B84E1D5F876;L0=47'h747B1F1E859C;
            end
      8'd1: begin
              C3=47'h03C7C5564D3A;C2=47'h6EE383DEED75;C1=47'h226C4BCD6437;C0=47'h6AE86AFD6E11;
              Q2=47'h7A4BD6D9D9DF;Q1=47'h16F2DCE84B05;Q0=47'h6EC14C49CEDD;
              L1=47'h0B796E208C51;L0=47'h74869E462291;
            end
      8'd2: begin
              C3=47'h03BC9543390F;C2=47'h6F05572DF0E3;C1=47'h224A34E0ECEA;C0=47'h6AF3DEAE529E;
              Q2=47'h7A571D571DEF;Q1=47'h16DC22D8EA28;Q0=47'h6ECCC0095A7D;
              L1=47'h0B6E1119D99E;L0=47'h74921205628E;
            end
      8'd3: begin
              C3=47'h03B191368C58;C2=47'h6F26C66DB448;C1=47'h2228615CAEBF;C0=47'h6AFF4700A7DA;
              Q2=47'h7A6242862110;Q1=47'h16C595A0D20C;Q0=47'h6ED828770D05;
              L1=47'h0B62CA7EBF16;L0=47'h749D7A72D2B7;
            end
      8'd4: begin
              C3=47'h03A6B7ED608E;C2=47'h6F47D46E76C6;C1=47'h2206CF2CB64E;C0=47'h6B0AA47BC571;
              Q2=47'h7A6D46E99822;Q1=47'h16AF34BBBCBC;Q0=47'h6EE385A93A95;
              L1=47'h0B579A0D2357;L0=47'h74A8D7A4BD94;
            end
      8'd5: begin
              C3=47'h039C098837BC;C2=47'h6F687FCBB450;C1=47'h21E5807F7F80;C0=47'h6B15F6362544;
              Q2=47'h7A782B01B9D1;Q1=47'h1698FFA76934;Q0=47'h6EEED7B5F63C;
              L1=47'h0B4C7F83EFD4;L0=47'h74B429B12C15;
            end
      8'd6: begin
              C3=47'h03918444CC16;C2=47'h6F88CCEA7BA6;C1=47'h21C4719AF783;C0=47'h6B213D483988;
              Q2=47'h7A82EF4C2796;Q1=47'h1682F5E3DEB7;Q0=47'h6EFA1EB2EB62;
              L1=47'h0B417AA30BE7;L0=47'h74BF70ADE691;
            end
      8'd7: begin
              C3=47'h03872784ABAC;C2=47'h6FA8BCBD2EFF;C1=47'h21A3A241BAF7;C0=47'h6B2C799CCDEA;
              Q2=47'h7A8D94445A9D;Q1=47'h166D16F2A175;Q0=47'h6F055AB5C1C5;
              L1=47'h0B368B2B5801;L0=47'h74CAACB075C5;
            end
      8'd8: begin
              C3=47'h037CF3789B45;C2=47'h6FC84DB8D9DF;C1=47'h218314C6B522;C0=47'h6B37AA3CAA8B;
              Q2=47'h7A981A634245;Q1=47'h165762578D03;Q0=47'h6F108BD3A9BF;
              L1=47'h0B2BB0DEA8F7;L0=47'h74D5DDCE23C4;
            end
      8'd9: begin
              C3=47'h0372E5B0B8D7;C2=47'h6FE7867B637B;C1=47'h2162C30D6C42;C0=47'h6B42D117F76F;
              Q2=47'h7AA2821FABE2;Q1=47'h1641D79811D8;Q0=47'h6F1BB221BC58;
              L1=47'h0B20EB7FC35F;L0=47'h74E1041BFCF6;
            end
      8'd10: begin
              C3=47'h0368FF256AB0;C2=47'h70066318CBAA;C1=47'h2142B1D9A3DE;C0=47'h6B4DEC605CF7;
              Q2=47'h7AACCBEE26F6;Q1=47'h162C763B8002;Q0=47'h6F26CDB4D14E;
              L1=47'h0B163AD2571D;L0=47'h74EC1FAED0F6;
            end
      8'd11: begin
              C3=47'h035F3E2FDD02;C2=47'h7024E7CFF5F5;C1=47'h2122DD76C2D8;C0=47'h6B58FD346285;
              Q2=47'h7AB6F84103F1;Q1=47'h16173DCB1BB9;Q0=47'h6F31DEA1708D;
              L1=47'h0B0B9E9AFAF6;L0=47'h74F7309B3385;
            end
      8'd12: begin
              C3=47'h0355A215F15D;C2=47'h704316087A41;C1=47'h2103451B8956;C0=47'h6B6403B1EC6D;
              Q2=47'h7AC107888331;Q1=47'h16022DD1CD0B;Q0=47'h6F3CE4FBF85D;
              L1=47'h0B01169F283B;L0=47'h750236F57D6E;
            end
      8'd13: begin
              C3=47'h034C2A921CC6;C2=47'h7060EDC05401;C1=47'h20E3E9772C39;C0=47'h6B6EFF738EC9;
              Q2=47'h7ACAFA32CC7D;Q1=47'h15ED45DC421F;Q0=47'h6F47E0D88815;
              L1=47'h0AF6A2A536A8;L0=47'h750D32D1CD61;
            end
      8'd14: begin
              C3=47'h0342D6BFCBAC;C2=47'h707E70EEF672;C1=47'h20C4C923F783;C0=47'h6B79F0CE7869;
              Q2=47'h7AD4D0ABF506;Q1=47'h15D88578F36E;Q0=47'h6F52D24AFA4E;
              L1=47'h0AEC4274583D;L0=47'h7518244408D4;
            end
      8'd15: begin
              C3=47'h0339A5DB451A;C2=47'h709BA12C0666;C1=47'h20A5E31B372D;C0=47'h6B84D7F7E6E3;
              Q2=47'h7ADE8B5E2E41;Q1=47'h15C3EC37D117;Q0=47'h6F5DB9670D24;
              L1=47'h0AE1F5D49530;L0=47'h75230B5FDCDD;
            end
      8'd16: begin
              C3=47'h033097691FC4;C2=47'h70B87F2F6719;C1=47'h2087373F54E8;C0=47'h6B8FB4D3810C;
              Q2=47'h7AE82AB1A420;Q1=47'h15AF79AA99A9;Q0=47'h6F689640311E;
              L1=47'h0AD7BC8EC813;L0=47'h752DE838BEFF;
            end
      8'd17: begin
              C3=47'h0327AA602800;C2=47'h70D50D7B72C4;C1=47'h2068C3871EA8;C0=47'h6B9A87F3FD5D;
              Q2=47'h7AF1AF0C94E3;Q1=47'h159B2D64B7C8;Q0=47'h6F7368E997DB;
              L1=47'h0ACD966C99E9;L0=47'h7538BAE1EE04;
            end
      8'd18: begin
              C3=47'h031EDF744F66;C2=47'h70F14904C23E;C1=47'h204A8BD571C6;C0=47'h6BA54FD08E8A;
              Q2=47'h7AFB18D37163;Q1=47'h158706FB0C4A;Q0=47'h6F7E31764D9B;
              L1=47'h0AC383387E71;L0=47'h7543836E72BD;
            end
      8'd19: begin
              C3=47'h03163453BE31;C2=47'h710D387885E4;C1=47'h202C89A3A747;C0=47'h6BB00E977370;
              Q2=47'h7B046868E422;Q1=47'h15730603ED69;Q0=47'h6F88EFF936C8;
              L1=47'h0AB982BDB06D;L0=47'h754E41F120DC;
            end
      8'd20: begin
              C3=47'h030DA90BFC90;C2=47'h7128DAED71B4;C1=47'h200EBE841BF8;C0=47'h6BBAC394E22B;
              Q2=47'h7B0D9E2DBD30;Q1=47'h155F2A176065;Q0=47'h6F93A484EDF2;
              L1=47'h0AAF94C82E0E;L0=47'h7558F67C97AA;
            end
      8'd21: begin
              C3=47'h03053DCB263F;C2=47'h71442F0DE301;C1=47'h1FF12C83693E;C0=47'h6BC56DE696DF;
              Q2=47'h7B16BA8109FF;Q1=47'h154B72CEF4CA;Q0=47'h6F9E4F2BD44D;
              L1=47'h0AA5B924B577;L0=47'h7563A12342C9;
            end
      8'd22: begin
              C3=47'h02FCF12D7667;C2=47'h715F38A04784;C1=47'h1FD3D02535D2;C0=47'h6BD00EA95478;
              Q2=47'h7B1FBDC02026;Q1=47'h1537DFC5BB44;Q0=47'h6FA8F000138D;
              L1=47'h0A9BEFA0C133;L0=47'h756E41F75B02;
            end
      8'd23: begin
              C3=47'h02F4C26B236A;C2=47'h7179F97B06A2;C1=47'h1FB6A7FCD7CF;C0=47'h6BDAA63E39C8;
              Q2=47'h7B28A846E45C;Q1=47'h15247097B84C;Q0=47'h6FB38713E806;
              L1=47'h0A92380A84F2;L0=47'h7578D90AE6F1;
            end
      8'd24: begin
              C3=47'h02ECB1E0A87D;C2=47'h71946FBB5044;C1=47'h1F99B6AC0E1A;C0=47'h6BE5338CBFC8;
              Q2=47'h7B317A6F3B48;Q1=47'h151124E32941;Q0=47'h6FBE1478ECE2;
              L1=47'h0A889230EA2A;L0=47'h7583666FBBBC;
            end
      8'd25: begin
              C3=47'h02E4BEDA5E59;C2=47'h71AE9CFA595F;C1=47'h1F7CFB081021;C0=47'h6BEFB6DD3ABE;
              Q2=47'h7B3A3491B992;Q1=47'h14FDFC4711C9;Q0=47'h6FC89840E316;
              L1=47'h0A7EFDE38CE2;L0=47'h758DEA377DD3;
            end
      8'd26: begin
              C3=47'h02DCE8145799;C2=47'h71C884B5F2E8;C1=47'h1F6071C9CDE5;C0=47'h6BFA314026AF;
              Q2=47'h7B42D705509A;Q1=47'h14EAF663FDA5;Q0=47'h6FD3127D4525;
              L1=47'h0A757AF2B88C;L0=47'h75986473A194;
            end
      8'd27: begin
              C3=47'h02D52DB882B5;C2=47'h71E225B9CDFA;C1=47'h1F441CD0D884;C0=47'h6C04A1E34DF4;
              Q2=47'h7B4B621F4DCD;Q1=47'h14D812DC0F92;Q0=47'h6FDD833F3BC3;
              L1=47'h0A6C092F64E6;L0=47'h75A2D5356C03;
            end
      8'd28: begin
              C3=47'h02CD8ECAF5CE;C2=47'h71FB82A207F9;C1=47'h1F27F9C53451;C0=47'h6C0F0981CBF3;
              Q2=47'h7B53D633AA25;Q1=47'h14C551525DC9;Q0=47'h6FE7EA97F563;
              L1=47'h0A62A86B32F7;L0=47'h75AD3C8DF36C;
            end
      8'd29: begin
              C3=47'h02C60B646726;C2=47'h72149A776885;C1=47'h1F0C0A426EDB;C0=47'h6C19676193BD;
              Q2=47'h7B5C3394C7D8;Q1=47'h14B2B16B9060;Q0=47'h6FF248984C26;
              L1=47'h0A5958786A1B;L0=47'h75B79A8E2014;
            end
      8'd30: begin
              C3=47'h02BEA29874C0;C2=47'h722D6FACE3C4;C1=47'h1EF04C1666A1;C0=47'h6C23BC319229;
              Q2=47'h7B647A93BED8;Q1=47'h14A032CD42ED;Q0=47'h6FFC9D511B3D;
              L1=47'h0A501929F516;L0=47'h75C1EF46ACD5;
            end
      8'd31: begin
              C3=47'h02B753EC144F;C2=47'h7246034131DF;C1=47'h1ED4BEA83443;C0=47'h6C2E080A3EEC;
              Q2=47'h7B6CAB800022;Q1=47'h148DD51EDEF3;Q0=47'h7006E8D2C26B;
              L1=47'h0A46EA535F3C;L0=47'h75CC3AC827C9;
            end
      8'd32: begin
              C3=47'h02B01F9C0FA3;C2=47'h725E53C9BDAB;C1=47'h1EB96413C58F;C0=47'h6C384A005930;
              Q2=47'h7B74C6A7D9CA;Q1=47'h147B98087FD5;Q0=47'h70112B2DC251;
              L1=47'h0A3DCBC8D1B2;L0=47'h75D67D22F2E0;
            end
      8'd33: begin
              C3=47'h02A904DA3876;C2=47'h72766361B370;C1=47'h1E9E3A7F9458;C0=47'h6C4282A3C479;
              Q2=47'h7B7CCC58198A;Q1=47'h14697B33CEEB;Q0=47'h701B64723EC2;
              L1=47'h0A34BD5F10AC;L0=47'h75E0B6674480;
            end
      8'd34: begin
              C3=47'h02A2022F1DE1;C2=47'h728E366CF815;C1=47'h1E833D72DC9E;C0=47'h6C4CB384A99C;
              Q2=47'h7B84BCDC54CF;Q1=47'h14577E4B6C45;Q0=47'h702594B05157;
              L1=47'h0A2BBEEB78BF;L0=47'h75EAE6A52822;
            end
      8'd35: begin
              C3=47'h029B184FAF45;C2=47'h72A5C9F2A3D6;C1=47'h1E6870C6EBA4;C0=47'h6C56DB1049BD;
              Q2=47'h7B8C987ECFC0;Q1=47'h1445A0FB3132;Q0=47'h702FBBF7E1B9;
              L1=47'h0A22D043FC4D;L0=47'h75F50DEC7EE5;
            end
      8'd36: begin
              C3=47'h029446E85E8E;C2=47'h72BD1E7AF79D;C1=47'h1E4DD4606401;C0=47'h6C60F9306AA1;
              Q2=47'h7B945F887364;Q1=47'h1433E2F05143;Q0=47'h7039DA589047;
              L1=47'h0A19F13F20F1;L0=47'h75FF2C4D0028;
            end
      8'd37: begin
              C3=47'h028D8D467B09;C2=47'h72D435D8140E;C1=47'h1E3366A8728F;C0=47'h6C6B0E5FCF8F;
              Q2=47'h7B9C12410D15;Q1=47'h142243D8D3FA;Q0=47'h7043EFE2004C;
              L1=47'h0A1121B3FCF7;L0=47'h760941D63A14;
            end
      8'd38: begin
              C3=47'h0286EA9A5D48;C2=47'h72EB12474F34;C1=47'h1E19258661BE;C0=47'h6C751B4D0A16;
              Q2=47'h7BA3B0EF16F6;Q1=47'h1410C3641D25;Q0=47'h704DFCA38808;
              L1=47'h0A08617A34FA;L0=47'h76134E97922E;
            end
      8'd39: begin
              C3=47'h02805ED31F24;C2=47'h7301B379D04C;C1=47'h1DFF11CA57B2;C0=47'h6C7F1F8AA4C0;
              Q2=47'h7BAB3BD7DA52;Q1=47'h13FF6142A85E;Q0=47'h705800AC5562;
              L1=47'h09FFB069F95F;L0=47'h761D52A045E9;
            end
      8'd40: begin
              C3=47'h0279E9D42310;C2=47'h731819490FC2;C1=47'h1DE52C17D7C1;C0=47'h6C891ABB264F;
              Q2=47'h7BB2B33FAD1E;Q1=47'h13EE1D258410;Q0=47'h7061FC0BB8C4;
              L1=47'h09F70E5C0411;L0=47'h76274DFF6B30;
            end
      8'd41: begin
              C3=47'h02738ACAD2E4;C2=47'h732E46094F6C;C1=47'h1DCB7231E460;C0=47'h6C930D9D7555;
              Q2=47'h7BBA176974CF;Q1=47'h13DCF6BF7BAD;Q0=47'h706BEED076D3;
              L1=47'h09EE7B29962D;L0=47'h763140C3F0E4;
            end
      8'd42: begin
              C3=47'h026D41E2A026;C2=47'h7344389EBC5B;C1=47'h1DB1E5D56894;C0=47'h6C9CF767928F;
              Q2=47'h7BC1689703B9;Q1=47'h13CBEDC44A08;Q0=47'h7075D9093C98;
              L1=47'h09E5F6AC75B4;L0=47'h763B2AFC9F6C;
            end
      8'd43: begin
              C3=47'h02670DF6BACF;C2=47'h7359F486DA13;C1=47'h1D988362C724;C0=47'h6CA6D96469AC;
              Q2=47'h7BC8A70957D1;Q1=47'h13BB01E80EE3;Q0=47'h707FBAC4EEAB;
              L1=47'h09DD80BEEB5E;L0=47'h76450CB81939;
            end
      8'd44: begin
              C3=47'h0260EF6621FF;C2=47'h736F77F5D2A5;C1=47'h1D7F4D622AC5;C0=47'h6CB0B27ADE4A;
              Q2=47'h7BCFD30000EF;Q1=47'h13AA32E0BE31;Q0=47'h70899411D117;
              L1=47'h09D5193BC063;L0=47'h764EE604DB46;
            end
      8'd45: begin
              C3=47'h025AE5311D1B;C2=47'h7384C5F1C642;C1=47'h1D6640B60630;C0=47'h6CBA83C601FE;
              Q2=47'h7BD6ECB9C248;Q1=47'h13998064AFCA;Q0=47'h709364FE5C3D;
              L1=47'h09CCBFFE3C66;L0=47'h7658B6F13D91;
            end
      8'd46: begin
              C3=47'h0254F011CFFA;C2=47'h7399DB6D0191;C1=47'h1D4D616458AC;C0=47'h6CC44B94E270;
              Q2=47'h7BDDF4743B60;Q1=47'h1388EA2B7307;Q0=47'h709D2D98BF46;
              L1=47'h09C474E22358;L0=47'h76627F8B73A3;
            end
      8'd47: begin
              C3=47'h024F0E1BACB8;C2=47'h73AEBEBE9F6F;C1=47'h1D34A85C424F;C0=47'h6CCE0C933ACD;
              Q2=47'h7BE4EA6C0C68;Q1=47'h13786FED81F7;Q0=47'h70A6EDEF0B20;
              L1=47'h09BC37C3B364;L0=47'h766C3FE18D03;
            end
      8'd48: begin
              C3=47'h02493FE26BB0;C2=47'h73C36D666D24;C1=47'h1D1C18F91C82;C0=47'h6CD7C553D6B2;
              Q2=47'h7BEBCEDCBF67;Q1=47'h136811647FA7;Q0=47'h70B0A60F0B95;
              L1=47'h09B4087FA2FA;L0=47'h7675F80175B6;
            end
      8'd49: begin
              C3=47'h0243857DEC62;C2=47'h73D7E697E479;C1=47'h1D03B498CF92;C0=47'h6CE1752FA13B;
              Q2=47'h7BF2A2012B5C;Q1=47'h1357CE4A5455;Q0=47'h70BA5606CCE2;
              L1=47'h09ABE6F31ED1;L0=47'h767FA7F8F6AA;
            end
      8'd50: begin
              C3=47'h023DDE37AB03;C2=47'h73EC2C69E9CF;C1=47'h1CEB7927A438;C0=47'h6CEB1CDD7F90;
              Q2=47'h7BF96412CAA8;Q1=47'h1347A65AC8BA;Q0=47'h70C3FDE3A523;
              L1=47'h09A3D2FBC7FC;L0=47'h76894FD5B63F;
            end
      8'd51: begin
              C3=47'h023849BD6C05;C2=47'h74003F917BA4;C1=47'h1CD366337803;C0=47'h6CF4BC6FB5AA;
              Q2=47'h7C00154A8C7B;Q1=47'h133799519A7D;Q0=47'h70CD9DB35778;
              L1=47'h099BCC77B1F7;L0=47'h7692EFA538A8;
            end
      8'd52: begin
              C3=47'h0232C773B9DD;C2=47'h741421CF5E39;C1=47'h1CBB7A052D39;C0=47'h6CFE547B95EA;
              Q2=47'h7C06B5E03906;Q1=47'h1327A6EBF77D;Q0=47'h70D735832FE9;
              L1=47'h0993D34560EB;L0=47'h769C8774E068;
            end
      8'd53: begin
              C3=47'h022D57C7FD33;C2=47'h7427D129D7CB;C1=47'h1CA3B76182D4;C0=47'h6D07E3C9EB47;
              Q2=47'h7C0D460AC356;Q1=47'h1317CEE7C169;Q0=47'h70E0C560722C;
              L1=47'h098BE743C7BA;L0=47'h76A61751EEBB;
            end
      8'd54: begin
              C3=47'h0227F91677C6;C2=47'h743B5326FCB2;C1=47'h1C8C17FCC13B;C0=47'h6D116CCA0934;
              Q2=47'h7C13C60025EF;Q1=47'h13081103EA4B;Q0=47'h70EA4D582032;
              L1=47'h09840852464F;L0=47'h76AF9F498406;
            end
      8'd55: begin
              C3=47'h0222AD18264F;C2=47'h744EA118FC8C;C1=47'h1C74A44FB70A;C0=47'h6D1AEBF5CFE6;
              Q2=47'h7C1A35F5B04D;Q1=47'h12F86CFFBFC3;Q0=47'h70F3CD7765EC;
              L1=47'h097C3650A7D0;L0=47'h76B91F68A047;
            end
      8'd56: begin
              C3=47'h021D71B70DF0;C2=47'h7461C22FD126;C1=47'h1C5D54003BE8;C0=47'h6D246494A37B;
              Q2=47'h7C20961FAF42;Q1=47'h12E8E29BC610;Q0=47'h70FD45CB1310;
              L1=47'h0974711F20F0;L0=47'h76C297BC2376;
            end
      8'd57: begin
              C3=47'h021847829106;C2=47'h7474B3FA7483;C1=47'h1C462A637EAB;C0=47'h6D2DD5338350;
              Q2=47'h7C26E6B19AB0;Q1=47'h12D97199505B;Q0=47'h7106B65FD809;
              L1=47'h096CB89E4E39;L0=47'h76CC0850CDF9;
            end
      8'd58: begin
              C3=47'h02132E435F84;C2=47'h748776DCE810;C1=47'h1C2F275E04FA;C0=47'h6D373DC3A15E;
              Q2=47'h7C2D27DE41AF;Q1=47'h12CA19BA1B04;Q0=47'h71101F4282CB;
              L1=47'h09650CAF3268;L0=47'h76D571334105;
            end
      8'd59: begin
              C3=47'h020E253D215A;C2=47'h749A0D28E117;C1=47'h1C184872D51B;C0=47'h6D409F30A01E;
              Q2=47'h7C3359D768BB;Q1=47'h12BADAC141AB;Q0=47'h7119807F668C;
              L1=47'h095D6D3334CF;L0=47'h76DED26FFF02;
            end
      8'd60: begin
              C3=47'h02092C87CA28;C2=47'h74AC76248DD6;C1=47'h1C018EE03861;C0=47'h6D49F8DF932B;
              Q2=47'h7C397CCE2D03;Q1=47'h12ABB4725279;Q0=47'h7122DA22EB1C;
              L1=47'h0955DA0C1FC2;L0=47'h76E82C136BF3;
            end
      8'd61: begin
              C3=47'h020443F1B8F1;C2=47'h74BEB22611C8;C1=47'h1BEAFA968D3B;C0=47'h6D534ABDDDCE;
              Q2=47'h7C3F90F30633;Q1=47'h129CA6914E9E;Q0=47'h712C2C398BDC;
              L1=47'h094E531C1EFF;L0=47'h76F17E29CDCF;
            end
      8'd62: begin
              C3=47'h01FF6AD3B7FA;C2=47'h74D0C33C17AA;C1=47'h1BD489613633;C0=47'h6D5C959C9315;
              Q2=47'h7C4596755A0B;Q1=47'h128DB0E3BD1B;Q0=47'h713576CF2C00;
              L1=47'h0946D845BE2A;L0=47'h76FAC8BF4CF6;
            end
      8'd63: begin
              C3=47'h01FAA139B7B8;C2=47'h74E2A8DD7C08;C1=47'h1BBE3C408AD9;C0=47'h6D65D8F9FF73;
              Q2=47'h7C4B8D840826;Q1=47'h127ED32F56F9;Q0=47'h713EB9EFE729;
              L1=47'h093F696BE751;L0=47'h77040BDFF479;
            end
      8'd64: begin
              C3=47'h01F5E6EA6FA1;C2=47'h74F46383C85F;C1=47'h1BA812F3C1EA;C0=47'h6D6F14D8FC26;
              Q2=47'h7C51764D429D;Q1=47'h12700D3A6DA6;Q0=47'h7147F5A7D14F;
              L1=47'h09380671E170;L0=47'h770D4797B282;
            end
      8'd65: begin
              C3=47'h01F13BFDE531;C2=47'h7505F2783DEF;C1=47'h1B920EB6C13F;C0=47'h6D78489D4900;
              Q2=47'h7C5750FE4B22;Q1=47'h12615ECC984A;Q0=47'h71512A0288A1;
              L1=47'h0930AF3B4EFD;L0=47'h77167BF258B8;
            end
      8'd66: begin
              C3=47'h01EC9F4D9F29;C2=47'h751759B6250A;C1=47'h1B7C2ADE54A9;C0=47'h6D817623868E;
              Q2=47'h7C5D1DC3F14D;Q1=47'h1252C7AD7D8B;Q0=47'h715A570BF637;
              L1=47'h092963AC2C82;L0=47'h771FA8FB9C7F;
            end
      8'd67: begin
              C3=47'h01E8114D38FA;C2=47'h75289732F479;C1=47'h1B666A4C9D75;C0=47'h6D8A9C1FEBDA;
              Q2=47'h7C62DCCA241C;Q1=47'h124447A5EDED;Q0=47'h71637CCF9BC8;
              L1=47'h092223A8CF30;L0=47'h7728CEBF177F;
            end
      8'd68: begin
              C3=47'h01E39216154D;C2=47'h7539AA35324F;C1=47'h1B50CE411549;C0=47'h6D93B9F3A949;
              Q2=47'h7C688E3C306C;Q1=47'h1235DE7F4CC9;Q0=47'h716C9B58F0E4;
              L1=47'h091AEF15E38C;L0=47'h7731ED4847C9;
            end
      8'd69: begin
              C3=47'h01DF20BB6BC9;C2=47'h754A95E9CD08;C1=47'h1B3B5308DB07;C0=47'h6D9CD1170197;
              Q2=47'h7C6E3244C2E9;Q1=47'h12278C039069;Q0=47'h7175B2B361B9;
              L1=47'h0913C5D86C12;L0=47'h773B04A2904E;
            end
      8'd70: begin
              C3=47'h01DABCFBD566;C2=47'h755B5AF83DFA;C1=47'h1B25F81C46E7;C0=47'h6DA5E1AE1367;
              Q2=47'h7C73C90DD6A9;Q1=47'h12194FFD734F;Q0=47'h717EC2EA2EA3;
              L1=47'h090CA7D5BFE1;L0=47'h774414D9392F;
            end
      8'd71: begin
              C3=47'h01D667587A40;C2=47'h756BF71FA388;C1=47'h1B10C0A9EC45;C0=47'h6DAEEA485661;
              Q2=47'h7C7952C0CC28;Q1=47'h120B2A383F17;Q0=47'h7187CC088C6B;
              L1=47'h090594F38974;L0=47'h774D1DF7700C;
            end
      8'd72: begin
              C3=47'h01D21E90D9CD;C2=47'h757C6EDBBA9F;C1=47'h1AFBA744749C;C0=47'h6DB7ED1FC2E2;
              Q2=47'h7C7ECF865295;Q1=47'h11FD1A800B70;Q0=47'h7190CE197AF5;
              L1=47'h08FE8D17C560;L0=47'h775620084855;
            end
      8'd73: begin
              C3=47'h01CDE3723BB0;C2=47'h758CBEC80644;C1=47'h1AE6B090B636;C0=47'h6DC0E8231867;
              Q2=47'h7C843F8694B4;Q1=47'h11EF20A15046;Q0=47'h7199C9280A26;
              L1=47'h08F79028C10F;L0=47'h775F1B16BBA5;
            end
      8'd74: begin
              C3=47'h01C9B57F2531;C2=47'h759CE87726DA;C1=47'h1AD1DAD8282A;C0=47'h6DC9DBF74742;
              Q2=47'h7C89A2E9134B;Q1=47'h11E13C694ABB;Q0=47'h71A2BD3F1818;
              L1=47'h08F09E0D1988;L0=47'h77680F2DAA09;
            end
      8'd75: begin
              C3=47'h01C5944440EB;C2=47'h75ACED59913A;C1=47'h1ABD248ABA04;C0=47'h6DD2C932CE5F;
              Q2=47'h7C8EF9D4C1C7;Q1=47'h11D36DA5B86B;Q0=47'h71ABAA697C08;
              L1=47'h08E9B6ABBA47;L0=47'h7770FC57DA4E;
            end
      8'd76: begin
              C3=47'h01C17FC800FC;C2=47'h75BCCD0A04BE;C1=47'h1AA88E7525E6;C0=47'h6DDBAF684F75;
              Q2=47'h7C94446FD45F;Q1=47'h11C5B4255D4A;Q0=47'h71B490B1AE62;
              L1=47'h08E2D9EBDBF6;L0=47'h7779E29FFA5B;
            end
      8'd77: begin
              C3=47'h01BD77B39E9E;C2=47'h75CC888EA906;C1=47'h1A94178CD0DD;C0=47'h6DE48EF5E812;
              Q2=47'h7C9982E02ADA;Q1=47'h11B80FB6F3BA;Q0=47'h71BD702277A6;
              L1=47'h08DC07B50366;L0=47'h7782C2109F6C;
            end
      8'd78: begin
              C3=47'h01B97BF124A6;C2=47'h75DC1FF329F5;C1=47'h1A7FC00AA200;C0=47'h6DED67AE27D1;
              Q2=47'h7C9EB54AEB92;Q1=47'h11AA802A36A5;Q0=47'h71C648C642FA;
              L1=47'h08D53FEF003F;L0=47'h778B9AB4467D;
            end
      8'd79: begin
              C3=47'h01B58C6F3440;C2=47'h75EB93317BA5;C1=47'h1A6B883F2DBD;C0=47'h6DF63958CB86;
              Q2=47'h7CA3DBD4AC27;Q1=47'h119D054F7CE5;Q0=47'h71CF1AA75DCB;
              L1=47'h08CE8281EC1F;L0=47'h77946C95545F;
            end
      8'd80: begin
              C3=47'h01B1A890233D;C2=47'h75FAE46D4D5F;C1=47'h1A576DA36689;C0=47'h6DFF04FBFE5C;
              Q2=47'h7CA8F6A1A445;Q1=47'h118F9EF7386B;Q0=47'h71D7E5D04B4C;
              L1=47'h08C7CF562946;L0=47'h779D37BE1635;
            end
      8'd81: begin
              C3=47'h01ADD0E32860;C2=47'h760A112AD51C;C1=47'h1A4373C0C931;C0=47'h6E07C8F6BD59;
              Q2=47'h7CAE05D545A2;Q1=47'h11824CF30B08;Q0=47'h71E0AA4B0DFF;
              L1=47'h08C1265461A3;L0=47'h77A5FC38C1A8;
            end
      8'd82: begin
              C3=47'h01AA047B90A9;C2=47'h76191CCA87C1;C1=47'h1A2F966ADCD6;C0=47'h6E10870980F9;
              Q2=47'h7CB30992B1D3;Q1=47'h11750F14957A;Q0=47'h71E96821EEB5;
              L1=47'h08BA876585C0;L0=47'h77AEBA0F7526;
            end
      8'd83: begin
              C3=47'h01A643E75D53;C2=47'h762804D448FA;C1=47'h1A1BD9296103;C0=47'h6E193D9220C0;
              Q2=47'h7CB801FC49B9;Q1=47'h1167E52EA428;Q0=47'h71F21F5EB541;
              L1=47'h08B3F272CBAC;L0=47'h77B7714C383D;
            end
      8'd84: begin
              C3=47'h01A28DDAE6EF;C2=47'h7636CE2B52E5;C1=47'h1A0835C4BA53;C0=47'h6E21EF3C485A;
              Q2=47'h7CBCEF34405C;Q1=47'h115ACF13AEDB;Q0=47'h71FAD00BA59D;
              L1=47'h08AD6765AE0E;L0=47'h77C021F8FBBC;
            end
      8'd85: begin
              C3=47'h019EE3C55DF9;C2=47'h764572D49042;C1=47'h19F4B47286EA;C0=47'h6E2A98513E36;
              Q2=47'h7CC1D15BFC1F;Q1=47'h114DCC978160;Q0=47'h72037A32658E;
              L1=47'h08A6E627EB07;L0=47'h77C8CC1F9A28;
            end
      8'd86: begin
              C3=47'h019B43DE2CC3;C2=47'h7653F9AE48C9;C1=47'h19E14C4EF6B7;C0=47'h6E333CAFD727;
              Q2=47'h7CC6A894996B;Q1=47'h1140DD8DE4C2;Q0=47'h720C1DDCDEFF;
              L1=47'h08A06EA38345;L0=47'h77D16FC9D7DD;
            end
      8'd87: begin
              C3=47'h0197AF410F27;C2=47'h76625E07055B;C1=47'h19CE03DF4E9B;C0=47'h6E3BD95DD299;
              Q2=47'h7CCB74FE7713;Q1=47'h113401CBD782;Q0=47'h7214BB146ED1;
              L1=47'h089A00C2B915;L0=47'h77DA0D01634D;
            end
      8'd88: begin
              C3=47'h019424B4A94A;C2=47'h7670A48A855E;C1=47'h19BAD5216E74;C0=47'h6E4470F729D9;
              Q2=47'h7CD036B9DC69;Q1=47'h11273925D51B;Q0=47'h721D51E30A74;
              L1=47'h08939C700F50;L0=47'h77E2A3CFD562;
            end
      8'd89: begin
              C3=47'h0190A5270DA5;C2=47'h767EC939A33E;C1=47'h19A7C5B42C05;C0=47'h6E4D00E43CFC;
              Q2=47'h7CD4EDE644E2;Q1=47'h111A8371BCA7;Q0=47'h7225E251F904;
              L1=47'h088D41964896;L0=47'h77EB343EB18E;
            end
      8'd90: begin
              C3=47'h018D2F4473BF;C2=47'h768CD134885A;C1=47'h1994CEED265E;C0=47'h6E558C113002;
              Q2=47'h7CD99AA2D9EF;Q1=47'h110DE0858E43;Q0=47'h722E6C6AAA6A;
              L1=47'h0886F0206638;L0=47'h77F3BE576642;
            end
      8'd91: begin
              C3=47'h0189C46765D3;C2=47'h769AB6BF654C;C1=47'h1981F8CC3283;C0=47'h6E5E0ECFEF76;
              Q2=47'h7CDE3D0E7655;Q1=47'h11015037642F;Q0=47'h7236F036BBFE;
              L1=47'h0880A7F9A770;L0=47'h77FC42234CF9;
            end
      8'd92: begin
              C3=47'h018662EF4EDC;C2=47'h76A8803AF556;C1=47'h196F3AEAB5AC;C0=47'h6E668CD9340C;
              Q2=47'h7CE2D54743E2;Q1=47'h10F4D25E809A;Q0=47'h723F6DBF40C3;
              L1=47'h087A690D8873;L0=47'h7804BFABAA94;
            end
      8'd93: begin
              C3=47'h01830C471FF9;C2=47'h76B627A1A839;C1=47'h195C9DB78422;C0=47'h6E6F0247482F;
              Q2=47'h7CE7636B1215;Q1=47'h10E866D26729;Q0=47'h7247E50D5C28;
              L1=47'h08743347C187;L0=47'h780D36F9AF94;
            end
      8'd94: begin
              C3=47'h017FBE00EC00;C2=47'h76C3B6AA93CA;C1=47'h194A142CFB60;C0=47'h6E7774F44B8E;
              Q2=47'h7CEBE79754C2;Q1=47'h10DC0D6AE32C;Q0=47'h7250562A3D63;
              L1=47'h086E06944642;L0=47'h7815A8167842;
            end
      8'd95: begin
              C3=47'h017C79EEABF0;C2=47'h76D125A76E64;C1=47'h1937A902DE27;C0=47'h6E7FDFED9439;
              Q2=47'h7CF061E91587;Q1=47'h10CFC600327A;Q0=47'h7258C11F0177;
              L1=47'h0867E2DF4495;L0=47'h781E130B0D03;
            end
      8'd96: begin
              C3=47'h01793F4E7293;C2=47'h76DE777A42A8;C1=47'h192558836656;C0=47'h6E8844D1C4C5;
              Q2=47'h7CF4D27CCE38;Q1=47'h10C3906B7020;Q0=47'h726125F468F5;
              L1=47'h0861C815240B;L0=47'h782677E06283;
            end
      8'd97: begin
              C3=47'h01760E6E268F;C2=47'h76EBAAA76124;C1=47'h191324F580C1;C0=47'h6E90A282AC11;
              Q2=47'h7CF9396EC5DC;Q1=47'h10B76C859881;Q0=47'h726984B383DE;
              L1=47'h085BB62284EE;L0=47'h782ED69F59F1;
            end
      8'd98: begin
              C3=47'h0172E5F94465;C2=47'h76F8C479AA37;C1=47'h19010743DC82;C0=47'h6E98FC314FCB;
              Q2=47'h7CFD96DAAE4B;Q1=47'h10AB5A289ACB;Q0=47'h7271DD64F4E1;
              L1=47'h0855ACF43F83;L0=47'h78372F50C13D;
            end
      8'd99: begin
              C3=47'h016FC71DE54C;C2=47'h7705BFD5F27B;C1=47'h18EF06B5B0B8;C0=47'h6EA14E71F09B;
              Q2=47'h7D01EADC0CDE;Q1=47'h109F592E3B7E;Q0=47'h727A3011B565;
              L1=47'h084FAC776339;L0=47'h783F81FD5348;
            end
      8'd100: begin
              C3=47'h016CB0F8B808;C2=47'h7712A036A56C;C1=47'h18DD1EB21D5A;C0=47'h6EA99B52753A;
              Q2=47'h7D06358DCAC1;Q1=47'h109369714C33;Q0=47'h72827CC23D13;
              L1=47'h0849B49935E7;L0=47'h7847CEADB819;
            end
      8'd101: begin
              C3=47'h0169A3E73571;C2=47'h771F63E0528A;C1=47'h18CB51D9A8E5;C0=47'h6EB1E189CE5A;
              Q2=47'h7D0A770A78E3;Q1=47'h10878ACCF366;Q0=47'h728AC37F000C;
              L1=47'h0843C5473306;L0=47'h7850156A8522;
            end
      8'd102: begin
              C3=47'h01669F533BCA;C2=47'h772C0D125420;C1=47'h18B99D4135F4;C0=47'h6EBA22621CE9;
              Q2=47'h7D0EAF6C863B;Q1=47'h107BBD1C1709;Q0=47'h72930450D6EF;
              L1=47'h083DDE6F0AFB;L0=47'h7858563C3D5C;
            end
      8'd103: begin
              C3=47'h0163A362014A;C2=47'h77389AFD5518;C1=47'h18A802403B1E;C0=47'h6EC25D2AC38C;
              Q2=47'h7D12DECDC323;Q1=47'h1070003ABB3F;Q0=47'h729B3F40095D;
              L1=47'h0837FFFEA24C;L0=47'h7860912B5197;
            end
      8'd104: begin
              C3=47'h0160AF8C5BE5;C2=47'h77450FA83F77;C1=47'h18967E32D789;C0=47'h6ECA930FD943;
              Q2=47'h7D170547B468;Q1=47'h106454051DD1;Q0=47'h72A37454EC5E;
              L1=47'h083229E410EE;L0=47'h7868C64020A2;
            end
      8'd105: begin
              C3=47'h015DC4441498;C2=47'h77516901336C;C1=47'h188514368E01;C0=47'h6ED2C28B49A4;
              Q2=47'h7D1B22F3A07D;Q1=47'h1058B8579350;Q0=47'h72ABA397FA95;
              L1=47'h082C5C0DA18E;L0=47'h7870F582F778;
            end
      8'd106: begin
              C3=47'h015AE16A3B78;C2=47'h775DA7576D6B;C1=47'h1873C412F05C;C0=47'h6EDAEBA5D82F;
              Q2=47'h7D1F37EA25FF;Q1=47'h104D2D0FB352;Q0=47'h72B3CD10FFB3;
              L1=47'h08269669D0EC;L0=47'h78791EFC1170;
            end
      8'd107: begin
              C3=47'h01580681D965;C2=47'h7769CC8BEAA5;C1=47'h18628B5401F1;C0=47'h6EE30F7719D9;
              Q2=47'h7D23444405CA;Q1=47'h1041B20A209A;Q0=47'h72BBF0C8A897;
              L1=47'h0820D8E74D0B;L0=47'h788142B39887;
            end
      8'd108: begin
              C3=47'h015533C156A6;C2=47'h7775D786F34A;C1=47'h18516BB9B7CE;C0=47'h6EEB2D1B2983;
              Q2=47'h7D274819509F;Q1=47'h10364724DE08;Q0=47'h72C40EC6DD01;
              L1=47'h081B2374F4A1;L0=47'h788960B1A577;
            end
      8'd109: begin
              C3=47'h015268BCB7C1;C2=47'h7781C9E58574;C1=47'h1840632B9C6B;C0=47'h6EF3458041E7;
              Q2=47'h7D2B4381CAFE;Q1=47'h102AEC3E37BA;Q0=47'h72CC27138346;
              L1=47'h08157601D65E;L0=47'h789178FE3FF5;
            end
      8'd110: begin
              C3=47'h014FA569B34C;C2=47'h778DA3A5A084;C1=47'h182F71DD5EE5;C0=47'h6EFB587E950A;
              Q2=47'h7D2F36951617;Q1=47'h101FA1345010;Q0=47'h72D439B6D242;
              L1=47'h080FD07D3053;L0=47'h78998BA15ECE;
            end
      8'd111: begin
              C3=47'h014CEA42F5EC;C2=47'h77996288CCB9;C1=47'h181E9B38CE5F;C0=47'h6F0364649675;
              Q2=47'h7D33216A4271;Q1=47'h101465E65A6D;Q0=47'h72DC46B86FD4;
              L1=47'h080A32D66F2F;L0=47'h78A198A2E83B;
            end
      8'd112: begin
              C3=47'h014A35E3C5C5;C2=47'h77A50C61273B;C1=47'h180DD7147F34;C0=47'h6F0B6D0A35DA;
              Q2=47'h7D3704183919;Q1=47'h10093A33715E;Q0=47'h72E44E2044EB;
              L1=47'h08049CFD2DC4;L0=47'h78A9A00AB1EB;
            end
      8'd113: begin
              C3=47'h0147897D18A5;C2=47'h77B09BDF6C29;C1=47'h17FD2D419958;C0=47'h6F136EA1B5C6;
              Q2=47'h7D3ADEB59CE9;Q1=47'h0FFE1DFAF04C;Q0=47'h72EC4FF63D18;
              L1=47'h07FF0EE13445;L0=47'h78B1A1E08141;
            end
      8'd114: begin
              C3=47'h0144E3F00C24;C2=47'h77BC15AFEC91;C1=47'h17EC97336DD3;C0=47'h6F1B6C417BB7;
              Q2=47'h7D3EB1588D43;Q1=47'h0FF3111D26DD;Q0=47'h72F44C41C45D;
              L1=47'h07F9887277BF;L0=47'h78B99E2C0B7F;
            end
      8'd115: begin
              C3=47'h0142467987F2;C2=47'h77C7744715C5;C1=47'h17DC1D1F9910;C0=47'h6F2361E4A56E;
              Q2=47'h7D427C172288;Q1=47'h0FE81379F448;Q0=47'h72FC430AC7BC;
              L1=47'h07F409A1197A;L0=47'h78C194F4F5EE;
            end
      8'd116: begin
              C3=47'h013FAFBCFE02;C2=47'h77D2BD63873E;C1=47'h17CBB6E40820;C0=47'h6F2B5368D257;
              Q2=47'h7D463F07008E;Q1=47'h0FDD24F205C0;Q0=47'h73043458CED1;
              L1=47'h07EE925D665B;L0=47'h78C98642D613;
            end
      8'd117: begin
              C3=47'h013D203CB526;C2=47'h77DDEEA3C096;C1=47'h17BB68234E78;C0=47'h6F333EFD08E0;
              Q2=47'h7D49FA3D7B40;Q1=47'h0FD245666FAC;Q0=47'h730C203344F3;
              L1=47'h07E92297D651;L0=47'h78D1721D31D5;
            end
      8'd118: begin
              C3=47'h013A9754D816;C2=47'h77E90AAAE3B5;C1=47'h17AB2D3217AB;C0=47'h6F3B265B6B56;
              Q2=47'h7D4DADCFA7EB;Q1=47'h0FC774B87D75;Q0=47'h731406A19BA8;
              L1=47'h07E3BA410BBD;L0=47'h78D9588B7FB1;
            end
      8'd119: begin
              C3=47'h0138161D31EE;C2=47'h77F40C82E69E;C1=47'h179B0D80920C;C0=47'h6F4305D45856;
              Q2=47'h7D5159D26CC7;Q1=47'h0FBCB2C985DA;Q0=47'h731BE7AB6A49;
              L1=47'h07DE5949D2F7;L0=47'h78E1399526C6;
            end
      8'd120: begin
              C3=47'h01359B5203FF;C2=47'h77FEF98FCC57;C1=47'h178B0158BECA;C0=47'h6F4AE11BD262;
              Q2=47'h7D54FE5A3498;Q1=47'h0FB1FF7BCCED;Q0=47'h7323C357C7CE;
              L1=47'h07D8FFA321A0;L0=47'h78E915417F24;
            end
      8'd121: begin
              C3=47'h013327464289;C2=47'h7809D03CF28A;C1=47'h177B0B37835C;C0=47'h6F52B6EC7614;
              Q2=47'h7D589B7B549B;Q1=47'h0FA75AB15BAC;Q0=47'h732B99AE2355;
              L1=47'h07D3AD3E1634;L0=47'h78F0EB97D1DC;
            end
      8'd122: begin
              C3=47'h0130B8F36917;C2=47'h781494EE49BE;C1=47'h176B24CBC1E5;C0=47'h6F5A8A54A287;
              Q2=47'h7D5C3149DB55;Q1=47'h0F9CC44C91C9;Q0=47'h73336AB5D8F5;
              L1=47'h07CE620BF75C;L0=47'h78F8BC9F5943;
            end
      8'd123: begin
              C3=47'h012E51D08BD1;C2=47'h781F40FF85FD;C1=47'h175B580ECDE6;C0=47'h6F62565DC5AA;
              Q2=47'h7D5FBFD96386;Q1=47'h0F923C30AD82;Q0=47'h733B3675CC72;
              L1=47'h07C91DFE3395;L0=47'h7900885F40EF;
            end
      8'd124: begin
              C3=47'h012BF15A9124;C2=47'h7829D68C3409;C1=47'h174BA212AD9D;C0=47'h6F6A1C6902FB;
              Q2=47'h7D63473D7A94;Q1=47'h0F87C2409F1D;Q0=47'h7342FCF54687;
              L1=47'h07C3E106607D;L0=47'h79084EDEA60F;
            end
      8'd125: begin
              C3=47'h012997B9571D;C2=47'h783454B9296E;C1=47'h173C044C40AC;C0=47'h6F71DBAD6198;
              Q2=47'h7D66C7895C4A;Q1=47'h0F7D565FD464;Q0=47'h734ABE3B5E32;
              L1=47'h07BEAB163A73;L0=47'h791010249767;
            end
      8'd126: begin
              C3=47'h0127435308A9;C2=47'h783EC2893FC8;C1=47'h172C74723DF5;C0=47'h6F79993968D6;
              Q2=47'h7D6A40CFE76D;Q1=47'h0F72F8725D66;Q0=47'h73527A4EDC24;
              L1=47'h07B97C1FA3F3;L0=47'h7917CC3815A3;
            end
      8'd127: begin
              C3=47'h0124F56133D8;C2=47'h78491A5EA9D9;C1=47'h171CFB0B1C7F;C0=47'h6F8150C417FD;
              Q2=47'h7D6DB323F25D;Q1=47'h0F68A85BF21C;Q0=47'h735A3136F4E9;
              L1=47'h07B45414A541;L0=47'h791F83201347;
            end
      8'd128: begin
              C3=47'h0122AE08BEB0;C2=47'h78535B6B8531;C1=47'h170D99794E8A;C0=47'h6F89018C6AD0;
              Q2=47'h7D711E97F02E;Q1=47'h0F5E66010340;Q0=47'h7361E2FA7CF4;
              L1=47'h07AF32E76BBE;L0=47'h792734E3750C;
            end
      8'd129: begin
              C3=47'h01206CA13784;C2=47'h785D887FAC00;C1=47'h16FE4BB09857;C0=47'h6F90AD898F8D;
              Q2=47'h7D74833E07B1;Q1=47'h0F5431467866;Q0=47'h73698FA0188F;
              L1=47'h07AA188A4991;L0=47'h792EE18911D9;
            end
      8'd130: begin
              C3=47'h011E3063ED2E;C2=47'h7867A4FBD2F4;C1=47'h16EF0CBEB92D;C0=47'h6F98572BF40E;
              Q2=47'h7D77E12861B3;Q1=47'h0F4A0A10C614;Q0=47'h7371372EEB89;
              L1=47'h07A504EFB51B;L0=47'h79368917B301;
            end
      8'd131: begin
              C3=47'h011BFAD02768;C2=47'h7871A9F664CD;C1=47'h16DFE738874C;C0=47'h6F9FF9146EC4;
              Q2=47'h7D7B38689513;Q1=47'h0F3FF045AD34;Q0=47'h7378D9AD47AA;
              L1=47'h079FF80A487E;L0=47'h793E2B961462;
            end
      8'd132: begin
              C3=47'h0119CAFBAA7E;C2=47'h787B9B6F949E;C1=47'h16D0D53E0371;C0=47'h6FA796293BB1;
              Q2=47'h7D7E89105008;Q1=47'h0F35E3CA3E4E;Q0=47'h738077222BD0;
              L1=47'h079AF1CCC135;L0=47'h7945C90AE47E;
            end
      8'd133: begin
              C3=47'h0117A0B4C011;C2=47'h78857A27E596;C1=47'h16C1D5D116E1;C0=47'h6FAF2EDE4F9F;
              Q2=47'h7D81D330CDB4;Q1=47'h0F2BE4847DA0;Q0=47'h73880F94060A;
              L1=47'h0795F229FF90;L0=47'h794D617CC4AE;
            end
      8'd134: begin
              C3=47'h01157C511981;C2=47'h788F4476274F;C1=47'h16B2EB9F5C3A;C0=47'h6FB6C1CAF638;
              Q2=47'h7D8516DB5897;Q1=47'h0F21F259D907;Q0=47'h738FA309DE15;
              L1=47'h0790F9150651;L0=47'h7954F4F24930;
            end
      8'd135: begin
              C3=47'h01135D4C7530;C2=47'h7898FC9544E5;C1=47'h16A413694BF3;C0=47'h6FBE5088901B;
              Q2=47'h7D8854208005;Q1=47'h0F180D319299;Q0=47'h739731897DC9;
              L1=47'h078C0680FA25;L0=47'h795C8371F96D;
            end
      8'd136: begin
              C3=47'h011143FA8E92;C2=47'h78A2A0E432E2;C1=47'h16954FD221C6;C0=47'h6FC5D9B256E9;
              Q2=47'h7D8B8B11320E;Q1=47'h0F0E34F166D8;Q0=47'h739EBB19FE71;
              L1=47'h07871A612158;L0=47'h79640D024FE5;
            end
      8'd137: begin
              C3=47'h010F3019E8D8;C2=47'h78AC326E3141;C1=47'h16869F6778B3;C0=47'h6FCD5DF7F446;
              Q2=47'h7D8EBBBDBE31;Q1=47'h0F046980938D;Q0=47'h73A63FC1790B;
              L1=47'h078234A8E33E;L0=47'h796B91A9BA8D;
            end
      8'd138: begin
              C3=47'h010D21630FFF;C2=47'h78B5B25CE84A;C1=47'h1678008420C1;C0=47'h6FD4DE250404;
              Q2=47'h7D91E63670E7;Q1=47'h0EFAAAC5FDFC;Q0=47'h73ADBF866FBD;
              L1=47'h077D554BC7F3;L0=47'h7973116E9AB6;
            end
      8'd139: begin
              C3=47'h010B17F79C9D;C2=47'h78BF1FF6296E;C1=47'h1669746A1B77;C0=47'h6FDC5988786E;
              Q2=47'h7D950A8B5503;Q1=47'h0EF0F8A8F41B;Q0=47'h73B53A6F39B1;
              L1=47'h07787C3D77C9;L0=47'h797A8C57455D;
            end
      8'd140: begin
              C3=47'h010913E0FFEB;C2=47'h78C87AEE464B;C1=47'h165AFBB34ACA;C0=47'h6FE3CFC65FEE;
              Q2=47'h7D9828CC3BAB;Q1=47'h0EE753111628;Q0=47'h73BCB0821369;
              L1=47'h0773A971BAFD;L0=47'h7982026A032F;
            end
      8'd141: begin
              C3=47'h01071520A682;C2=47'h78D1C31E28DC;C1=47'h164C96C248D5;C0=47'h6FEB409E7528;
              Q2=47'h7D9B4108B427;Q1=47'h0EDDB9E671CB;Q0=47'h73C421C50907;
              L1=47'h076EDCDC7942;L0=47'h798973AD10B1;
            end
      8'd142: begin
              C3=47'h01051B967666;C2=47'h78DAF8FB2FD1;C1=47'h163E4506B145;C0=47'h6FF2AC4E18BF;
              Q2=47'h7D9E53505D53;Q1=47'h0ED42D1086D0;Q0=47'h73CB8E3EB901;
              L1=47'h076A1671B958;L0=47'h7990E0269E6E;
            end
      8'd143: begin
              C3=47'h010326BC63AA;C2=47'h78E41ED95CD5;C1=47'h16300303731A;C0=47'h6FFA1498DDD4;
              Q2=47'h7DA15FB25800;Q1=47'h0ECAAC780021;Q0=47'h73D2F5F4FD70;
              L1=47'h07655625A0C7;L0=47'h799847DCD0E0;
            end
      8'd144: begin
              C3=47'h010137281749;C2=47'h78ED31DF07E7;C1=47'h1621D54CA1A0;C0=47'h70017711D518;
              Q2=47'h7DA4663DAE05;Q1=47'h0EC1380575C5;Q0=47'h73DA58EDE21F;
              L1=47'h07609BEC7344;L0=47'h799FAAD5C0E9;
            end
      8'd145: begin
              C3=47'h00FF4C3F38E8;C2=47'h78F634C1E40E;C1=47'h1613B7C942D4;C0=47'h7008D5CF32BA;
              Q2=47'h7DA7670161D0;Q1=47'h0EB7CFA13CC1;Q0=47'h73E1B72FCA7B;
              L1=47'h075BE7BA928F;L0=47'h79A709177B98;
            end
      8'd146: begin
              C3=47'h00FD66229CC8;C2=47'h78FF26CBBCAD;C1=47'h1605ABB6FEAD;C0=47'h701030204666;
              Q2=47'h7DAA620BF4E0;Q1=47'h0EAE7334E4E6;Q0=47'h73E910C04647;
              L1=47'h075739847DE3;L0=47'h79AE62A80283;
            end
      8'd147: begin
              C3=47'h00FB8505A987;C2=47'h790806ECDE1C;C1=47'h15F7B2E380F3;C0=47'h701785070B72;
              Q2=47'h7DAD576C11F0;Q1=47'h0EA522A9253C;Q0=47'h73F065A5B18E;
              L1=47'h0752913ED1C1;L0=47'h79B5B78D4BB5;
            end
      8'd148: begin
              C3=47'h00F9A87E179F;C2=47'h7910D6FE52C5;C1=47'h15E9CA884BC8;C0=47'h701ED5EC5163;
              Q2=47'h7DB0473002DC;Q1=47'h0E9BDDE78E64;Q0=47'h73F7B5E5DFAC;
              L1=47'h074DEEDE476D;L0=47'h79BD07CD41F6;
            end
      8'd149: begin
              C3=47'h00F7D14D851D;C2=47'h7919934CE630;C1=47'h15DBF8A13BC3;C0=47'h70261F9CA5AF;
              Q2=47'h7DB33165CA1A;Q1=47'h0E92A4DA3D69;Q0=47'h73FF01865666;
              L1=47'h07495257B4AA;L0=47'h79C4536DC4D8;
            end
      8'd150: begin
              C3=47'h00F5FE71036A;C2=47'h792240881AB0;C1=47'h15CE35E821A0;C0=47'h702D65E12911;
              Q2=47'h7DB6161B818C;Q1=47'h0E89776AB0EE;Q0=47'h7406488D39FD;
              L1=47'h0744BBA00B59;L0=47'h79CB9A74A8D0;
            end
      8'd151: begin
              C3=47'h00F42F8CE39C;C2=47'h792AE04CB667;C1=47'h15C07FE89532;C0=47'h7034A9FDFBA0;
              Q2=47'h7DB8F55F02C7;Q1=47'h0E805582DF50;Q0=47'h740D8B007160;
              L1=47'h07402AAC5929;L0=47'h79D2DCE7B742;
            end
      8'd152: begin
              C3=47'h00F265ABE72B;C2=47'h79336D876BDA;C1=47'h15B2DED45D6A;C0=47'h703BE7902448;
              Q2=47'h7DBBCF3DD7B3;Q1=47'h0E773F0D69D1;Q0=47'h7414C8E57C5C;
              L1=47'h073B9F71C733;L0=47'h79DA1ACCAEC2;
            end
      8'd153: begin
              C3=47'h00F0A0070B58;C2=47'h793BEBD3B9DA;C1=47'h15A54D0D932B;C0=47'h704321873686;
              Q2=47'h7DBEA3C57E81;Q1=47'h0E6E33F4C5F6;Q0=47'h741C02421DA3;
              L1=47'h073719E599B3;L0=47'h79E15429430A;
            end
      8'd154: begin
              C3=47'h00EEDF16B047;C2=47'h794458D5A15A;C1=47'h1597CE79C3F4;C0=47'h704A55C4424D;
              Q2=47'h7DC173034302;Q1=47'h0E653423B9BD;Q0=47'h7423371BF7D1;
              L1=47'h073299FD2F9F;L0=47'h79E889031D37;
            end
      8'd155: begin
              C3=47'h00ED2213011E;C2=47'h794CB833C44B;C1=47'h158A5D5E5C6B;C0=47'h7051874BAAC8;
              Q2=47'h7DC43D045EAF;Q1=47'h0E5C3F84F607;Q0=47'h742A6778DE58;
              L1=47'h072E1FAE0270;L0=47'h79EFB95FDBBD;
            end
      8'd156: begin
              C3=47'h00EB69CFDBA6;C2=47'h795505D7678D;C1=47'h157D006BA726;C0=47'h7058B27DA770;
              Q2=47'h7DC701D5B72D;Q1=47'h0E535603EA5B;Q0=47'h7431935E2B38;
              L1=47'h0729AAEDA5AF;L0=47'h79F6E54512B2;
            end
      8'd157: begin
              C3=47'h00E9B59B2C8A;C2=47'h795D4501BA94;C1=47'h156FB285310E;C0=47'h705FDA0C46C3;
              Q2=47'h7DC9C1842492;Q1=47'h0E4A778BE49D;Q0=47'h7438BAD17252;
              L1=47'h07253BB1C6C7;L0=47'h79FE0CB84BAA;
            end
      8'd158: begin
              C3=47'h00E8058FBC50;C2=47'h79657518B33D;C1=47'h156274C0A5D2;C0=47'h7066FD580775;
              Q2=47'h7DCC7C1C546F;Q1=47'h0E41A4086F25;Q0=47'h743FDDD835C5;
              L1=47'h0720D1F02C8E;L0=47'h7A052FBF061A;
            end
      8'd159: begin
              C3=47'h00E659DDF92D;C2=47'h796D951781E5;C1=47'h155548E37AD9;C0=47'h706E1B60D985;
              Q2=47'h7DCF31AAD09F;Q1=47'h0E38DB653BF1;Q0=47'h7446FC77F633;
              L1=47'h071C6D9EB725;L0=47'h7A0C4E5EB725;
            end
      8'd160: begin
              C3=47'h00E4B1F3B131;C2=47'h7975A7AD15FF;C1=47'h15482AB10F62;C0=47'h707536669AF3;
              Q2=47'h7DD1E23BE3DE;Q1=47'h0E301D8E7F0C;Q0=47'h744E16B5E906;
              L1=47'h07180EB35F7D;L0=47'h7A13689CC9F6;
            end
      8'd161: begin
              C3=47'h00E30EE36063;C2=47'h797DA784755B;C1=47'h153B22F537FB;C0=47'h707C4998A5C8;
              Q2=47'h7DD48DDBFE44;Q1=47'h0E276A6FA8CE;Q0=47'h74552C9800D7;
              L1=47'h0713B5243728;L0=47'h7A1A7E7E9FB0;
            end
      8'd162: begin
              C3=47'h00E16ED409C7;C2=47'h79859D8E13FE;C1=47'h152E233BC0AC;C0=47'h70835CC67F58;
              Q2=47'h7DD7349705BD;Q1=47'h0E1EC1F5A243;Q0=47'h745C3E231B90;
              L1=47'h070F60E76807;L0=47'h7A2190098F91;
            end
      8'd163: begin
              C3=47'h00DFD31AEB54;C2=47'h798D832D0B3F;C1=47'h15213669F93E;C0=47'h708A69F9A3B8;
              Q2=47'h7DD9D678E26D;Q1=47'h0E16240D05E2;Q0=47'h74634B5C73D9;
              L1=47'h070B11F333F5;L0=47'h7A289D42E720;
            end
      8'd164: begin
              C3=47'h00DE3B453AE2;C2=47'h79955A7BCC4A;C1=47'h1514592E2DA1;C0=47'h709172F5B14A;
              Q2=47'h7DDC738D67A0;Q1=47'h0E0D90A26B23;Q0=47'h746A54496401;
              L1=47'h0706C83DF48D;L0=47'h7A2FA62FEA1B;
            end
      8'd165: begin
              C3=47'h00DCA75EFD1F;C2=47'h799D2327A3B1;C1=47'h15078C2D1FD6;C0=47'h70987755E129;
              Q2=47'h7DDF0BE0558A;Q1=47'h0E0507A26135;Q0=47'h747158EF6A44;
              L1=47'h070283BE1AE2;L0=47'h7A36AAD5D2A8;
            end
      8'd166: begin
              C3=47'h00DB1732BA5E;C2=47'h79A4DE217389;C1=47'h14FACDF6DE7B;C0=47'h709F77D9A1C6;
              Q2=47'h7DE19F7D14F8;Q1=47'h0DFC88FA50EC;Q0=47'h747859536EBA;
              L1=47'h06FE446A2F21;L0=47'h7A3DAB39D183;
            end
      8'd167: begin
              C3=47'h00D98AF02632;C2=47'h79AC8A663FAC;C1=47'h14EE205303C1;C0=47'h70A6737BFF39;
              Q2=47'h7DE42E6F1893;Q1=47'h0DF414973E1B;Q0=47'h747F557AC8B8;
              L1=47'h06FA0A38D06A;L0=47'h7A44A7610DDC;
            end
      8'd168: begin
              C3=47'h00D801E4529D;C2=47'h79B42B58508B;C1=47'h14E17DC30732;C0=47'h70AD6D3B181F;
              Q2=47'h7DE6B8C19497;Q1=47'h0DEBAA66B6B2;Q0=47'h74864D6A79BF;
              L1=47'h06F5D520B474;L0=47'h7A4B9F50A5A2;
            end
      8'd169: begin
              C3=47'h00D67D272541;C2=47'h79BBBB71F0EA;C1=47'h14D4EF8934D1;C0=47'h70B45FEF7A6C;
              Q2=47'h7DE93E7FA27C;Q1=47'h0DE34A565E40;Q0=47'h748D41278CEF;
              L1=47'h06F1A518A759;L0=47'h7A52930DAD75;
            end
      8'd170: begin
              C3=47'h00D4FBFC832C;C2=47'h79C33E43A327;C1=47'h14C86FD9EFC1;C0=47'h70BB4EC1E2BA;
              Q2=47'h7DEBBFB44143;Q1=47'h0DDAF453EDDB;Q0=47'h749430B7171E;
              L1=47'h06ED7A178B43;L0=47'h7A59829D30DF;
            end
      8'd171: begin
              C3=47'h00D37E1C6617;C2=47'h79CAB52112DA;C1=47'h14BBFC980E31;C0=47'h70C23AD62666;
              Q2=47'h7DEE3C6A54A1;Q1=47'h0DD2A84D379B;Q0=47'h749B1C1E33A9;
              L1=47'h06E95414583E;L0=47'h7A606E04323C;
            end
      8'd172: begin
              C3=47'h00D20412E544;C2=47'h79D21D37A8A8;C1=47'h14AF9A93E413;C0=47'h70C921750833;
              Q2=47'h7DF0B4AC834C;Q1=47'h0DCA66309859;Q0=47'h74A20361A530;
              L1=47'h06E533061BDF;L0=47'h7A675547AB0B;
            end
      8'd173: begin
              C3=47'h00D08D99C3FE;C2=47'h79D977D10365;C1=47'h14A347C363A8;C0=47'h70D003B639ED;
              Q2=47'h7DF328858E3B;Q1=47'h0DC22DEBD4D2;Q0=47'h74A8E686C84F;
              L1=47'h06E116E3F913;L0=47'h7A6E386C8BCD;
            end
      8'd174: begin
              C3=47'h00CF1A263EA5;C2=47'h79E0C793BECC;C1=47'h1496FFCC6B9A;C0=47'h70D6E400192A;
              Q2=47'h7DF597FFB79C;Q1=47'h0DB9FF6E1B53;Q0=47'h74AFC591E544;
              L1=47'h06DCFFA527E2;L0=47'h7A751777BC35;
            end
      8'd175: begin
              C3=47'h00CDAA53AF5F;C2=47'h79E8095D51EA;C1=47'h148AC80B639A;C0=47'h70DDBF4974F8;
              Q2=47'h7DF803257D19;Q1=47'h0DB1DAA59464;Q0=47'h74B6A08839CA;
              L1=47'h06D8ED40F51F;L0=47'h7A7BF26E1B49;
            end
      8'd176: begin
              C3=47'h00CC3DDD5911;C2=47'h79EF3E73D124;C1=47'h147E9E7635AF;C0=47'h70E496AD0AFD;
              Q2=47'h7DFA6A012B5C;Q1=47'h0DA9BF80CEC0;Q0=47'h74BD776EC859;
              L1=47'h06D4DFAEC240;L0=47'h7A82C9547F4E;
            end
      8'd177: begin
              C3=47'h00CAD50C2B7C;C2=47'h79F665506675;C1=47'h147285BC5242;C0=47'h70EB689D4769;
              Q2=47'h7DFCCC9CB726;Q1=47'h0DA1ADEF44D9;Q0=47'h74C44A49E60D;
              L1=47'h06D0D6E6051D;L0=47'h7A899C2FB5F6;
            end
      8'd178: begin
              C3=47'h00C96F76FA0A;C2=47'h79FD7FF3FC38;C1=47'h14667A94D560;C0=47'h70F236E9FFC5;
              Q2=47'h7DFF2B025593;Q1=47'h0D99A5DF5B20;Q0=47'h74CB191EEC9B;
              L1=47'h06CCD2DE479B;L0=47'h7A906B048489;
            end
      8'd179: begin
              C3=47'h00C80CEDE0C1;C2=47'h7A048F3FB367;C1=47'h145A7B98F654;C0=47'h70F90255C2A3;
              Q2=47'h7E01853BCC7E;Q1=47'h0D91A740B2D3;Q0=47'h74D1E3F242EF;
              L1=47'h06C8D38F279A;L0=47'h7A9735D7A7C8;
            end
      8'd180: begin
              C3=47'h00C6ADC1A3F6;C2=47'h7A0B9184C8AD;C1=47'h144E8BBCB755;C0=47'h70FFC92B7049;
              Q2=47'h7E03DB52CBB0;Q1=47'h0D89B202FDF2;Q0=47'h74D8AAC85A1D;
              L1=47'h06C4D8F0568A;L0=47'h7A9DFCADD440;
            end
      8'd181: begin
              C3=47'h00C551960481;C2=47'h7A1288878868;C1=47'h1442A815EF99;C0=47'h71068D099899;
              Q2=47'h7E062D512694;Q1=47'h0D81C6153A95;Q0=47'h74DF6DA65542;
              L1=47'h06C0E2F9996E;L0=47'h7AA4BF8BB605;
            end
      8'd182: begin
              C3=47'h00C3F926BF46;C2=47'h7A197071ADED;C1=47'h1436D74CD185;C0=47'h710D4A1B8D9E;
              Q2=47'h7E087B404FA6;Q1=47'h0D79E367778A;Q0=47'h74E62C9087D1;
              L1=47'h06BCF1A2C866;L0=47'h7AAB7E75F129;
            end
      8'd183: begin
              C3=47'h00C2A31CDF59;C2=47'h7A2050119FC0;C1=47'h142B0DD2D0E7;C0=47'h711406F05637;
              Q2=47'h7E0AC529D9A5;Q1=47'h0D7209E91C4D;Q0=47'h74ECE78BEC8C;
              L1=47'h06B904E3CE9D;L0=47'h7AB239712188;
            end
      8'd184: begin
              C3=47'h00C150C89142;C2=47'h7A2720938D94;C1=47'h141F5774A291;C0=47'h711ABCC06B23;
              Q2=47'h7E0D0B16EE09;Q1=47'h0D6A398AC0DA;Q0=47'h74F39E9C9166;
              L1=47'h06B51CB4AA07;L0=47'h7AB8F081DAF9;
            end
      8'd185: begin
              C3=47'h00C0013055DE;C2=47'h7A2DE6EA619F;C1=47'h1413ABCA6D52;C0=47'h712170527A1D;
              Q2=47'h7E0F4D10ED6A;Q1=47'h0D62723C084A;Q0=47'h74FA51C76E64;
              L1=47'h06B1390D6B2B;L0=47'h7ABFA3ACA95A;
            end
      8'd186: begin
              C3=47'h00BEB4D35C17;C2=47'h7A34A072E0E4;C1=47'h14080F767340;C0=47'h71281EF49AE7;
              Q2=47'h7E118B20DFE9;Q1=47'h0D5AB3ED8ED7;Q0=47'h75010110BCFB;
              L1=47'h06AD59E634EA;L0=47'h7AC652F610A2;
            end
      8'd187: begin
              C3=47'h00BD6B2FDE42;C2=47'h7A3B4FBBB02E;C1=47'h13FC7E24E6B2;C0=47'h712ECB1BEA7E;
              Q2=47'h7E13C54FE71A;Q1=47'h0D52FE8F6294;Q0=47'h7507AC7D48BC;
              L1=47'h06A97F373C55;L0=47'h7ACCFE628CEC;
            end
      8'd188: begin
              C3=47'h00BC24DA2BAC;C2=47'h7A41F1B07647;C1=47'h13F0FD4222D7;C0=47'h7135719E194D;
              Q2=47'h7E15FBA6E7CB;Q1=47'h0D4B52122D71;Q0=47'h750E54116E08;
              L1=47'h06A5A8F8C864;L0=47'h7AD3A5F692A6;
            end
      8'd189: begin
              C3=47'h00BAE1083759;C2=47'h7A488A5B4707;C1=47'h13E585E2E156;C0=47'h713C1672C352;
              Q2=47'h7E182E2EAF87;Q1=47'h0D43AE66B4EE;Q0=47'h7514F7D1884A;
              L1=47'h06A1D72331D9;L0=47'h7ADA49B68E7A;
            end
      8'd190: begin
              C3=47'h00B9A013FBFB;C2=47'h7A4F17D770B1;C1=47'h13DA1B64F670;C0=47'h7142B79FC28C;
              Q2=47'h7E1A5CEFFF45;Q1=47'h0D3C137DB58B;Q0=47'h751B97C21193;
              L1=47'h069E09AEE301;L0=47'h7AE0E9A6E579;
            end
      8'd191: begin
              C3=47'h00B86285D1E2;C2=47'h7A55974898AB;C1=47'h13CEC2DF2689;C0=47'h714952254C29;
              Q2=47'h7E1C87F34FFE;Q1=47'h0D348148B2E0;Q0=47'h752233E6ECE7;
              L1=47'h069A40945786;L0=47'h7AE785CBF52D;
            end
      8'd192: begin
              C3=47'h00B7270A3725;C2=47'h7A5C0F91504F;C1=47'h13C370601458;C0=47'h714FECEF6AE6;
              Q2=47'h7E1EAF416E8F;Q1=47'h0D2CF7B7D7D3;Q0=47'h7528CC4540C6;
              L1=47'h06967BCC1C37;L0=47'h7AEE1E2A1397;
            end
      8'd193: begin
              C3=47'h00B5EF1E8467;C2=47'h7A6278CE53FC;C1=47'h13B831CC2E07;C0=47'h71567FDA9607;
              Q2=47'h7E20D2E2A290;Q1=47'h0D2576BCEDFC;Q0=47'h752F60E0DFDC;
              L1=47'h0692BB4ECEDF;L0=47'h7AF4B2C58F60;
            end
      8'd194: begin
              C3=47'h00B4B98AEE60;C2=47'h7A68D95647EB;C1=47'h13ACFC1D9D08;C0=47'h715D114EBAC8;
              Q2=47'h7E22F2DF4B64;Q1=47'h0D1DFE4939B8;Q0=47'h7535F1BE270A;
              L1=47'h068EFF151E12;L0=47'h7AFB43A2AFC5;
            end
      8'd195: begin
              C3=47'h00B386E970BC;C2=47'h7A6F2DED6C22;C1=47'h13A1D517D04E;C0=47'h71639DE3A060;
              Q2=47'h7E250F3F8F44;Q1=47'h0D168E4E96A7;Q0=47'h753C7EE1041B;
              L1=47'h068B4717C8FB;L0=47'h7B01D0C5B4C5;
            end
      8'd196: begin
              C3=47'h00B25730EFEF;C2=47'h7A7576B1B1AD;C1=47'h1396BC9EE6DD;C0=47'h716A259F42BC;
              Q2=47'h7E27280BC277;Q1=47'h0D0F26BE0CB5;Q0=47'h7543084E34FA;
              L1=47'h0687934F9F32;L0=47'h7B085A32D71B;
            end
      8'd197: begin
              C3=47'h00B129A3E9E4;C2=47'h7A7BB780446A;C1=47'h138BABF3144D;C0=47'h7170AC73B236;
              Q2=47'h7E293D4BDA27;Q1=47'h0D07C789C29B;Q0=47'h75498E099042;
              L1=47'h0683E3B5807B;L0=47'h7B0EDFEE4880;
            end
      8'd198: begin
              C3=47'h00AFFEF6C192;C2=47'h7A81EC8CB146;C1=47'h1380A9E05836;C0=47'h71772E576EF7;
              Q2=47'h7E2B4F07EE4B;Q1=47'h0D0070A333A9;Q0=47'h75501017996C;
              L1=47'h068038425CC6;L0=47'h7B1561FC3355;
            end
      8'd199: begin
              C3=47'h00AED68FEEFA;C2=47'h7A8818F89749;C1=47'h1375B0ED098F;C0=47'h717DAE7F670D;
              Q2=47'h7E2D5D47C9F4;Q1=47'h0CF921FCBC26;Q0=47'h75568E7C21B9;
              L1=47'h067C90EF33CF;L0=47'h7B1BE060BB1D;
            end
      8'd200: begin
              C3=47'h00ADB0C73C4C;C2=47'h7A8E3AE19411;C1=47'h136AC484F5CC;C0=47'h71842ADDEE1B;
              Q2=47'h7E2F68134EAC;Q1=47'h0CF1DB883974;Q0=47'h755D093B7FE4;
              L1=47'h0678EDB51507;L0=47'h7B225B1FFC5E;
            end
      8'd201: begin
              C3=47'h00AC8E5FD79F;C2=47'h7A944E21566A;C1=47'h135FEC27E89A;C0=47'h718A9EF2DDFF;
              Q2=47'h7E316F722966;Q1=47'h0CEA9D381577;Q0=47'h75638059A27A;
              L1=47'h06754E8D1F73;L0=47'h7B28D23E0CA6;
            end
      8'd202: begin
              C3=47'h00AB6DD78A0D;C2=47'h7A9A5ABC62EF;C1=47'h1355199B46F6;C0=47'h7191132D0AB8;
              Q2=47'h7E33736C0A83;Q1=47'h0CE366FE7FAF;Q0=47'h7569F3DAC0A4;
              L1=47'h0671B370815E;L0=47'h7B2F45BEFACF;
            end
      8'd203: begin
              C3=47'h00AA5014B760;C2=47'h7AA05BD0D2C3;C1=47'h134A55AC5E61;C0=47'h719782467B9D;
              Q2=47'h7E3574086C81;Q1=47'h0CDC38CE3AD4;Q0=47'h757063C2A239;
              L1=47'h066E1C58785B;L0=47'h7B35B5A6CEC2;
            end
      8'd204: begin
              C3=47'h00A93477DE34;C2=47'h7AA654A9EEA7;C1=47'h133F9A86D0A0;C0=47'h719DEFB36638;
              Q2=47'h7E37714ECB4F;Q1=47'h0CD51299D789;Q0=47'h7576D0154FF3;
              L1=47'h066A893E50FD;L0=47'h7B3C21F989B7;
            end
      8'd205: begin
              C3=47'h00A81BC6E235;C2=47'h7AAC410D7AD1;C1=47'h1334EFD87233;C0=47'h71A456D19F4E;
              Q2=47'h7E396B4696E8;Q1=47'h0CCDF453E4A6;Q0=47'h757D38D6E838;
              L1=47'h0666FA1B66C0;L0=47'h7B428ABB2635;
            end
      8'd206: begin
              C3=47'h00A7050E3697;C2=47'h7AB22610A80C;C1=47'h132A4C8DB6B1;C0=47'h71AABD0C11EC;
              Q2=47'h7E3B61F723F7;Q1=47'h0CC6DDEF26C4;Q0=47'h75839E0B6D4A;
              L1=47'h06636EE923B9;L0=47'h7B48EFEF9844;
            end
      8'd207: begin
              C3=47'h00A5F0F8AD7F;C2=47'h7AB80008EA94;C1=47'h131FB7569EF3;C0=47'h71B11E55D3FA;
              Q2=47'h7E3D55679FD4;Q1=47'h0CBFCF5EC4E9;Q0=47'h7589FFB69C1F;
              L1=47'h065FE7A100A7;L0=47'h7B4F519ACD3B;
            end
      8'd208: begin
              C3=47'h00A4DF3CA0D6;C2=47'h7ABDD076C270;C1=47'h13152D909A6F;C0=47'h71B77C3CE831;
              Q2=47'h7E3F459F44FF;Q1=47'h0CB8C8958B49;Q0=47'h75905DDC9757;
              L1=47'h065C643C84A9;L0=47'h7B55AFC0ABF1;
            end
      8'd209: begin
              C3=47'h00A3CFA47C8A;C2=47'h7AC39870538F;C1=47'h130AAD55059D;C0=47'h71BDD7E0A108;
              Q2=47'h7E4132A51583;Q1=47'h0CB1C986E7C6;Q0=47'h7596B8810273;
              L1=47'h0658E4B54509;L0=47'h7B5C0A6514E6;
            end
      8'd210: begin
              C3=47'h00A2C28FC913;C2=47'h7AC955DF1DC2;C1=47'h13003A81AB20;C0=47'h71C42EE21A51;
              Q2=47'h7E431C8030B4;Q1=47'h0CAAD225B3AD;Q0=47'h759D0FA81B29;
              L1=47'h06556904E52B;L0=47'h7B62618BE23B;
            end
      8'd211: begin
              C3=47'h00A1B78A3475;C2=47'h7ACF0B30B6C7;C1=47'h12F5D0BD9009;C0=47'h71CA83DD42C9;
              Q2=47'h7E4503374F4B;Q1=47'h0CA3E26613E3;Q0=47'h75A363550453;
              L1=47'h0651F1251680;L0=47'h7B68B538E778;
            end
      8'd212: begin
              C3=47'h00A0AF940268;C2=47'h7AD4B2DA4298;C1=47'h12EB7A3CB6A2;C0=47'h71D0D09331F6;
              Q2=47'h7E46E6D17806;Q1=47'h0C9CFA3AE7CE;Q0=47'h75A9B38C1C1C;
              L1=47'h064E7D0F981B;L0=47'h7B6F056FF22A;
            end
      8'd213: begin
              C3=47'h009FA91C85F6;C2=47'h7ADA5563EB0B;C1=47'h12E127784BAF;C0=47'h71D71E72D05D;
              Q2=47'h7E48C7556CEE;Q1=47'h0C961997E035;Q0=47'h75B0005114B5;
              L1=47'h064B0CBE36C3;L0=47'h7B755234C98F;
            end
      8'd214: begin
              C3=47'h009EA54974B5;C2=47'h7ADFEC733E92;C1=47'h12D6E4243483;C0=47'h71DD6650718E;
              Q2=47'h7E4AA4C9DEE1;Q1=47'h0C8F4070C481;Q0=47'h75B649A79DE3;
              L1=47'h0647A02ACCC1;L0=47'h7B7B9B8B2EA9;
            end
      8'd215: begin
              C3=47'h009DA31D3E16;C2=47'h7AE57D704217;C1=47'h12CCA664704B;C0=47'h71E3AE2E125C;
              Q2=47'h7E4C7F354F6C;Q1=47'h0C886EB9E226;Q0=47'h75BC8F92FE6C;
              L1=47'h0644374F41B0;L0=47'h7B81E176DC61;
            end
      8'd216: begin
              C3=47'h009CA344A4DF;C2=47'h7AEB04960F20;C1=47'h12C275371444;C0=47'h71E9F1BC7F25;
              Q2=47'h7E4E569E91C4;Q1=47'h0C81A4663259;Q0=47'h75C2D217C84F;
              L1=47'h0640D2258A6F;L0=47'h7B8823FB8787;
            end
      8'd217: begin
              C3=47'h009BA5B91C74;C2=47'h7AF081FA6058;C1=47'h12B85088C9B2;C0=47'h71F030FE8E6B;
              Q2=47'h7E502B0C08EF;Q1=47'h0C7AE16A23CA;Q0=47'h75C911394836;
              L1=47'h063D70A7A8D6;L0=47'h7B8E631CDF07;
            end
      8'd218: begin
              C3=47'h009AAA9C3927;C2=47'h7AF5F4D4587B;C1=47'h12AE39E1FAEB;C0=47'h71F66AF91D5F;
              Q2=47'h7E51FC840DD1;Q1=47'h0C7425BA2494;Q0=47'h75CF4CFADC77;
              L1=47'h063A12CFABC7;L0=47'h7B949EDE8BA2;
            end
      8'd219: begin
              C3=47'h0099B176F077;C2=47'h7AFB5FABCE5A;C1=47'h12A42CA60FA0;C0=47'h71FCA27CC654;
              Q2=47'h7E53CB0D1BF7;Q1=47'h0C6D7149FBF4;Q0=47'h75D585608FBB;
              L1=47'h0636B897AED9;L0=47'h7B9AD7443061;
            end
      8'd220: begin
              C3=47'h0098BA58A981;C2=47'h7B00C21F5028;C1=47'h129A2999B9A1;C0=47'h7202D709A997;
              Q2=47'h7E5596AD6469;Q1=47'h0C66C40E5F97;Q0=47'h75DBBA6DA129;
              L1=47'h063361F9DA59;L0=47'h7BA10C516A56;
            end
      8'd221: begin
              C3=47'h0097C4D8B39C;C2=47'h7B061E6CBE6D;C1=47'h12902C9EE4FA;C0=47'h72090B28A3B8;
              Q2=47'h7E575F6B5199;Q1=47'h0C601DFB09C0;Q0=47'h75E1EC264B46;
              L1=47'h06300EF06322;L0=47'h7BA73E09D0B0;
            end
      8'd222: begin
              C3=47'h0096D1E2AB21;C2=47'h7B0B6F625A5B;C1=47'h12863F753562;C0=47'h720F38C419C5;
              Q2=47'h7E59254CD230;Q1=47'h0C597F055CA7;Q0=47'h75E81A8D4F1B;
              L1=47'h062CBF758A62;L0=47'h7BAD6C70F502;
            end
      8'd223: begin
              C3=47'h0095E072AEB6;C2=47'h7B10BAA3DA4D;C1=47'h127C57A5B8CD;C0=47'h721566588CE0;
              Q2=47'h7E5AE85843AF;Q1=47'h0C52E720F810;Q0=47'h75EE45A72309;
              L1=47'h062973839D9D;L0=47'h7BB3978A6301;
            end
      8'd224: begin
              C3=47'h0094F1AF62F5;C2=47'h7B15F9AE516D;C1=47'h127281721B33;C0=47'h721B8C38E369;
              Q2=47'h7E5CA8936743;Q1=47'h0C4C56439FCF;Q0=47'h75F46D764E36;
              L1=47'h06262B14F66E;L0=47'h7BB9BF59A0D2;
            end
      8'd225: begin
              C3=47'h0094048CCC9F;C2=47'h7B1B3257E959;C1=47'h1268B1FC02B6;C0=47'h7221B1279649;
              Q2=47'h7E5E6604649C;Q1=47'h0C45CC617407;Q0=47'h75FA91FEF14E;
              L1=47'h0622E623FA7C;L0=47'h7BBFE3E22EEC;
            end
      8'd226: begin
              C3=47'h009319ABA926;C2=47'h7B20610AE62F;C1=47'h125EF0102FB0;C0=47'h7227D0DB99FD;
              Q2=47'h7E6020B10F57;Q1=47'h0C3F496FAC7F;Q0=47'h7600B34437A1;
              L1=47'h061FA4AB1B56;L0=47'h7BC605278829;
            end
      8'd227: begin
              C3=47'h00923046EEE5;C2=47'h7B258A1574F3;C1=47'h125533A23948;C0=47'h722DF05C3CCC;
              Q2=47'h7E61D89F501A;Q1=47'h0C38CD630EBA;Q0=47'h7606D149C867;
              L1=47'h061C66A4D644;L0=47'h7BCC232D21F1;
            end
      8'd228: begin
              C3=47'h00914966D4BA;C2=47'h7B2AA7939403;C1=47'h124B87E175E4;C0=47'h72340898BC9B;
              Q2=47'h7E638DD5029F;Q1=47'h0C3258306D5C;Q0=47'h760CEC134F7B;
              L1=47'h06192C0BB442;L0=47'h7BD23DF66C0D;
            end
      8'd229: begin
              C3=47'h009063608862;C2=47'h7B2FC2F121ED;C1=47'h1241DB098C7C;C0=47'h723A24BFA08B;
              Q2=47'h7E654057BF50;Q1=47'h0C2BE9CD771D;Q0=47'h761303A3B8D9;
              L1=47'h0615F4DA49BD;L0=47'h7BD85586D10A;
            end
      8'd230: begin
              C3=47'h008F8049C666;C2=47'h7B34D048A0BA;C1=47'h123843B58A8D;C0=47'h72403682CE6E;
              Q2=47'h7E66F02D3CB3;Q1=47'h0C25822F46EF;Q0=47'h761917FE8C30;
              L1=47'h0612C10B36A5;L0=47'h7BDE69E1B5D2;
            end
      8'd231: begin
              C3=47'h008E9E98BCE8;C2=47'h7B39D84F9E99;C1=47'h122EB170CEEE;C0=47'h72464842C6F3;
              Q2=47'h7E689D5B1EBC;Q1=47'h0C1F214B1C0A;Q0=47'h761F29273F0C;
              L1=47'h060F9099261C;L0=47'h7BE47B0A7A2C;
            end
      8'd232: begin
              C3=47'h008DBF3D0ABF;C2=47'h7B3ED5A2FDF8;C1=47'h12252E8BB04B;C0=47'h724C536DF56F;
              Q2=47'h7E6A47E704A5;Q1=47'h0C18C71625D0;Q0=47'h762537216647;
              L1=47'h060C637ECE89;L0=47'h7BEA8904785A;
            end
      8'd233: begin
              C3=47'h008CE10BD78A;C2=47'h7B43CEE5E650;C1=47'h121BAE6CBB77;C0=47'h725260009245;
              Q2=47'h7E6BEFD65904;Q1=47'h0C1273863ADC;Q0=47'h762B41F00754;
              L1=47'h060939B6F147;L0=47'h7BF093D30590;
            end
      8'd234: begin
              C3=47'h008C053BA1FF;C2=47'h7B48BD1A31C9;C1=47'h12123E7EF7D3;C0=47'h72586568DC0D;
              Q2=47'h7E6D952E91BB;Q1=47'h0C0C2690E64E;Q0=47'h763149967EE3;
              L1=47'h0606133C5AC7;L0=47'h7BF69B797193;
            end
      8'd235: begin
              C3=47'h008B2A8BA24F;C2=47'h7B4DA767C3B8;C1=47'h1208D11E3310;C0=47'h725E6C552FAC;
              Q2=47'h7E6F37F51C72;Q1=47'h0C05E02BB1E7;Q0=47'h76374E183AD0;
              L1=47'h0602F009E227;L0=47'h7BFC9FFB0733;
            end
      8'd236: begin
              C3=47'h008A51AD6F81;C2=47'h7B5289C8CB95;C1=47'h11FF6E0BC172;C0=47'h72646FCD0E31;
              Q2=47'h7E70D82F3BF2;Q1=47'h0BFFA04CABBE;Q0=47'h763D4F78396C;
              L1=47'h05FFD01A6962;L0=47'h7C02A15B0BE8;
            end
      8'd237: begin
              C3=47'h00897B1251A9;C2=47'h7B5761A2D48D;C1=47'h11F61A5CFE48;C0=47'h726A6C84E710;
              Q2=47'h7E7275E24C0B;Q1=47'h0BF966E961D8;Q0=47'h76434DBA033E;
              L1=47'h05FCB368DD06;L0=47'h7C089F9CC02B;
            end
      8'd238: begin
              C3=47'h0088A5D84684;C2=47'h7B5C3404AF4C;C1=47'h11ECCC645C66;C0=47'h727068AC1D13;
              Q2=47'h7E7411136BD8;Q1=47'h0BF333F82C7A;Q0=47'h764948E06D57;
              L1=47'h05F999F03417;L0=47'h7C0E9AC35F6F;
            end
      8'd239: begin
              C3=47'h0087D26C1E21;C2=47'h7B60FE6F3569;C1=47'h11E389000766;C0=47'h7276611C1660;
              Q2=47'h7E75A9C7F31F;Q1=47'h0BED076E69ED;Q0=47'h764F40EF4CFC;
              L1=47'h05F683AB7011;L0=47'h7C1492D22014;
            end
      8'd240: begin
              C3=47'h008700B15B7B;C2=47'h7B65C17D04EE;C1=47'h11DA4F14A37E;C0=47'h727C5684980B;
              Q2=47'h7E774004F830;Q1=47'h0BE6E1425608;Q0=47'h765535E9B0E4;
              L1=47'h05F370959CBC;L0=47'h7C1A87CC3378;
            end
      8'd241: begin
              C3=47'h008630DE11E5;C2=47'h7B6A7BE8B909;C1=47'h11D1212931FC;C0=47'h7282473C41C1;
              Q2=47'h7E78D3CF6160;Q1=47'h0BE0C16AC894;Q0=47'h765B27D21ED4;
              L1=47'h05F060A9D00A;L0=47'h7C2079B4C624;
            end
      8'd242: begin
              C3=47'h008562B4732B;C2=47'h7B6F2F0F3D3C;C1=47'h11C7FCA8E29B;C0=47'h728834E721E0;
              Q2=47'h7E7A652C523B;Q1=47'h0BDAA7DD8DC4;Q0=47'h766116AC2E8F;
              L1=47'h05ED53E32A07;L0=47'h7C26688EFFA9;
            end
      8'd243: begin
              C3=47'h008495D7483F;C2=47'h7B73DD0839EF;C1=47'h11BEDD8D1325;C0=47'h728E221D4589;
              Q2=47'h7E7BF420EBBF;Q1=47'h0BD494905CCB;Q0=47'h7667027B9BCE;
              L1=47'h05EA4A3CD4C5;L0=47'h7C2C545E02C3;
            end
      8'd244: begin
              C3=47'h0083CAA1D1FC;C2=47'h7B7883B5B91B;C1=47'h11B5C801A03A;C0=47'h72940C2483E3;
              Q2=47'h7E7D80B1D1C9;Q1=47'h0BCE877AB6E2;Q0=47'h766CEB427266;
              L1=47'h05E743B2042D;L0=47'h7C323D24ED68;
            end
      8'd245: begin
              C3=47'h0083017DDA98;C2=47'h7B7D209FE1FE;C1=47'h11ACC0EB42D6;C0=47'h7299EFC43F39;
              Q2=47'h7E7F0AE3F3C4;Q1=47'h0BC88092D9F8;Q0=47'h7672D10406F4;
              L1=47'h05E4403DF605;L0=47'h7C3822E6D8A7;
            end
      8'd246: begin
              C3=47'h008239C86E58;C2=47'h7B81B7788FD1;C1=47'h11A3C11F6DB4;C0=47'h729FD1A186BC;
              Q2=47'h7E8092BC5FBC;Q1=47'h0BC27FCE6DE0;Q0=47'h7678B3C45047;
              L1=47'h05E13FDBF1B7;L0=47'h7C3E05A6D8F3;
            end
      8'd247: begin
              C3=47'h00817362251C;C2=47'h7B8648F113B5;C1=47'h119AC74C5643;C0=47'h72A5B295B9E1;
              Q2=47'h7E82183FB188;Q1=47'h0BBC8524BCF4;Q0=47'h767E9385B980;
              L1=47'h05DE4287484A;L0=47'h7C43E567FE02;
            end
      8'd248: begin
              C3=47'h0080AEE6D2C0;C2=47'h7B8AD168DDD2;C1=47'h1191DAA1887D;C0=47'h72AB8DE535D5;
              Q2=47'h7E839B728A35;Q1=47'h0BB6908CE198;Q0=47'h7684704AE9CA;
              L1=47'h05DB483B5455;L0=47'h7C49C22D52C5;
            end
      8'd249: begin
              C3=47'h007FEB6AFB67;C2=47'h7B8F56468D3F;C1=47'h1188F088840E;C0=47'h72B16A7E3514;
              Q2=47'h7E851C59C379;Q1=47'h0BB0A1FCFACB;Q0=47'h768A4A178DB2;
              L1=47'h05D850F379C2;L0=47'h7C4F9BF9DDBB;
            end
      8'd250: begin
              C3=47'h007F2A17DFAA;C2=47'h7B93D0A13032;C1=47'h118016B1989C;C0=47'h72B73F59BA41;
              Q2=47'h7E869AF9E675;Q1=47'h0BAAB96C48E3;Q0=47'h769020EE42C6;
              L1=47'h05D55CAB25D6;L0=47'h7C5572D0A0AF;
            end
      8'd251: begin
              C3=47'h007E69FB4C94;C2=47'h7B98460A9A8F;C1=47'h1177422A6CF6;C0=47'h72BD13A6A275;
              Q2=47'h7E8817579D72;Q1=47'h0BA4D6D16DD6;Q0=47'h7695F4D25053;
              L1=47'h05D26B5DCF0E;L0=47'h7C5B46B498F1;
            end
      8'd252: begin
              C3=47'h007DAB97F24F;C2=47'h7B9CB37166A2;C1=47'h116E7913A4F8;C0=47'h72C2E353A432;
              Q2=47'h7E8991776914;Q1=47'h0B9EFA2394B1;Q0=47'h769BC5C683E1;
              L1=47'h05CF7D06F51F;L0=47'h7C6117A8BF14;
            end
      8'd253: begin
              C3=47'h007CEE9CCDA7;C2=47'h7BA11AAE86A5;C1=47'h1165B7D0CE2B;C0=47'h72C8B0BDE2BC;
              Q2=47'h7E8B095DD9D3;Q1=47'h0B9923598E9E;Q0=47'h76A193CE1189;
              L1=47'h05CC91A220AB;L0=47'h7C66E5B0077B;
            end
      8'd254: begin
              C3=47'h007C32BC7A8A;C2=47'h7BA57D88AC85;C1=47'h115CFAE33098;C0=47'h72CE7E33193C;
              Q2=47'h7E8C7F0F3193;Q1=47'h0B93526B4AA4;Q0=47'h76A75EEB1E40;
              L1=47'h05C9A92AE359;L0=47'h7C6CB0CD61EB;
            end
      8'd255: begin
              C3=47'h007B78E087DA;C2=47'h7BA9D6823757;C1=47'h11544D4A1C8C;C0=47'h72D4445EAABB;
              Q2=47'h7E8DF29017A7;Q1=47'h0B8D874F0923;Q0=47'h76AD27218901;
              L1=47'h05C6C39CD7A5;L0=47'h7C727903B9D5;
            end
     endcase
  end

  
  // assign the coefficients
  assign coef3_sh_dist = ((`coef_max_size-`coef3_size)<0)?0:
                            $unsigned(`coef_max_size-`coef3_size);
  assign coef2_sh_dist = ((`coef_max_size-`coef2_size)<0)?0:
                            $unsigned(`coef_max_size-`coef2_size);
  assign coef1_sh_dist = ((`coef_max_size-`coef1_size)<0)?0:
                            $unsigned(`coef_max_size-`coef1_size);
  assign coef0_sh_dist = ((`coef_max_size-`coef0_size)<0)?0:
                            $unsigned(`coef_max_size-`coef0_size);
  assign Coef3 = (op_width < `min_op_width_cubic)?0:
                $signed(C3) >>> coef3_sh_dist;
  assign Coef2 = (op_width < `min_op_width_quadratic)?0:
                (op_width < `min_op_width_cubic)?
	           $signed(Q2) >>> coef2_sh_dist:
	           $signed(C2) >>> coef2_sh_dist;
  assign Coef1 = (op_width < `min_op_width_linear)?0:
                (op_width < `min_op_width_quadratic)?
                    $signed(L1) >>> coef1_sh_dist:
                    (op_width < `min_op_width_cubic)?   
                       $signed(Q1) >>> coef1_sh_dist:
	               $signed(C1) >>> coef1_sh_dist;
  assign Coef0 = (op_width < `min_op_width_linear)?0:
                (op_width < `min_op_width_quadratic)?
                   $signed(L0) >>> coef0_sh_dist:
                   (op_width < `min_op_width_cubic)?   
                     $signed(Q0) >>> coef0_sh_dist:
                     $signed(C0) >>> coef0_sh_dist;
  // compute the polynomial using Horner's method
  assign p3 = $signed(Coef3) * $signed({1'b0,a}) + $signed({Coef2,{op_width-1+`bits{1'b0}}});
  assign p3_aligned = $signed(p3) >>> (op_width-1+`bits);
  assign p2 = $signed(p3_aligned) * $signed({1'b0,a}) + $signed({Coef1,{op_width-1{1'b0}}});
  assign p2_aligned = $signed(p2) >>> (op_width-1);
  assign p1 = $signed(p2_aligned) * $signed({1'b0,a}) + $signed({Coef0,{op_width-1{1'b0}}});
  assign p1_aligned = p1;
  assign z_int = p1_aligned[`prod1_MSB-4:`prod1_MSB-4-`z_int_size+1];
  assign z_round =  z_int[`z_int_size-2:`z_int_size-2-`z_round_MSB]+
                    {1'b1,{`chain-1{1'b0}}};
  assign z_poly = z_round[`z_round_MSB:`z_round_MSB-op_width+1];

//----------------------------------------------------------------------
// The following commands describe the computation of log2 using 
// polynomial approximation. It is a better implementation of the
// approximation algorithm
//
// The defines for this portion of the code is the same as the 
// defines for the previous one. 

  wire signed [`coef3_size-1:0] Coef3_new;
  wire signed [`coef2_size-1:0] Coef2_new;
  wire signed [`coef1_size-1:0] Coef1_new;
  wire signed [`coef0_size-1:0] Coef0_new;
  wire signed [`prod1_MSB:0] p1_new; 
  wire signed [`prod2_MSB:0] p2_new; 
  wire signed [`prod3_MSB:0] p3_new;
  wire signed [`prod1_MSB:0] p1_aligned_new;
  wire signed [`prod2_MSB:0] p2_aligned_new;
  wire signed [`prod3_MSB:0] p3_aligned_new;
  wire [`z_int_size-1:0] z_int_new;
  reg  [`table_addrsize-1:0] addr_new;
  reg [op_width-1:0] short_a;  // value of a without MS bits 
                              // (remove address bits)
  wire [2*op_width-1:0] a_square;
  wire [op_width+`extra_LSBs-1:0] a_square_trunc;
  wire [3*op_width-1:0] a_cube;
  wire [op_width+`extra_LSBs-1:0] a_cube_trunc;
  wire [op_width-1:0] z_poly_new;
  wire [`z_round_MSB:0] z_round_new;
  wire [7:0] coef3_sh_dist_new, coef2_sh_dist_new, coef1_sh_dist_new, coef0_sh_dist_new;
  // Declare the table outputs and include the table output definitions 
  reg [`coef_max_size-1:0]  C3_new, // cubic approx. coefficients
		            C2_new,
                            C1_new,
                            C0_new,
                            Q2_new, // quadratic approx. coefficients
                            Q1_new,
                            Q0_new,
                            L1_new, // linear approx. coefficients
                            L0_new;

  // fill in zeros when a is smaller than the table address field
  always @ (a)
  begin
    if (op_width-1-`table_addrsize <= 0)
      addr_new = a[op_width-2:0] << (`table_addrsize-op_width+1);
    else
      addr_new = a[op_width-2:op_width-2-`table_addrsize+1];
    short_a = (a << (`table_addrsize+1)) >> (`table_addrsize+1);
     case (addr_new)
      8'd0: begin
              C3_new=47'h03D32246D962;C2_new=47'h7A3AB1D5C3D6;C1_new=47'h0B8AA3B1C545;C0_new=47'h00000000000A;
              Q2_new=47'h7A406E892D6B;Q1_new=47'h0B8AA1676F49;Q0_new=47'h00000000306C;
              L1_new=47'h0B84E1D5F876;L0_new=47'h000000F47E12;
            end
      8'd1: begin
              C3_new=47'h03C7C5564EBF;C2_new=47'h7A462B31D80D;C1_new=47'h0B7F248D3A7F;C0_new=47'h000B84E236C7;
              Q2_new=47'h7A4BD6D9DA68;Q1_new=47'h0B7F2249B277;Q0_new=47'h000B84E2669A;
              L1_new=47'h0B796E208C52;L0_new=47'h000B85D4CF6E;
            end
      8'd2: begin
              C3_new=47'h03BC95255266;C2_new=47'h7A5182776249;C1_new=47'h0B73BC395760;C0_new=47'h0016FE50B6F8;
              Q2_new=47'h7A571D571720;Q1_new=47'h0B73B9FC8287;Q0_new=47'h0016FE50E63E;
              L1_new=47'h0B6E1119D99E;L0_new=47'h0016FF416FDF;
            end
      8'd3: begin
              C3_new=47'h03B1910813B5;C2_new=47'h7A5CB82C92B4;C1_new=47'h0B686A72750E;C0_new=47'h00226C622F5C;
              Q2_new=47'h7A624286226F;Q1_new=47'h0B68683C38F3;Q0_new=47'h00226C625E16;
              L1_new=47'h0B62CA7EBF17;L0_new=47'h00226D510E0B;
            end
      8'd4: begin
              C3_new=47'h03A6B81AF1D9;C2_new=47'h7A67CCD56AFE;C1_new=47'h0B5D2EF5F6F3;C0_new=47'h002DCF2D0B8F;
              Q2_new=47'h7A6D46E99383;Q1_new=47'h0B5D2CC639C5;Q0_new=47'h002DCF2D39BF;
              L1_new=47'h0B579A0D2358;L0_new=47'h002DD01A157A;
            end
      8'd5: begin
              C3_new=47'h039C0949BB00;C2_new=47'h7A72C0F3C2C9;C1_new=47'h0B520982459E;C0_new=47'h003926C77513;
              Q2_new=47'h7A782B01B01C;Q1_new=47'h0B520758EE24;Q0_new=47'h003926C7A2BD;
              L1_new=47'h0B4C7F83EFD4;L0_new=47'h003927B2AF99;
            end
      8'd6: begin
              C3_new=47'h03918431165C;C2_new=47'h7A7D9505D889;C1_new=47'h0B46F9D6CA8B;C0_new=47'h004473475456;
              Q2_new=47'h7A82EF4C2563;Q1_new=47'h0B46F7B3BFC1;Q0_new=47'h00447347817A;
              L1_new=47'h0B417AA30BE7;L0_new=47'h00447430C4C0;
            end
      8'd7: begin
              C3_new=47'h038727AE02FC;C2_new=47'h7A884988CBF3;C1_new=47'h0B3BFFB3EA0F;C0_new=47'h004FB4C251AA;
              Q2_new=47'h7A8D94445261;Q1_new=47'h0B3BFD9713AF;Q0_new=47'h004FB4C27E4B;
              L1_new=47'h0B368B2B5802;L0_new=47'h004FB5A9FD2E;
            end
      8'd8: begin
              C3_new=47'h037CF325C958;C2_new=47'h7A92DEF6895D;C1_new=47'h0B311ADAFF9B;C0_new=47'h005AEB4DD645;
              Q2_new=47'h7A981A633B5E;Q1_new=47'h0B3118C445BC;Q0_new=47'h005AEB4E0265;
              L1_new=47'h0B2BB0DEA8F7;L0_new=47'h005AEC33C203;
            end
      8'd9: begin
              C3_new=47'h0372E5E88A47;C2_new=47'h7A9D55C6D175;C1_new=47'h0B264B0E58A9;C0_new=47'h006616FF0D2E;
              Q2_new=47'h7AA2821FB19B;Q1_new=47'h0B2648FDA3AE;Q0_new=47'h006616FF38CF;
              L1_new=47'h0B20EB7FC360;L0_new=47'h006617E33E34;
            end
      8'd10: begin
              C3_new=47'h0368FF0E492B;C2_new=47'h7AA7AE6F9560;C1_new=47'h0B1B90112FF7;C0_new=47'h007137EAE433;
              Q2_new=47'h7AACCBEE27A1;Q1_new=47'h0B1B8E0668F7;Q0_new=47'h007137EB0F57;
              L1_new=47'h0B163AD2571E;L0_new=47'h007138CD5F7C;
            end
      8'd11: begin
              C3_new=47'h035F3E002483;C2_new=47'h7AB1E9640AB1;C1_new=47'h0B10E9A7A99D;C0_new=47'h007C4E260CD1;
              Q2_new=47'h7AB6F841084E;Q1_new=47'h0B10E7A2B9EC;Q0_new=47'h007C4E26377A;
              L1_new=47'h0B0B9E9AFAF6;L0_new=47'h007C4F06D743;
            end
      8'd12: begin
              C3_new=47'h0355A1F370CE;C2_new=47'h7ABC0715A051;C1_new=47'h0B065796CE38;C0_new=47'h008759C4FD1D;
              Q2_new=47'h7AC107888393;Q1_new=47'h0B0655979FB8;Q0_new=47'h008759C5274C;
              L1_new=47'h0B01169F283B;L0_new=47'h00875AA41B8C;
            end
      8'd13: begin
              C3_new=47'h034C2A7D24AF;C2_new=47'h7AC607F31007;C1_new=47'h0AFBD9A4872C;C0_new=47'h00925ADBF0A3;
              Q2_new=47'h7ACAFA32CCAD;Q1_new=47'h0AFBD7AB03DD;Q0_new=47'h00925ADC1A5A;
              L1_new=47'h0AF6A2A536A9;L0_new=47'h00925BB967D0;
            end
      8'd14: begin
              C3_new=47'h0342D691BA14;C2_new=47'h7ACFEC6A1F7B;C1_new=47'h0AF16F97999A;C0_new=47'h009D517EE947;
              Q2_new=47'h7AD4D0ABFB38;Q1_new=47'h0AF16DA3AC41;Q0_new=47'h009D517F1288;
              L1_new=47'h0AEC4274583C;L0_new=47'h009D525ABDE4;
            end
      8'd15: begin
              C3_new=47'h0339A5C267A6;C2_new=47'h7AD9B4E58AEB;C1_new=47'h0AE71937A36B;C0_new=47'h00A83DC1B022;
              Q2_new=47'h7ADE8B5E2E68;Q1_new=47'h0AE717493703;Q0_new=47'h00A83DC1D8EE;
              L1_new=47'h0AE1F5D49531;L0_new=47'h00A83E9BE6CB;
            end
      8'd16: begin
              C3_new=47'h0330976768D6;C2_new=47'h7AE361CE7FE3;C1_new=47'h0ADCD64D1694;C0_new=47'h00B31FB7D650;
              Q2_new=47'h7AE82AB19EF9;Q1_new=47'h0ADCD4641675;Q0_new=47'h00B31FB7FEAA;
              L1_new=47'h0AD7BC8EC814;L0_new=47'h00B320907394;
            end
      8'd17: begin
              C3_new=47'h0327AAB3D78A;C2_new=47'h7AECF38C8141;C1_new=47'h0AD2A6A13550;C0_new=47'h00BDF774B5CC;
              Q2_new=47'h7AF1AF0C8FD4;Q1_new=47'h0AD2A4BD8D5C;Q0_new=47'h00BDF774DDB6;
              L1_new=47'h0ACD966C99EB;L0_new=47'h00BDF84BBE26;
            end
      8'd18: begin
              C3_new=47'h031EDF46313D;C2_new=47'h7AF66A8488C9;C1_new=47'h0AC889FE0EBB;C0_new=47'h00C8C50B7239;
              Q2_new=47'h7AFB18D37480;Q1_new=47'h0AC8881FAAFE;Q0_new=47'h00C8C50B99B3;
              L1_new=47'h0AC383387E72;L0_new=47'h00C8C5E0EA14;
            end
      8'd19: begin
              C3_new=47'h03163445E24F;C2_new=47'h7AFFC71A7DCC;C1_new=47'h0ABE802E7A73;C0_new=47'h00D3888EF9AB;
              Q2_new=47'h7B046868E568;Q1_new=47'h0ABE7E554789;Q0_new=47'h00D3888F20B8;
              L1_new=47'h0AB982BDB06D;L0_new=47'h00D38962E562;
            end
      8'd20: begin
              C3_new=47'h030DA9586948;C2_new=47'h7B0909AFB53F;C1_new=47'h0AB488FE15A8;C0_new=47'h00DE42120574;
              Q2_new=47'h7B0D9E2DBC31;Q1_new=47'h0AB4872A0054;Q0_new=47'h00DE42122C15;
              L1_new=47'h0AAF94C82E10;L0_new=47'h00DE42E46952;
            end
      8'd21: begin
              C3_new=47'h03053DD31FD5;C2_new=47'h7B1232A44618;C1_new=47'h0AAAA4393EFB;C0_new=47'h00E8F1A71AE3;
              Q2_new=47'h7B16BA81051C;Q1_new=47'h0AAAA26A3472;Q0_new=47'h00E8F1A74119;
              L1_new=47'h0AA5B924B577;L0_new=47'h00E8F277FB22;
            end
      8'd22: begin
              C3_new=47'h02FCF12A42D0;C2_new=47'h7B1B42566839;C1_new=47'h0AA0D1AD1342;C0_new=47'h00F397608C04;
              Q2_new=47'h7B1FBDC0246C;Q1_new=47'h0AA0CFE30110;Q0_new=47'h00F39760B1D1;
              L1_new=47'h0A9BEFA0C133;L0_new=47'h00F3982FECD0;
            end
      8'd23: begin
              C3_new=47'h02F4C2CC6812;C2_new=47'h7B243922A787;C1_new=47'h0A9711276A23;C0_new=47'h00FE3350785F;
              Q2_new=47'h7B28A846DC3E;Q1_new=47'h0A970F623E16;Q0_new=47'h00FE33509DC4;
              L1_new=47'h0A92380A84F2;L0_new=47'h00FE341E5DD4;
            end
      8'd24: begin
              C3_new=47'h02ECB21409A8;C2_new=47'h7B2D17641F04;C1_new=47'h0A8D6276D28C;C0_new=47'h0108C588CDAE;
              Q2_new=47'h7B317A6F37EA;Q1_new=47'h0A8D60B67AF3;Q0_new=47'h0108C588F2AE;
              L1_new=47'h0A889230EA2A;L0_new=47'h0108C6553BDA;
            end
      8'd25: begin
              C3_new=47'h02E4BED758C6;C2_new=47'h7B35DD7373CA;C1_new=47'h0A83C56A9009;C0_new=47'h01134E1B4897;
              Q2_new=47'h7B3A3491B68F;Q1_new=47'h0A83C3AEFB2D;Q0_new=47'h01134E1B6D32;
              L1_new=47'h0A7EFDE38CE3;L0_new=47'h01134EE64377;
            end
      8'd26: begin
              C3_new=47'h02DCE803DEBD;C2_new=47'h7B3E8BA9493C;C1_new=47'h0A7A39D29658;C0_new=47'h011DCD197559;
              Q2_new=47'h7B42D705492D;Q1_new=47'h0A7A381BB343;Q0_new=47'h011DCD199991;
              L1_new=47'h0A757AF2B88C;L0_new=47'h011DCDE300DE;
            end
      8'd27: begin
              C3_new=47'h02D52DA94F32;C2_new=47'h7B47225AD009;C1_new=47'h0A70BF7F8801;C0_new=47'h01284294B081;
              Q2_new=47'h7B4B621F4DAD;Q1_new=47'h0A70BDCD4598;Q0_new=47'h01284294D457;
              L1_new=47'h0A6C092F64E5;L0_new=47'h0128435CD08C;
            end
      8'd28: begin
              C3_new=47'h02CD8EEE0BE3;C2_new=47'h7B4FA1DD46B5;C1_new=47'h0A675642B18C;C0_new=47'h0132AE9E2791;
              Q2_new=47'h7B53D633B12F;Q1_new=47'h0A675494FF46;Q0_new=47'h0132AE9E4B07;
              L1_new=47'h0A62A86B32F8;L0_new=47'h0132AF64DFF7;
            end
      8'd29: begin
              C3_new=47'h02C60B6EC8B9;C2_new=47'h7B580A83ABE6;C1_new=47'h0A5DFDEE07B0;C0_new=47'h013D1146D9AF;
              Q2_new=47'h7B5C3394CC1A;Q1_new=47'h0A5DFC44D550;Q0_new=47'h013D1146FCC5;
              L1_new=47'h0A5958786A1C;L0_new=47'h013D120C2E35;
            end
      8'd30: begin
              C3_new=47'h02BEA2ADB94A;C2_new=47'h7B605C9FB6F4;C1_new=47'h0A54B65423EB;C0_new=47'h01476A9F9846;
              Q2_new=47'h7B647A93B93C;Q1_new=47'h0A54B4AF615D;Q0_new=47'h01476A9FBAFE;
              L1_new=47'h0A501929F516;L0_new=47'h01476B638CA5;
            end
      8'd31: begin
              C3_new=47'h02B754212711;C2_new=47'h7B689881D724;C1_new=47'h0A4B7F48419F;C0_new=47'h0151BAB907AC;
              Q2_new=47'h7B6CAB8002EC;Q1_new=47'h0A4B7DA7DF3A;Q0_new=47'h0151BAB92A08;
              L1_new=47'h0A46EA535F3D;L0_new=47'h0151BB7B9F8F;
            end
      8'd32: begin
              C3_new=47'h02B01FC41A37;C2_new=47'h7B70BE782D47;C1_new=47'h0A42589E3BD7;C0_new=47'h015C01A39FC3;
              Q2_new=47'h7B74C6A7D33F;Q1_new=47'h0A42570229E2;Q0_new=47'h015C01A3C1C4;
              L1_new=47'h0A3DCBC8D1B4;L0_new=47'h015C0264DEC9;
            end
      8'd33: begin
              C3_new=47'h02A90480ACDF;C2_new=47'h7B78CED15AD8;C1_new=47'h0A39422A8918;C0_new=47'h01663F6FAC97;
              Q2_new=47'h7B7CCC5817D0;Q1_new=47'h0A394092B896;Q0_new=47'h01663F6FCE3E;
              L1_new=47'h0A34BD5F10AD;L0_new=47'h0166402F9652;
            end
      8'd34: begin
              C3_new=47'h02A20240D616;C2_new=47'h7B80C9D8F8E2;C1_new=47'h0A303BC23A79;C0_new=47'h0170742D4EF6;
              Q2_new=47'h7B84BCDC531D;Q1_new=47'h0A303A2E9C6E;Q0_new=47'h0170742D7044;
              L1_new=47'h0A2BBEEB78BF;L0_new=47'h017074EBE6EA;
            end
      8'd35: begin
              C3_new=47'h029B18605780;C2_new=47'h7B88AFDA464D;C1_new=47'h0A27453AF7AD;C0_new=47'h017A9FEC7D0C;
              Q2_new=47'h7B8C987ECFCB;Q1_new=47'h0A2743AB7D7E;Q0_new=47'h017A9FEC9E03;
              L1_new=47'h0A22D043FC4E;L0_new=47'h017AA0A9C6B1;
            end
      8'd36: begin
              C3_new=47'h029446FD5D18;C2_new=47'h7B90811DF669;C1_new=47'h0A1E5E6AFD85;C0_new=47'h0184C2BD02F6;
              Q2_new=47'h7B945F887264;Q1_new=47'h0A1E5CDF987E;Q0_new=47'h0184C2BD2397;
              L1_new=47'h0A19F13F20F1;L0_new=47'h0184C37901BA;
            end
      8'd37: begin
              C3_new=47'h028D8D08469A;C2_new=47'h7B983DED81A5;C1_new=47'h0A15872919C7;C0_new=47'h018EDCAE8358;
              Q2_new=47'h7B9C12410CFA;Q1_new=47'h0A1585A1BBEB;Q0_new=47'h018EDCAEA3A4;
              L1_new=47'h0A1121B3FCF9;L0_new=47'h018EDD693A9C;
            end
      8'd38: begin
              C3_new=47'h0286EA92F242;C2_new=47'h7B9FE68F3404;C1_new=47'h0A0CBF4CAAAF;C0_new=47'h0198EDD077EC;
              Q2_new=47'h7BA3B0EF13AD;Q1_new=47'h0A0CBDC945E5;Q0_new=47'h0198EDD097E4;
              L1_new=47'h0A08617A34FA;L0_new=47'h0198EE89EB04;
            end
      8'd39: begin
              C3_new=47'h02805EEA89E5;C2_new=47'h7BA77B4982E6;C1_new=47'h0A0406AD9AD3;C0_new=47'h01A2F6323211;
              Q2_new=47'h7BAB3BD7E2A1;Q1_new=47'h0A04052E217C;Q0_new=47'h01A2F63251B6;
              L1_new=47'h09FFB069F95E;L0_new=47'h01A2F6EA6446;
            end
      8'd40: begin
              C3_new=47'h0279E9DDF1B8;C2_new=47'h7BAEFC60DB15;C1_new=47'h09FB5D245FDC;C0_new=47'h01ACF5E2DB54;
              Q2_new=47'h7BB2B33FADD4;Q1_new=47'h09FB5BA8C464;Q0_new=47'h01ACF5E2FAA7;
              L1_new=47'h09F70E5C0412;L0_new=47'h01ACF699CFE5;
            end
      8'd41: begin
              C3_new=47'h02738ADA9CA3;C2_new=47'h7BB66A1921DA;C1_new=47'h09F2C289F781;C0_new=47'h01B6ECF175FF;
              Q2_new=47'h7BBA1769642F;Q1_new=47'h09F2C1122CCA;Q0_new=47'h01B6ECF19501;
              L1_new=47'h09EE7B29962E;L0_new=47'h01B6EDA7301E;
            end
      8'd42: begin
              C3_new=47'h026D41B89B0F;C2_new=47'h7BBDC4B47098;C1_new=47'h09EA36B7E5D4;C0_new=47'h01C0DB6CDD9A;
              Q2_new=47'h7BC16897091A;Q1_new=47'h09EA3543DEAB;Q0_new=47'h01C0DB6CFC4D;
              L1_new=47'h09E5F6AC75B5;L0_new=47'h01C0DC216070;
            end
      8'd43: begin
              C3_new=47'h02670DE8AA00;C2_new=47'h7BC50C7475D8;C1_new=47'h09E1B988325A;C0_new=47'h01CAC163C776;
              Q2_new=47'h7BC8A70951C1;Q1_new=47'h09E1B817E20C;Q0_new=47'h01CAC163E5DB;
              L1_new=47'h09DD80BEEB5D;L0_new=47'h01CAC217161F;
            end
      8'd44: begin
              C3_new=47'h0260EF3997B9;C2_new=47'h7BCC41992E7B;C1_new=47'h09D94AD56680;C0_new=47'h01D49EE4C32B;
              Q2_new=47'h7BCFD30007B6;Q1_new=47'h09D94968C05C;Q0_new=47'h01D49EE4E142;
              L1_new=47'h09D5193BC063;L0_new=47'h01D49F96E0BA;
            end
      8'd45: begin
              C3_new=47'h025AE52EB8C2;C2_new=47'h7BD36462054A;C1_new=47'h09D0EA7A8AEC;C0_new=47'h01DE73FE3B19;
              Q2_new=47'h7BD6ECB9CBD0;Q1_new=47'h09D0E911829C;Q0_new=47'h01DE73FE58E4;
              L1_new=47'h09CCBFFE3C68;L0_new=47'h01DE74AF2A97;
            end
      8'd46: begin
              C3_new=47'h0254EFBDA8C2;C2_new=47'h7BDA750C9EA9;C1_new=47'h09C8985325F3;C0_new=47'h01E840BE74EB;
              Q2_new=47'h7BDDF47442E1;Q1_new=47'h09C896EDAF15;Q0_new=47'h01E840BE926B;
              L1_new=47'h09C474E22358;L0_new=47'h01E8416E3956;
            end
      8'd47: begin
              C3_new=47'h024F0E1B0652;C2_new=47'h7BE173D6E282;C1_new=47'h09C0543B3890;C0_new=47'h01F20533920E;
              Q2_new=47'h7BE4EA6C0BB8;Q1_new=47'h09C052D94759;Q0_new=47'h01F20533AF43;
              L1_new=47'h09BC37C3B365;L0_new=47'h01F205E22E58;
            end
      8'd48: begin
              C3_new=47'h02494033D074;C2_new=47'h7BE860FC7CEC;C1_new=47'h09B81E0F3D99;C0_new=47'h01FBC16B902B;
              Q2_new=47'h7BEBCEDCCE51;Q1_new=47'h09B81CB0C62D;Q0_new=47'h01FBC16BAD17;
              L1_new=47'h09B4087FA2FC;L0_new=47'h01FBC219073F;
            end
      8'd49: begin
              C3_new=47'h024385AF1E45;C2_new=47'h7BEF3CB8A50C;C1_new=47'h09AFF5AC26DC;C0_new=47'h0205757449A5;
              Q2_new=47'h7BF2A2012A61;Q1_new=47'h09AFF4511DA9;Q0_new=47'h020575746649;
              L1_new=47'h09ABE6F31ED3;L0_new=47'h020576209E63;
            end
      8'd50: begin
              C3_new=47'h023DDE4AAE93;C2_new=47'h7BF6074566D4;C1_new=47'h09A7DAEF5B9A;C0_new=47'h020F215B760B;
              Q2_new=47'h7BF96412D6B3;Q1_new=47'h09A7D997B524;Q0_new=47'h020F215B9266;
              L1_new=47'h09A3D2FBC7FC;L0_new=47'h020F2206AB49;
            end
      8'd51: begin
              C3_new=47'h023849BA3B59;C2_new=47'h7BFCC0DBFAA1;C1_new=47'h099FCDB6B665;C0_new=47'h0218C52EAA8A;
              Q2_new=47'h7C00154A8FA0;Q1_new=47'h099FCC62676A;Q0_new=47'h0218C52EC69F;
              L1_new=47'h099BCC77B1F9;L0_new=47'h0218C5D8C316;
            end
      8'd52: begin
              C3_new=47'h0232C7A56711;C2_new=47'h7C0369B4BCD5;C1_new=47'h0997CDE0834E;C0_new=47'h022260FB5A66;
              Q2_new=47'h7C06B5E02F1A;Q1_new=47'h0997CC8F80BD;Q0_new=47'h022260FB7635;
              L1_new=47'h0993D34560EB;L0_new=47'h022261A45903;
            end
      8'd53: begin
              C3_new=47'h022D57AB684F;C2_new=47'h7C0A02073633;C1_new=47'h098FDB4B7E0C;C0_new=47'h022BF4CED765;
              Q2_new=47'h7C0D460ABAD7;Q1_new=47'h098FD9FDBCFF;Q0_new=47'h022BF4CEF2F0;
              L1_new=47'h098BE743C7BA;L0_new=47'h022BF576BECF;
            end
      8'd54: begin
              C3_new=47'h0227F981B536;C2_new=47'h7C108A09E17B;C1_new=47'h0987F5D6D04F;C0_new=47'h023580B65242;
              Q2_new=47'h7C13C6002706;Q1_new=47'h0987F48C4628;Q0_new=47'h023580B66D89;
              L1_new=47'h09840852464F;L0_new=47'h0235815D252A;
            end
      8'd55: begin
              C3_new=47'h0222ACFEB67A;C2_new=47'h7C1701F230B2;C1_new=47'h09801D620FF4;C0_new=47'h023F04BEDB16;
              Q2_new=47'h7C1A35F5B196;Q1_new=47'h09801C1AB21F;Q0_new=47'h023F04BEF61A;
              L1_new=47'h097C3650A7D0;L0_new=47'h023F05649C24;
            end
      8'd56: begin
              C3_new=47'h021D719FE20C;C2_new=47'h7C1D69F54429;C1_new=47'h097851CD3CFE;C0_new=47'h024880F561C5;
              Q2_new=47'h7C20961FAA9F;Q1_new=47'h097850890146;Q0_new=47'h024880F57C87;
              L1_new=47'h0974711F20EF;L0_new=47'h0248819A139A;
            end
      8'd57: begin
              C3_new=47'h0218479CFA78;C2_new=47'h7C23C24630B0;C1_new=47'h097092F8C0B8;C0_new=47'h0251F566B669;
              Q2_new=47'h7C26E6B19F75;Q1_new=47'h097091B79C9A;Q0_new=47'h0251F566D0E9;
              L1_new=47'h096CB89E4E3A;L0_new=47'h0251F60A5B9D;
            end
      8'd58: begin
              C3_new=47'h02132E35C981;C2_new=47'h7C2A0B18E937;C1_new=47'h0968E0C56A92;C0_new=47'h025B621F89B7;
              Q2_new=47'h7C2D27DE3C25;Q1_new=47'h0968DF87542C;Q0_new=47'h025B621FA3F7;
              L1_new=47'h09650CAF3268;L0_new=47'h025B62C224D9;
            end
      8'd59: begin
              C3_new=47'h020E253D9F51;C2_new=47'h7C30449F8503;C1_new=47'h09613B146FF3;C0_new=47'h0264C72C6D69;
              Q2_new=47'h7C3359D766B6;Q1_new=47'h096139D95D6A;Q0_new=47'h0264C72C8769;
              L1_new=47'h095D6D3334D1;L0_new=47'h0264C7CE00FF;
            end
      8'd60: begin
              C3_new=47'h02092C7CC1F2;C2_new=47'h7C366F0B7914;C1_new=47'h0959A1C769E8;C0_new=47'h026E2499D49E;
              Q2_new=47'h7C397CCE2E46;Q1_new=47'h0959A08F5196;Q0_new=47'h026E2499EE5F;
              L1_new=47'h0955DA0C1FC4;L0_new=47'h026E253A6326;
            end
      8'd61: begin
              C3_new=47'h020443DE0B97;C2_new=47'h7C3C8A8D29C6;C1_new=47'h095214C053E1;C0_new=47'h02777A74143F;
              Q2_new=47'h7C3F90F2F910;Q1_new=47'h0952138B2C06;Q0_new=47'h02777A742DC2;
              L1_new=47'h094E531C1EFF;L0_new=47'h02777B13A032;
            end
      8'd62: begin
              C3_new=47'h01FF6AEDEE7B;C2_new=47'h7C429754E606;C1_new=47'h094A93E1899C;C0_new=47'h0280C8C76364;
              Q2_new=47'h7C45967550B4;Q1_new=47'h094A92AF48DA;Q0_new=47'h0280C8C77CAA;
              L1_new=47'h0946D845BE2A;L0_new=47'h0280C965EF2F;
            end
      8'd63: begin
              C3_new=47'h01FAA15B86C0;C2_new=47'h7C4895920123;C1_new=47'h09431F0DC619;C0_new=47'h028A0F9FDBAE;
              Q2_new=47'h7C4B8D840AD8;Q1_new=47'h09431DDE6346;Q0_new=47'h028A0F9FF4B7;
              L1_new=47'h093F696BE752;L0_new=47'h028A103D69B8;
            end
      8'd64: begin
              C3_new=47'h01F5E71BDA4F;C2_new=47'h7C4E85729731;C1_new=47'h093BB6282245;C0_new=47'h02934F0979A7;
              Q2_new=47'h7C51764D402A;Q1_new=47'h093BB4FB9430;Q0_new=47'h02934F099274;
              L1_new=47'h09380671E170;L0_new=47'h02934FA60C51;
            end
      8'd65: begin
              C3_new=47'h01F13BD07735;C2_new=47'h7C5467249FC6;C1_new=47'h0934591412F3;C0_new=47'h029C87101D23;
              Q2_new=47'h7C5750FE4FEE;Q1_new=47'h093457EA50AF;Q0_new=47'h029C871035B5;
              L1_new=47'h0930AF3B4EFF;L0_new=47'h029C87ABB6C3;
            end
      8'd66: begin
              C3_new=47'h01EC9F734B27;C2_new=47'h7C5A3AD4CA4E;C1_new=47'h092D07B56802;C0_new=47'h02A5B7BF8996;
              Q2_new=47'h7C5D1DC3F3F3;Q1_new=47'h092D068E688E;Q0_new=47'h02A5B7BFA1EE;
              L1_new=47'h092963AC2C83;L0_new=47'h02A5B85A2C7D;
            end
      8'd67: begin
              C3_new=47'h01E81186CAE0;C2_new=47'h7C6000AFDC04;C1_new=47'h0925C1F04A51;C0_new=47'h02AEE1236673;
              Q2_new=47'h7C62DCCA2189;Q1_new=47'h0925C0CC050F;Q0_new=47'h02AEE1237E91;
              L1_new=47'h092223A8CF31;L0_new=47'h02AEE1BD14E9;
            end
      8'd68: begin
              C3_new=47'h01E3922456C7;C2_new=47'h7C65B8E0EFC3;C1_new=47'h091E87A93B33;C0_new=47'h02B803473F7E;
              Q2_new=47'h7C688E3C2E93;Q1_new=47'h091E8687A75E;Q0_new=47'h02B803475764;
              L1_new=47'h091AEF15E38E;L0_new=47'h02B803DFFBC7;
            end
      8'd69: begin
              C3_new=47'h01DF20A2E2C4;C2_new=47'h7C6B6393C57B;C1_new=47'h091758C511F8;C0_new=47'h02C11E36852D;
              Q2_new=47'h7C6E3244C006;Q1_new=47'h091757A62751;Q0_new=47'h02C11E369CDA;
              L1_new=47'h0913C5D86C12;L0_new=47'h02C11ECE5181;
            end
      8'd70: begin
              C3_new=47'h01DABCF6F771;C2_new=47'h7C7100F25F21;C1_new=47'h09103528FBC9;C0_new=47'h02CA31FC8CF3;
              Q2_new=47'h7C73C90DCDA9;Q1_new=47'h0910340CB213;Q0_new=47'h02CA31FCA468;
              L1_new=47'h090CA7D5BFE1;L0_new=47'h02CA32936B88;
            end
      8'd71: begin
              C3_new=47'h01D66730A86C;C2_new=47'h7C769125F890;C1_new=47'h09091CBA79DC;C0_new=47'h02D33EA4919E;
              Q2_new=47'h7C7952C0C715;Q1_new=47'h09091BA0C8AB;Q0_new=47'h02D33EA4A8DD;
              L1_new=47'h090594F38974;L0_new=47'h02D33F3A84A0;
            end
      8'd72: begin
              C3_new=47'h01D21EC297EA;C2_new=47'h7C7C14582973;C1_new=47'h09020F5F5FA8;C0_new=47'h02DC4439B3A5;
              Q2_new=47'h7C7ECF865155;Q1_new=47'h09020E483F0F;Q0_new=47'h02DC4439CAAE;
              L1_new=47'h08FE8D17C560;L0_new=47'h02DC44CEBD3A;
            end
      8'd73: begin
              C3_new=47'h01CDE3AF3501;C2_new=47'h7C818AB10898;C1_new=47'h08FB0CFDD281;C0_new=47'h02E542C6F97B;
              Q2_new=47'h7C843F869559;Q1_new=47'h08FB0BE93A79;Q0_new=47'h02E542C7104F;
              L1_new=47'h08F79028C10F;L0_new=47'h02E5435B1BC3;
            end
      8'd74: begin
              C3_new=47'h01C9B59A8A8F;C2_new=47'h7C86F458A82C;C1_new=47'h08F4157C47B1;C0_new=47'h02EE3A574FE3;
              Q2_new=47'h7C89A2E9160C;Q1_new=47'h08F4146A3074;Q0_new=47'h02EE3A576681;
              L1_new=47'h08F09E0D198A;L0_new=47'h02EE3AEA8CF5;
            end
      8'd75: begin
              C3_new=47'h01C59439BB66;C2_new=47'h7C8C51766677;C1_new=47'h08ED28C1838D;C0_new=47'h02F72AF58A39;
              Q2_new=47'h7C8EF9D4B425;Q1_new=47'h08ED27B1E594;Q0_new=47'h02F72AF5A0A2;
              L1_new=47'h08E9B6ABBA48;L0_new=47'h02F72B87E429;
            end
      8'd76: begin
              C3_new=47'h01C17FB99A1F;C2_new=47'h7C91A23040DC;C1_new=47'h08E646B498A9;C0_new=47'h030014AC62C7;
              Q2_new=47'h7C94446FD21A;Q1_new=47'h08E645A76C26;Q0_new=47'h030014AC78FD;
              L1_new=47'h08E2D9EBDBF7;L0_new=47'h0300153DDBA0;
            end
      8'd77: begin
              C3_new=47'h01BD77E64B2D;C2_new=47'h7C96E6AC4480;C1_new=47'h08DF6F3CE5ED;C0_new=47'h0308F7867B0F;
              Q2_new=47'h7C9982E028D3;Q1_new=47'h08DF6E32233A;Q0_new=47'h0308F7869113;
              L1_new=47'h08DC07B50363;L0_new=47'h0308F81714D8;
            end
      8'd78: begin
              C3_new=47'h01B97C048AFB;C2_new=47'h7C9C1F10DE6D;C1_new=47'h08D8A2421545;C0_new=47'h0311D38E5C19;
              Q2_new=47'h7C9EB54AE934;Q1_new=47'h08D8A139B557;Q0_new=47'h0311D38E71EA;
              L1_new=47'h08D53FEF0041;L0_new=47'h0311D41E18D1;
            end
      8'd79: begin
              C3_new=47'h01B58C53C706;C2_new=47'h7CA14B823875;C1_new=47'h08D1DFAC1BE1;C0_new=47'h031AA8CE76BB;
              Q2_new=47'h7CA3DBD4B2CF;Q1_new=47'h08D1DEA6176D;Q0_new=47'h031AA8CE8C5B;
              L1_new=47'h08CE8281EC1F;L0_new=47'h031AA95D585C;
            end
      8'd80: begin
              C3_new=47'h01B1A8B3CDA1;C2_new=47'h7CA66C249814;C1_new=47'h08CB276337E3;C0_new=47'h0323775123E6;
              Q2_new=47'h7CA8F6A1A47C;Q1_new=47'h08CB265F87A1;Q0_new=47'h032377513954;
              L1_new=47'h08C7CF562945;L0_new=47'h032377DF2C62;
            end
      8'd81: begin
              C3_new=47'h01ADD0EDBC0C;C2_new=47'h7CAB811BDFDA;C1_new=47'h08C4794FEF85;C0_new=47'h032C3F20A4EB;
              Q2_new=47'h7CAE05D54705;Q1_new=47'h08C4784E8C5D;Q0_new=47'h032C3F20BA28;
              L1_new=47'h08C1265461A3;L0_new=47'h032C3FADD630;
            end
      8'd82: begin
              C3_new=47'h01AA0496D576;C2_new=47'h7CB08A8BC73A;C1_new=47'h08BDD55B0FF8;C0_new=47'h0335004723C7;
              Q2_new=47'h7CB30992A907;Q1_new=47'h08BDD45BF316;Q0_new=47'h0335004738D5;
              L1_new=47'h08BA876585BF;L0_new=47'h033500D37FBE;
            end
      8'd83: begin
              C3_new=47'h01A643CC9B97;C2_new=47'h7CB5889698F7;C1_new=47'h08B73B6DACEC;C0_new=47'h033DBACEB368;
              Q2_new=47'h7CB801FC4F12;Q1_new=47'h08B73A70CF60;Q0_new=47'h033DBACEC845;
              L1_new=47'h08B3F272CBAE;L0_new=47'h033DBB5A3BF1;
            end
      8'd84: begin
              C3_new=47'h01A28E1AB905;C2_new=47'h7CBA7B5F1777;C1_new=47'h08B0AB711EA3;C0_new=47'h03466EC14FEF;
              Q2_new=47'h7CBCEF3440D1;Q1_new=47'h08B0AA7679CE;Q0_new=47'h03466EC1649E;
              L1_new=47'h08AD6765AE0E;L0_new=47'h03466F4C06E8;
            end
      8'd85: begin
              C3_new=47'h019EE37DC3FC;C2_new=47'h7CBF6306BEE8;C1_new=47'h08AA254F01CC;C0_new=47'h034F1C28DEFB;
              Q2_new=47'h7CC1D15BFACE;Q1_new=47'h08AA24568F0C;Q0_new=47'h034F1C28F37B;
              L1_new=47'h08A6E627EB07;L0_new=47'h034F1CB2C639;
            end
      8'd86: begin
              C3_new=47'h019B43E80CBC;C2_new=47'h7CC43FAEABC4;C1_new=47'h08A3A8F13608;C0_new=47'h0357C30F2FE7;
              Q2_new=47'h7CC6A8948A63;Q1_new=47'h08A3A7FAEEBC;Q0_new=47'h0357C30F4439;
              L1_new=47'h08A06EA38347;L0_new=47'h0357C398493D;
            end
      8'd87: begin
              C3_new=47'h0197AF383F07;C2_new=47'h7CC9117796E1;C1_new=47'h089D3641DD02;C0_new=47'h0360637DFC0F;
              Q2_new=47'h7CCB74FE75EC;Q1_new=47'h089D354DBA9D;Q0_new=47'h0360637E1035;
              L1_new=47'h089A00C2B914;L0_new=47'h036064064948;
            end
      8'd88: begin
              C3_new=47'h019424B6C6F5;C2_new=47'h7CCDD882C783;C1_new=47'h0896CD2B58F7;C0_new=47'h0368FD7EE713;
              Q2_new=47'h7CD036B9D687;Q1_new=47'h0896CC39557A;Q0_new=47'h0368FD7EFB0C;
              L1_new=47'h08939C700F51;L0_new=47'h0368FE0669F6;
            end
      8'd89: begin
              C3_new=47'h0190A50738DD;C2_new=47'h7CD294EEBA89;C1_new=47'h08906D984D71;C0_new=47'h0371911B7F13;
              Q2_new=47'h7CD4EDE6437D;Q1_new=47'h08906CA86251;Q0_new=47'h0371911B92E0;
              L1_new=47'h088D41964895;L0_new=47'h037191A23961;
            end
      8'd90: begin
              C3_new=47'h018D2F96EB18;C2_new=47'h7CD746DB853E;C1_new=47'h088A17739C37;C0_new=47'h037A1E5D3CF5;
              Q2_new=47'h7CD99AA2E6F7;Q1_new=47'h088A1685C350;Q0_new=47'h037A1E5D5095;
              L1_new=47'h0886F0206637;L0_new=47'h037A1EE33069;
            end
      8'd91: begin
              C3_new=47'h0189C457A8C1;C2_new=47'h7CDBEE67F7AD;C1_new=47'h0883CAA865BD;C0_new=47'h0382A54D849C;
              Q2_new=47'h7CDE3D0E7850;Q1_new=47'h0883C9BC98F8;Q0_new=47'h0382A54D9811;
              L1_new=47'h0880A7F9A76F;L0_new=47'h0382A5D2B2EE;
            end
      8'd92: begin
              C3_new=47'h0186630620C2;C2_new=47'h7CE08BB2BEB8;C1_new=47'h087D872207C3;C0_new=47'h038B25F5A52E;
              Q2_new=47'h7CE2D547487F;Q1_new=47'h087D86384128;Q0_new=47'h038B25F5B878;
              L1_new=47'h087A690D8872;L0_new=47'h038B267A1010;
            end
      8'd93: begin
              C3_new=47'h01830B91EA10;C2_new=47'h7CE51ED9C0FD;C1_new=47'h08774CCC1CC0;C0_new=47'h0393A05ED94B;
              Q2_new=47'h7CE7636B1529;Q1_new=47'h08774BE45674;Q0_new=47'h0393A05EEC6C;
              L1_new=47'h08743347C189;L0_new=47'h0393A0E2826A;
            end
      8'd94: begin
              C3_new=47'h017FBE109177;C2_new=47'h7CE9A7FA3C98;C1_new=47'h08711B927AF3;C0_new=47'h039C1492474D;
              Q2_new=47'h7CEBE79756C2;Q1_new=47'h08711AACAEED;Q0_new=47'h039C14925A44;
              L1_new=47'h086E06944643;L0_new=47'h039C15153051;
            end
      8'd95: begin
              C3_new=47'h017C79D7B3EF;C2_new=47'h7CEE2732531D;C1_new=47'h086AF36132C1;C0_new=47'h03A482990181;
              Q2_new=47'h7CF061E9102A;Q1_new=47'h086AF27D5B86;Q0_new=47'h03A48299144E;
              L1_new=47'h0867E2DF4497;L0_new=47'h03A4831B2C0D;
            end
      8'd96: begin
              C3_new=47'h01793F376EFD;C2_new=47'h7CF29C9E03C0;C1_new=47'h0864D4248F74;C0_new=47'h03ACEA7C0660;
              Q2_new=47'h7CF4D27CCB2C;Q1_new=47'h0864D342A741;Q0_new=47'h03ACEA7C1904;
              L1_new=47'h0861C815240B;L0_new=47'h03ACEAFD7412;
            end
      8'd97: begin
              C3_new=47'h01760E19E033;C2_new=47'h7CF70859992A;C1_new=47'h085EBDC9151F;C0_new=47'h03B54C4440CC;
              Q2_new=47'h7CF9396EC08B;Q1_new=47'h085EBCE9162E;Q0_new=47'h03B54C445348;
              L1_new=47'h085BB62284EF;L0_new=47'h03B54CC4F33F;
            end
      8'd98: begin
              C3_new=47'h0172E5E050B7;C2_new=47'h7CFB6A81E77F;C1_new=47'h0858B03B7FBB;C0_new=47'h03BDA7FA8849;
              Q2_new=47'h7CFD96DAB74A;Q1_new=47'h0858AF5D64CB;Q0_new=47'h03BDA7FA9A9D;
              L1_new=47'h0855ACF43F84;L0_new=47'h03BDA87A8112;
            end
      8'd99: begin
              C3_new=47'h016FC6FE17BB;C2_new=47'h7CFFC33187A3;C1_new=47'h0852AB68C3C0;C0_new=47'h03C5FDA7A131;
              Q2_new=47'h7D01EADC062F;Q1_new=47'h0852AA8C8732;Q0_new=47'h03C5FDA7B35D;
              L1_new=47'h084FAC776339;L0_new=47'h03C5FE26E1E0;
            end
      8'd100: begin
              C3_new=47'h016CB0FBFD7E;C2_new=47'h7D041284419D;C1_new=47'h084CAF3E0BA3;C0_new=47'h03CE4D543CED;
              Q2_new=47'h7D06358DC237;Q1_new=47'h084CAE63A823;Q0_new=47'h03CE4D544EF2;
              L1_new=47'h0849B49935E6;L0_new=47'h03CE4DD2C70E;
            end
      8'd101: begin
              C3_new=47'h0169A3ADBF2E;C2_new=47'h7D085894F8D9;C1_new=47'h0846BBA8B823;C0_new=47'h03D69708FA2E;
              Q2_new=47'h7D0A770A82CA;Q1_new=47'h0846BAD02884;Q0_new=47'h03D697090C0D;
              L1_new=47'h0843C5473307;L0_new=47'h03D69786CF49;
            end
      8'd102: begin
              C3_new=47'h01669F427E32;C2_new=47'h7D0C957DA005;C1_new=47'h0840D0965F86;C0_new=47'h03DEDACE651E;
              Q2_new=47'h7D0EAF6C872B;Q1_new=47'h0840CFBF9E75;Q0_new=47'h03DEDACE76D7;
              L1_new=47'h083DDE6F0AFC;L0_new=47'h03DEDB4B86B8;
            end
      8'd103: begin
              C3_new=47'h0163A32C7BC1;C2_new=47'h7D10C958FE63;C1_new=47'h083AEDF4CC09;C0_new=47'h03E718ACF79B;
              Q2_new=47'h7D12DECDC21F;Q1_new=47'h083AED1FD489;Q0_new=47'h03E718AD092E;
              L1_new=47'h0837FFFEA24C;L0_new=47'h03E719296731;
            end
      8'd104: begin
              C3_new=47'h0160AF77C5A1;C2_new=47'h7D14F4408AA0;C1_new=47'h083513B1FC21;C0_new=47'h03EF50AD1963;
              Q2_new=47'h7D170547BB9B;Q1_new=47'h083512DEC931;Q0_new=47'h03EF50AD2AD1;
              L1_new=47'h083229E410ED;L0_new=47'h03EF5128D870;
            end
      8'd105: begin
              C3_new=47'h015DC4708490;C2_new=47'h7D19164CE85D;C1_new=47'h082F41BC219B;C0_new=47'h03F782D7204F;
              Q2_new=47'h7D1B22F3914E;Q1_new=47'h082F40EAAE00;Q0_new=47'h03F782D73198;
              L1_new=47'h082C5C0DA190;L0_new=47'h03F78352304A;
            end
      8'd106: begin
              C3_new=47'h015AE1629904;C2_new=47'h7D1D2F981D84;C1_new=47'h082978019FC4;C0_new=47'h03FFAF335082;
              Q2_new=47'h7D1F37EA33D1;Q1_new=47'h08297731E6B8;Q0_new=47'h03FFAF3361A6;
              L1_new=47'h08269669D0EC;L0_new=47'h03FFAFADB2DE;
            end
      8'd107: begin
              C3_new=47'h0158067FEC1A;C2_new=47'h7D21403A4F3E;C1_new=47'h0823B6710C57;C0_new=47'h0407D5C9DC9B;
              Q2_new=47'h7D234444105C;Q1_new=47'h0823B5A308FA;Q0_new=47'h0407D5C9ED9B;
              L1_new=47'h0820D8E74D0A;L0_new=47'h0407D64392C6;
            end
      8'd108: begin
              C3_new=47'h015533A093B0;C2_new=47'h7D25484BE2FA;C1_new=47'h081DFCF92DC8;C0_new=47'h040FF6A2E5E8;
              Q2_new=47'h7D2748194EDC;Q1_new=47'h081DFC2CDB52;Q0_new=47'h040FF6A2F6C5;
              L1_new=47'h081B2374F4A0;L0_new=47'h040FF71BF14D;
            end
      8'd109: begin
              C3_new=47'h015268973A5C;C2_new=47'h7D2947E4F20F;C1_new=47'h08184B88FAD7;C0_new=47'h041811C67C96;
              Q2_new=47'h7D2B4381D248;Q1_new=47'h08184ABE548E;Q0_new=47'h041811C68D4F;
              L1_new=47'h08157601D65F;L0_new=47'h0418123EDE9A;
            end
      8'd110: begin
              C3_new=47'h014FA55EB82D;C2_new=47'h7D2D3F1D06BA;C1_new=47'h0812A20F9A07;C0_new=47'h0420273C9FDE;
              Q2_new=47'h7D2F36950D08;Q1_new=47'h0812A1469B46;Q0_new=47'h0420273CB074;
              L1_new=47'h080FD07D3052;L0_new=47'h042027B459E4;
            end
      8'd111: begin
              C3_new=47'h014CE9F278BF;C2_new=47'h7D312E0B5324;C1_new=47'h080D007C60E5;C0_new=47'h0428370D3E3A;
              Q2_new=47'h7D33216A4027;Q1_new=47'h080CFFB504EF;Q0_new=47'h0428370D4EAE;
              L1_new=47'h080A32D66F30;L0_new=47'h0428378451A2;
            end
      8'd112: begin
              C3_new=47'h014A35E2D8EC;C2_new=47'h7D3514C76BD4;C1_new=47'h080766BED309;C0_new=47'h043041403591;
              Q2_new=47'h7D3704183BBA;Q1_new=47'h080765F91587;Q0_new=47'h0430414045E2;
              L1_new=47'h08049CFD2DC2;L0_new=47'h043041B6A3B4;
            end
      8'd113: begin
              C3_new=47'h014789687078;C2_new=47'h7D38F3677EF2;C1_new=47'h0801D4C6A24C;C0_new=47'h043845DD5361;
              Q2_new=47'h7D3ADEB59827;Q1_new=47'h0801D4027EAC;Q0_new=47'h043845DD6390;
              L1_new=47'h07FF0EE13444;L0_new=47'h043846531D97;
            end
      8'd114: begin
              C3_new=47'h0144E45E9EC5;C2_new=47'h7D3CCA0204B8;C1_new=47'h07FC4A83AD63;C0_new=47'h044044EC54F4;
              Q2_new=47'h7D3EB158970A;Q1_new=47'h07FC49C11F29;Q0_new=47'h044044EC6502;
              L1_new=47'h07F9887277C1;L0_new=47'h044045617C91;
            end
      8'd115: begin
              C3_new=47'h0142467FC01D;C2_new=47'h7D4098AD6A4D;C1_new=47'h07F6C7E5FF63;C0_new=47'h04483E74E788;
              Q2_new=47'h7D427C172C42;Q1_new=47'h07F6C725024F;Q0_new=47'h04483E74F775;
              L1_new=47'h07F409A1197C;L0_new=47'h04483EE96DDB;
            end
      8'd116: begin
              C3_new=47'h013FAFDBB1E9;C2_new=47'h7D445F7F34C5;C1_new=47'h07F14CDDCF9F;C0_new=47'h0450327EA87B;
              Q2_new=47'h7D463F0702A5;Q1_new=47'h07F14C1E5F58;Q0_new=47'h0450327EB847;
              L1_new=47'h07EE925D665B;L0_new=47'h045032F28ED1;
            end
      8'd117: begin
              C3_new=47'h013D20532193;C2_new=47'h7D481E8CFACF;C1_new=47'h07EBD95B808C;C0_new=47'h04582111257A;
              Q2_new=47'h7D49FA3D7CD7;Q1_new=47'h07EBD89D98D1;Q0_new=47'h045821113526;
              L1_new=47'h07E92297D64F;L0_new=47'h045821846D1A;
            end
      8'd118: begin
              C3_new=47'h013A97C76F7D;C2_new=47'h7D4BD5EBF9A0;C1_new=47'h07E66D4F9F70;C0_new=47'h04600A33DCA8;
              Q2_new=47'h7D4DADCFAF97;Q1_new=47'h07E66C933C0E;Q0_new=47'h04600A33EC33;
              L1_new=47'h07E3BA410BBE;L0_new=47'h04600AA686D8;
            end
      8'd119: begin
              C3_new=47'h0138160CF164;C2_new=47'h7D4F85B15021;C1_new=47'h07E108AAE3A0;C0_new=47'h0467EDEE3CCB;
              Q2_new=47'h7D5159D26B79;Q1_new=47'h07E107F0008B;Q0_new=47'h0467EDEE4C37;
              L1_new=47'h07DE5949D2F8;L0_new=47'h0467EE604ACD;
            end
      8'd120: begin
              C3_new=47'h01359B2AFE31;C2_new=47'h7D532DF17026;C1_new=47'h07DBAB5E2E50;C0_new=47'h046FCC47A576;
              Q2_new=47'h7D54FE5A363B;Q1_new=47'h07DBAAA4C76C;Q0_new=47'h046FCC47B4C2;
              L1_new=47'h07D8FFA321A1;L0_new=47'h046FCCB91888;
            end
      8'd121: begin
              C3_new=47'h013326BEEA2E;C2_new=47'h7D56CEC14545;C1_new=47'h07D6555A895A;C0_new=47'h0477A5476731;
              Q2_new=47'h7D589B7B595F;Q1_new=47'h07D654A29AD9;Q0_new=47'h0477A547765E;
              L1_new=47'h07D3AD3E1632;L0_new=47'h0477A5B8408E;
            end
      8'd122: begin
              C3_new=47'h0130B942A83C;C2_new=47'h7D5A6833F500;C1_new=47'h07D1069127E7;C0_new=47'h047F78F4C3A2;
              Q2_new=47'h7D5C3149DBD2;Q1_new=47'h07D105DAAD81;Q0_new=47'h047F78F4D2B1;
              L1_new=47'h07CE620BF75D;L0_new=47'h047F79650482;
            end
      8'd123: begin
              C3_new=47'h012E522251A6;C2_new=47'h7D5DFA5E35F3;C1_new=47'h07CBBEF36432;C0_new=47'h04874756EDB7;
              Q2_new=47'h7D5FBFD96690;Q1_new=47'h07CBBE3E5A2F;Q0_new=47'h04874756FCA8;
              L1_new=47'h07C91DFE3396;L0_new=47'h048747C6974E;
            end
      8'd124: begin
              C3_new=47'h012BF1792BFB;C2_new=47'h7D6185534D42;C1_new=47'h07C67E72C084;C0_new=47'h048F107509CC;
              Q2_new=47'h7D63473D7B58;Q1_new=47'h07C67DBF2304;Q0_new=47'h048F1075189E;
              L1_new=47'h07C3E106607E;L0_new=47'h048F10E41D4A;
            end
      8'd125: begin
              C3_new=47'h0129975AE469;C2_new=47'h7D650926510E;C1_new=47'h07C14500E611;C0_new=47'h0496D4562DD1;
              Q2_new=47'h7D66C7895A8F;Q1_new=47'h07C1444EB117;Q0_new=47'h0496D4563C85;
              L1_new=47'h07BEAB163A72;L0_new=47'h0496D4C4AC65;
            end
      8'd126: begin
              C3_new=47'h0127435932CE;C2_new=47'h7D6885EAEA02;C1_new=47'h07BC128FA414;C0_new=47'h049E93016175;
              Q2_new=47'h7D6A40CFF3A7;Q1_new=47'h07BC11DED401;Q0_new=47'h049E9301700C;
              L1_new=47'h07B97C1FA3F5;L0_new=47'h049E936F4C49;
            end
      8'd127: begin
              C3_new=47'h0124F5929AAC;C2_new=47'h7D6BFBB39E46;C1_new=47'h07B6E710F029;C0_new=47'h04A64C7D9E47;
              Q2_new=47'h7D6DB323F9D8;Q1_new=47'h07B6E6618146;Q0_new=47'h04A64C7DACC1;
              L1_new=47'h07B45414A541;L0_new=47'h04A64CEAF683;
            end
      8'd128: begin
              C3_new=47'h0122ADE71306;C2_new=47'h7D6F6A931702;C1_new=47'h07B1C276E52A;C0_new=47'h04AE00D1CFE0;
              Q2_new=47'h7D711E97EDAB;Q1_new=47'h07B1C1C8D3D1;Q0_new=47'h04AE00D1DE3D;
              L1_new=47'h07AF32E76BBE;L0_new=47'h04AE013E96A9;
            end
      8'd129: begin
              C3_new=47'h01206C66D746;C2_new=47'h7D72D29B71FA;C1_new=47'h07ACA4B3C312;C0_new=47'h04B5B004D406;
              Q2_new=47'h7D74833E0E92;Q1_new=47'h07ACA4070B84;Q0_new=47'h04B5B004E247;
              L1_new=47'h07AA188A4991;L0_new=47'h04B5B0710A7D;
            end
      8'd130: begin
              C3_new=47'h011E30A409EA;C2_new=47'h7D7633DF6CED;C1_new=47'h07A78DB9EDDD;C0_new=47'h04BD5A1D7AD1;
              Q2_new=47'h7D77E1285A4C;Q1_new=47'h07A78D0E8CC1;Q0_new=47'h04BD5A1D88F6;
              L1_new=47'h07A504EFB51A;L0_new=47'h04BD5A892214;
            end
      8'd131: begin
              C3_new=47'h011BFAFEB923;C2_new=47'h7D798E7019ED;C1_new=47'h07A27D7BEE53;C0_new=47'h04C4FF2286CF;
              Q2_new=47'h7D7B38689FA0;Q1_new=47'h07A27CD1DFDD;Q0_new=47'h04C4FF2294D8;
              L1_new=47'h079FF80A487F;L0_new=47'h04C4FF8D9FFA;
            end
      8'd132: begin
              C3_new=47'h0119CAED5EC8;C2_new=47'h7D7CE25FF84E;C1_new=47'h079D73EC6FE1;C0_new=47'h04CC9F1AAD29;
              Q2_new=47'h7D7E8910530A;Q1_new=47'h079D7343B0E2;Q0_new=47'h04CC9F1ABB15;
              L1_new=47'h079AF1CCC134;L0_new=47'h04CC9F853954;
            end
      8'd133: begin
              C3_new=47'h0117A0F25C06;C2_new=47'h7D802FBF6E70;C1_new=47'h079870FE4203;C0_new=47'h04D43A0C95C3;
              Q2_new=47'h7D81D330DB4F;Q1_new=47'h07987056CEB6;Q0_new=47'h04D43A0CA395;
              L1_new=47'h0795F229FF91;L0_new=47'h04D43A769605;
            end
      8'd134: begin
              C3_new=47'h01157C419A12;C2_new=47'h7D8376A0EDD7;C1_new=47'h079374A455B7;C0_new=47'h04DBCFFEDB66;
              Q2_new=47'h7D8516DB48C1;Q1_new=47'h079373FE2B06;Q0_new=47'h04DBCFFEE91C;
              L1_new=47'h0790F915064F;L0_new=47'h04DBD06850D1;
            end
      8'd135: begin
              C3_new=47'h01135D63F7A4;C2_new=47'h7D86B7146978;C1_new=47'h078E7ED1BF49;C0_new=47'h04E360F80BD9;
              Q2_new=47'h7D8854208815;Q1_new=47'h078E7E2CD99C;Q0_new=47'h04E360F81974;
              L1_new=47'h078C0680FA26;L0_new=47'h04E36160F77D;
            end
      8'd136: begin
              C3_new=47'h011143F3E460;C2_new=47'h7D89F12B3BBC;C1_new=47'h07898F79B3FB;C0_new=47'h04EAECFEA80A;
              Q2_new=47'h7D8B8B112ED1;Q1_new=47'h07898ED61026;Q0_new=47'h04EAECFEB58B;
              L1_new=47'h07871A612156;L0_new=47'h04EAED670AF4;
            end
      8'd137: begin
              C3_new=47'h010F2FEDB21C;C2_new=47'h7D8D24F5D64B;C1_new=47'h0784A68F8ABB;C0_new=47'h04F27419242D;
              Q2_new=47'h7D8EBBBDBE75;Q1_new=47'h0784A5ED2581;Q0_new=47'h04F274193194;
              L1_new=47'h078234A8E341;L0_new=47'h04F27480FF68;
            end
      8'd138: begin
              C3_new=47'h010D2158D647;C2_new=47'h7D905284648B;C1_new=47'h077FC406BB6A;C0_new=47'h04F9F64DE7DD;
              Q2_new=47'h7D91E6366BFD;Q1_new=47'h077FC3659187;Q0_new=47'h04F9F64DF52A;
              L1_new=47'h077D554BC7F3;L0_new=47'h04F9F6B53C72;
            end
      8'd139: begin
              C3_new=47'h010B1805DC9E;C2_new=47'h7D9379E742FA;C1_new=47'h077AE7D2DE30;C0_new=47'h050173A34E3F;
              Q2_new=47'h7D950A8B49EF;Q1_new=47'h077AE732EC80;Q0_new=47'h050173A35B71;
              L1_new=47'h07787C3D77CB;L0_new=47'h0501740A1D31;
            end
      8'd140: begin
              C3_new=47'h01091405AC4A;C2_new=47'h7D969B2E26BC;C1_new=47'h077611E7AB81;C0_new=47'h0508EC1FA61C;
              Q2_new=47'h7D9828CC2CA4;Q1_new=47'h07761148EED2;Q0_new=47'h0508EC1FB335;
              L1_new=47'h0773A971BAFF;L0_new=47'h0508EC85F06F;
            end
      8'd141: begin
              C3_new=47'h0107152FA698;C2_new=47'h7D99B668EEDF;C1_new=47'h07714238FB57;C0_new=47'h05105FC9320A;
              Q2_new=47'h7D9B4108BBF1;Q1_new=47'h0771419B7085;Q0_new=47'h05105FC93F0A;
              L1_new=47'h076EDCDC7942;L0_new=47'h0510602EF8BE;
            end
      8'd142: begin
              C3_new=47'h01051B78A8E6;C2_new=47'h7D9CCBA7222C;C1_new=47'h076C78BAC4FB;C0_new=47'h0517CEA62883;
              Q2_new=47'h7D9E53505C3A;Q1_new=47'h076C781E68FF;Q0_new=47'h0517CEA6356A;
              L1_new=47'h076A1671B95D;L0_new=47'h0517CF0B6C95;
            end
      8'd143: begin
              C3_new=47'h010326B511D7;C2_new=47'h7D9FDAF8465C;C1_new=47'h0767B5611E85;C0_new=47'h051F38BCB40B;
              Q2_new=47'h7DA15FB258B4;Q1_new=47'h0767B4C5EE6C;Q0_new=47'h051F38BCC0D9;
              L1_new=47'h07655625A0C6;L0_new=47'h051F39217676;
            end
      8'd144: begin
              C3_new=47'h0101371FDD39;C2_new=47'h7DA2E46B01AC;C1_new=47'h0762F8203CE4;C0_new=47'h05269E12F348;
              Q2_new=47'h7DA4663DB596;Q1_new=47'h0762F7863590;Q0_new=47'h05269E12FFFE;
              L1_new=47'h07609BEC7345;L0_new=47'h05269E773505;
            end
      8'd145: begin
              C3_new=47'h00FF4C1D63D4;C2_new=47'h7DA5E80F39A8;C1_new=47'h075E40EC7270;C0_new=47'h052DFEAEF927;
              Q2_new=47'h7DA767015D50;Q1_new=47'h075E40539132;Q0_new=47'h052DFEAF05C5;
              L1_new=47'h075BE7BA9290;L0_new=47'h052DFF12BB2B;
            end
      8'd146: begin
              C3_new=47'h00FD66316E39;C2_new=47'h7DA8E5F2BA79;C1_new=47'h07598FBA302D;C0_new=47'h05355A96CCF5;
              Q2_new=47'h7DAA620C0333;Q1_new=47'h07598F2271E4;Q0_new=47'h05355A96D97A;
              L1_new=47'h075739847DE8;L0_new=47'h05355AFA1033;
            end
      8'd147: begin
              C3_new=47'h00FB85310008;C2_new=47'h7DABDE244B0F;C1_new=47'h0754E47E03F3;C0_new=47'h053CB1D06A7E;
              Q2_new=47'h7DAD576C1596;Q1_new=47'h0754E3E765AF;Q0_new=47'h053CB1D076EC;
              L1_new=47'h0752913ED1C5;L0_new=47'h053CB2332FE8;
            end
      8'd148: begin
              C3_new=47'h00F9A8C2E0A5;C2_new=47'h7DAED0B2DA64;C1_new=47'h07503F2C9863;C0_new=47'h05440461C22B;
              Q2_new=47'h7DB0472FF595;Q1_new=47'h07503E97177B;Q0_new=47'h05440461CE82;
              L1_new=47'h074DEEDE476F;L0_new=47'h054404C40AB0;
            end
      8'd149: begin
              C3_new=47'h00F7D130D525;C2_new=47'h7DB1BDABFCA9;C1_new=47'h074B9FBAB574;C0_new=47'h054B5250B91F;
              Q2_new=47'h7DB33165C5C4;Q1_new=47'h074B9F264EE5;Q0_new=47'h054B5250C55E;
              L1_new=47'h07495257B4A9;L0_new=47'h054B52B285AB;
            end
      8'd150: begin
              C3_new=47'h00F5FE13AF9C;C2_new=47'h7DB4A51E6EAC;C1_new=47'h0747061D3EA4;C0_new=47'h05529BA32952;
              Q2_new=47'h7DB6161B84E0;Q1_new=47'h07470589EFD5;Q0_new=47'h05529BA3357A;
              L1_new=47'h0744BBA00B5A;L0_new=47'h05529C047ACE;
            end
      8'd151: begin
              C3_new=47'h00F42FBB540C;C2_new=47'h7DB787175F6A;C1_new=47'h07427249342A;C0_new=47'h0559E05EE1AD;
              Q2_new=47'h7DB8F55F0718;Q1_new=47'h074271B6FA20;Q0_new=47'h0559E05EEDBE;
              L1_new=47'h07402AAC5928;L0_new=47'h0559E0BFB902;
            end
      8'd152: begin
              C3_new=47'h00F265A51C22;C2_new=47'h7DBA63A55E56;C1_new=47'h073DE433B105;C0_new=47'h05612089A628;
              Q2_new=47'h7DBBCF3DD466;Q1_new=47'h073DE3A2895F;Q0_new=47'h05612089B223;
              L1_new=47'h073B9F71C734;L0_new=47'h056120EA043B;
            end
      8'd153: begin
              C3_new=47'h00F0A033C215;C2_new=47'h7DBD3AD52CC3;C1_new=47'h07395BD1EC57;C0_new=47'h05685C292FE4;
              Q2_new=47'h7DBEA3C58048;Q1_new=47'h07395B41D430;Q0_new=47'h05685C293BC8;
              L1_new=47'h073719E599B2;L0_new=47'h05685C891598;
            end
      8'd154: begin
              C3_new=47'h00EEDF0B0EDE;C2_new=47'h7DC00CB4BA9C;C1_new=47'h0734D9193779;C0_new=47'h056F93432D46;
              Q2_new=47'h7DC173034961;Q1_new=47'h0734D88A2C56;Q0_new=47'h056F93433914;
              L1_new=47'h073299FD2F9F;L0_new=47'h056F93A29B7C;
            end
      8'd155: begin
              C3_new=47'h00ED2265B2A2;C2_new=47'h7DC2D950BF24;C1_new=47'h07305BFEFEFA;C0_new=47'h0576C5DD4211;
              Q2_new=47'h7DC43D046003;Q1_new=47'h07305B70FE0D;Q0_new=47'h0576C5DD4DC9;
              L1_new=47'h072E1FAE026E;L0_new=47'h0576C63C39A8;
            end
      8'd156: begin
              C3_new=47'h00EB69FA551C;C2_new=47'h7DC5A0B6B7D4;C1_new=47'h072BE478C926;C0_new=47'h057DF3FD0783;
              Q2_new=47'h7DC701D5B03C;Q1_new=47'h072BE3EBCFFF;Q0_new=47'h057DF3FD1326;
              L1_new=47'h0729AAEDA5AF;L0_new=47'h057DF45B8958;
            end
      8'd157: begin
              C3_new=47'h00E9B5BD5AF1;C2_new=47'h7DC862F382BE;C1_new=47'h0727727C3691;C0_new=47'h05851DA80C6D;
              Q2_new=47'h7DC9C184239F;Q1_new=47'h072771F042A1;Q0_new=47'h05851DA817FA;
              L1_new=47'h07253BB1C6C4;L0_new=47'h05851E061959;
            end
      8'd158: begin
              C3_new=47'h00E805ABFD19;C2_new=47'h7DCB2013D9AE;C1_new=47'h072305FF0162;C0_new=47'h058C42E3D54D;
              Q2_new=47'h7DCC7C1C52D6;Q1_new=47'h07230574103D;Q0_new=47'h058C42E3E0C4;
              L1_new=47'h0720D1F02C8F;L0_new=47'h058C43416E2A;
            end
      8'd159: begin
              C3_new=47'h00E659C17D6A;C2_new=47'h7DCDD82433BD;C1_new=47'h071E9EF6FD3C;C0_new=47'h059363B5DC68;
              Q2_new=47'h7DCF31AAD1DE;Q1_new=47'h071E9E6D0C54;Q0_new=47'h059363B5E7CA;
              L1_new=47'h071C6D9EB725;L0_new=47'h05936413020B;
            end
      8'd160: begin
              C3_new=47'h00E4B2206F32;C2_new=47'h7DD08B30CB59;C1_new=47'h071A3D5A16C2;C0_new=47'h059A802391E3;
              Q2_new=47'h7DD1E23BF73C;Q1_new=47'h071A3CD12386;Q0_new=47'h059A80239D30;
              L1_new=47'h07180EB35F7F;L0_new=47'h059A80804521;
            end
      8'd161: begin
              C3_new=47'h00E30E69A488;C2_new=47'h7DD339466469;C1_new=47'h0715E11E5310;C0_new=47'h05A198325BDD;
              Q2_new=47'h7DD48DDBFF7E;Q1_new=47'h0715E0965B2B;Q0_new=47'h05A198326715;
              L1_new=47'h0713B524372B;L0_new=47'h05A1988E9D88;
            end
      8'd162: begin
              C3_new=47'h00E16ED607A8;C2_new=47'h7DD5E270B74C;C1_new=47'h07118A39D01D;C0_new=47'h05A8ABE79685;
              Q2_new=47'h7DD73496FB19;Q1_new=47'h071189B2D10C;Q0_new=47'h05A8ABE7A1A9;
              L1_new=47'h070F60E76808;L0_new=47'h05A8AC43676D;
            end
      8'd163: begin
              C3_new=47'h00DFD30AC788;C2_new=47'h7DD886BC50FF;C1_new=47'h070D38A2C388;C0_new=47'h05AFBB489434;
              Q2_new=47'h7DD9D678E26F;Q1_new=47'h070D381CBB13;Q0_new=47'h05AFBB489F44;
              L1_new=47'h070B11F333F6;L0_new=47'h05AFBBA3F529;
            end
      8'd164: begin
              C3_new=47'h00DE3B52A857;C2_new=47'h7DDB263471CD;C1_new=47'h0708EC4F7B71;C0_new=47'h05B6C65A9D87;
              Q2_new=47'h7DDC738D6F58;Q1_new=47'h0708EBCA6722;Q0_new=47'h05B6C65AA883;
              L1_new=47'h0706C83DF491;L0_new=47'h05B6C6B58F54;
            end
      8'd165: begin
              C3_new=47'h00DCA7558EA0;C2_new=47'h7DDDC0E557FE;C1_new=47'h0704A5365CED;C0_new=47'h05BDCD22F172;
              Q2_new=47'h7DDF0BE05C4F;Q1_new=47'h0704A4B23A86;Q0_new=47'h05BDCD22FC5A;
              L1_new=47'h070283BE1AE4;L0_new=47'h05BDCD7D74E1;
            end
      8'd166: begin
              C3_new=47'h00DB17142B26;C2_new=47'h7DE056DA7F87;C1_new=47'h0700634DE4B5;C0_new=47'h05C4CFA6C55C;
              Q2_new=47'h7DE19F7D1A93;Q1_new=47'h070062CAB208;Q0_new=47'h05C4CFA6D030;
              L1_new=47'h06FE446A2F23;L0_new=47'h05C4D000DB35;
            end
      8'd167: begin
              C3_new=47'h00D98AB92424;C2_new=47'h7DE2E81F0750;C1_new=47'h06FC268CA6A6;C0_new=47'h05CBCDEB4532;
              Q2_new=47'h7DE42E6F1C1B;Q1_new=47'h06FC260A6150;Q0_new=47'h05CBCDEB4FF2;
              L1_new=47'h06FA0A38D06D;L0_new=47'h05CBCE44EE3D;
            end
      8'd168: begin
              C3_new=47'h00D802116F90;C2_new=47'h7DE574BE7E75;C1_new=47'h06F7EEE94D12;C0_new=47'h05D2C7F59383;
              Q2_new=47'h7DE6B8C199E7;Q1_new=47'h06F7EE67F2DE;Q0_new=47'h05D2C7F59E2F;
              L1_new=47'h06F5D520B478;L0_new=47'h05D2C84ED083;
            end
      8'd169: begin
              C3_new=47'h00D67D20F3B8;C2_new=47'h7DE7FCC3F404;C1_new=47'h06F3BC5A9904;C0_new=47'h05D9BDCAC990;
              Q2_new=47'h7DE93E7FA50B;Q1_new=47'h06F3BBDA27B7;Q0_new=47'h05D9BDCAD42A;
              L1_new=47'h06F1A518A75C;L0_new=47'h05D9BE239B4A;
            end
      8'd170: begin
              C3_new=47'h00D4FBCD1097;C2_new=47'h7DEA803A9528;C1_new=47'h06EF8ED7618E;C0_new=47'h05E0AF6FF76A;
              Q2_new=47'h7DEBBFB44531;Q1_new=47'h06EF8E57D704;Q0_new=47'h05E0AF7001F1;
              L1_new=47'h06ED7A178B4A;L0_new=47'h05E0AFC85E9D;
            end
      8'd171: begin
              C3_new=47'h00D37E1CF373;C2_new=47'h7DECFF2D2CBF;C1_new=47'h06EB665693E7;C0_new=47'h05E79CEA2402;
              Q2_new=47'h7DEE3C6A4F56;Q1_new=47'h06EB65D7EDF4;Q0_new=47'h05E79CEA2E76;
              L1_new=47'h06E954145843;L0_new=47'h05E79D42216E;
            end
      8'd172: begin
              C3_new=47'h00D203EDFABE;C2_new=47'h7DEF79A6A943;C1_new=47'h06E742CF32D7;C0_new=47'h05EE863E4D42;
              Q2_new=47'h7DF0B4AC8A0C;Q1_new=47'h06E742516F58;Q0_new=47'h05EE863E57A2;
              L1_new=47'h06E533061BE2;L0_new=47'h05EE8695E1A4;
            end
      8'd173: begin
              C3_new=47'h00D08D2C10F0;C2_new=47'h7DF1EFB1C48F;C1_new=47'h06E3243856A8;C0_new=47'h05F56B71681F;
              Q2_new=47'h7DF328858513;Q1_new=47'h06E323BB7390;Q0_new=47'h05F56B71726D;
              L1_new=47'h06E116E3F916;L0_new=47'h05F56BC89433;
            end
      8'd174: begin
              C3_new=47'h00CF1A01BAEF;C2_new=47'h7DF46158BE38;C1_new=47'h06DF0A892CF5;C0_new=47'h05FC4C8860B5;
              Q2_new=47'h7DF597FFB5F2;Q1_new=47'h06DF0A0D282B;Q0_new=47'h05FC4C886AF0;
              L1_new=47'h06DCFFA527E1;L0_new=47'h05FC4CDF2535;
            end
      8'd175: begin
              C3_new=47'h00CDAA6B2BA8;C2_new=47'h7DF6CEA5DD1B;C1_new=47'h06DAF5B8F858;C0_new=47'h060329881A54;
              Q2_new=47'h7DF803258859;Q1_new=47'h06DAF53DCF97;Q0_new=47'h06032988247E;
              L1_new=47'h06D8ED40F51F;L0_new=47'h060329DE77F8;
            end
      8'd176: begin
              C3_new=47'h00CC3DDE3407;C2_new=47'h7DF937A465AB;C1_new=47'h06D6E5BF0F78;C0_new=47'h060A02756F9D;
              Q2_new=47'h7DFA6A012F83;Q1_new=47'h06D6E544C113;Q0_new=47'h060A027579B5;
              L1_new=47'h06D4DFAEC243;L0_new=47'h060A02CB671B;
            end
      8'd177: begin
              C3_new=47'h00CAD4D47093;C2_new=47'h7DFB9C5D8C83;C1_new=47'h06D2DA92DE86;C0_new=47'h0610D755328F;
              Q2_new=47'h7DFCCC9CC887;Q1_new=47'h06D2DA196855;Q0_new=47'h0610D7553C95;
              L1_new=47'h06D0D6E6051E;L0_new=47'h0610D7AAC49C;
            end
      8'd178: begin
              C3_new=47'h00C96F4886EA;C2_new=47'h7DFDFCDB652B;C1_new=47'h06CED42BE565;C0_new=47'h0617A82C2CA0;
              Q2_new=47'h7DFF2B02526A;Q1_new=47'h06CED3B3454D;Q0_new=47'h0617A82C3694;
              L1_new=47'h06CCD2DE479E;L0_new=47'h0617A88159F0;
            end
      8'd179: begin
              C3_new=47'h00C80CED57BF;C2_new=47'h7E00592854DE;C1_new=47'h06CAD281B7C7;C0_new=47'h061E74FF1ED0;
              Q2_new=47'h7E01853BBE0B;Q1_new=47'h06CAD209EBDA;Q0_new=47'h061E74FF28B2;
              L1_new=47'h06C8D38F2798;L0_new=47'h061E7553E814;
            end
      8'd180: begin
              C3_new=47'h00C6ADADE9B4;C2_new=47'h7E02B14E4533;C1_new=47'h06C6D58BFD53;C0_new=47'h06253DD2C1BD;
              Q2_new=47'h7E03DB52C717;Q1_new=47'h06C6D51503C8;Q0_new=47'h06253DD2CB8E;
              L1_new=47'h06C4D8F0568F;L0_new=47'h06253E2727A5;
            end
      8'd181: begin
              C3_new=47'h00C551C57F36;C2_new=47'h7E050556738E;C1_new=47'h06C2DD42718C;C0_new=47'h062C02ABC5B6;
              Q2_new=47'h7E062D511C52;Q1_new=47'h06C2DCCC4854;Q0_new=47'h062C02ABCF76;
              L1_new=47'h06C0E2F99970;L0_new=47'h062C02FFC8F0;
            end
      8'd182: begin
              C3_new=47'h00C3F8FD83F8;C2_new=47'h7E07554ACF9A;C1_new=47'h06BEE99CE2DD;C0_new=47'h0632C38ED2D0;
              Q2_new=47'h7E087B405439;Q1_new=47'h06BEE9278813;Q0_new=47'h0632C38EDC7F;
              L1_new=47'h06BCF1A2C867;L0_new=47'h0632C3E27409;
            end
      8'd183: begin
              C3_new=47'h00C2A320DD51;C2_new=47'h7E09A1352547;C1_new=47'h06BAFA9332D1;C0_new=47'h0639808088F6;
              Q2_new=47'h7E0AC529CF97;Q1_new=47'h06BAFA1EA4CE;Q0_new=47'h063980809295;
              L1_new=47'h06B904E3CE9E;L0_new=47'h063980D3C8D9;
            end
      8'd184: begin
              C3_new=47'h00C150A70089;C2_new=47'h7E0BE91DF88D;C1_new=47'h06B7101D566F;C0_new=47'h064039858001;
              Q2_new=47'h7E0D0B16EE69;Q1_new=47'h06B70FA99319;Q0_new=47'h06403985898F;
              L1_new=47'h06B51CB4AA08;L0_new=47'h064039D85F38;
            end
      8'd185: begin
              C3_new=47'h00C001430612;C2_new=47'h7E0E2D0F06C5;C1_new=47'h06B32A3354C3;C0_new=47'h0646EEA247C6;
              Q2_new=47'h7E0F4D10EE6F;Q1_new=47'h06B329C05A3D;Q0_new=47'h0646EEA25143;
              L1_new=47'h06B1390D6B2C;L0_new=47'h0646EEF4C6F8;
            end
      8'd186: begin
              C3_new=47'h00BEB4B7FD59;C2_new=47'h7E106D11D848;C1_new=47'h06AF48CD475F;C0_new=47'h064D9FDB682B;
              Q2_new=47'h7E118B20EFAE;Q1_new=47'h06AF485B13FC;Q0_new=47'h064D9FDB7198;
              L1_new=47'h06AD59E634EC;L0_new=47'h064DA02D87FF;
            end
      8'd187: begin
              C3_new=47'h00BD6B1D7944;C2_new=47'h7E12A92F4D34;C1_new=47'h06AB6BE35A57;C0_new=47'h06544D356139;
              Q2_new=47'h7E13C54FFC5F;Q1_new=47'h06AB6B71EC55;Q0_new=47'h06544D356A96;
              L1_new=47'h06A97F373C54;L0_new=47'h06544D872254;
            end
      8'd188: begin
              C3_new=47'h00BC24850DCC;C2_new=47'h7E14E1703092;C1_new=47'h06A7936DCBD4;C0_new=47'h065AF6B4AB2E;
              Q2_new=47'h7E15FBA6F185;Q1_new=47'h06A792FD2171;Q0_new=47'h065AF6B4B47A;
              L1_new=47'h06A5A8F8C863;L0_new=47'h065AF7060E33;
            end
      8'd189: begin
              C3_new=47'h00BAE0FA2AAB;C2_new=47'h7E1715DD3D6C;C1_new=47'h06A3BF64EBCE;C0_new=47'h06619C5DB68F;
              Q2_new=47'h7E182E2EAE22;Q1_new=47'h06A3BEF5032B;Q0_new=47'h06619C5DBFCB;
              L1_new=47'h06A1D72331D8;L0_new=47'h06619CAEBC20;
            end
      8'd190: begin
              C3_new=47'h00B9A04C2B71;C2_new=47'h7E19467F8383;C1_new=47'h069FEFC11BB0;C0_new=47'h06683E34EC39;
              Q2_new=47'h7E1A5CEFF7D4;Q1_new=47'h069FEF51F30A;Q0_new=47'h06683E34F565;
              L1_new=47'h069E09AEE301;L0_new=47'h06683E8594F7;
            end
      8'd191: begin
              C3_new=47'h00B86265EEF3;C2_new=47'h7E1B735FC54A;C1_new=47'h069C247ACE6E;C0_new=47'h066EDC3EAD74;
              Q2_new=47'h7E1C87F35CE6;Q1_new=47'h069C240C6429;Q0_new=47'h066EDC3EB691;
              L1_new=47'h069A40945786;L0_new=47'h066EDC8EF9FF;
            end
      8'd192: begin
              C3_new=47'h00B72771FDB0;C2_new=47'h7E1D9C863E9F;C1_new=47'h06985D8A887B;C0_new=47'h0675767F5405;
              Q2_new=47'h7E1EAF4170A4;Q1_new=47'h06985D1CDAC7;Q0_new=47'h0675767F5D12;
              L1_new=47'h06967BCC1C39;L0_new=47'h067576CF44F9;
            end
      8'd193: begin
              C3_new=47'h00B5EF279AA3;C2_new=47'h7E1FC1FBDE73;C1_new=47'h06949AE8DEEE;C0_new=47'h067C0CFB323B;
              Q2_new=47'h7E20D2E298BF;Q1_new=47'h06949A7BEC49;Q0_new=47'h067C0CFB3B38;
              L1_new=47'h0692BB4ECEE1;L0_new=47'h067C0D4AC836;
            end
      8'd194: begin
              C3_new=47'h00B4B9C7A587;C2_new=47'h7E21E3C887E4;C1_new=47'h0690DC8E7845;C0_new=47'h06829FB69305;
              Q2_new=47'h7E22F2DF371F;Q1_new=47'h0690DC223EDD;Q0_new=47'h06829FB69BF3;
              L1_new=47'h068EFF151E14;L0_new=47'h0682A005CEA1;
            end
      8'd195: begin
              C3_new=47'h00B386F57CAA;C2_new=47'h7E2401F51E07;C1_new=47'h068D22740B16;C0_new=47'h06892EB5B9FF;
              Q2_new=47'h7E250F3F906A;Q1_new=47'h068D2208896A;Q0_new=47'h06892EB5C2DF;
              L1_new=47'h068B4717C8FC;L0_new=47'h06892F049BD6;
            end
      8'd196: begin
              C3_new=47'h00B256ECA260;C2_new=47'h7E261C8961C8;C1_new=47'h06896C925F01;C0_new=47'h068FB9FCE387;
              Q2_new=47'h7E27280BC131;Q1_new=47'h06896C27936D;Q0_new=47'h068FB9FCEC57;
              L1_new=47'h0687934F9F2F;L0_new=47'h068FBA4B6C31;
            end
      8'd197: begin
              C3_new=47'h00B1299793E4;C2_new=47'h7E28338D81C7;C1_new=47'h0685BAE24BC1;C0_new=47'h0696419044C6;
              Q2_new=47'h7E293D4BE390;Q1_new=47'h0685BA78349B;Q0_new=47'h069641904D87;
              L1_new=47'h0683E3B5807F;L0_new=47'h069641DE74DA;
            end
      8'd198: begin
              C3_new=47'h00AFFEEDC2BA;C2_new=47'h7E2A47098C74;C1_new=47'h06820D5CB927;C0_new=47'h069CC5740BC9;
              Q2_new=47'h7E2B4F07F349;Q1_new=47'h06820CF354D7;Q0_new=47'h069CC574147B;
              L1_new=47'h068038425CCB;L0_new=47'h069CC5C1E3DC;
            end
      8'd199: begin
              C3_new=47'h00AED6CBF1F6;C2_new=47'h7E2C5705A004;C1_new=47'h067E63FA9EF6;C0_new=47'h06A345AC5F8A;
              Q2_new=47'h7E2D5D47D457;Q1_new=47'h067E6391EBFE;Q0_new=47'h06A345AC682E;
              L1_new=47'h067C90EF33D2;L0_new=47'h06A345F9E032;
            end
      8'd200: begin
              C3_new=47'h00ADB13795DD;C2_new=47'h7E2E63898528;C1_new=47'h067ABEB504DB;C0_new=47'h06A9C23D6006;
              Q2_new=47'h7E2F681352C6;Q1_new=47'h067ABE4D01B8;Q0_new=47'h06A9C23D689B;
              L1_new=47'h0678EDB5150A;L0_new=47'h06A9C28A89D4;
            end
      8'd201: begin
              C3_new=47'h00AC8E769364;C2_new=47'h7E306C9C730D;C1_new=47'h06771D850259;C0_new=47'h06B03B2B2645;
              Q2_new=47'h7E316F722999;Q1_new=47'h06771D1DAD48;Q0_new=47'h06B03B2B2ECC;
              L1_new=47'h06754E8D1F70;L0_new=47'h06B03B77F9CC;
            end
      8'd202: begin
              C3_new=47'h00AB6DEC79E4;C2_new=47'h7E3272472018;C1_new=47'h06738063BD9A;C0_new=47'h06B6B079C473;
              Q2_new=47'h7E33736C03BA;Q1_new=47'h06737FFD1557;Q0_new=47'h06B6B079CCEB;
              L1_new=47'h0671B370815B;L0_new=47'h06B6B0C64242;
            end
      8'd203: begin
              C3_new=47'h00AA5020A14B;C2_new=47'h7E3474902EA7;C1_new=47'h066FE74A6D19;C0_new=47'h06BD222D45E5;
              Q2_new=47'h7E357408644D;Q1_new=47'h066FE6E46FF7;Q0_new=47'h06BD222D4E50;
              L1_new=47'h066E1C58785A;L0_new=47'h06BD22796E8C;
            end
      8'd204: begin
              C3_new=47'h00A9349D61AF;C2_new=47'h7E36737FE23F;C1_new=47'h066C52325585;C0_new=47'h06C39049AF33;
              Q2_new=47'h7E37714ECCCC;Q1_new=47'h066C51CD0233;Q0_new=47'h06C39049B78F;
              L1_new=47'h066A893E50FE;L0_new=47'h06C390958340;
            end
      8'd205: begin
              C3_new=47'h00A81B9C1BDD;C2_new=47'h7E386F1D3440;C1_new=47'h0668C114CB2D;C0_new=47'h06C9FAD2FE3D;
              Q2_new=47'h7E396B469B61;Q1_new=47'h0668C0B02021;Q0_new=47'h06C9FAD3068B;
              L1_new=47'h0666FA1B66BD;L0_new=47'h06C9FB1E7E3C;
            end
      8'd206: begin
              C3_new=47'h00A705143B3F;C2_new=47'h7E3A676F8658;C1_new=47'h066533EB30DA;C0_new=47'h06D061CD2A41;
              Q2_new=47'h7E3B61F72C32;Q1_new=47'h066533872C8D;Q0_new=47'h06D061CD3281;
              L1_new=47'h06636EE923B9;L0_new=47'h06D0621856BE;
            end
      8'd207: begin
              C3_new=47'h00A5F100C28B;C2_new=47'h7E3C5C7E20B6;C1_new=47'h0661AAAEF7FD;C0_new=47'h06D6C53C23E6;
              Q2_new=47'h7E3D5567A458;Q1_new=47'h0661AA4B9907;Q0_new=47'h06D6C53C2C19;
              L1_new=47'h065FE7A100AC;L0_new=47'h06D6C586FD6C;
            end
      8'd208: begin
              C3_new=47'h00A4DF3BF916;C2_new=47'h7E3E4E5068D7;C1_new=47'h065E2559A068;C0_new=47'h06DD2523D54D;
              Q2_new=47'h7E3F459F452D;Q1_new=47'h065E24F6E564;Q0_new=47'h06DD2523DD73;
              L1_new=47'h065C643C84A9;L0_new=47'h06DD256E5C64;
            end
      8'd209: begin
              C3_new=47'h00A3CFAAAA5B;C2_new=47'h7E403CED9ED3;C1_new=47'h065AA3E4B84A;C0_new=47'h06E38188221D;
              Q2_new=47'h7E4132A5195E;Q1_new=47'h065AA3829FEE;Q0_new=47'h06E381882A35;
              L1_new=47'h0658E4B54507;L0_new=47'h06E381D2574D;
            end
      8'd210: begin
              C3_new=47'h00A2C27CB245;C2_new=47'h7E42285C70E0;C1_new=47'h06572649DC35;C0_new=47'h06E9DA6CE793;
              Q2_new=47'h7E431C8025D7;Q1_new=47'h065725E8650A;Q0_new=47'h06E9DA6CEF9E;
              L1_new=47'h06556904E531;L0_new=47'h06E9DAB6CB62;
            end
      8'd211: begin
              C3_new=47'h00A1B7E51FA0;C2_new=47'h7E4410A36B16;C1_new=47'h0653AC82B6CC;C0_new=47'h06F02FD5FC8E;
              Q2_new=47'h7E4503374913;Q1_new=47'h0653AC21DF39;Q0_new=47'h06F02FD6048C;
              L1_new=47'h0651F1251681;L0_new=47'h06F0301F8F83;
            end
      8'd212: begin
              C3_new=47'h00A0AF41C5B9;C2_new=47'h7E45F5CA9563;C1_new=47'h06503688FFB5;C0_new=47'h06F681C731A0;
              Q2_new=47'h7E46E6D1767D;Q1_new=47'h06503628C6A4;Q0_new=47'h06F681C73991;
              L1_new=47'h064E7D0F981A;L0_new=47'h06F68210743F;
            end
      8'd213: begin
              C3_new=47'h009FA8F8B2D2;C2_new=47'h7E47D7D7EDC4;C1_new=47'h064CC4567D62;C0_new=47'h06FCD044511A;
              Q2_new=47'h7E48C75565CD;Q1_new=47'h064CC3F6E15D;Q0_new=47'h06FCD04458FD;
              L1_new=47'h064B0CBE36C4;L0_new=47'h06FCD08D43E6;
            end
      8'd214: begin
              C3_new=47'h009EA4F290D7;C2_new=47'h7E49B6D25DB0;C1_new=47'h064955E50345;C0_new=47'h07031B511F18;
              Q2_new=47'h7E4AA4C9CD64;Q1_new=47'h0649558602F4;Q0_new=47'h07031B5126EF;
              L1_new=47'h0647A02ACCC2;L0_new=47'h07031B99C293;
            end
      8'd215: begin
              C3_new=47'h009DA3058756;C2_new=47'h7E4B92C0D232;C1_new=47'h0645EB2E7232;C0_new=47'h070962F15992;
              Q2_new=47'h7E4C7F355501;Q1_new=47'h0645EAD00C5D;Q0_new=47'h070962F1615D;
              L1_new=47'h0644374F41B3;L0_new=47'h07096339AE3E;
            end
      8'd216: begin
              C3_new=47'h009CA3712E9D;C2_new=47'h7E4D6BA96CAE;C1_new=47'h0642842CB8A4;C0_new=47'h070FA728B868;
              Q2_new=47'h7E4E569E9836;Q1_new=47'h064283CEEBD5;Q0_new=47'h070FA728C026;
              L1_new=47'h0640D2258A6D;L0_new=47'h070FA770BEC5;
            end
      8'd217: begin
              C3_new=47'h009BA5FCF709;C2_new=47'h7E4F4192FF25;C1_new=47'h063F20D9D1E3;C0_new=47'h0715E7FAED6E;
              Q2_new=47'h7E502B0C0605;Q1_new=47'h063F207C9CD0;Q0_new=47'h0715E7FAF51F;
              L1_new=47'h063D70A7A8D8;L0_new=47'h0715E842A5F9;
            end
      8'd218: begin
              C3_new=47'h009AAA932B22;C2_new=47'h7E5114843063;C1_new=47'h063BC12FC62F;C0_new=47'h071C256BA479;
              Q2_new=47'h7E51FC8411C2;Q1_new=47'h063BC0D327B5;Q0_new=47'h071C256BAC1D;
              L1_new=47'h063A12CFABC5;L0_new=47'h071C25B30FB1;
            end
      8'd219: begin
              C3_new=47'h0099B1306922;C2_new=47'h7E52E4835855;C1_new=47'h06386528AAD7;C0_new=47'h07225F7E836E;
              Q2_new=47'h7E53CB0D1F1D;Q1_new=47'h063864CCA1BA;Q0_new=47'h07225F7E8B06;
              L1_new=47'h0636B897AEDA;L0_new=47'h07225FC5A1D0;
            end
      8'd220: begin
              C3_new=47'h0098BA159090;C2_new=47'h7E54B19652A1;C1_new=47'h06350CBEA210;C0_new=47'h072896372A4D;
              Q2_new=47'h7E5596AD7478;Q1_new=47'h06350C632CE8;Q0_new=47'h0728963731D9;
              L1_new=47'h063361F9DA5D;L0_new=47'h0728967DFC55;
            end
      8'd221: begin
              C3_new=47'h0097C4D46D9B;C2_new=47'h7E567BC4181A;C1_new=47'h0631B7EBDA15;C0_new=47'h072EC9993340;
              Q2_new=47'h7E575F6B55C8;Q1_new=47'h0631B790F7CE;Q0_new=47'h072EC9993AC0;
              L1_new=47'h06300EF06323;L0_new=47'h072EC9DFB968;
            end
      8'd222: begin
              C3_new=47'h0096D1C05D79;C2_new=47'h7E584312422A;C1_new=47'h062E66AA8E3A;C0_new=47'h0734F9A832A3;
              Q2_new=47'h7E59254CE57B;Q1_new=47'h062E66503D80;Q0_new=47'h0734F9A83A17;
              L1_new=47'h062CBF758A63;L0_new=47'h0734F9EE6D65;
            end
      8'd223: begin
              C3_new=47'h0095E0BF6C97;C2_new=47'h7E5A07871C59;C1_new=47'h062B18F505C9;C0_new=47'h073B2667B715;
              Q2_new=47'h7E5AE858369B;Q1_new=47'h062B189B4566;Q0_new=47'h073B2667BE7D;
              L1_new=47'h062973839D9D;L0_new=47'h073B26ADA6EA;
            end
      8'd224: begin
              C3_new=47'h0094F1B1D9C6;C2_new=47'h7E5BC928D964;C1_new=47'h0627CEC5944D;C0_new=47'h07414FDB4982;
              Q2_new=47'h7E5CA8936708;Q1_new=47'h0627CE6C6308;Q0_new=47'h07414FDB50DF;
              L1_new=47'h06262B14F66F;L0_new=47'h07415020EEE2;
            end
      8'd225: begin
              C3_new=47'h009404B1BE45;C2_new=47'h7E5D87FD54EF;C1_new=47'h062488169973;C0_new=47'h074776066D31;
              Q2_new=47'h7E5E66045DAE;Q1_new=47'h062487BDF623;Q0_new=47'h074776067482;
              L1_new=47'h0622E623FA7F;L0_new=47'h0747764BC892;
            end
      8'd226: begin
              C3_new=47'h00931983D7FA;C2_new=47'h7E5F440ACC54;C1_new=47'h062144E280C6;C0_new=47'h074D98EC9FCD;
              Q2_new=47'h7E6020B11164;Q1_new=47'h0621448A6A47;Q0_new=47'h074D98ECA712;
              L1_new=47'h061FA4AB1B58;L0_new=47'h074D9931B1A4;
            end
      8'd227: begin
              C3_new=47'h009230869BD0;C2_new=47'h7E60FD5684A2;C1_new=47'h061E0523C1F3;C0_new=47'h0753B8915972;
              Q2_new=47'h7E61D89F5C4E;Q1_new=47'h061E04CC36EB;Q0_new=47'h0753B89160AB;
              L1_new=47'h061C66A4D647;L0_new=47'h0753B8D62235;
            end
      8'd228: begin
              C3_new=47'h00914915625E;C2_new=47'h7E62B3E75ACC;C1_new=47'h061AC8D4DFA7;C0_new=47'h0759D4F80CBB;
              Q2_new=47'h7E638DD500DD;Q1_new=47'h061AC87DDF3E;Q0_new=47'h0759D4F813E9;
              L1_new=47'h06192C0BB441;L0_new=47'h0759D53C8CDD;
            end
      8'd229: begin
              C3_new=47'h009063C9DA0E;C2_new=47'h7E6467C20859;C1_new=47'h06178FF06919;C0_new=47'h075FEE2426CB;
              Q2_new=47'h7E654057BE5C;Q1_new=47'h06178F99F200;Q0_new=47'h075FEE242DED;
              L1_new=47'h0615F4DA49BF;L0_new=47'h075FEE685EBF;
            end
      8'd230: begin
              C3_new=47'h008F804E808D;C2_new=47'h7E6618ECCD2F;C1_new=47'h06145A70F839;C0_new=47'h076604190F5A;
              Q2_new=47'h7E66F02D407C;Q1_new=47'h06145A1B0963;Q0_new=47'h076604191671;
              L1_new=47'h0612C10B36A4;L0_new=47'h0766045CFF92;
            end
      8'd231: begin
              C3_new=47'h008E9E9E395D;C2_new=47'h7E67C76D3D23;C1_new=47'h0611285132A6;C0_new=47'h076C16DA28BF;
              Q2_new=47'h7E689D5B28F8;Q1_new=47'h061127FBCAF5;Q0_new=47'h076C16DA2FCB;
              L1_new=47'h060F9099261D;L0_new=47'h076C171DD1AC;
            end
      8'd232: begin
              C3_new=47'h008DBEC3670B;C2_new=47'h7E697348EAA8;C1_new=47'h060DF98BC91C;C0_new=47'h0772266ACFFE;
              Q2_new=47'h7E6A47E70459;Q1_new=47'h060DF936E781;Q0_new=47'h0772266AD6FF;
              L1_new=47'h060C637ECE87;L0_new=47'h077226AE320F;
            end
      8'd233: begin
              C3_new=47'h008CE0FAAA86;C2_new=47'h7E6B1C84E0FA;C1_new=47'h060ACE1B77C8;C0_new=47'h077832CE5CCE;
              Q2_new=47'h7E6BEFD65D77;Q1_new=47'h060ACDC71AEC;Q0_new=47'h077832CE63C5;
              L1_new=47'h060939B6F14A;L0_new=47'h077833117874;
            end
      8'd234: begin
              C3_new=47'h008C04B77A3E;C2_new=47'h7E6CC327822F;C1_new=47'h0607A5FB051C;C0_new=47'h077E3C0821AC;
              Q2_new=47'h7E6D952E9435;Q1_new=47'h0607A5A72C2F;Q0_new=47'h077E3C082897;
              L1_new=47'h0606133C5AC4;L0_new=47'h077E3C4AF753;
            end
      8'd235: begin
              C3_new=47'h008B2A746E5D;C2_new=47'h7E6E67356111;C1_new=47'h060481254354;C0_new=47'h0784421B6BDD;
              Q2_new=47'h7E6F37F51439;Q1_new=47'h060480D1ED14;Q0_new=47'h0784421B72BE;
              L1_new=47'h0602F009E228;L0_new=47'h0784425DFBF4;
            end
      8'd236: begin
              C3_new=47'h008A51E54500;C2_new=47'h7E7008B4650B;C1_new=47'h06015F950EB3;C0_new=47'h078A450B8381;
              Q2_new=47'h7E70D82F38C8;Q1_new=47'h06015F423A2B;Q0_new=47'h078A450B8A56;
              L1_new=47'h05FFD01A6965;L0_new=47'h078A454DCE73;
            end
      8'd237: begin
              C3_new=47'h00897B0EA190;C2_new=47'h7E71A7A9B0F3;C1_new=47'h05FE41454EA1;C0_new=47'h079044DBAB96;
              Q2_new=47'h7E7275E24416;Q1_new=47'h05FE40F2FAC2;Q0_new=47'h079044DBB261;
              L1_new=47'h05FCB368DD05;L0_new=47'h0790451DB1CF;
            end
      8'd238: begin
              C3_new=47'h0088A60D0F66;C2_new=47'h7E73441A6461;C1_new=47'h05FB2630F4F9;C0_new=47'h0796418F2209;
              Q2_new=47'h7E7411137579;Q1_new=47'h05FB25DF20A2;Q0_new=47'h0796418F28CA;
              L1_new=47'h05F999F03417;L0_new=47'h079641D0E3F4;
            end
      8'd239: begin
              C3_new=47'h0087D27A785E;C2_new=47'h7E74DE0C48B9;C1_new=47'h05F80E52FDB9;C0_new=47'h079C3B291FBE;
              Q2_new=47'h7E75A9C7F441;Q1_new=47'h05F80E01A821;Q0_new=47'h079C3B292675;
              L1_new=47'h05F683AB7015;L0_new=47'h079C3B6A9DC5;
            end
      8'd240: begin
              C3_new=47'h008700FD7F92;C2_new=47'h7E76758369D6;C1_new=47'h05F4F9A6700C;C0_new=47'h07A231ACD89B;
              Q2_new=47'h7E774004EC4D;Q1_new=47'h05F4F95597D1;Q0_new=47'h07A231ACDF47;
              L1_new=47'h05F370959CBE;L0_new=47'h07A231EE1326;
            end
      8'd241: begin
              C3_new=47'h008630FAE5D0;C2_new=47'h7E780A85E679;C1_new=47'h05F1E8265C4F;C0_new=47'h07A8251D7B8F;
              Q2_new=47'h7E78D3CF6036;Q1_new=47'h05F1E7D600AB;Q0_new=47'h07A8251D8231;
              L1_new=47'h05F060A9D00A;L0_new=47'h07A8255E7307;
            end
      8'd242: begin
              C3_new=47'h008562A04A11;C2_new=47'h7E799D186E83;C1_new=47'h05EED9CDDDBB;C0_new=47'h07AE157E32A2;
              Q2_new=47'h7E7A652C5BA6;Q1_new=47'h05EED97DFDAF;Q0_new=47'h07AE157E393A;
              L1_new=47'h05ED53E32A09;L0_new=47'h07AE15BEE76E;
            end
      8'd243: begin
              C3_new=47'h0084960F943C;C2_new=47'h7E7B2D3FC3E5;C1_new=47'h05EBCE98197B;C0_new=47'h07B402D222FB;
              Q2_new=47'h7E7BF420DD23;Q1_new=47'h05EBCE48B3E9;Q0_new=47'h07B402D22988;
              L1_new=47'h05EA4A3CD4C5;L0_new=47'h07B403129581;
            end
      8'd244: begin
              C3_new=47'h0083CAD1E3FC;C2_new=47'h7E7CBB0195A0;C1_new=47'h05E8C6803E38;C0_new=47'h07B9ED1C6CEB;
              Q2_new=47'h7E7D80B1CFFC;Q1_new=47'h05E8C631525F;Q0_new=47'h07B9ED1C736E;
              L1_new=47'h05E743B20430;L0_new=47'h07B9ED5C9D90;
            end
      8'd245: begin
              C3_new=47'h008301839FB6;C2_new=47'h7E7E4661C0C1;C1_new=47'h05E5C1818550;C0_new=47'h07BFD4602BF5;
              Q2_new=47'h7E7F0AE40AB1;Q1_new=47'h05E5C13311FB;Q0_new=47'h07BFD460326E;
              L1_new=47'h05E4403DF606;L0_new=47'h07BFD4A01B20;
            end
      8'd246: begin
              C3_new=47'h0082399F02CB;C2_new=47'h7E7FCF65F85A;C1_new=47'h05E2BF9730EB;C0_new=47'h07C5B8A076DE;
              Q2_new=47'h7E8092BC6373;Q1_new=47'h05E2BF493553;Q0_new=47'h07C5B8A07D4D;
              L1_new=47'h05E13FDBF1B7;L0_new=47'h07C5B8E024F1;
            end
      8'd247: begin
              C3_new=47'h00817367FA0E;C2_new=47'h7E8156128790;C1_new=47'h05DFC0BC8D93;C0_new=47'h07CB99E05FAE;
              Q2_new=47'h7E82183FA74F;Q1_new=47'h05DFC06F08A6;Q0_new=47'h07CB99E06614;
              L1_new=47'h05DE4287484E;L0_new=47'h07CB9A1FCD0D;
            end
      8'd248: begin
              C3_new=47'h0080AEC80C1B;C2_new=47'h7E82DA6C577E;C1_new=47'h05DCC4ECF0FC;C0_new=47'h07D17822F3C2;
              Q2_new=47'h7E839B728799;Q1_new=47'h05DCC49FE1CC;Q0_new=47'h07D17822FA1E;
              L1_new=47'h05DB483B5454;L0_new=47'h07D1786220CF;
            end
      8'd249: begin
              C3_new=47'h007FEBA95A98;C2_new=47'h7E845C7840F7;C1_new=47'h05D9CC23BA51;C0_new=47'h07D7536B3BCE;
              Q2_new=47'h7E851C59BEA3;Q1_new=47'h05D9CBD72000;Q0_new=47'h07D7536B4220;
              L1_new=47'h05D850F379BF;L0_new=47'h07D753AA28EB;
            end
      8'd250: begin
              C3_new=47'h007F2A046BF4;C2_new=47'h7E85DC3AE3AE;C1_new=47'h05D6D65C5245;C0_new=47'h07DD2BBC3BEC;
              Q2_new=47'h7E869AF9E6AF;Q1_new=47'h05D6D6102BED;Q0_new=47'h07DD2BBC4235;
              L1_new=47'h05D55CAB25D3;L0_new=47'h07DD2BFAE97A;
            end
      8'd251: begin
              C3_new=47'h007E6A191CBE;C2_new=47'h7E8759B87181;C1_new=47'h05D3E3922AEA;C0_new=47'h07E30118F3A3;
              Q2_new=47'h7E8817579B27;Q1_new=47'h05D3E3467776;Q0_new=47'h07E30118F9E2;
              L1_new=47'h05D26B5DCF14;L0_new=47'h07E301576202;
            end
      8'd252: begin
              C3_new=47'h007DAB8453F9;C2_new=47'h7E88D4F61CC7;C1_new=47'h05D0F3C0BF0B;C0_new=47'h07E8D3845DF1;
              Q2_new=47'h7E899177677D;Q1_new=47'h05D0F3757DB7;Q0_new=47'h07E8D3846426;
              L1_new=47'h05CF7D06F51F;L0_new=47'h07E8D3C28D80;
            end
      8'd253: begin
              C3_new=47'h007CEE6D1D54;C2_new=47'h7E8A4DF82004;C1_new=47'h05CE06E392FD;C0_new=47'h07EEA3017151;
              Q2_new=47'h7E8B095DC955;Q1_new=47'h05CE0698C2E1;Q0_new=47'h07EEA301777E;
              L1_new=47'h05CC91A220AB;L0_new=47'h07EEA33F6270;
            end
      8'd254: begin
              C3_new=47'h007C32DFB99E;C2_new=47'h7E8BC4C2E18F;C1_new=47'h05CB1CF633EA;C0_new=47'h07F46F931FCB;
              Q2_new=47'h7E8C7F0F35CE;Q1_new=47'h05CB1CABD422;Q0_new=47'h07F46F9325EE;
              L1_new=47'h05C9A92AE359;L0_new=47'h07F46FD0D2D6;
            end
      8'd255: begin
              C3_new=47'h007B789E3D42;C2_new=47'h7E8D395B2CC2;C1_new=47'h05C835F437CA;C0_new=47'h07FA393C56F5;
              Q2_new=47'h7E8DF29018DF;Q1_new=47'h05C835AA4792;Q0_new=47'h07FA393C5D0F;
              L1_new=47'h05C6C39CD7AB;L0_new=47'h07FA3979CC4A;
            end
     endcase
  end  // end of always block
  
  // assign the coefficients
  assign coef3_sh_dist_new = ((`coef_max_size-`coef3_size)<0)?0:
                            $unsigned(`coef_max_size-`coef3_size);
  assign coef2_sh_dist_new = ((`coef_max_size-`coef2_size)<0)?0:
                            $unsigned(`coef_max_size-`coef2_size);
  assign coef1_sh_dist_new = ((`coef_max_size-`coef1_size)<0)?0:
                            $unsigned(`coef_max_size-`coef1_size);
  assign coef0_sh_dist_new = ((`coef_max_size-`coef0_size)<0)?0:
                            $unsigned(`coef_max_size-`coef0_size);
  assign Coef3_new = (op_width < `min_op_width_cubic)?0:
                $signed(C3_new) >>> coef3_sh_dist_new;
  assign Coef2_new = (op_width < `min_op_width_quadratic)?0:
                (op_width < `min_op_width_cubic)?
	           $signed(Q2_new) >>> coef2_sh_dist_new:
	           $signed(C2_new) >>> coef2_sh_dist_new;
  assign Coef1_new = (op_width < `min_op_width_linear)?0:
                (op_width < `min_op_width_quadratic)?
                    $signed(L1_new) >>> coef1_sh_dist_new:
                    (op_width < `min_op_width_cubic)?   
                       $signed(Q1_new) >>> coef1_sh_dist_new:
	               $signed(C1_new) >>> coef1_sh_dist_new;
  assign Coef0_new = (op_width < `min_op_width_linear)?0:
                (op_width < `min_op_width_quadratic)?
                   $signed(L0_new) >>> coef0_sh_dist_new:
                   (op_width < `min_op_width_cubic)?   
                     $signed(Q0_new) >>> coef0_sh_dist_new:
                     $signed(C0_new) >>> coef0_sh_dist_new;
  assign a_square = short_a * short_a;
  assign a_square_trunc = (op_width-2)<`extra_LSBs?
                          a_square << (`extra_LSBs-op_width+2):
                          a_square >> (op_width-2-`extra_LSBs);
  assign a_cube = short_a * short_a * short_a;
  assign a_cube_trunc = (2*op_width-3)<`extra_LSBs?
                        a_cube << (`extra_LSBs-2*op_width+3):
                        a_cube >> (2*op_width-3-`extra_LSBs);
  assign p3_new = (arch == 0)?
              $signed(Coef3_new) * $signed({1'b0,short_a}) + $signed({Coef2_new,{op_width-1+`bits{1'b0}}}):
              $signed(Coef3_new) * $signed(a_cube_trunc);
  assign p3_aligned_new = (arch == 0)?
                      $signed(p3_new) >>> (op_width-1+`bits):
                      $signed(p3_new) >>> (op_width+`extra_LSBs+`bits);
  assign p2_new = (arch == 0)?
              $signed(p3_aligned_new) * $signed({1'b0,short_a}) + $signed({Coef1_new,{op_width-1{1'b0}}}):
              $signed(Coef2_new) * $signed(a_square_trunc);
  assign p2_aligned_new = (arch == 0)?
                      $signed(p2_new) >>> (op_width-1):
                      $signed(p2_new) >>> (op_width+`extra_LSBs);
  assign p1_new = (arch == 0)?
              $signed(p2_aligned_new) * $signed({1'b0,short_a}) + $signed({Coef0_new,{op_width-1{1'b0}}}):
              $signed(Coef1_new) * $signed({1'b0,short_a});
  assign p1_aligned_new = (arch == 0)?$signed(p1_new) >>> (op_width-1):
                      $signed(p1_new) >>> (op_width-1);
  assign z_int_new = (arch == 0)?
                 p1_aligned_new:
                 p3_aligned_new+p2_aligned_new+p1_aligned_new+Coef0_new;
  assign z_round_new =  (err_range == 1)?
                    z_int_new[`z_int_size-1:`extra_LSBs]+
                    z_int_new[`extra_LSBs-1]:
                    z_int_new[`z_int_size-1:`extra_LSBs];
  assign z_poly_new = z_round_new;

//----------------------------------------------------------------------
// The following commands describe the computation of log2 using 
// multiplicative normalization
// Extra bits are added to the LS positions
// Besides that, one integer bit plus a sign bit are used
`define extra_bits 4
// this information is collected based on the table size
// created using other programs.
`define r4table_nrows 264
`define r4table_wordsize 68
`define r4table_addrsize 9

function [op_width+`extra_bits+2:0] log2_table;
  input [`r4table_addrsize-1:0] addr;
  reg [`r4table_wordsize-1:0] rom_out;
  
  begin
     case (addr)
      9'd8: rom_out = 68'hEB6587B432E47501C;
      9'd9: rom_out = 68'h00000000000000000;
      9'd10: rom_out = 68'hDA8FF971810A5E182;
      9'd11: rom_out = 68'hCC544C055FDE99334;
      9'd12: rom_out = 68'h1A8FF971810A5E180;
      9'd13: rom_out = 68'hCC544C055FDE99334;
      9'd14: rom_out = 68'h40000000000000000;
      9'd15: rom_out = 68'hCC544C055FDE99334;
      9'd16: rom_out = 68'hFA6702414DBB3A60D;
      9'd17: rom_out = 68'h00000000000000000;
      9'd18: rom_out = 68'hF51FF2E30214BC303;
      9'd19: rom_out = 68'hF021F4A37ECBFAEE3;
      9'd20: rom_out = 68'h05F58125B3EED319B;
      9'd21: rom_out = 68'hF021F4A37ECBFAEE3;
      9'd22: rom_out = 68'h0C544C055FDE99333;
      9'd23: rom_out = 68'hF021F4A37ECBFAEE3;
      9'd24: rom_out = 68'hFE918697A3D2DD676;
      9'd25: rom_out = 68'h00000000000000000;
      9'd26: rom_out = 68'hFD28A5914E204F19D;
      9'd27: rom_out = 68'hFBC531D8175819531;
      9'd28: rom_out = 68'h01743EE861F355635;
      9'd29: rom_out = 68'hFBC531D8175819531;
      9'd30: rom_out = 68'h02EE72993B2B1AABA;
      9'd31: rom_out = 68'hFBC531D8175819531;
      9'd32: rom_out = 68'hFFA3D8EE4A154E22D;
      9'd33: rom_out = 68'h00000000000000000;
      9'd34: rom_out = 68'hFF480D7A4887BD740;
      9'd35: rom_out = 68'hFEEC9CEE85684F3B5;
      9'd36: rom_out = 68'h005C836701AA0D7A9;
      9'd37: rom_out = 68'hFEEC9CEE85684F3B5;
      9'd38: rom_out = 68'h00B963DD107B993AD;
      9'd39: rom_out = 68'hFEEC9CEE85684F3B5;
      9'd40: rom_out = 68'hFFE8ED9AC8BC0BABF;
      9'd41: rom_out = 68'h00000000000000000;
      9'd42: rom_out = 68'hFFD1E0F801EB15368;
      9'd43: rom_out = 68'hFFBADA14CC207B8C2;
      9'd44: rom_out = 68'h0017182A894B69C58;
      9'd45: rom_out = 68'hFFBADA14CC207B8C2;
      9'd46: rom_out = 68'h002E361D485CBFB44;
      9'd47: rom_out = 68'hFFBADA14CC207B8C2;
      9'd48: rom_out = 68'hFFFA3ADC4F57900DD;
      9'd49: rom_out = 68'h00000000000000000;
      9'd50: rom_out = 68'hFFF47614E843541E8;
      9'd51: rom_out = 68'hFFEEB1A9BF3BE6D05;
      9'd52: rom_out = 68'h0005C58005C632CAA;
      9'd53: rom_out = 68'hFFEEB1A9BF3BE6D05;
      9'd54: rom_out = 68'h000B8B5C6C35E142A;
      9'd55: rom_out = 68'hFFEEB1A9BF3BE6D05;
      9'd56: rom_out = 68'hFFFE8EAE6C4E82CA2;
      9'd57: rom_out = 68'h00000000000000000;
      9'd58: rom_out = 68'hFFFD1D629DC0B593A;
      9'd59: rom_out = 68'hFFFBAC1C9428710C3;
      9'd60: rom_out = 68'h00017157590356AEC;
      9'd61: rom_out = 68'hFFFBAC1C9428710C3;
      9'd62: rom_out = 68'h0002E2B47786B27A9;
      9'd63: rom_out = 68'hFFFBAC1C9428710C3;
      9'd64: rom_out = 68'hFFFFA3AB1095C1F76;
      9'd65: rom_out = 68'h00000000000000000;
      9'd66: rom_out = 68'hFFFF47567D7FE8DA8;
      9'd67: rom_out = 68'hFFFEEB0246BDBC026;
      9'd68: rom_out = 68'h00005C554BBF5B9D7;
      9'd69: rom_out = 68'hFFFEEB0246BDBC026;
      9'd70: rom_out = 68'h0000B8AAF3D48D7B0;
      9'd71: rom_out = 68'hFFFEEB0246BDBC026;
      9'd72: rom_out = 68'hFFFFE8EABB7D7CEE8;
      9'd73: rom_out = 68'h00000000000000000;
      9'd74: rom_out = 68'hFFFFD1D57CC048D3B;
      9'd75: rom_out = 68'hFFFFBAC043C860CCE;
      9'd76: rom_out = 68'h000017154A47D4EAB;
      9'd77: rom_out = 68'hFFFFBAC043C860CCE;
      9'd78: rom_out = 68'h00002E2A9A54FE917;
      9'd79: rom_out = 68'hFFFFBAC043C860CCE;
      9'd80: rom_out = 68'hFFFFFA3AAE54DFAC1;
      9'd81: rom_out = 68'h00000000000000000;
      9'd82: rom_out = 68'hFFFFF4755D06146A4;
      9'd83: rom_out = 68'hFFFFEEB00C139E2EE;
      9'd84: rom_out = 68'h000005C5520775717;
      9'd85: rom_out = 68'hFFFFEEB00C139E2EE;
      9'd86: rom_out = 68'h00000B8AA46B400C0;
      9'd87: rom_out = 68'hFFFFEEB00C139E2EE;
      9'd88: rom_out = 68'hFFFFFE8EAB8C8FF0B;
      9'd89: rom_out = 68'h00000000000000000;
      9'd90: rom_out = 68'hFFFFFD1D571EE5331;
      9'd91: rom_out = 68'hFFFFFBAC02B6FFC6F;
      9'd92: rom_out = 68'h00000171547935612;
      9'd93: rom_out = 68'hFFFFFBAC02B6FFC6F;
      9'd94: rom_out = 68'h000002E2A8F830144;
      9'd95: rom_out = 68'hFFFFFBAC02B6FFC6F;
      9'd96: rom_out = 68'hFFFFFFA3AAE2997C8;
      9'd97: rom_out = 68'h00000000000000000;
      9'd98: rom_out = 68'hFFFFFF4755C58F4E2;
      9'd99: rom_out = 68'hFFFFFEEB00A8E174D;
      9'd100: rom_out = 68'h0000005C551DC2D89;
      9'd101: rom_out = 68'hFFFFFEEB00A8E174D;
      9'd102: rom_out = 68'h000000B8AA3BE2065;
      9'd103: rom_out = 68'hFFFFFEEB00A8E174D;
      9'd104: rom_out = 68'hFFFFFFE8EAB89DB72;
      9'd105: rom_out = 68'h00000000000000000;
      9'd106: rom_out = 68'hFFFFFFD1D57141339;
      9'd107: rom_out = 68'hFFFFFFBAC029EA756;
      9'd108: rom_out = 68'h000000171547680E2;
      9'd109: rom_out = 68'hFFFFFFBAC029EA756;
      9'd110: rom_out = 68'h0000002E2A8ED5E1A;
      9'd111: rom_out = 68'hFFFFFFBAC029EA756;
      9'd112: rom_out = 68'hFFFFFFFA3AAE26E34;
      9'd113: rom_out = 68'h00000000000000000;
      9'd114: rom_out = 68'hFFFFFFF4755C4E22E;
      9'd115: rom_out = 68'hFFFFFFEEB00A75BED;
      9'd116: rom_out = 68'h00000005C551D9790;
      9'd117: rom_out = 68'hFFFFFFEEB00A75BED;
      9'd118: rom_out = 68'h0000000B8AA3B34E6;
      9'd119: rom_out = 68'hFFFFFFEEB00A75BED;
      9'd120: rom_out = 68'hFFFFFFFE8EAB89B02;
      9'd121: rom_out = 68'h00000000000000000;
      9'd122: rom_out = 68'hFFFFFFFD1D5713661;
      9'd123: rom_out = 68'hFFFFFFFBAC029D21C;
      9'd124: rom_out = 68'h00000001715476559;
      9'd125: rom_out = 68'hFFFFFFFBAC029D21C;
      9'd126: rom_out = 68'h00000002E2A8ECB0F;
      9'd127: rom_out = 68'hFFFFFFFBAC029D21C;
      9'd128: rom_out = 68'hFFFFFFFFA3AAE26B8;
      9'd129: rom_out = 68'h00000000000000000;
      9'd130: rom_out = 68'hFFFFFFFF4755C4D75;
      9'd131: rom_out = 68'hFFFFFFFEEB00A7439;
      9'd132: rom_out = 68'h000000005C551D94D;
      9'd133: rom_out = 68'hFFFFFFFEEB00A7439;
      9'd134: rom_out = 68'h00000000B8AA3B2A1;
      9'd135: rom_out = 68'hFFFFFFFEEB00A7439;
      9'd136: rom_out = 68'hFFFFFFFFE8EAB89AE;
      9'd137: rom_out = 68'h00000000000000000;
      9'd138: rom_out = 68'hFFFFFFFFD1D57135C;
      9'd139: rom_out = 68'hFFFFFFFFBAC029D09;
      9'd140: rom_out = 68'h00000000171547652;
      9'd141: rom_out = 68'hFFFFFFFFBAC029D09;
      9'd142: rom_out = 68'h000000002E2A8ECA6;
      9'd143: rom_out = 68'hFFFFFFFFBAC029D09;
      9'd144: rom_out = 68'hFFFFFFFFFA3AAE26C;
      9'd145: rom_out = 68'h00000000000000000;
      9'd146: rom_out = 68'hFFFFFFFFF4755C4D7;
      9'd147: rom_out = 68'hFFFFFFFFEEB00A742;
      9'd148: rom_out = 68'h0000000005C551D94;
      9'd149: rom_out = 68'hFFFFFFFFEEB00A742;
      9'd150: rom_out = 68'h000000000B8AA3B29;
      9'd151: rom_out = 68'hFFFFFFFFEEB00A742;
      9'd152: rom_out = 68'hFFFFFFFFFE8EAB89B;
      9'd153: rom_out = 68'h00000000000000000;
      9'd154: rom_out = 68'hFFFFFFFFFD1D57136;
      9'd155: rom_out = 68'hFFFFFFFFFBAC029D1;
      9'd156: rom_out = 68'h00000000017154765;
      9'd157: rom_out = 68'hFFFFFFFFFBAC029D1;
      9'd158: rom_out = 68'h0000000002E2A8ECA;
      9'd159: rom_out = 68'hFFFFFFFFFBAC029D1;
      9'd160: rom_out = 68'hFFFFFFFFFFA3AAE26;
      9'd161: rom_out = 68'h00000000000000000;
      9'd162: rom_out = 68'hFFFFFFFFFF4755C4D;
      9'd163: rom_out = 68'hFFFFFFFFFEEB00A74;
      9'd164: rom_out = 68'h00000000005C551D9;
      9'd165: rom_out = 68'hFFFFFFFFFEEB00A74;
      9'd166: rom_out = 68'h0000000000B8AA3B2;
      9'd167: rom_out = 68'hFFFFFFFFFEEB00A74;
      9'd168: rom_out = 68'hFFFFFFFFFFE8EAB89;
      9'd169: rom_out = 68'h00000000000000000;
      9'd170: rom_out = 68'hFFFFFFFFFFD1D5713;
      9'd171: rom_out = 68'hFFFFFFFFFFBAC029D;
      9'd172: rom_out = 68'h00000000001715476;
      9'd173: rom_out = 68'hFFFFFFFFFFBAC029D;
      9'd174: rom_out = 68'h00000000002E2A8EC;
      9'd175: rom_out = 68'hFFFFFFFFFFBAC029D;
      9'd176: rom_out = 68'hFFFFFFFFFFFA3AAE2;
      9'd177: rom_out = 68'h00000000000000000;
      9'd178: rom_out = 68'hFFFFFFFFFFF4755C4;
      9'd179: rom_out = 68'hFFFFFFFFFFEEB00A8;
      9'd180: rom_out = 68'h000000000005C551D;
      9'd181: rom_out = 68'hFFFFFFFFFFEEB00A8;
      9'd182: rom_out = 68'h00000000000B8AA3B;
      9'd183: rom_out = 68'hFFFFFFFFFFEEB00A8;
      9'd184: rom_out = 68'hFFFFFFFFFFFE8EAB8;
      9'd185: rom_out = 68'h00000000000000000;
      9'd186: rom_out = 68'hFFFFFFFFFFFD1D571;
      9'd187: rom_out = 68'hFFFFFFFFFFFBAC02A;
      9'd188: rom_out = 68'h00000000000171547;
      9'd189: rom_out = 68'hFFFFFFFFFFFBAC02A;
      9'd190: rom_out = 68'h000000000002E2A8E;
      9'd191: rom_out = 68'hFFFFFFFFFFFBAC02A;
      9'd192: rom_out = 68'hFFFFFFFFFFFFA3AAF;
      9'd193: rom_out = 68'h00000000000000000;
      9'd194: rom_out = 68'hFFFFFFFFFFFF4755C;
      9'd195: rom_out = 68'hFFFFFFFFFFFEEB00A;
      9'd196: rom_out = 68'h0000000000005C551;
      9'd197: rom_out = 68'hFFFFFFFFFFFEEB00A;
      9'd198: rom_out = 68'h000000000000B8AA3;
      9'd199: rom_out = 68'hFFFFFFFFFFFEEB00A;
      9'd200: rom_out = 68'hFFFFFFFFFFFFE8EAC;
      9'd201: rom_out = 68'h00000000000000000;
      9'd202: rom_out = 68'hFFFFFFFFFFFFD1D57;
      9'd203: rom_out = 68'hFFFFFFFFFFFFBAC02;
      9'd204: rom_out = 68'h00000000000017154;
      9'd205: rom_out = 68'hFFFFFFFFFFFFBAC02;
      9'd206: rom_out = 68'h0000000000002E2A8;
      9'd207: rom_out = 68'hFFFFFFFFFFFFBAC02;
      9'd208: rom_out = 68'hFFFFFFFFFFFFFA3AA;
      9'd209: rom_out = 68'h00000000000000000;
      9'd210: rom_out = 68'hFFFFFFFFFFFFF4755;
      9'd211: rom_out = 68'hFFFFFFFFFFFFEEB01;
      9'd212: rom_out = 68'h00000000000005C55;
      9'd213: rom_out = 68'hFFFFFFFFFFFFEEB01;
      9'd214: rom_out = 68'h0000000000000B8AA;
      9'd215: rom_out = 68'hFFFFFFFFFFFFEEB01;
      9'd216: rom_out = 68'hFFFFFFFFFFFFFE8EA;
      9'd217: rom_out = 68'h00000000000000000;
      9'd218: rom_out = 68'hFFFFFFFFFFFFFD1D5;
      9'd219: rom_out = 68'hFFFFFFFFFFFFFBAC1;
      9'd220: rom_out = 68'h00000000000001715;
      9'd221: rom_out = 68'hFFFFFFFFFFFFFBAC1;
      9'd222: rom_out = 68'h00000000000002E2A;
      9'd223: rom_out = 68'hFFFFFFFFFFFFFBAC1;
      9'd224: rom_out = 68'hFFFFFFFFFFFFFFA3A;
      9'd225: rom_out = 68'h00000000000000000;
      9'd226: rom_out = 68'hFFFFFFFFFFFFFF475;
      9'd227: rom_out = 68'hFFFFFFFFFFFFFEEB1;
      9'd228: rom_out = 68'h000000000000005C5;
      9'd229: rom_out = 68'hFFFFFFFFFFFFFEEB1;
      9'd230: rom_out = 68'h00000000000000B8A;
      9'd231: rom_out = 68'hFFFFFFFFFFFFFEEB1;
      9'd232: rom_out = 68'hFFFFFFFFFFFFFFE8E;
      9'd233: rom_out = 68'h00000000000000000;
      9'd234: rom_out = 68'hFFFFFFFFFFFFFFD1D;
      9'd235: rom_out = 68'hFFFFFFFFFFFFFFBAC;
      9'd236: rom_out = 68'h00000000000000171;
      9'd237: rom_out = 68'hFFFFFFFFFFFFFFBAC;
      9'd238: rom_out = 68'h000000000000002E2;
      9'd239: rom_out = 68'hFFFFFFFFFFFFFFBAC;
      9'd240: rom_out = 68'hFFFFFFFFFFFFFFFA4;
      9'd241: rom_out = 68'h00000000000000000;
      9'd242: rom_out = 68'hFFFFFFFFFFFFFFF48;
      9'd243: rom_out = 68'hFFFFFFFFFFFFFFEEB;
      9'd244: rom_out = 68'h0000000000000005C;
      9'd245: rom_out = 68'hFFFFFFFFFFFFFFEEB;
      9'd246: rom_out = 68'h000000000000000B8;
      9'd247: rom_out = 68'hFFFFFFFFFFFFFFEEB;
      9'd248: rom_out = 68'hFFFFFFFFFFFFFFFE9;
      9'd249: rom_out = 68'h00000000000000000;
      9'd250: rom_out = 68'hFFFFFFFFFFFFFFFD2;
      9'd251: rom_out = 68'hFFFFFFFFFFFFFFFBA;
      9'd252: rom_out = 68'h00000000000000017;
      9'd253: rom_out = 68'hFFFFFFFFFFFFFFFBA;
      9'd254: rom_out = 68'h0000000000000002E;
      9'd255: rom_out = 68'hFFFFFFFFFFFFFFFBA;
      9'd256: rom_out = 68'hFFFFFFFFFFFFFFFFA;
      9'd257: rom_out = 68'h00000000000000000;
      9'd258: rom_out = 68'hFFFFFFFFFFFFFFFF4;
      9'd259: rom_out = 68'hFFFFFFFFFFFFFFFEF;
      9'd260: rom_out = 68'h00000000000000005;
      9'd261: rom_out = 68'hFFFFFFFFFFFFFFFEF;
      9'd262: rom_out = 68'h0000000000000000B;
      9'd263: rom_out = 68'hFFFFFFFFFFFFFFFEF;
      9'd264: rom_out = 68'hFFFFFFFFFFFFFFFFE;
      9'd265: rom_out = 68'h00000000000000000;
      9'd266: rom_out = 68'hFFFFFFFFFFFFFFFFD;
      9'd267: rom_out = 68'hFFFFFFFFFFFFFFFFB;
      9'd268: rom_out = 68'h00000000000000001;
      9'd269: rom_out = 68'hFFFFFFFFFFFFFFFFB;
      9'd270: rom_out = 68'h00000000000000002;
      9'd271: rom_out = 68'hFFFFFFFFFFFFFFFFB;
     endcase
    log2_table = {rom_out[`r4table_wordsize-1],
		  rom_out[`r4table_wordsize-1:`r4table_wordsize-(op_width+`extra_bits+2)]};
  end
endfunction

function [2:0] selection;
  input [5:0] A;
  input integer i;
  reg sign;    // complement - 1 when negative digit
  reg double;  // 2x value should be used
  reg zero;    // selection is a zero digit
  begin
    if (i<3)
    begin
      sign = ~A[5] & A[2] & A[0] |
                        ~A[5] & A[2] & A[1] |
                        ~A[5] & A[3] |
                        ~A[5] & A[4];
      double = ~A[5] & A[3] & A[2] & A[0] |
                        ~A[5] & A[3] & A[2] & A[1] |
                        A[4] & ~A[3] & ~A[0] |
                        A[4] & ~A[3] & ~A[1] |
                        A[4] & ~A[3] & ~A[2] |
                        A[5] & ~A[4] |
                        ~A[5] & A[4];
      zero = ~A[4] & ~A[3] & ~A[1] & ~A[0] |
                        A[4] & A[3] & A[2] & A[0] |
                        A[4] & A[3] & A[2] & A[1] |
                        ~A[4] & ~A[3] & ~A[2];
    end
    else
    begin
      sign = ~A[5] & A[2] |
			~A[5] & A[3] |
			~A[5] & A[4];
      double = A[4] & ~A[3] & ~A[1] & ~A[0] |
			A[4] & ~A[3] & ~A[2] |
			~A[5] & A[3] & A[2] |
			A[5] & ~A[4] |
			~A[5] & A[4];
      zero = A[4] & A[3] & A[2] & A[0] |
			A[4] & A[3] & A[2] & A[1] |
			~A[4] & ~A[3] & ~A[2];
    end
    selection = {sign,double,zero}; 
  end
endfunction

// Definition of signals
  // internal format is used as xxx.xxxxx
  reg signed [op_width+`extra_bits+2:0] u;
  reg [op_width+`extra_bits+2:0] y;
  reg [op_width:0] result;
  reg [op_width-1:0] z_r4;
  reg [2:0] d;
  reg sign, double, zero;
  reg [2:0] d_tc;
  reg [`r4table_addrsize-1:0] r4addr;
  reg [op_width+`extra_bits+2:0] sel_u;
  reg signed [op_width+`extra_bits+2:0] cmpl_u;
  integer i;
  reg [op_width+`extra_bits+2:0] r4table_info;

  always @ (a)
  begin
    // the initialization of variable u and y
    // input format is assumed to be in the form .xxxxx
    if (a[op_width-1:op_width-3] == 3'b100) 
      begin
	// when the input is less than 5/8
        // u = 4(2x-1)
        // y = -1
        // 2x - 1 is computed as:
	u = $signed({{3{1'b0}},a[op_width-2:0],{`extra_bits+1{1'b0}}});
	u = u <<< 2;
        y = 0;
        y[op_width+`extra_bits+2:op_width+`extra_bits] = 3'b111;
      end
    else
      begin
        // when the input is larger or equal to 5/8
        // u = 4(x-1)
        // y = 0
	u = $signed({{3{1'b1}},a[op_width-1:0],{`extra_bits{1'b0}}});
	u = u <<< 2;
        y = 0;
      end
    result = 0; 
    for (i=1; i<= op_width/2+1; i=i+1)
    begin
      d = selection(u[op_width+`extra_bits+2:op_width+`extra_bits-3],i);
      sign = d[2];
      double = d[1];
      zero = d[0];
      // digit value to be added to variable u
      d_tc = {sign,(sign | double),~(double | zero)};
      r4addr = {i,d};
      sel_u = (double)? 
		 ($unsigned($signed(u)>>>(2*i-1)) & {op_width+`extra_bits+3{~zero}}):
		 ($unsigned($signed(u)>>>(2*i)) & {op_width+`extra_bits+3{~zero}});
      cmpl_u = $signed($unsigned(sel_u) ^ {op_width+`extra_bits+3{sign}});
      // the original operation would be
      //      u = (u+(digit<<(op_width+`extra_bits))+cmpl_u+negation)<<<2;
      // and it is equivalent to:
      u[op_width+`extra_bits+2:op_width+`extra_bits]=u[op_width+`extra_bits+2:op_width+`extra_bits] + d_tc;
      u = (u + cmpl_u + $signed({1'b0,sign})) <<< 2;
      r4table_info = log2_table(r4addr);
      y = y + r4table_info;
    end  // for
    result = y[op_width+`extra_bits-1:op_width+`extra_bits-op_width-1]+1; 
    z_r4 = result[op_width:1];
  end


assign z = (op_width < `min_op_width_linear)?z_lookup:
             (op_width < `min_op_width_normalization)?
                (arch == 2?z_poly:z_poly_new):z_r4;

`undef min_op_width_linear 
`undef min_op_width_quadratic 
`undef min_op_width_cubic 
`undef min_op_width_normalization 

`undef lookuptable_nrows
`undef lookuptable_wordsize
`undef lookuptable_addrsize
`undef lookupint_bits 

`undef table_nrows
`undef table_wordsize
`undef table_addrsize
`undef coef_max_size 
`undef int_bits 
`undef extra_LSBs
`undef bits
`undef coef3_size
`undef coef2_size
`undef coef1_size
`undef coef0_size
`undef prod1_MSB
`undef prod2_MSB
`undef prod3_MSB
`undef z_int_size
`undef chain
`undef z_round_MSB

`undef extra_bits
`undef r4table_nrows
`undef r4table_wordsize
`undef r4table_addrsize

endmodule
