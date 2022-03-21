
//-------------------------------------------------------------------------------
//
// ABSTRACT: Fixed-point natural logarithm (DW_ln)
//           Computes the natural logarithm of a fixed point value in the 
//           range [1,2). 
//           The number of fractional bits to be used is controlled by
//           a parameter. 
//
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              op_width        operand size,  >= 2
//                              including integer bit
//              arch            implementation selection
//                              0 - area optimized (default)
//                              1 - speed optimized
//              err_range       error range of the result compared to the
//                              true result
//                              1 - 1 ulp error (default)
//                              2 - 2 ulp error
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               main input with op_width fractional bits
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               op_width fractional bits. ln(a)
//
// MODIFIED:
//
//-------------------------------------------------------------------------------

//////////////////////////////////////////////////////////////////////////////// 

module DW_ln (

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
parameter arch = 0;                   // RANGE 0 to 1
parameter err_range = 1;              // RANGE 1 to 2

//----------------------------------------------------------------------------
//  declaration of inputs and outputs
input  [op_width-1:0] a;  // all bits of the input are fractional bits
output [op_width-1:0] z;


//------------------------------------------------------------------
// General setting
`define min_op_width_linear 13
`define min_op_width_quadratic 19
`define min_op_width_cubic 29
`define min_op_width_normalization 40
//#define debug true

//------------------------------------------------------------------
// The following information is used to generate the output using
// lookup a table
//------------------------------------------------------------------
// Read the header of included file ln_lookup_rom.tbl
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
  // when the number of bits being passed is larger than the address space
  // of the table, this result of this method to compute ln is useless 
  // anyway
  if (`lookuptable_addrsize-op_width+1 > 0)
     tblu_addr = a[op_width-2:0]<<(`lookuptable_addrsize-op_width+1);
  else
     tblu_addr = a[op_width-2:0];
end

//////////////////////////////////////// 


    assign rom_out[14] = 1'b0;

    assign rom_out[13] = 1'b0;

    assign rom_out[12] = tblu_addr[10] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] |
			tblu_addr[10] & tblu_addr[9];

    assign rom_out[11] = tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[3];

    assign rom_out[10] = tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[4] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[4] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8];

    assign rom_out[9] = ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[4] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[3] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4];

    assign rom_out[8] = ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0];

    assign rom_out[7] = tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4];

    assign rom_out[6] = tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4];

    assign rom_out[5] = tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3];

    assign rom_out[4] = ~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1];

    assign rom_out[3] = tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0];

    assign rom_out[2] = tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0];

    assign rom_out[1] = tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1];

    assign rom_out[0] = ~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[6] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[3] & ~tblu_addr[2] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[4] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[3] & tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & tblu_addr[4] & tblu_addr[3] & tblu_addr[2] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[5] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & ~tblu_addr[6] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & tblu_addr[3] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[7] & ~tblu_addr[5] & tblu_addr[4] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[3] & ~tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & ~tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[9] & ~tblu_addr[8] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[7] & ~tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[2] & tblu_addr[1] |
			~tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[6] & ~tblu_addr[5] & tblu_addr[2] & ~tblu_addr[1] |
			~tblu_addr[9] & ~tblu_addr[8] & ~tblu_addr[7] & tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & ~tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[6] & ~tblu_addr[5] & ~tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] & tblu_addr[1] & tblu_addr[0] |
			tblu_addr[10] & tblu_addr[9] & tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[2] |
			tblu_addr[9] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & tblu_addr[3] & ~tblu_addr[2] & tblu_addr[0] |
			~tblu_addr[10] & tblu_addr[8] & ~tblu_addr[7] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0] |
			tblu_addr[10] & ~tblu_addr[9] & ~tblu_addr[8] & tblu_addr[6] & ~tblu_addr[5] & tblu_addr[4] & ~tblu_addr[3] & tblu_addr[1] & ~tblu_addr[0];


assign z_extended = (`lookuptable_wordsize-1-`lookupint_bits-op_width >= 0)?
                     rom_out[`lookuptable_wordsize-1-`lookupint_bits:
                             `lookuptable_wordsize-1-`lookupint_bits-op_width]:
                     0;
assign z_lookup = z_extended[op_width:1];

//----------------------------------------------------------------------
// The following commands describe the computation of ln using 
// polynomial approximation.
//
// Extra bits are added to the LS positions
// Besides that, some integer bits were generated in the table.
// This information is collected based on the table size
// created using Matlab, espresso and pla2ver programs.
// Check the file header of ln_gen_poly_rom.h
`define table_nrows 256
`define coef_max_size 49
`define table_wordsize ('coef_max_size*9)
`define table_addrsize 8
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
`define z_round_MSB (op_width-1)

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
  reg [op_width-1:0] short_a;  // value of a without MS bits 
                              // (remove address bits)
  wire [2*op_width-1:0] a_square;
  wire [op_width+`extra_LSBs-1:0] a_square_trunc;
  wire [3*op_width-1:0] a_cube;
  wire [op_width+`extra_LSBs-1:0] a_cube_trunc;
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
    if (op_width-1-`table_addrsize <= 0)
      addr = a[op_width-2:0] << (`table_addrsize-op_width+1);
    else
      addr = a[op_width-2:op_width-2-`table_addrsize+1];
    short_a = (a << (`table_addrsize+1)) >> (`table_addrsize+1);
     case (addr)
      8'd0: begin
              C3=49'h00A9ABC4FA82E;C2=49'h1F0000A36B5FC;C1=49'h01FFFFFFDBDF6;C0=49'h000000000001C;
              Q2=49'h1F00FF2512B7D;Q1=49'h01FFFF9A412E2;Q0=49'h0000000008642;
              L1=49'h01FF00996640F;L0=49'h0000002A5E088;
            end
      8'd1: begin
              C3=49'h00A7B3B049854;C2=49'h1F01FDA4DD5FE;C1=49'h01FE01FDDE6DC;C0=49'h0001FF00AA2CC;
              Q2=49'h1F02F93265F5A;Q1=49'h01FE019971984;Q0=49'h0001FF00B2764;
              L1=49'h01FD0492A3FE3;L0=49'h0001FF2AB4177;
            end
      8'd2: begin
              C3=49'h00A5C35CB5421;C2=49'h1F03F4BE1DAFF;C1=49'h01FC07EFFCBA3;C0=49'h0003FC054D63C;
              Q2=49'h1F04ED6328346;Q1=49'h01FC078CB91CB;Q0=49'h0003FC055594B;
              L1=49'h01FB0C7A1C44D;L0=49'h0003FC2F042BC;
            end
      8'd3: begin
              C3=49'h00A3DAAC70732;C2=49'h1F05E6066D25C;C1=49'h01FA11CA7DA3E;C0=49'h0005F711D7E1F;
              Q2=49'h1F06DBCE706C9;Q1=49'h01FA11685EA95;Q0=49'h0005F711DFFAC;
              L1=49'h01F918442D19F;L0=49'h0005F73B3C7D0;
            end
      8'd4: begin
              C3=49'h00A1F97807F99;C2=49'h1F07D194ABC1B;C1=49'h01F81F81D62DA;C0=49'h0007F02A2C40A;
              Q2=49'h1F08C48ADFCEA;Q1=49'h01F81F20D75CD;Q0=49'h0007F02A3441B;
              L1=49'h01F727E5623CA;L0=49'h0007F0533FA0A;
            end
      8'd5: begin
              C3=49'h00A01F8FA8E72;C2=49'h1F09B77F59712;C1=49'h01F6310AA89BB;C0=49'h0009E75221A4F;
              Q2=49'h1F0AA7AEB0B37;Q1=49'h01F630AAC5959;Q0=49'h0009E752298E9;
              L1=49'h01F53B5274464;L0=49'h0009E77AE4B81;
            end
      8'd6: begin
              C3=49'h009E4CE214FF0;C2=49'h1F0B97DC56976;C1=49'h01F44659C3B70;C0=49'h000BDC8D83EC7;
              Q2=49'h1F0C854FAA447;Q1=49'h01F445FAF8262;Q0=49'h000BDC8D8BBF0;
              L1=49'h01F3528047D08;L0=49'h000BDCB5F79D4;
            end
      8'd7: begin
              C3=49'h009C813CECCA9;C2=49'h1F0D72C151CC8;C1=49'h01F25F6421C13;C0=49'h000DCFE013D96;
              Q2=49'h1F0E5D832D763;Q1=49'h01F25F066970A;Q0=49'h000DCFE01B953;
              L1=49'h01F16D63EC9E1;L0=49'h000DD008390EF;
            end
      8'd8: begin
              C3=49'h009ABC8540168;C2=49'h1F0F48436C0E0;C1=49'h01F07C1EE7CDA;C0=49'h000FC14D873DA;
              Q2=49'h1F10305E32BEA;Q1=49'h01F07BC23E98C;Q0=49'h000FC14D8EE32;
              L1=49'h01EF8BF29CCB6;L0=49'h000FC1755EDB8;
            end
      8'd9: begin
              C3=49'h0098FE9CB6F0B;C2=49'h1F1118776552F;C1=49'h01EE9C7F64E12;C0=49'h0011B0D989256;
              Q2=49'h1F11FDF55100C;Q1=49'h01EE9C23C6B02;Q0=49'h0011B0D990B4D;
              L1=49'h01EDAE21BC015;L0=49'h0011B101140B9;
            end
      8'd10: begin
              C3=49'h0097475B1ADD4;C2=49'h1F12E371ADE43;C1=49'h01ECC07B111D8;C0=49'h00139E87BA004;
              Q2=49'h1F13C65CB6069;Q1=49'h01ECC02079F82;Q0=49'h00139E87C179F;
              L1=49'h01EBD3E6D6AE2;L0=49'h00139EAEF90B9;
            end
      8'd11: begin
              C3=49'h009596A633631;C2=49'h1F14A9463CB11;C1=49'h01EAE8078D144;C0=49'h00158A5BAFCA6;
              Q2=49'h1F1589A8358B7;Q1=49'h01EAE7ADF90D1;Q0=49'h00158A5BB72EB;
              L1=49'h01E9FD37A142D;L0=49'h00158A82A3D45;
            end
      8'd12: begin
              C3=49'h0093EC5AD2EBB;C2=49'h1F166A08B9E02;C1=49'h01E9131AA0F0C;C0=49'h00177458F6345;
              Q2=49'h1F1747EB40581;Q1=49'h01E912C20C327;Q0=49'h00177458FD83A;
              L1=49'h01E82A09F772A;L0=49'h0017747FA0131;
            end
      8'd13: begin
              C3=49'h00924866BEFD2;C2=49'h1F1825CC54B8D;C1=49'h01E741AA3BD1D;C0=49'h00195C830ECA5;
              Q2=49'h1F190138EF081;Q1=49'h01E74152A28C6;Q0=49'h00195C831604E;
              L1=49'h01E65A53DB7B6;L0=49'h00195CA96F50E;
            end
      8'd14: begin
              C3=49'h0090AA9B28983;C2=49'h1F19DCA413D53;C1=49'h01E573AC72E9F;C0=49'h001B42DD711AE;
              Q2=49'h1F1AB5A3FCCC7;Q1=49'h01E57355D16F9;Q0=49'h001B42DD7840F;
              L1=49'h01E48E0B756C6;L0=49'h001B430389193;
            end
      8'd15: begin
              C3=49'h008F12E52CB1A;C2=49'h1F1B8EA275929;C1=49'h01E3A91780FC2;C0=49'h001D276B8ADC7;
              Q2=49'h1F1C653ECD400;Q1=49'h01E3A8C1D3A89;Q0=49'h001D276B91EE6;
              L1=49'h01E2C5271275C;L0=49'h001D27915B1F7;
            end
      8'd16: begin
              C3=49'h008D81277944B;C2=49'h1F1D3BD9B40ED;C1=49'h01E1E1E1C58AB;C0=49'h001F0A30C012C;
              Q2=49'h1F1E101B6FE73;Q1=49'h01E1E18D08C97;Q0=49'h001F0A30C710D;
              L1=49'h01E0FF9D24396;L0=49'h001F0A5649644;
            end
      8'd17: begin
              C3=49'h008BF53F2CA99;C2=49'h1F1EE45BBE4F8;C1=49'h01E01E01C42F3;C0=49'h0020EB306B332;
              Q2=49'h1F1FB64B9D35B;Q1=49'h01E01DADF4839;Q0=49'h0020EB30721DA;
              L1=49'h01DF3D644020A;L0=49'h0020EB55AE5A2;
            end
      8'd18: begin
              C3=49'h008A6F1A6F43E;C2=49'h1F20883A152EE;C1=49'h01DE5D6E2402E;C0=49'h0022CA6DDD484;
              Q2=49'h1F2157E0BD46C;Q1=49'h01DE5D1B3DF82;Q0=49'h0022CA6DE41F8;
              L1=49'h01DD7E731EB55;L0=49'h0022CA92DB08B;
            end
      8'd19: begin
              C3=49'h0088EE9471305;C2=49'h1F222786077E5;C1=49'h01DCA01DAEDF1;C0=49'h0024A7EC5E157;
              Q2=49'h1F22F4EBE5F45;Q1=49'h01DC9FCBAF18E;Q0=49'h0024A7EC64D9B;
              L1=49'h01DBC2C09AFEB;L0=49'h0024A81117309;
            end
      8'd20: begin
              C3=49'h0087739D10D33;C2=49'h1F23C25073AE0;C1=49'h01DAE60750D91;C0=49'h002683AF2C38F;
              Q2=49'h1F248D7DDFB3C;Q1=49'h01DAE5B63401E;Q0=49'h002683AF32EA7;
              L1=49'h01DA0A43B1E1A;L0=49'h002683D3A16D1;
            end
      8'd21: begin
              C3=49'h0085FE174ABB5;C2=49'h1F2558A9FF98E;C1=49'h01D92F22178B5;C0=49'h00285DB97D4DD;
              Q2=49'h1F2621A722E34;Q1=49'h01D92ED1DA61A;Q0=49'h00285DB983ECE;
              L1=49'h01D854F381848;L0=49'h00285DDDAF56A;
            end
      8'd22: begin
              C3=49'h00848DEA58B1E;C2=49'h1F26EAA2FF989;C1=49'h01D77B653186C;C0=49'h002A360E7E0D7;
              Q2=49'h1F27B177DE9C0;Q1=49'h01D77B15D0D7A;Q0=49'h002A360E849A5;
              L1=49'h01D6A2C748B61;L0=49'h002A36326DA3E;
            end
      8'd23: begin
              C3=49'h008322FD3D33A;C2=49'h1F28784B7D0F4;C1=49'h01D5CAC7EDBA7;C0=49'h002C0CB1526FE;
              Q2=49'h1F293CFFF9503;Q1=49'h01D5CA79665F3;Q0=49'h002C0CB158EAD;
              L1=49'h01D4F3B666587;L0=49'h002C0CD5004A5;
            end
      8'd24: begin
              C3=49'h0081BD334E5D1;C2=49'h1F2A01B34165C;C1=49'h01D41D41BAD96;C0=49'h002DE1A515CC1;
              Q2=49'h1F2AC44F0D823;Q1=49'h01D41CF409C0D;Q0=49'h002DE1A51C355;
              L1=49'h01D347B858CE5;L0=49'h002DE1C8829E3;
            end
      8'd25: begin
              C3=49'h00805C854F42C;C2=49'h1F2B86E9A9194;C1=49'h01D272CA26E22;C0=49'h002FB4ECDAF75;
              Q2=49'h1F2C477471027;Q1=49'h01D2727D48FAB;Q0=49'h002FB4ECE14F3;
              L1=49'h01D19EC4BD6BA;L0=49'h002FB51007725;
            end
      8'd26: begin
              C3=49'h007F00C3BB61C;C2=49'h1F2D07FE10367;C1=49'h01D0CB58DE5C0;C0=49'h0031868BAC646;
              Q2=49'h1F2DC67F34B44;Q1=49'h01D0CB0CD0B52;Q0=49'h0031868BB2AB0;
              L1=49'h01CFF8D34FE9D;L0=49'h003186AE9936F;
            end
      8'd27: begin
              C3=49'h007DA9F11596A;C2=49'h1F2E84FF3A2AE;C1=49'h01CF26E5AC17A;C0=49'h003356848C419;
              Q2=49'h1F2F417E23966;Q1=49'h01CF269A6BBAB;Q0=49'h0033568492774;
              L1=49'h01CE55DBE9DE1;L0=49'h003356A73A17D;
            end
      8'd28: begin
              C3=49'h007C57E7E3933;C2=49'h1F2FFDFBEBE96;C1=49'h01CD8568785C2;C0=49'h003524DA7496D;
              Q2=49'h1F30B87FC8B06;Q1=49'h01CD851E026B0;Q0=49'h003524DA7ABBD;
              L1=49'h01CCB5D68233E;L0=49'h003524FCE41A9;
            end
      8'd29: begin
              C3=49'h007B0A96CD66B;C2=49'h1F31730288026;C1=49'h01CBE6D94893E;C0=49'h0036F19057630;
              Q2=49'h1F322B9268FFD;Q1=49'h01CBE68F9A3EF;Q0=49'h0036F1905D778;
              L1=49'h01CB18BB2CA7E;L0=49'h0036F1B2893BB;
            end
      8'd30: begin
              C3=49'h0079C1E81CBEB;C2=49'h1F32E42136B6E;C1=49'h01CA4B303EB8B;C0=49'h0038BCA91EB8B;
              Q2=49'h1F339AC4127EF;Q1=49'h01CA4AE755362;Q0=49'h0038BCA924BCF;
              L1=49'h01C97E821948A;L0=49'h0038BCCB138B6;
            end
      8'd31: begin
              C3=49'h00787DC3FCBD0;C2=49'h1F345165E8B81;C1=49'h01C8B26598D10;C0=49'h003A8627ACDA8;
              Q2=49'h1F3506228D9B7;Q1=49'h01C8B21D716A6;Q0=49'h003A8627B2CEC;
              L1=49'h01C7E72393F80;L0=49'h003A8649654A0;
            end
      8'd32: begin
              C3=49'h00773E293B5C0;C2=49'h1F35BADE28256;C1=49'h01C71C71B08E1;C0=49'h003C4E0EDC570;
              Q2=49'h1F366DBB65DB9;Q1=49'h01C71C2A488A0;Q0=49'h003C4E0EE23B7;
              L1=49'h01C6529803EFA;L0=49'h003C4E305903D;
            end
      8'd33: begin
              C3=49'h007602E873380;C2=49'h1F37209794058;C1=49'h01C5894CFA934;C0=49'h003E14618023D;
              Q2=49'h1F37D19BEFE37;Q1=49'h01C589064F587;Q0=49'h003E146185F8C;
              L1=49'h01C4C0D7EB483;L0=49'h003E1482C1AC5;
            end
      8'd34: begin
              C3=49'h0074CBFC87366;C2=49'h1F38829F47E88;C1=49'h01C3F8F0064B5;C0=49'h003FD92263B8E;
              Q2=49'h1F3931D1417E9;Q1=49'h01C3F8AA15418;Q0=49'h003FD922697E6;
              L1=49'h01C331DBE682B;L0=49'h003FD9436AB93;
            end
      8'd35: begin
              C3=49'h0073994AB2E5B;C2=49'h1F39E1024B7C0;C1=49'h01C26B537D3BF;C0=49'h00419C544B2A7;
              Q2=49'h1F3A8E683A321;Q1=49'h01C26B0E43DAC;Q0=49'h00419C5450E0D;
              L1=49'h01C1A59CAC151;L0=49'h00419C75183C8;
            end
      8'd36: begin
              C3=49'h00726AD68F1FB;C2=49'h1F3B3BCD39EFD;C1=49'h01C0E07022C07;C0=49'h00435DF9F3434;
              Q2=49'h1F3BE76D7BCAE;Q1=49'h01C0E02B9E7BF;Q0=49'h00435DF9F8EAB;
              L1=49'h01C01C130BF7D;L0=49'h00435E1A86FF0;
            end
      8'd37: begin
              C3=49'h007140724FE69;C2=49'h1F3C930CCCCF4;C1=49'h01BF583ED353B;C0=49'h00451E16119E1;
              Q2=49'h1F3D3CED782C4;Q1=49'h01BF57FB01BF1;Q0=49'h00451E161736C;
              L1=49'h01BE9537EF376;L0=49'h00451E366C995;
            end
      8'd38: begin
              C3=49'h00701A206AB51;C2=49'h1F3DE6CD3393A;C1=49'h01BDD2B884786;C0=49'h0046DCAB54BEA;
              Q2=49'h1F3E8EF464CE8;Q1=49'h01BDD27563226;Q0=49'h0046DCAB5A48C;
              L1=49'h01BD110457876;L0=49'h0046DCCB778D3;
            end
      8'd39: begin
              C3=49'h006EF7C1EBA93;C2=49'h1F3F371AA3D2A;C1=49'h01BC4FD644033;C0=49'h004899BC642A6;
              Q2=49'h1F3FDD8E46B7D;Q1=49'h01BC4F93D08FD;Q0=49'h004899BC69A63;
              L1=49'h01BB8F715ED68;L0=49'h004899DC4F5E1;
            end
      8'd40: begin
              C3=49'h006DD94E0BA4E;C2=49'h1F408400F9349;C1=49'h01BACF9137E38;C0=49'h004A554BE080D;
              Q2=49'h1F4128C6EF62C;Q1=49'h01BACF4F6FF82;Q0=49'h004A554BE5EE7;
              L1=49'h01BA107836E7B;L0=49'h004A556B94A96;
            end
      8'd41: begin
              C3=49'h006CBEABEA606;C2=49'h1F41CD8BF7094;C1=49'h01B951E29D9B5;C0=49'h004C0F5C6392F;
              Q2=49'h1F4270A9F829C;Q1=49'h01B951A17EF20;Q0=49'h004C0F5C68F2A;
              L1=49'h01B8941228EA0;L0=49'h004C0F7BE13E6;
            end
      8'd42: begin
              C3=49'h006BA7D4864EF;C2=49'h1F4313C711DE0;C1=49'h01B7D6C3C9F46;C0=49'h004DC7F0807B3;
              Q2=49'h1F43B542D1486;Q1=49'h01B7D68352442;Q0=49'h004DC7F085CD1;
              L1=49'h01B71A3895157;L0=49'h004DC80FC8358;
            end
      8'd43: begin
              C3=49'h006A94AF1E6B1;C2=49'h1F4456BDAB1D9;C1=49'h01B65E2E28815;C0=49'h004F7F0AC3B40;
              Q2=49'h1F44F69CB18BC;Q1=49'h01B65DEE55963;Q0=49'h004F7F0AC8F85;
              L1=49'h01B5A2E4F247B;L0=49'h004F7F29D6075;
            end
      8'd44: begin
              C3=49'h00698532B7FA3;C2=49'h1F45967AD9AA3;C1=49'h01B4E81B3B567;C0=49'h005134ADB32EE;
              Q2=49'h1F4634C2A664F;Q1=49'h01B4E7DC0AFD7;Q0=49'h005134ADB865C;
              L1=49'h01B42E10CDA3D;L0=49'h005134CC90A37;
            end
      8'd45: begin
              C3=49'h00687949F4CFF;C2=49'h1F46D3099B3C3;C1=49'h01B374849A938;C0=49'h0052E8DBCE6A4;
              Q2=49'h1F476FBF8A433;Q1=49'h01B374460AA9A;Q0=49'h0052E8DBD393E;
              L1=49'h01B2BBB5CA340;L0=49'h0052E8FA77869;
            end
      8'd46: begin
              C3=49'h006770F32F3D8;C2=49'h1F480C749DC0C;C1=49'h01B20363F420A;C0=49'h00549B978E87B;
              Q2=49'h1F48A79E0BAC9;Q1=49'h01B203260280F;Q0=49'h00549B9793A44;
              L1=49'h01B14BCDA08C9;L0=49'h00549BB603D09;
            end
      8'd47: begin
              C3=49'h00666C0AE23F4;C2=49'h1F4942C69B852;C1=49'h01B094B30B26B;C0=49'h00564CE366616;
              Q2=49'h1F49DC68ABDA4;Q1=49'h01B09475B5C5A;Q0=49'h00564CE36B711;
              L1=49'h01AFDE521E718;L0=49'h00564D01A859B;
            end
      8'd48: begin
              C3=49'h00656A8E3385D;C2=49'h1F4A7609EB8B5;C1=49'h01AF286BB7EBE;C0=49'h0057FCC1C29F3;
              Q2=49'h1F4B0E29C1724;Q1=49'h01AF282EFCBB2;Q0=49'h0057FCC1C7A22;
              L1=49'h01AE733D267CA;L0=49'h0057FCDFD1C83;
            end
      8'd49: begin
              C3=49'h00646C6D9D09E;C2=49'h1F4BA648D0C71;C1=49'h01ADBE87E7541;C0=49'h0059AB3509CB9;
              Q2=49'h1F4C3CEB74A21;Q1=49'h01ADBE4BC4529;Q0=49'h0059AB350EC1F;
              L1=49'h01AD0A88AFC74;L0=49'h0059AB52E6A4E;
            end
      8'd50: begin
              C3=49'h0063719D6DF59;C2=49'h1F4CD38D5A42C;C1=49'h01AC57019A9DC;C0=49'h005B583F9C682;
              Q2=49'h1F4D68B7C654C;Q1=49'h01AC56C60DCD8;Q0=49'h005B583FA1522;
              L1=49'h01ABA42EC5940;L0=49'h005B585D476FA;
            end
      8'd51: begin
              C3=49'h00627A0F886A4;C2=49'h1F4DFDE173E99;C1=49'h01AAF1D2E701D;C0=49'h005D03E3D501B;
              Q2=49'h1F4E91988AD54;Q1=49'h01AAF197EE702;Q0=49'h005D03E3D9DF7;
              L1=49'h01AA402986FAE;L0=49'h005D04014EB3A;
            end
      8'd52: begin
              C3=49'h006185B6F19F4;C2=49'h1F4F254EDE9FC;C1=49'h01A98EF5F5660;C0=49'h005EAE2408443;
              Q2=49'h1F4FB79770000;Q1=49'h01A98EBB8F27A;Q0=49'h005EAE240D15E;
              L1=49'h01A8DE7326977;L0=49'h005EAE41511B4;
            end
      8'd53: begin
              C3=49'h006094806FBB6;C2=49'h1F5049DF3D664;C1=49'h01A82E650206D;C0=49'h00605702850E3;
              Q2=49'h1F50DABDFEDAA;Q1=49'h01A82E2B2C386;Q0=49'h0060570289D3F;
              L1=49'h01A77F05EA374;L0=49'h0060571F9D837;
            end
      8'd54: begin
              C3=49'h005FA660EC5A6;C2=49'h1F516B9BFE9D9;C1=49'h01A6D01A5C310;C0=49'h0061FE819483F;
              Q2=49'h1F51FB15906CD;Q1=49'h01A6CFE114FB9;Q0=49'h0061FE81993DF;
              L1=49'h01A621DC2A8BF;L0=49'h0061FE9E7D0EE;
            end
      8'd55: begin
              C3=49'h005EBB4FD332D;C2=49'h1F528A8E66C4C;C1=49'h01A5741065EF1;C0=49'h0063A4A37A228;
              Q2=49'h1F5318A75F03A;Q1=49'h01A573D7AB7D8;Q0=49'h0063A4A37ED0E;
              L1=49'h01A4C6F052DC6;L0=49'h0063A4C033392;
            end
      8'd56: begin
              C3=49'h005DD337D496A;C2=49'h1F53A6BFA94BF;C1=49'h01A41A4193B10;C0=49'h0065496A73D22;
              Q2=49'h1F54337C7B36D;Q1=49'h01A41A09643E4;Q0=49'h0065496A78751;
              L1=49'h01A36E3CE0B94;L0=49'h00654986FDE8E;
            end
      8'd57: begin
              C3=49'h005CEE2175105;C2=49'h1F54C038A11E7;C1=49'h01A2C2A86C24F;C0=49'h0066ECD8B9F8B;
              Q2=49'h1F554B9DD3CFD;Q1=49'h01A2C270C5DED;Q0=49'h0066ECD8BE905;
              L1=49'h01A217BC63B2A;L0=49'h0066ECF515829;
            end
      8'd58: begin
              C3=49'h005C0BEBF5F8C;C2=49'h1F55D7024E895;C1=49'h01A16D3F87AC7;C0=49'h00688EF07F8B9;
              Q2=49'h1F56611430EBC;Q1=49'h01A16D0868DC5;Q0=49'h00688EF084180;
              L1=49'h01A0C3697D0D4;L0=49'h00688F0CACFA3;
            end
      8'd59: begin
              C3=49'h005B2C8F4FD88;C2=49'h1F56EB255FF6B;C1=49'h01A01A019053E;C0=49'h006A2FB3F2218;
              Q2=49'h1F5773E837D6D;Q1=49'h01A019CAF744E;Q0=49'h006A2FB3F6A2E;
              L1=49'h019F713EDF7CD;L0=49'h006A2FCFF1E4D;
            end
      8'd60: begin
              C3=49'h005A5001E5BDE;C2=49'h1F57FCAA6744F;C1=49'h019EC8E9416CE;C0=49'h006BCF253A03C;
              Q2=49'h1F58842269250;Q1=49'h019EC8B32C72E;Q0=49'h006BCF253E7A4;
              L1=49'h019E21374EDC0;L0=49'h006BCF410C8A8;
            end
      8'd61: begin
              C3=49'h00597640B2EE6;C2=49'h1F590B99C644A;C1=49'h019D79F16755B;C0=49'h006D6D467A3F9;
              Q2=49'h1F5991CB27B03;Q1=49'h019D79BBD4C00;Q0=49'h006D6D467EAB5;
              L1=49'h019CD34D9FE7B;L0=49'h006D6D621FF71;
            end
      8'd62: begin
              C3=49'h00589F3738DFD;C2=49'h1F5A17FBDCB8C;C1=49'h019C2D14DF1BD;C0=49'h006F0A19D0B6F;
              Q2=49'h1F5A9CEAB071F;Q1=49'h019C2CDFCD4AF;Q0=49'h006F0A19D5180;
              L1=49'h019B877CB7FB5;L0=49'h006F0A354A0B1;
            end
      8'd63: begin
              C3=49'h0057CAD6ACA02;C2=49'h1F5B21D8DED87;C1=49'h019AE24E964F6;C0=49'h0070A5A156311;
              Q2=49'h1F5BA58921133;Q1=49'h019AE21A03AD0;Q0=49'h0070A5A15A87B;
              L1=49'h019A3DBF8CCE1;L0=49'h0070A5BCA38C7;
            end
      8'd64: begin
              C3=49'h0056F91EAE4FB;C2=49'h1F5C2938C848C;C1=49'h019999998AC77;C0=49'h00723FDF1E6B2;
              Q2=49'h1F5CABAE762FC;Q1=49'h0199996575BB6;Q0=49'h00723FDF22B76;
              L1=49'h0198F61124318;L0=49'h00723FFA4036E;
            end
      8'd65: begin
              C3=49'h005629FD53B4F;C2=49'h1F5D2E23925CD;C1=49'h019852F0CA461;C0=49'h0073D8D53827D;
              Q2=49'h1F5DAF628CE56;Q1=49'h019852BD3144E;Q0=49'h0073D8D53C69D;
              L1=49'h0197B06C93D1C;L0=49'h0073D8F02ECBF;
            end
      8'd66: begin
              C3=49'h00555D72FFD9C;C2=49'h1F5E30A0F971B;C1=49'h01970E4F7256E;C0=49'h00757085AD3FA;
              Q2=49'h1F5EB0AD25812;Q1=49'h01970E1C53D06;Q0=49'h00757085B1778;
              L1=49'h01966CCD00F61;L0=49'h007570A07922C;
            end
      8'd67: begin
              C3=49'h00549368F9771;C2=49'h1F5F30B8C0C58;C1=49'h0195CBB0AFEF3;C0=49'h007706F282B06;
              Q2=49'h1F5FAF95DD63C;Q1=49'h0195CB7E0A662;Q0=49'h007706F286DE5;
              L1=49'h01952B2DA0439;L0=49'h0077070D2437E;
            end
      8'd68: begin
              C3=49'h0053CBE3B0DFA;C2=49'h1F602E726091A;C1=49'h01948B0FBF5A2;C0=49'h00789C1DB8AC7;
              Q2=49'h1F60AC2437A11;Q1=49'h01948ADD9148F;Q0=49'h00789C1DBCD08;
              L1=49'h0193EB89B5809;L0=49'h00789C38303C8;
            end
      8'd69: begin
              C3=49'h005306C6BEB0F;C2=49'h1F6129D56C37D;C1=49'h01934C67EBC8B;C0=49'h007A30094AAA1;
              Q2=49'h1F61A65F974BB;Q1=49'h01934C3633C19;Q0=49'h007A30094EC46;
              L1=49'h0192ADDC9358F;L0=49'h007A302398A58;
            end
      8'd70: begin
              C3=49'h0052440EE39EC;C2=49'h1F6222E92D14F;C1=49'h01920FB48F4B9;C0=49'h007BC2B72F721;
              Q2=49'h1F629E4F42CD0;Q1=49'h01920F834BE10;Q0=49'h007BC2B73382C;
              L1=49'h019172219B23A;L0=49'h007BC2D1543A9;
            end
      8'd71: begin
              C3=49'h005183BF85D2E;C2=49'h1F6319B4C7B73;C1=49'h0190D4F11284D;C0=49'h007D5429592E9;
              Q2=49'h1F6393FA67F27;Q1=49'h0190D4C042418;Q0=49'h007D54295D35C;
              L1=49'h019038543CA99;L0=49'h007D54435524B;
            end
      8'd72: begin
              C3=49'h0050C5C09FFD2;C2=49'h1F640E3F709BA;C1=49'h018F9C18EC571;C0=49'h007EE461B579A;
              Q2=49'h1F64876812204;Q1=49'h018F9BE88DDAE;Q0=49'h007EE461B9776;
              L1=49'h018F006FF5ED0;L0=49'h007EE47B88FCA;
            end
      8'd73: begin
              C3=49'h00500A11CD2A3;C2=49'h1F6500901A887;C1=49'h018E6527A1D55;C0=49'h008073622D6B2;
              Q2=49'h1F65789F367E0;Q1=49'h018E64F7B3BC2;Q0=49'h00807362315FA;
              L1=49'h018DCA7052F2B;L0=49'h0080737BD8D94;
            end
      8'd74: begin
              C3=49'h004F50A309BBE;C2=49'h1F65F0ADB870C;C1=49'h018D3018C5EB6;C0=49'h0082012CA5A72;
              Q2=49'h1F6667A6ADC30;Q1=49'h018D2FE946DDA;Q0=49'h0082012CA9928;
              L1=49'h018C9650ED8B6;L0=49'h00820146295D5;
            end
      8'd75: begin
              C3=49'h004E99686FDEB;C2=49'h1F66DE9F1A066;C1=49'h018BFCE7F93B9;C0=49'h00838DC2FE6B6;
              Q2=49'h1F67548535327;Q1=49'h018BFCB8E7E9D;Q0=49'h00838DC3024DB;
              L1=49'h018B640D6D1EC;L0=49'h00838DDC5AC59;
            end
      8'd76: begin
              C3=49'h004DE469480E1;C2=49'h1F67CA6AD5B39;C1=49'h018ACB90E9F3C;C0=49'h00851927139D2;
              Q2=49'h1F683F417330F;Q1=49'h018ACB624503B;Q0=49'h0085192717768;
              L1=49'h018A33A18676C;L0=49'h0085194048F62;
            end
      8'd77: begin
              C3=49'h004D319C4A106;C2=49'h1F68B41784AE4;C1=49'h01899C0F537C1;C0=49'h0086A35ABCD65;
              Q2=49'h1F6927E1F0F6C;Q1=49'h01899BE1199BA;Q0=49'h0086A35AC0A6E;
              L1=49'h01890508FB8C9;L0=49'h0086A373CB87D;
            end
      8'd78: begin
              C3=49'h004C80E083A59;C2=49'h1F699BABCFACD;C1=49'h01886E5EFE3EA;C0=49'h00882C5FCD72F;
              Q2=49'h1F6A0E6D20F08;Q1=49'h01886E312E34E;Q0=49'h00882C5FD13AC;
              L1=49'h0187D83F9B55E;L0=49'h00882C78B5D5A;
            end
      8'd79: begin
              C3=49'h004BD241EB326;C2=49'h1F6A812DF88A2;C1=49'h0187427BBFAFA;C0=49'h0089B438149DE;
              Q2=49'h1F6AF2E95B25F;Q1=49'h0187424E58388;Q0=49'h0089B438185D0;
              L1=49'h0186AD4141939;L0=49'h0089B450D7094;
            end
      8'd80: begin
              C3=49'h004B25BAC7CB9;C2=49'h1F6B64A44A7A7;C1=49'h0186186179E55;C0=49'h008B3AE55D5DC;
              Q2=49'h1F6BD55CE25D0;Q1=49'h0186183479BE9;Q0=49'h008B3AE561146;
              L1=49'h01858409D6A0E;L0=49'h008B3AFDFA288;
            end
      8'd81: begin
              C3=49'h004A7B40E4114;C2=49'h1F6C4614FCFE1;C1=49'h0184F00C1B76A;C0=49'h008CC0696EA1B;
              Q2=49'h1F6CB5CDDEA63;Q1=49'h0184EFDF81656;Q0=49'h008CC069724FE;
              L1=49'h01845C954F43F;L0=49'h008CC081E6213;
            end
      8'd82: begin
              C3=49'h0049D2C23D98F;C2=49'h1F6D25864055B;C1=49'h0183C9779F452;C0=49'h008E44C60B4D6;
              Q2=49'h1F6D9442637D2;Q1=49'h0183C94B6A1AE;Q0=49'h008E44C60EF34;
              L1=49'h018336DFAC7E4;L0=49'h008E44DE5DD64;
            end
      8'd83: begin
              C3=49'h00492C44B5E87;C2=49'h1F6E02FE04768;C1=49'h0182A4A00C6B1;C0=49'h008FC7FCF245A;
              Q2=49'h1F6E70C06C108;Q1=49'h0182A4743AF2E;Q0=49'h008FC7FCF5E35;
              L1=49'h018212E4FB5EF;L0=49'h008FC815202B6;
            end
      8'd84: begin
              C3=49'h004887B2C09BD;C2=49'h1F6EDE8251729;C1=49'h0181818175E2B;C0=49'h00914A0FDE7C5;
              Q2=49'h1F6F4B4DDDCEA;Q1=49'h0181815606F7A;Q0=49'h00914A0FE211E;
              L1=49'h0180F0A154D55;L0=49'h00914A27E8117;
            end
      8'd85: begin
              C3=49'h0047E50D17A73;C2=49'h1F6FB818F2BA4;C1=49'h01806017FA834;C0=49'h0092CB0086FC4;
              Q2=49'h1F7023F0866C7;Q1=49'h01805FECECFE7;Q0=49'h0092CB008A89C;
              L1=49'h017FD010DD84E;L0=49'h0092CB186C925;
            end
      8'd86: begin
              C3=49'h0047444FB6BB6;C2=49'h1F708FC7A7C31;C1=49'h017F405FC4BC6;C0=49'h00944AD09EF4C;
              Q2=49'h1F70FAAE1FCF0;Q1=49'h017F40351778B;Q0=49'h00944AD0A27A5;
              L1=49'h017EB12FC5988;L0=49'h00944AE860DC6;
            end
      8'd87: begin
              C3=49'h0046A576A5220;C2=49'h1F71659419CA9;C1=49'h017E22550A70D;C0=49'h0095C981D5C57;
              Q2=49'h1F71CF8C4DA24;Q1=49'h017E222ABC4AC;Q0=49'h0095C981D9432;
              L1=49'h017D93FA48989;L0=49'h0095C999744E5;
            end
      8'd88: begin
              C3=49'h004608603951D;C2=49'h1F7239840F4B2;C1=49'h017D05F40CB21;C0=49'h00974715D7097;
              Q2=49'h1F72A2909EC36;Q1=49'h017D05CA1CA11;Q0=49'h00974715DA7F6;
              L1=49'h017C786CAD400;L0=49'h0097472D52826;
            end
      8'd89: begin
              C3=49'h00456D29F3396;C2=49'h1F730B9CCEAFF;C1=49'h017BEB3917E52;C0=49'h0098C38E4AA29;
              Q2=49'h1F7373C08D77F;Q1=49'h017BEB0F84C59;Q0=49'h0098C38E4E10D;
              L1=49'h017B5E8345532;L0=49'h0098C3A5A3596;
            end
      8'd90: begin
              C3=49'h0044D3BAB4366;C2=49'h1F73DBE3E8000;C1=49'h017AD2208334D;C0=49'h009A3EECD4C47;
              Q2=49'h1F7443217FA70;Q1=49'h017AD1F74BF72;Q0=49'h009A3EECD82B2;
              L1=49'h017A463A6D76D;L0=49'h009A3F040B061;
            end
      8'd91: begin
              C3=49'h00443C0FF0F6C;C2=49'h1F74AA5EB09BD;C1=49'h0179BAA6B0ABD;C0=49'h009BB93315FF4;
              Q2=49'h1F7510B8C8535;Q1=49'h0179BA7DD4405;Q0=49'h009BB933195E7;
              L1=49'h01792F8E8D089;L0=49'h009BB94A2A17C;
            end
      8'd92: begin
              C3=49'h0043A61CFF6E3;C2=49'h1F7577127C44B;C1=49'h0178A4C80CEF6;C0=49'h009D3262AB4AB;
              Q2=49'h1F75DC8BA8201;Q1=49'h0178A49F8A4EB;Q0=49'h009D3262AEA27;
              L1=49'h01781A7C15F72;L0=49'h009D32799D854;
            end
      8'd93: begin
              C3=49'h004311DF93CAA;C2=49'h1F76420477F30;C1=49'h017790810F2E4;C0=49'h009EAA7D2E103;
              Q2=49'h1F76A69F469CF;Q1=49'h01779058E5541;Q0=49'h009EAA7D3160B;
              L1=49'h017706FF849AC;L0=49'h009EAA93FEB74;
            end
      8'd94: begin
              C3=49'h00427F5C57C06;C2=49'h1F770B39B456A;C1=49'h01767DCE38F0E;C0=49'h00A021843435C;
              Q2=49'h1F776EF8BF149;Q1=49'h01767DA666D22;Q0=49'h00A02184377EF;
              L1=49'h0175F5155F912;L0=49'h00A0219AE392A;
            end
      8'd95: begin
              C3=49'h0041EE73F03E3;C2=49'h1F77D2B76B4DA;C1=49'h01756CAC15D53;C0=49'h00A197795027C;
              Q2=49'h1F78359D18164;Q1=49'h01756C849A7E9;Q0=49'h00A197795369D;
              L1=49'h0174E4BA3796B;L0=49'h00A1978FDE833;
            end
      8'd96: begin
              C3=49'h00415F35242D2;C2=49'h1F7898827650E;C1=49'h01745D173BABB;C0=49'h00A30C5E10E37;
              Q2=49'h1F78FA9144343;Q1=49'h01745CF0161D9;Q0=49'h00A30C5E141E7;
              L1=49'h0173D5EAA761B;L0=49'h00A30C747E855;
            end
      8'd97: begin
              C3=49'h0040D19D30392;C2=49'h1F795C9FBB5BD;C1=49'h01734F0C4A1DB;C0=49'h00A480340200C;
              Q2=49'h1F79BDDA27200;Q1=49'h01734EE57957F;Q0=49'h00A480340534C;
              L1=49'h0172C8A3537F1;L0=49'h00A4804A4F301;
            end
      8'd98: begin
              C3=49'h0040458F18B17;C2=49'h1F7A1F143ACC7;C1=49'h01724287EA837;C0=49'h00A5F2FCABBC4;
              Q2=49'h1F7A7F7C9145E;Q1=49'h017242616D9C3;Q0=49'h00A5F2FCAEE95;
              L1=49'h0171BCE0EA2DC;L0=49'h00A5F312D8BF2;
            end
      8'd99: begin
              C3=49'h003FBB1FA9400;C2=49'h1F7ADFE48FD4C;C1=49'h01713786CFFE6;C0=49'h00A764B993008;
              Q2=49'h1F7B3F7D3F431;Q1=49'h01713760A5FD5;Q0=49'h00A764B99626C;
              L1=49'h0170B2A0233C9;L0=49'h00A764CFA01C7;
            end
      8'd100: begin
              C3=49'h003F323A0FDC8;C2=49'h1F7B9F158AAAC;C1=49'h01702E05B70D6;C0=49'h00A8D56C39703;
              Q2=49'h1F7BFDE0E29AF;Q1=49'h01702DDFDF057;Q0=49'h00A8D56C3C8FB;
              L1=49'h016FA9DDBFE82;L0=49'h00A8D58226E9D;
            end
      8'd101: begin
              C3=49'h003EAAD5E5D8F;C2=49'h1F7C5CABD46F4;C1=49'h016F260165960;C0=49'h00AA45161D6F0;
              Q2=49'h1F7CBAAC16AA3;Q1=49'h016F25DBDEA13;Q0=49'h00AA45162087D;
              L1=49'h016EA2968AB80;L0=49'h00AA452BEB8A3;
            end
      8'd102: begin
              C3=49'h003E24FC20923;C2=49'h1F7D18ABED39A;C1=49'h016E1F76AAC31;C0=49'h00ABB3B8BA2B4;
              Q2=49'h1F7D75E368174;Q1=49'h016E1F5173F68;Q0=49'h00ABB3B8BD3D7;
              L1=49'h016D9CC7575EA;L0=49'h00ABB3CE692B2;
            end
      8'd103: begin
              C3=49'h003DA094586C7;C2=49'h1F7DD31A76DE7;C1=49'h016D1A625EC47;C0=49'h00AD215587A6F;
              Q2=49'h1F7E2F8B56049;Q1=49'h016D1A3D7741B;Q0=49'h00AD21558AB29;
              L1=49'h016C986D0297C;L0=49'h00AD216B17CDE;
            end
      8'd104: begin
              C3=49'h003D1DA063B59;C2=49'h1F7E8BFBDCBD7;C1=49'h016C16C162D29;C0=49'h00AE8DEDFAC0C;
              Q2=49'h1F7EE7A84CA32;Q1=49'h016C169CC9BC8;Q0=49'h00AE8DEDFDC5E;
              L1=49'h016B958472094;L0=49'h00AE8E036C507;
            end
      8'd105: begin
              C3=49'h003C9C2CFF4DD;C2=49'h1F7F435462FFD;C1=49'h016B1490A10EA;C0=49'h00AFF983853D1;
              Q2=49'h1F7F9E3EA6A53;Q1=49'h016B146C557C9;Q0=49'h00AFF983883BC;
              L1=49'h016A940A9422F;L0=49'h00AFF998D8766;
            end
      8'd106: begin
              C3=49'h003C1C1B907F7;C2=49'h1F7FF9288C854;C1=49'h016A13CD0C2AD;C0=49'h00B1641795CEA;
              Q2=49'h1F805352B630F;Q1=49'h016A13A90D499;Q0=49'h00B1641798C71;
              L1=49'h016993FC5FFFC;L0=49'h00B1642CCAF1D;
            end
      8'd107: begin
              C3=49'h003B9D74CD9EC;C2=49'h1F80AD7C876F6;C1=49'h016914739F99A;C0=49'h00B2CDAB981F8;
              Q2=49'h1F8106E8B6C83;Q1=49'h0169144FEC905;Q0=49'h00B2CDAB9B11A;
              L1=49'h01689556D5470;L0=49'h00B2CDC0AF6C0;
            end
      8'd108: begin
              C3=49'h003B2030A87DF;C2=49'h1F8160548FCDA;C1=49'h016816815F3BC;C0=49'h00B43640F4D91;
              Q2=49'h1F81B904D835A;Q1=49'h0168165DF736D;Q0=49'h00B43640F7C50;
              L1=49'h01679816FC0EF;L0=49'h00B43655EE8DB;
            end
      8'd109: begin
              C3=49'h003AA4486037D;C2=49'h1F8211B4D1E79;C1=49'h016719F357527;C0=49'h00B59DD911AD1;
              Q2=49'h1F8269AB3D923;Q1=49'h016719D03980D;Q0=49'h00B59DD91492E;
              L1=49'h01669C39E4BE4;L0=49'h00B59DEDEE07F;
            end
      8'd110: begin
              C3=49'h003A29BB60622;C2=49'h1F82C1A16096C;C1=49'h01661EC69C663;C0=49'h00B70475515D7;
              Q2=49'h1F8318DFF8301;Q1=49'h01661EA3C7F84;Q0=49'h00B70475543D4;
              L1=49'h0165A1BCA7F04;L0=49'h00B7048A109C1;
            end
      8'd111: begin
              C3=49'h0039B08837517;C2=49'h1F83701E41D4C;C1=49'h016524F84B24C;C0=49'h00B86A1713C4F;
              Q2=49'h1F83C6A70E553;Q1=49'h016524D5BF48C;Q0=49'h00B86A17169EC;
              L1=49'h0164A89C66574;L0=49'h00B86A2BB6240;
            end
      8'd112: begin
              C3=49'h0039389AB7947;C2=49'h1F841D2F8D845;C1=49'h01642C8588355;C0=49'h00B9CEBFB5DEE;
              Q2=49'h1F84730474C7B;Q1=49'h01642C63442BF;Q0=49'h00B9CEBFB8B2C;
              L1=49'h0163B0D648A09;L0=49'h00B9CED43B9A8;
            end
      8'd113: begin
              C3=49'h0038C1FF1C650;C2=49'h1F84C8D91770C;C1=49'h0163356B8047C;C0=49'h00BB327091CF4;
              Q2=49'h1F851DFC15A12;Q1=49'h0163354983446;Q0=49'h00BB3270949D4;
              L1=49'h0162BA677F5A1;L0=49'h00BB3284FB22F;
            end
      8'd114: begin
              C3=49'h00384CAC9BC47;C2=49'h1F85731EC8B92;C1=49'h01623FA767CB8;C0=49'h00BC952AFEEAA;
              Q2=49'h1F85C791CC3E5;Q1=49'h01623F85B108B;Q0=49'h00BC952B01B2D;
              L1=49'h0161C54D42D50;L0=49'h00BC953F4C112;
            end
      8'd115: begin
              C3=49'h0037D897FCB9F;C2=49'h1F861C048265B;C1=49'h01614B367AE58;C0=49'h00BDF6F051BDE;
              Q2=49'h1F866FC966856;Q1=49'h01614B1509A67;Q0=49'h00BDF6F054805;
              L1=49'h0160D184D30CE;L0=49'h00BDF70482F16;
            end
      8'd116: begin
              C3=49'h003765C4F9659;C2=49'h1F86C38DFD525;C1=49'h01605815FD646;C0=49'h00BF57C1DC15E;
              Q2=49'h1F8716A6A5579;Q1=49'h016057F4D0E74;Q0=49'h00BF57C1DED2B;
              L1=49'h015FDF0B778CB;L0=49'h00BF57D5F1900;
            end
      8'd117: begin
              C3=49'h0036F42BC03E1;C2=49'h1F8769BEFB861;C1=49'h015F66433A8D3;C0=49'h00C0B7A0ED070;
              Q2=49'h1F87BC2D3E069;Q1=49'h015F662252166;Q0=49'h00C0B7A0EFBE3;
              L1=49'h015EEDDE7F547;L0=49'h00C0B7B4E700B;
            end
      8'd118: begin
              C3=49'h003683C8ED39B;C2=49'h1F880E9B282D7;C1=49'h015E75BB8513B;C0=49'h00C2168ED0F4B;
              Q2=49'h1F886060D7490;Q1=49'h015E759ADFE91;Q0=49'h00C2168ED3A65;
              L1=49'h015DFDFB40C05;L0=49'h00C216A2AFA64;
            end
      8'd119: begin
              C3=49'h00361494D4660;C2=49'h1F88B2262C265;C1=49'h015D867C36F56;C0=49'h00C3748CD198B;
              Q2=49'h1F8903450C95B;Q1=49'h015D865BD462B;Q0=49'h00C3748CD444E;
              L1=49'h015D0F5F196F8;L0=49'h00C374A09539E;
            end
      8'd120: begin
              C3=49'h0035A6917099E;C2=49'h1F89546390AC3;C1=49'h015C9882B1702;C0=49'h00C4D19C360A7;
              Q2=49'h1F89A4DD6C57E;Q1=49'h015C986290BE8;Q0=49'h00C4D19C38B12;
              L1=49'h015C22076E2AC;L0=49'h00C4D1AFDED26;
            end
      8'd121: begin
              C3=49'h003539ABE89D8;C2=49'h1F89F556FA5A3;C1=49'h015BABCC5CCB0;C0=49'h00C62DBE42C60;
              Q2=49'h1F8A452D7A63F;Q1=49'h015BABAC7D533;Q0=49'h00C62DBE45675;
              L1=49'h015B35F1AACD4;L0=49'h00C62DD1D0EB4;
            end
      8'd122: begin
              C3=49'h0034CDF948D0D;C2=49'h1F8A9503B9C5C;C1=49'h015AC056A878C;C0=49'h00C788F439B37;
              Q2=49'h1F8AE438AF61C;Q1=49'h015AC037097CF;Q0=49'h00C788F43C4F7;
              L1=49'h015A4B1B422C6;L0=49'h00C78907AD6C0;
            end
      8'd123: begin
              C3=49'h003463615A9D0;C2=49'h1F8B336D61FAD;C1=49'h0159D61F0AB24;C0=49'h00C8E33F5A2DA;
              Q2=49'h1F8B8202735A3;Q1=49'h0159D5FFAB8BF;Q0=49'h00C8E33F5CC45;
              L1=49'h01596181ADFF4;L0=49'h00C8E352B3AEF;
            end
      8'd124: begin
              C3=49'h0033F9E82BD7A;C2=49'h1F8BD0974D1E6;C1=49'h0158ED23009CD;C0=49'h00CA3CA0E1091;
              Q2=49'h1F8C1E8E27D36;Q1=49'h0158ED03E0A0E;Q0=49'h00CA3CA0E39A9;
              L1=49'h015879226EC87;L0=49'h00CA3CB420880;
            end
      8'd125: begin
              C3=49'h00339192011B7;C2=49'h1F8C6C84C7683;C1=49'h015805600E204;C0=49'h00CB951A089AE;
              Q2=49'h1F8CB9DF22DB4;Q1=49'h015805412C9CB;Q0=49'h00CB951A0B274;
              L1=49'h015791FB0BBFB;L0=49'h00CB952D2E4BB;
            end
      8'd126: begin
              C3=49'h00332A4A73A4F;C2=49'h1F8D07393B262;C1=49'h01571ED3BDB91;C0=49'h00CCECAC08BF6;
              Q2=49'h1F8D53F8AB9A4;Q1=49'h01571EB51A0DD;Q0=49'h00CCECAC0B46A;
              L1=49'h0156AC0912B98;L0=49'h00CCECBF14D5D;
            end
      8'd127: begin
              C3=49'h0032C4170F8D7;C2=49'h1F8DA0B7DE861;C1=49'h0156397BA0898;C0=49'h00CE435816E09;
              Q2=49'h1F8DECDE00CEB;Q1=49'h0156395D3A12E;Q0=49'h00CE43581962D;
              L1=49'h0155C74A1813C;L0=49'h00CE436B098FF;
            end
      8'd128: begin
              C3=49'h00325EF29C520;C2=49'h1F8E3903EBADF;C1=49'h015555554E2B7;C0=49'h00CF991F65FD1;
              Q2=49'h1F8E849256C3E;Q1=49'h015555372446D;Q0=49'h00CF991F687A5;
              L1=49'h0154E3BBB69D7;L0=49'h00CF99323F780;
            end
      8'd129: begin
              C3=49'h0031FADFF0250;C2=49'h1F8ED020864D4;C1=49'h0154725E64A59;C0=49'h00D0EE0326AE2;
              Q2=49'h1F8F1B18D6A03;Q1=49'h0154724076AC9;Q0=49'h00D0EE0329266;
              L1=49'h0154015B8F832;L0=49'h00D0EE15E726C;
            end
      8'd130: begin
              C3=49'h003197CB318E2;C2=49'h1F8F6610EFD3F;C1=49'h01539094883B3;C0=49'h00D24204872E3;
              Q2=49'h1F8FB0749F2DB;Q1=49'h01539076D599C;Q0=49'h00D2420489A18;
              L1=49'h015320274A38F;L0=49'h00D242172ED63;
            end
      8'd131: begin
              C3=49'h003135C6A9F53;C2=49'h1F8FFAD81A64E;C1=49'h0152AFF56391C;C0=49'h00D39524B35F2;
              Q2=49'h1F9044A8C5A2D;Q1=49'h0152AFD7EB9F7;Q0=49'h00D39524B5CDA;
              L1=49'h0152401C94653;L0=49'h00D395374267A;
            end
      8'd132: begin
              C3=49'h0030D4B93A0AC;C2=49'h1F908E793D26E;C1=49'h0151D07EA74D9;C0=49'h00D4E764D4D09;
              Q2=49'h1F90D7B8512A6;Q1=49'h0151D061697D0;Q0=49'h00D4E764D73A5;
              L1=49'h0151613921CDF;L0=49'h00D4E7774B6A3;
            end
      8'd133: begin
              C3=49'h003074B9F3F31;C2=49'h1F9120F72D626;C1=49'h0150F22E0A557;C0=49'h00D638C612C5D;
              Q2=49'h1F9169A644B15;Q1=49'h0150F21105FEC;Q0=49'h00D638C6152AD;
              L1=49'h0150837AAC433;L0=49'h00D638D87120B;
            end
      8'd134: begin
              C3=49'h003015A55E6AD;C2=49'h1F91B2551F808;C1=49'h01501501495A0;C0=49'h00D78949923C1;
              Q2=49'h1F91FA759682E;Q1=49'h015014E47DF4F;Q0=49'h00D78949949C6;
              L1=49'h014FA6DEF38B9;L0=49'h00D7895BD887D;
            end
      8'd135: begin
              C3=49'h002FB7935B11D;C2=49'h1F924295D5C33;C1=49'h014F38F6272F5;C0=49'h00D8D8F075F03;
              Q2=49'h1F928A29343DF;Q1=49'h014F38D9941C4;Q0=49'h00D8D8F0784BD;
              L1=49'h014ECB63BD50C;L0=49'h00D8D902A45C0;
            end
      8'd136: begin
              C3=49'h002F5A718FF26;C2=49'h1F92D1BC52B47;C1=49'h014E5E0A6C5BA;C0=49'h00DA27BBDE64C;
              Q2=49'h1F9318C3FE2D4;Q1=49'h014E5DEE110E1;Q0=49'h00DA27BBE0BBD;
              L1=49'h014DF106D50CA;L0=49'h00DA27CDF51F4;
            end
      8'd137: begin
              C3=49'h002EFE3F642F9;C2=49'h1F935FCB70653;C1=49'h014D843BE73CC;C0=49'h00DB75ACE9E7E;
              Q2=49'h1F93A648D015E;Q1=49'h014D841FC325E;Q0=49'h00DB75ACEC3A6;
              L1=49'h014D17C60BF61;L0=49'h00DB75BEE91F5;
            end
      8'd138: begin
              C3=49'h002EA30046043;C2=49'h1F93ECC5F8A31;C1=49'h014CAB886BE77;C0=49'h00DCC2C4B498D;
              Q2=49'h1F9432BA798A6;Q1=49'h014CAB6C7E74B;Q0=49'h00DCC2C4B6E6D;
              L1=49'h014C3F9F38EE3;L0=49'h00DCC2D69C7AD;
            end
      8'd139: begin
              C3=49'h002E48A98CE79;C2=49'h1F9478AEC5171;C1=49'h014BD3EDD4045;C0=49'h00DE0F04586DB;
              Q2=49'h1F94BE1BC336B;Q1=49'h014BD3D21CAB9;Q0=49'h00DE0F045AB73;
              L1=49'h014B6890386EE;L0=49'h00DE0F1629279;
            end
      8'd140: begin
              C3=49'h002DEF3EA9C98;C2=49'h1F9503888DA62;C1=49'h014AFD69FED8E;C0=49'h00DF5A6CED392;
              Q2=49'h1F95486F6B4A5;Q1=49'h014AFD4E7D0BE;Q0=49'h00DF5A6CEF7E4;
              L1=49'h014A9296EC771;L0=49'h00DF5A7EA6F7C;
            end
      8'd141: begin
              C3=49'h002D96BA29195;C2=49'h1F958D56101BB;C1=49'h014A27FAD11F1;C0=49'h00E0A4FF88AFC;
              Q2=49'h1F95D1B8286C1;Q1=49'h014A27DF84526;Q0=49'h00E0A4FF8AF08;
              L1=49'h0149BDB13C7AD;L0=49'h00E0A5112B9F7;
            end
      8'd142: begin
              C3=49'h002D3F175333B;C2=49'h1F96161A014D5;C1=49'h0149539E34FCF;C0=49'h00E1EEBD3E6DB;
              Q2=49'h1F9659F8A54C9;Q1=49'h014953831CAAF;Q0=49'h00E1EEBD40AA1;
              L1=49'h0148E9DD15503;L0=49'h00E1EECECABA5;
            end
      8'd143: begin
              C3=49'h002CE850C24FD;C2=49'h1F969DD70E71E;C1=49'h0148805219F20;C0=49'h00E337A71FFBC;
              Q2=49'h1F96E133883E3;Q1=49'h0148803735972;Q0=49'h00E337A72233E;
              L1=49'h01481718691F7;L0=49'h00E337B895D0D;
            end
      8'd144: begin
              C3=49'h002C927041B92;C2=49'h1F97248FC2329;C1=49'h0147AE1474D39;C0=49'h00E47FBE3CD51;
              Q2=49'h1F97676B6BE27;Q1=49'h0147ADF9C3E4F;Q0=49'h00E47FBE3F08F;
              L1=49'h014745612F50C;L0=49'h00E47FCF9C5DA;
            end
      8'd145: begin
              C3=49'h002C3D5A17FC6;C2=49'h1F97AA46DFB8E;C1=49'h0146DCE33F8E6;C0=49'h00E5C703A26C2;
              Q2=49'h1F97ECA2E5530;Q1=49'h0146DCC8C196E;Q0=49'h00E5C703A49BC;
              L1=49'h014674B5647C4;L0=49'h00E5C714EBD2B;
            end
      8'd146: begin
              C3=49'h002BE92695383;C2=49'h1F982EFEC7800;C1=49'h01460CBC79651;C0=49'h00E70D785C2FE;
              Q2=49'h1F9870DC8109F;Q1=49'h01460CA22DD81;Q0=49'h00E70D785E5B6;
              L1=49'h0145A5130A596;L0=49'h00E70D898F9EC;
            end
      8'd147: begin
              C3=49'h002B95CBC88D4;C2=49'h1F98B2BA0DC74;C1=49'h01453D9E2691E;C0=49'h00E8531D73913;
              Q2=49'h1F98F41ABF0D5;Q1=49'h01453D840CEF7;Q0=49'h00E8531D75B89;
              L1=49'h0144D67827AE8;L0=49'h00E8532E91322;
            end
      8'd148: begin
              C3=49'h002B433C8A753;C2=49'h1F99357B432E8;C1=49'h01446F8650553;C0=49'h00E997F3F007A;
              Q2=49'h1F9976601D5BD;Q1=49'h01446F6C6823C;Q0=49'h00E997F3F22AF;
              L1=49'h014408E2C840D;L0=49'h00E99804F803F;
            end
      8'd149: begin
              C3=49'h002AF185AD5D2;C2=49'h1F99B744C6AF1;C1=49'h0143A27304F9F;C0=49'h00EADBFCD7167;
              Q2=49'h1F99F7AF0F2A4;Q1=49'h0143A2594DB66;Q0=49'h00EADBFCD935B;
              L1=49'h01433C50FCC55;L0=49'h00EADC0DC9972;
            end
      8'd150: begin
              C3=49'h002AA093612D7;C2=49'h1F9A381925877;C1=49'h0142D6625797A;C0=49'h00EC1F392C51C;
              Q2=49'h1F9A780A0101B;Q1=49'h0142D648D0CF1;Q0=49'h00EC1F392E6D0;
              L1=49'h014270C0DACFF;L0=49'h00EC1F4A097F5;
            end
      8'd151: begin
              C3=49'h002A50756ABB9;C2=49'h1F9AB7FAA6706;C1=49'h01420B52603F3;C0=49'h00ED61A9F1631;
              Q2=49'h1F9AF773585C8;Q1=49'h01420B39096CC;Q0=49'h00ED61A9F37A5;
              L1=49'h0141A6307CC53;L0=49'h00ED61BAB965B;
            end
      8'd152: begin
              C3=49'h002A0112FDC8F;C2=49'h1F9B36EBD1C0E;C1=49'h014141413BA3B;C0=49'h00EEA350260E6;
              Q2=49'h1F9B75ED6DC58;Q1=49'h01414128145D7;Q0=49'h00EEA3502821C;
              L1=49'h0140DC9E01CB5;L0=49'h00EEA360D90DD;
            end
      8'd153: begin
              C3=49'h0029B27FFDA6A;C2=49'h1F9BB4EEDAE0F;C1=49'h0140782D0B58D;C0=49'h00EFE42CC836F;
              Q2=49'h1F9BF37A9B799;Q1=49'h01407814131ED;Q0=49'h00EFE42CCA467;
              L1=49'h014014078DBA8;L0=49'h00EFE43D665A9;
            end
      8'd154: begin
              C3=49'h002964AAFB3AA;C2=49'h1F9C32062C881;C1=49'h013FB013F57F1;C0=49'h00F12440D3E3A;
              Q2=49'h1F9C701D2C9B1;Q1=49'h013FAFFB2BE22;Q0=49'h00F12440D5EF4;
              L1=49'h013F4C6B490EB;L0=49'h00F124515D527;
            end
      8'd155: begin
              C3=49'h0029179E0F32A;C2=49'h1F9CAE33FC1E1;C1=49'h013EE8F424EA5;C0=49'h00F2638D4343F;
              Q2=49'h1F9CEBD76AB95;Q1=49'h013EE8DB896ED;Q0=49'h00F2638D454BD;
              L1=49'h013E85C760D9E;L0=49'h00F2639DB8248;
            end
      8'd156: begin
              C3=49'h0028CB4C03323;C2=49'h1F9D297AA0D84;C1=49'h013E22CBC8E70;C0=49'h00F3A2130EB47;
              Q2=49'h1F9D66AB929E1;Q1=49'h013E22B35B217;Q0=49'h00F3A21310B88;
              L1=49'h013DC01A06B40;L0=49'h00F3A2236F2D1;
            end
      8'd157: begin
              C3=49'h00287FB48F146;C2=49'h1F9DA3DC5206F;C1=49'h013D5D9915500;C0=49'h00F4DFD32CC35;
              Q2=49'h1F9DE09BE1671;Q1=49'h013D5D80D4CDF;Q0=49'h00F4DFD32EC3A;
              L1=49'h013CFB6170AF5;L0=49'h00F4DFE378F9C;
            end
      8'd158: begin
              C3=49'h002834D4E5FBA;C2=49'h1F9E1D5B47E8C;C1=49'h013C995A426C6;C0=49'h00F61CCE9234A;
              Q2=49'h1F9E59AA85F71;Q1=49'h013C99422EC2B;Q0=49'h00F61CCE94314;
              L1=49'h013C379BD9488;L0=49'h00F61CDECA4E7;
            end
      8'd159: begin
              C3=49'h0027EAAEA2F8E;C2=49'h1F9E95F9A8A1D;C1=49'h013BD60D8CEF8;C0=49'h00F7590632073;
              Q2=49'h1F9ED1D9ADF02;Q1=49'h013BD5F5A5AC7;Q0=49'h00F7590634002;
              L1=49'h013B74C77F5A6;L0=49'h00F7591656298;
            end
      8'd160: begin
              C3=49'h0027A1454EBFA;C2=49'h1F9F0DB995BEF;C1=49'h013B13B135E00;C0=49'h00F8947AFD787;
              Q2=49'h1F9F492B7CE55;Q1=49'h013B13997A92F;Q0=49'h00F8947AFF6DC;
              L1=49'h013AB2E2A60FF;L0=49'h00F8948B0DC81;
            end
      8'd161: begin
              C3=49'h0027588B2B25A;C2=49'h1F9F849D41497;C1=49'h013A52438285B;C0=49'h00F9CF2DE4093;
              Q2=49'h1F9FBFA211811;Q1=49'h013A522BF2C57;Q0=49'h00F9CF2DE5FAF;
              L1=49'h0139F1EB94D6F;L0=49'h00F9CF3DE0AA8;
            end
      8'd162: begin
              C3=49'h00271085F8294;C2=49'h1F9FFAA6BA6A1;C1=49'h013991C2BC706;C0=49'h00FB091FD3818;
              Q2=49'h1FA0353F83543;Q1=49'h013991AB57D04;Q0=49'h00FB091FD56FB;
              L1=49'h013931E097539;L0=49'h00FB092FBC98A;
            end
      8'd163: begin
              C3=49'h0026C92A9CC1D;C2=49'h1FA06FD824890;C1=49'h0138D22D31535;C0=49'h00FC4251B7F53;
              Q2=49'h1FA0AA05E5018;Q1=49'h0138D215F76DE;Q0=49'h00FC4251B9DFD;
              L1=49'h013872BFFD52F;L0=49'h00FC42618DA5E;
            end
      8'd164: begin
              C3=49'h00268283ACA37;C2=49'h1FA0E4337911D;C1=49'h0138138133160;C0=49'h00FD7AC47BC7D;
              Q2=49'h1FA11DF73EFCB;Q1=49'h0138136A237FA;Q0=49'h00FD7AC47DAF0;
              L1=49'h0137B4881ABE9;L0=49'h00FD7AD43E357;
            end
      8'd165: begin
              C3=49'h00263C81CF45B;C2=49'h1FA157BAD6243;C1=49'h013755BD17A15;C0=49'h00FEB27907B0E;
              Q2=49'h1FA19115990DD;Q1=49'h013755A631F72;Q0=49'h00FEB27909949;
              L1=49'h0136F73747904;L0=49'h00FEB288B6FE8;
            end
      8'd166: begin
              C3=49'h0025F7271D070;C2=49'h1FA1CA70354F4;C1=49'h013698DF38F6E;C0=49'h00FFE97042BFE;
              Q2=49'h1FA20362EFA04;Q1=49'h013698C87CD5C;Q0=49'h00FFE97044A02;
              L1=49'h01363ACBDFC54;L0=49'h00FFE97FDF103;
            end
      8'd167: begin
              C3=49'h0025B27763F77;C2=49'h1FA23C558A4F0;C1=49'h0135DCE5F514D;C0=49'h01011FAB12603;
              Q2=49'h1FA274E13D801;Q1=49'h0135DCCF62151;Q0=49'h01011FAB143D1;
              L1=49'h01357F444352C;L0=49'h01011FBA9BD5B;
            end
      8'd168: begin
              C3=49'h00256E6C43B8C;C2=49'h1FA2AD6CD2260;C1=49'h013521CFADE4B;C0=49'h0102552A5A5D4;
              Q2=49'h1FA2E59274B76;Q1=49'h013521B943A39;Q0=49'h0102552A5C36D;
              L1=49'h0134C49ED618A;L0=49'h01025539D11A0;
            end
      8'd169: begin
              C3=49'h00252B06ECF18;C2=49'h1FA31DB7F6D7B;C1=49'h0134679AC93B7;C0=49'h010389EEFCE66;
              Q2=49'h1FA35578811A6;Q1=49'h0134678487568;Q0=49'h010389EEFEBCA;
              L1=49'h01340AD9FFD78;L0=49'h010389FE610C1;
            end
      8'd170: begin
              C3=49'h0024E8411F98A;C2=49'h1FA38D38EA1E9;C1=49'h0133AE45B0C12;C0=49'h0104BDF9DA92A;
              Q2=49'h1FA3C4954B510;Q1=49'h0133AE2F96D8D;Q0=49'h0104BDF9DC658;
              L1=49'h013351F42C241;L0=49'h0104BE092C42C;
            end
      8'd171: begin
              C3=49'h0024A61D9DFB9;C2=49'h1FA3FBF188305;C1=49'h0132F5CED1F48;C0=49'h0105F14BD2649;
              Q2=49'h1FA432EAB3A71;Q1=49'h0132F5B8DFA7F;Q0=49'h0105F14BD4343;
              L1=49'h013299EBCA5B6;L0=49'h0105F15B11C03;
            end
      8'd172: begin
              C3=49'h00246493DC999;C2=49'h1FA469E3BB82F;C1=49'h01323E349E0D6;C0=49'h010723E5C1CE2;
              Q2=49'h1FA4A07A985EB;Q1=49'h01323E1ED2FFB;Q0=49'h010723E5C39A9;
              L1=49'h0131E2BF4D981;L0=49'h010723F4EEF63;
            end
      8'd173: begin
              C3=49'h002423A3F3CB6;C2=49'h1FA4D711586FC;C1=49'h013187758A041;C0=49'h010855C884B48;
              Q2=49'h1FA50D46CDEA2;Q1=49'h0131875FE5D91;Q0=49'h010855C8867DB;
              L1=49'h01312C6D2CA70;L0=49'h010855D79FC97;
            end
      8'd174: begin
              C3=49'h0023E351DE250;C2=49'h1FA5437C2BB5F;C1=49'h0130D1900E7CD;C0=49'h010986F4F5738;
              Q2=49'h1FA5795124D81;Q1=49'h0130D17A90D77;Q0=49'h010986F4F7398;
              L1=49'h013076F3E1FC3;L0=49'h01098703FE959;
            end
      8'd175: begin
              C3=49'h0023A39F5CC1B;C2=49'h1FA5AF25F9EC5;C1=49'h01301C82A7C22;C0=49'h010AB76BECE18;
              Q2=49'h1FA5E49B6ADBA;Q1=49'h01301C6D503DC;Q0=49'h010AB76BEEA45;
              L1=49'h012FC251EBA8A;L0=49'h010AB77AE4309;
            end
      8'd176: begin
              C3=49'h00236472FD8EA;C2=49'h1FA61A10B7EF2;C1=49'h012F684BD597B;C0=49'h010BE72E4252E;
              Q2=49'h1FA64F2763EF4;Q1=49'h012F6836A3EA5;Q0=49'h010BE72E44129;
              L1=49'h012F0E85CB4E5;L0=49'h010BE73D27EE9;
            end
      8'd177: begin
              C3=49'h002325E3D8758;C2=49'h1FA6843DFC662;C1=49'h012EB4EA1B7C2;C0=49'h010D163CCB9DA;
              Q2=49'h1FA6B8F6D1FD1;Q1=49'h012EB4D50F44F;Q0=49'h010D163CCD5A4;
              L1=49'h012E5B8E0616F;L0=49'h010D164B9FA54;
            end
      8'd178: begin
              C3=49'h0022E7ED7B8B1;C2=49'h1FA6EDAF8C35F;C1=49'h012E025C00558;C0=49'h010E44985D1CF;
              Q2=49'h1FA7220B6F515;Q1=49'h012E02471939D;Q0=49'h010E44985ED69;
              L1=49'h012DA96924A92;L0=49'h010E44A71FAFA;
            end
      8'd179: begin
              C3=49'h0022AA85DBDD6;C2=49'h1FA756672CE08;C1=49'h012D50A00E7F3;C0=49'h010F7241C9B4C;
              Q2=49'h1FA78A66F60C4;Q1=49'h012D508B4C274;Q0=49'h010F7241CB6B5;
              L1=49'h012CF815B31D6;L0=49'h010F72507AF14;
            end
      8'd180: begin
              C3=49'h00226DA909063;C2=49'h1FA7BE6697B74;C1=49'h012C9FB4D3C58;C0=49'h01109F39E2D4F;
              Q2=49'h1FA7F20B151CE;Q1=49'h012C9FA035E09;Q0=49'h01109F39E4888;
              L1=49'h012C479240F5A;L0=49'h01109F4882D9B;
            end
      8'd181: begin
              C3=49'h0022315F525A1;C2=49'h1FA825AF6AEF0;C1=49'h012BEF98E1624;C0=49'h0111CB81787D0;
              Q2=49'h1FA858F979FE2;Q1=49'h012BEF8467976;Q0=49'h0111CB817A2D9;
              L1=49'h012B97DD61115;L0=49'h0111CB9007682;
            end
      8'd182: begin
              C3=49'h0021F59FCFB9A;C2=49'h1FA88C435CCC7;C1=49'h012B404ACBDC5;C0=49'h0112F719593F3;
              Q2=49'h1FA8BF33CDD2E;Q1=49'h012B403675D78;Q0=49'h0112F7195AECC;
              L1=49'h012AE8F5A9A55;L0=49'h0112F727D72EB;
            end
      8'd183: begin
              C3=49'h0021BA62DA4F2;C2=49'h1FA8F2241E930;C1=49'h012A91C92B085;C0=49'h0114220252440;
              Q2=49'h1FA924BBB1E2B;Q1=49'h012A91B4F87F4;Q0=49'h0114220253EEB;
              L1=49'h012A3AD9B4312;L0=49'h01142210BF558;
            end
      8'd184: begin
              C3=49'h00217FBAA639E;C2=49'h1FA957532D171;C1=49'h0129E4129A1A4;C0=49'h01154C3D2F4D9;
              Q2=49'h1FA98992C5277;Q1=49'h0129E3FE8AB04;Q0=49'h01154C3D30F55;
              L1=49'h01298D881D756;L0=49'h01154C4B8B9E7;
            end
      8'd185: begin
              C3=49'h0021459B72EDA;C2=49'h1FA9BBD237665;C1=49'h01293725B766E;C0=49'h011675CABABA9;
              Q2=49'h1FA9EDBAA1882;Q1=49'h01293711CAC9E;Q0=49'h011675CABC5F7;
              L1=49'h0128E0FF856B4;L0=49'h011675D90667F;
            end
      8'd186: begin
              C3=49'h00210BFCF83F2;C2=49'h1FAA1FA2DF9A5;C1=49'h01288B012479F;C0=49'h01179EABBD89C;
              Q2=49'h1FAA5134DB786;Q1=49'h01288AED5A5EE;Q0=49'h01179EABBF2BD;
              L1=49'h0128353E8F3A5;L0=49'h01179EB9F8B09;
            end
      8'd187: begin
              C3=49'h0020D2DE5CC34;C2=49'h1FAA82C6B72C9;C1=49'h0127DFA386109;C0=49'h0118C6E0FF5D2;
              Q2=49'h1FAAB40305555;Q1=49'h0127DF8FDE297;Q0=49'h0118C6E100FC5;
              L1=49'h01278A43E12F1;L0=49'h0118C6EF2A19D;
            end
      8'd188: begin
              C3=49'h00209A45149D7;C2=49'h1FAAE53F40B51;C1=49'h0127350B840C3;C0=49'h0119EE6B467CC;
              Q2=49'h1FAB1626A70A1;Q1=49'h012734F7FE0C1;Q0=49'h0119EE6B48193;
              L1=49'h0126E00E24B33;L0=49'h0119EE7960EBC;
            end
      8'd189: begin
              C3=49'h00206234CCBD6;C2=49'h1FAB470DFC2B4;C1=49'h01268B37C9670;C0=49'h011B154B57DA5;
              Q2=49'h1FAB77A14AE94;Q1=49'h01268B2464F86;Q0=49'h011B154B59740;
              L1=49'h0126369C06437;L0=49'h011B15596217B;
            end
      8'd190: begin
              C3=49'h00202AA467EA8;C2=49'h1FABA8347E1D6;C1=49'h0125E227041BA;C0=49'h011C3B81F713F;
              Q2=49'h1FABD874755AA;Q1=49'h0125E213C0F18;Q0=49'h011C3B81F8AAD;
              L1=49'h01258DEC3566F;L0=49'h011C3B8FF13B8;
            end
      8'd191: begin
              C3=49'h001FF38D691A2;C2=49'h1FAC08B44E9A4;C1=49'h012539D7E5308;C0=49'h011D610FE6773;
              Q2=49'h1FAC38A1A288D;Q1=49'h012539C4C3050;Q0=49'h011D610FE80B6;
              L1=49'h0124E5FD64A78;L0=49'h011D611DD0A48;
            end
      8'd192: begin
              C3=49'h001FBCF9E4E4E;C2=49'h1FAC688ED6648;C1=49'h0124924920B7B;C0=49'h011E85F5E7043;
              Q2=49'h1FAC982A4E69F;Q1=49'h012492361F392;Q0=49'h011E85F5E895B;
              L1=49'h01243ECE4987A;L0=49'h011E8603C152B;
            end
      8'd193: begin
              C3=49'h001F86DB72A8C;C2=49'h1FACC7C5A4D2A;C1=49'h0123EB796DA18;C0=49'h011FAA34B870C;
              Q2=49'h1FACF70FEDB33;Q1=49'h0123EB668C8D6;Q0=49'h011FAA34B9FF9;
              L1=49'h0123985D9C7B0;L0=49'h011FAA4282FB7;
            end
      8'd194: begin
              C3=49'h001F513F318DA;C2=49'h1FAD265A15434;C1=49'h0123456785E3E;C0=49'h0120CDCD192AE;
              Q2=49'h1FAD5553F49DF;Q1=49'h01234554C4E90;Q0=49'h0120CDCD1AB71;
              L1=49'h0122F2AA18DDB;L0=49'h0120CDDAD40CA;
            end
      8'd195: begin
              C3=49'h001F1C14E403A;C2=49'h1FAD844DB241E;C1=49'h0122A012263E7;C0=49'h0121F0BFC65C1;
              Q2=49'h1FADB2F7D18E6;Q1=49'h01229FFF851A4;Q0=49'h0121F0BFC7E5A;
              L1=49'h01224DB27CEC0;L0=49'h0121F0CD71AF8;
            end
      8'd196: begin
              C3=49'h001EE765ADAA2;C2=49'h1FADE1A1D3D01;C1=49'h0121FB780E65B;C0=49'h0123130D7BEC2;
              Q2=49'h1FAE0FFCEC76A;Q1=49'h0121FB658CCDF;Q0=49'h0123130D7D731;
              L1=49'h0121A97589BA8;L0=49'h0123131B17CB9;
            end
      8'd197: begin
              C3=49'h001EB32DE69F8;C2=49'h1FAE3E57E77EB;C1=49'h0121579800D43;C0=49'h012434B6F483C;
              Q2=49'h1FAE6C64AC470;Q1=49'h012157859E81C;Q0=49'h012434B6F6081;
              L1=49'h012105F2032E3;L0=49'h012434C481096;
            end
      8'd198: begin
              C3=49'h001E7F6D2A7B1;C2=49'h1FAE9A714FAC1;C1=49'h0120B470C2D4A;C0=49'h012555BCE98FA;
              Q2=49'h1FAEC830741ED;Q1=49'h0120B45E7F7F5;Q0=49'h012555BCEB117;
              L1=49'h01206326AFF39;L0=49'h012555CA66D56;
            end
      8'd199: begin
              C3=49'h001E4C1BF7831;C2=49'h1FAEF5EF76417;C1=49'h012012011C713;C0=49'h0126762013433;
              Q2=49'h1FAF2361A10DA;Q1=49'h012011EEF7D72;Q0=49'h0126762014C28;
              L1=49'h011FC11259780;L0=49'h0126762D8162C;
            end
      8'd200: begin
              C3=49'h001E193CBE27A;C2=49'h1FAF50D3B3428;C1=49'h011F7047D875E;C0=49'h012795E1289B3;
              Q2=49'h1FAF7DF98D95C;Q1=49'h011F7035D2540;Q0=49'h012795E12A180;
              L1=49'h011F1FB3CBE1A;L0=49'h012795EE87AE1;
            end
      8'd201: begin
              C3=49'h001DE6DA0E8A4;C2=49'h1FAFAB1F48562;C1=49'h011ECF43C46EE;C0=49'h0128B500DF60A;
              Q2=49'h1FAFD7F990249;Q1=49'h011ECF31DC773;Q0=49'h0128B500E0DAE;
              L1=49'h011E7F09D6073;L0=49'h0128B50E2F7FF;
            end
      8'd202: begin
              C3=49'h001DB4D9F4C1B;C2=49'h1FB004D3B644B;C1=49'h011E2EF3B0717;C0=49'h0129D37FEC2B3;
              Q2=49'h1FB03162FD66C;Q1=49'h011E2EE1E66BC;Q0=49'h0129D37FEDA30;
              L1=49'h011DDF1349696;L0=49'h0129D38D2D701;
            end
      8'd203: begin
              C3=49'h001D83535C40E;C2=49'h1FB05DF224D9A;C1=49'h011D8F566F660;C0=49'h012AF15F02643;
              Q2=49'h1FB08A3722DF5;Q1=49'h011D8F44C307D;Q0=49'h012AF15F03D99;
              L1=49'h011D3FCEFA2A8;L0=49'h012AF16C34E76;
            end
      8'd204: begin
              C3=49'h001D523253F12;C2=49'h1FB0B67C01023;C1=49'h011CF06AD6ADA;C0=49'h012C0E9ED4491;
              Q2=49'h1FB0E2774C52C;Q1=49'h011CF05947BC1;Q0=49'h012C0E9ED5BC0;
              L1=49'h011CA13BBF086;L0=49'h012C0EABF8233;
            end
      8'd205: begin
              C3=49'h001D218136798;C2=49'h1FB10E7280654;C1=49'h011C522FBE5A9;C0=49'h012D2B4012EDF;
              Q2=49'h1FB13A24C23FE;Q1=49'h011C521E4C917;Q0=49'h012D2B40145E7;
              L1=49'h011C03587153C;L0=49'h012D2B4D28375;
            end
      8'd206: begin
              C3=49'h001CF13BF1D5C;C2=49'h1FB165D6EE673;C1=49'h011BB4A401033;C0=49'h012E47436E405;
              Q2=49'h1FB19140C9622;Q1=49'h011BB492AC20A;Q0=49'h012E47436FAE7;
              L1=49'h011B6623ECEA4;L0=49'h012E475075113;
            end
      8'd207: begin
              C3=49'h001CC165513CB;C2=49'h1FB1BCAA879F3;C1=49'h011B17C67BCAE;C0=49'h012F62A995097;
              Q2=49'h1FB1E7CC9F61C;Q1=49'h011B17B5438F3;Q0=49'h012F62A996754;
              L1=49'h011AC99D102EA;L0=49'h012F62B68D79C;
            end
      8'd208: begin
              C3=49'h001C91F3A5BD1;C2=49'h1FB212EE99B43;C1=49'h011A7B960E4D4;C0=49'h01307D7334F13;
              Q2=49'h1FB23DC986FA3;Q1=49'h011A7B84F27B5;Q0=49'h01307D73365AA;
              L1=49'h011A2DC2BC024;L0=49'h01307D801F18A;
            end
      8'd209: begin
              C3=49'h001C62E5D601F;C2=49'h1FB268A46038D;C1=49'h0119E0119AAA2;C0=49'h013197A0FA801;
              Q2=49'h1FB29338B7A55;Q1=49'h0119E0009B064;Q0=49'h013197A0FBE72;
              L1=49'h01199293D3BE2;L0=49'h013197ADD6763;
            end
      8'd210: begin
              C3=49'h001C34414A0BE;C2=49'h1FB2BDCD0834D;C1=49'h0119453805783;C0=49'h0132B13391220;
              Q2=49'h1FB2E81B68F3C;Q1=49'h0119452721C26;Q0=49'h0132B1339286C;
              L1=49'h0118F80F3D2B6;L0=49'h0132B1405EFE3;
            end
      8'd211: begin
              C3=49'h001C060F8738E;C2=49'h1FB31269B3899;C1=49'h0118AB0835C16;C0=49'h0133CA2BA328C;
              Q2=49'h1FB33C72CBB27;Q1=49'h0118AAF76DB37;Q0=49'h0133CA2BA48B4;
              L1=49'h01185E33E07EF;L0=49'h0133CA3863023;
            end
      8'd212: begin
              C3=49'h001BD833489CA;C2=49'h1FB3667BC71F1;C1=49'h0118118114D23;C0=49'h0134E289D9CE4;
              Q2=49'h1FB3904013DE0;Q1=49'h01181170683BB;Q0=49'h0134E289DB2E8;
              L1=49'h0117C500A84FA;L0=49'h0134E2968BBBE;
            end
      8'd213: begin
              C3=49'h001BAABEDFA69;C2=49'h1FB3BA044DD42;C1=49'h011778A18E849;C0=49'h0135FA4EDD371;
              Q2=49'h1FB3E3846C293;Q1=49'h01177890FD25E;Q0=49'h0135FA4EDE951;
              L1=49'h01172C7481924;L0=49'h0135FA5B814F9;
            end
      8'd214: begin
              C3=49'h001B7DB050D34;C2=49'h1FB40D0474BEF;C1=49'h0116E06890F7B;C0=49'h0137117B5474A;
              Q2=49'h1FB43640FD997;Q1=49'h0116E0581A93E;Q0=49'h0137117B55D06;
              L1=49'h0116948E5B91B;L0=49'h01371187EACE9;
            end
      8'd215: begin
              C3=49'h001B50FE9F17E;C2=49'h1FB45F7D72A17;C1=49'h011648D50C981;C0=49'h0138280FE587C;
              Q2=49'h1FB48876EFC8E;Q1=49'h011648C4B0F95;Q0=49'h0138280FE6E14;
              L1=49'h0115FD4D27E93;L0=49'h0138281C6E399;
            end
      8'd216: begin
              C3=49'h001B24B446BE9;C2=49'h1FB4B17059CFD;C1=49'h0115B1E5F42FF;C0=49'h01393E0D3562C;
              Q2=49'h1FB4DA2767BC8;Q1=49'h0115B1D5B316C;Q0=49'h01393E0D36BA2;
              L1=49'h011566AFDA7E7;L0=49'h01393E19B0829;
            end
      8'd217: begin
              C3=49'h001AF8C98D50E;C2=49'h1FB502DE530E2;C1=49'h01151B9A3CC6E;C0=49'h013A5373E7EC0;
              Q2=49'h1FB52B5383593;Q1=49'h01151B8A15F6F;Q0=49'h013A5373E9413;
              L1=49'h0114D0B5697AA;L0=49'h013A5380558FD;
            end
      8'd218: begin
              C3=49'h001ACD37A70DB;C2=49'h1FB553C88BCEF;C1=49'h011485F0DD9AF;C0=49'h013B68449FFFE;
              Q2=49'h1FB57BFC60698;Q1=49'h011485E0D0E42;Q0=49'h013B6844A152F;
              L1=49'h01143B5CCD445;L0=49'h013B6851003D8;
            end
      8'd219: begin
              C3=49'h001AA201545BB;C2=49'h1FB5A43018196;C1=49'h0113F0E8D035E;C0=49'h013C7C7FFF734;
              Q2=49'h1FB5CC2319F0A;Q1=49'h0113F0D8DD607;Q0=49'h013C7C8000C43;
              L1=49'h0113A6A5007AA;L0=49'h013C7C8C52605;
            end
      8'd220: begin
              C3=49'h001A772DEFCCF;C2=49'h1FB5F4160170E;C1=49'h01135C8110570;C0=49'h013D9026A7159;
              Q2=49'h1FB61BC8C6BC3;Q1=49'h01135C7137263;Q0=49'h013D9026A8646;
              L1=49'h0113128CFFECE;L0=49'h013D9032ECC78;
            end
      8'd221: begin
              C3=49'h001A4CAEE07A5;C2=49'h1FB6437B76F25;C1=49'h0112C8B89BD80;C0=49'h013EA33936B31;
              Q2=49'h1FB66AEE7C881;Q1=49'h0112C8A8DC1B8;Q0=49'h013EA33937FFC;
              L1=49'h01127F13CA981;L0=49'h013EA3456F3F3;
            end
      8'd222: begin
              C3=49'h001A229015CBD;C2=49'h1FB6926173A1E;C1=49'h0112358E72D68;C0=49'h013FB5B84D171;
              Q2=49'h1FB6B9954BCA1;Q1=49'h0112357ECC521;Q0=49'h013FB5B84E61B;
              L1=49'h0111EC38619D9;L0=49'h013FB5C478926;
            end
      8'd223: begin
              C3=49'h0019F8CD158DE;C2=49'h1FB6E0C90F7CD;C1=49'h0111A301977FE;C0=49'h0140C7A4880DF;
              Q2=49'h1FB707BE420BC;Q1=49'h0111A2F209FE5;Q0=49'h0140C7A489568;
              L1=49'h011159F9C8407;L0=49'h0140C7B0A68D6;
            end
      8'd224: begin
              C3=49'h0019CF5F957E4;C2=49'h1FB72EB35E4CA;C1=49'h011111110E233;C0=49'h0141D8FE84674;
              Q2=49'h1FB7556A6E4D7;Q1=49'h01111101996EF;Q0=49'h0141D8FE85ADD;
              L1=49'h0110C85703DD6;L0=49'h0141D90A95FFA;
            end
      8'd225: begin
              C3=49'h0019A64D06C6E;C2=49'h1FB77C21623B4;C1=49'h01107FBBDD2B5;C0=49'h0142E9C6DDF83;
              Q2=49'h1FB7A29AD6115;Q1=49'h01107FAC81106;Q0=49'h0142E9C6DF3CA;
              L1=49'h0110374F1BE65;L0=49'h0142E9D2E2BDF;
            end
      8'd226: begin
              C3=49'h00197D8D55E5E;C2=49'h1FB7C9142EE50;C1=49'h010FEF010D0E4;C0=49'h0143F9FE2F9D0;
              Q2=49'h1FB7EF5083188;Q1=49'h010FEEF1C959C;Q0=49'h0143F9FE30DF8;
              L1=49'h010FA6E119DCD;L0=49'h0143FA0A27A4A;
            end
      8'd227: begin
              C3=49'h0019552CFF1CF;C2=49'h1FB8158CB28E6;C1=49'h010F5EDFA85D4;C0=49'h014509A5133BD;
              Q2=49'h1FB83B8C778F6;Q1=49'h010F5ED07CD4B;Q0=49'h014509A5147C4;
              L1=49'h010F170C094C7;L0=49'h014509B0FE997;
            end
      8'd228: begin
              C3=49'h00192D11E31D6;C2=49'h1FB8618C1860D;C1=49'h010ECF56BB943;C0=49'h014618BC21C60;
              Q2=49'h1FB8874FB4106;Q1=49'h010ECF47A8113;Q0=49'h014618BC23048;
              L1=49'h010E87CEF7C58;L0=49'h014618C8008DD;
            end
      8'd229: begin
              C3=49'h001905572AEA6;C2=49'h1FB8AD1333954;C1=49'h010E40655558F;C0=49'h01472743F33AC;
              Q2=49'h1FB8D29B36C06;Q1=49'h010E405659A09;Q0=49'h01472743F4775;
              L1=49'h010DF928F4D79;L0=49'h0147274FC5808;
            end
      8'd230: begin
              C3=49'h0018DDEAB75E3;C2=49'h1FB8F8231C5D9;C1=49'h010DB20A862BB;C0=49'h0148353D1EA8B;
              Q2=49'h1FB91D6FFC763;Q1=49'h010DB1FBA20F8;Q0=49'h0148353D1FE34;
              L1=49'h010D6B19120BF;L0=49'h01483548E4802;
            end
      8'd231: begin
              C3=49'h0018B6CE55495;C2=49'h1FB942BCC8434;C1=49'h010D244560945;C0=49'h014942A83A2FE;
              Q2=49'h1FB967CEFD4B7;Q1=49'h010D243693E4B;Q0=49'h014942A83B688;
              L1=49'h010CDD9E62E1D;L0=49'h014942B3F3ACA;
            end
      8'd232: begin
              C3=49'h0018900435B28;C2=49'h1FB98CE12BCF1;C1=49'h010C9714F90A9;C0=49'h014A4F85DB040;
              Q2=49'h1FB9B1B930FC3;Q1=49'h010C97064395F;Q0=49'h014A4F85DC3AC;
              L1=49'h010C50B7FCC74;L0=49'h014A4F9188398;
            end
      8'd233: begin
              C3=49'h001869963E4E8;C2=49'h1FB9D6912914A;C1=49'h010C0A7865FD8;C0=49'h014B5BD6956E4;
              Q2=49'h1FB9FB2F8BC29;Q1=49'h010C0A69C7891;Q0=49'h014B5BD696A31;
              L1=49'h010BC464F7153;L0=49'h014B5BE2366FB;
            end
      8'd234: begin
              C3=49'h0018436B7496D;C2=49'h1FBA1FCDDC921;C1=49'h010B7E6EBFA3E;C0=49'h014C679AFCCF0;
              Q2=49'h1FBA4432FD933;Q1=49'h010B7E60380C9;Q0=49'h014C679AFE01F;
              L1=49'h010B38A46B0A1;L0=49'h014C67A691AF7;
            end
      8'd235: begin
              C3=49'h00181D996BCB5;C2=49'h1FBA68980F3FA;C1=49'h010AF2F720426;C0=49'h014D72D3A39FF;
              Q2=49'h1FBA8CC475CD5;Q1=49'h010AF2E8AF507;Q0=49'h014D72D3A4D10;
              L1=49'h010AAD7573C61;L0=49'h014D72DF2C726;
            end
      8'd236: begin
              C3=49'h0017F8114E6FE;C2=49'h1FBAB0F0CA33A;C1=49'h010A6810A3D7D;C0=49'h014E7D811B75D;
              Q2=49'h1FBAD4E4E3000;Q1=49'h010A680249610;Q0=49'h014E7D811CA51;
              L1=49'h010A22D72E441;L0=49'h014E7D8C984D1;
            end
      8'd237: begin
              C3=49'h0017D2D6699CB;C2=49'h1FBAF8D8ECEFB;C1=49'h0109DDBA6854B;C0=49'h014F87A3F5029;
              Q2=49'h1FBB1C952DFC2;Q1=49'h0109DDAC2428C;Q0=49'h014F87A3F62FF;
              L1=49'h010998C8B956A;L0=49'h014F87AF65F12;
            end
      8'd238: begin
              C3=49'h0017ADEDEE943;C2=49'h1FBB40515A8A4;C1=49'h010953F38D759;C0=49'h0150913CC016A;
              Q2=49'h1FBB63D63F410;Q1=49'h010953E55F630;Q0=49'h0150913CC1423;
              L1=49'h01090F4935A24;L0=49'h01509148252F2;
            end
      8'd239: begin
              C3=49'h001789433C7CF;C2=49'h1FBB875B18892;C1=49'h0108CABB34B96;C0=49'h01519A4C0BA36;
              Q2=49'h1FBBAAA8FBC09;Q1=49'h0108CAAD1C9E2;Q0=49'h01519A4C0CCD2;
              L1=49'h01088657C599C;L0=49'h01519A5764F81;
            end
      8'd240: begin
              C3=49'h001764F662A5B;C2=49'h1FBBCDF6D6BD9;C1=49'h0108421081903;C0=49'h0152A2D265BC7;
              Q2=49'h1FBBF10E48F30;Q1=49'h010842027F2EA;Q0=49'h0152A2D266E46;
              L1=49'h0107FDF38D77A;L0=49'h0152A2DDB35F8;
            end
      8'd241: begin
              C3=49'h001740EB27136;C2=49'h1FBC1425A39F3;C1=49'h0107B9F299032;C0=49'h0153AAD05B99D;
              Q2=49'h1FBC3707050DD;Q1=49'h0107B9E4AC376;Q0=49'h0153AAD05CC00;
              L1=49'h0107761BB33C3;L0=49'h0153AADB9D9D5;
            end
      8'd242: begin
              C3=49'h00171D284D511;C2=49'h1FBC59E8535BD;C1=49'h01073260A1F77;C0=49'h0154B24679996;
              Q2=49'h1FBC7C940FF47;Q1=49'h01073252CA968;Q0=49'h0154B2467ABDC;
              L1=49'h0106EECF5EA69;L0=49'h0154B251B00F3;
            end
      8'd243: begin
              C3=49'h0016F9B60578C;C2=49'h1FBC9F3FB4ADE;C1=49'h0106AB59C512B;C0=49'h0155B9354B40D;
              Q2=49'h1FBCC1B64694E;Q1=49'h0106AB4C02EB0;Q0=49'h0155B9354C638;
              L1=49'h0106680DB9315;L0=49'h0155B940763AB;
            end
      8'd244: begin
              C3=49'h0016D67E70B50;C2=49'h1FBCE42CC6943;C1=49'h010624DD2C996;C0=49'h0156BF9D5B3F5;
              Q2=49'h1FBD066E83EBC;Q1=49'h010624CF7F8A1;Q0=49'h0156BF9D5C604;
              L1=49'h0105E1D5EE0E2;L0=49'h0156BFA87ACEE;
            end
      8'd245: begin
              C3=49'h0016B39B9475D;C2=49'h1FBD28B034A31;C1=49'h01059EEA04AF6;C0=49'h0157C57F336F3;
              Q2=49'h1FBD4ABD9E119;Q1=49'h01059EDC6C835;Q0=49'h0157C57F348E6;
              L1=49'h01055C272A216;L0=49'h0157C58A47A5E;
            end
      8'd246: begin
              C3=49'h001690F858059;C2=49'h1FBD6CCAF846A;C1=49'h0105197F7AFE7;C0=49'h0158CADB5CD7B;
              Q2=49'h1FBD8EA46C92D;Q1=49'h01051971F7909;Q0=49'h0158CADB5DF53;
              L1=49'h0104D7009BFD1;L0=49'h0158CAE665C6E;
            end
      8'd247: begin
              C3=49'h00166E9F3B25A;C2=49'h1FBDB07DD4039;C1=49'h0104949CBEF79;C0=49'h0159CFB25FAEA;
              Q2=49'h1FBDD223C370C;Q1=49'h0104948F501A6;Q0=49'h0159CFB260CA6;
              L1=49'h0104526173DE1;L0=49'h0159CFBD5D677;
            end
      8'd248: begin
              C3=49'h00164C8D1ED80;C2=49'h1FBDF3C99F027;C1=49'h0104104101A86;C0=49'h015AD404C35A1;
              Q2=49'h1FBE153C73070;Q1=49'h01041033A732B;Q0=49'h015AD404C4742;
              L1=49'h0103CE48E3A5D;L0=49'h015AD40FB5ED9;
            end
      8'd249: begin
              C3=49'h00162ABC8B6EC;C2=49'h1FBE36AF3232B;C1=49'h01038C6B75C05;C0=49'h015BD7D30E71E;
              Q2=49'h1FBE57EF4D3D7;Q1=49'h01038C5E2F8AA;Q0=49'h015BD7D30F8A5;
              L1=49'h01034AB61ED7E;L0=49'h015BD7DDF5F11;
            end
      8'd250: begin
              C3=49'h0016092D97E9B;C2=49'h1FBE792F59F26;C1=49'h0103091B4F93F;C0=49'h015CDB1DC6C19;
              Q2=49'h1FBE9A3D1DC51;Q1=49'h0103090E1D778;Q0=49'h015CDB1DC7D85;
              L1=49'h0102C7A85A958;L0=49'h015CDB28A33D3;
            end
      8'd251: begin
              C3=49'h0015E7ECD3B86;C2=49'h1FBEBB4ACCD42;C1=49'h0102864FC51C1;C0=49'h015DDDE57149A;
              Q2=49'h1FBEDC26B1721;Q1=49'h01028642A6E70;Q0=49'h015DDDE5725EC;
              L1=49'h0102451ECD98D;L0=49'h015DDDF042D26;
            end
      8'd252: begin
              C3=49'h0015C6E5F4CB1;C2=49'h1FBEFD027831F;C1=49'h010204080DCC5;C0=49'h015EE02A92418;
              Q2=49'h1FBF1DACD1E34;Q1=49'h010203FB035F2;Q0=49'h015EE02A93550;
              L1=49'h0101C318B0311;L0=49'h015EE03558E7D;
            end
      8'd253: begin
              C3=49'h0015A621AFBC6;C2=49'h1FBF3E5713244;C1=49'h0101824362C78;C0=49'h015FE1EDAD18A;
              Q2=49'h1FBF5ED0463C1;Q1=49'h010182366BF98;Q0=49'h015FE1EDAE2A8;
              L1=49'h010141953C3FF;L0=49'h015FE1F868ECF;
            end
      8'd254: begin
              C3=49'h001585A2924DD;C2=49'h1FBF7F495F7F4;C1=49'h01010100FEB75;C0=49'h0160E32F4478A;
              Q2=49'h1FBF9F91D41A2;Q1=49'h010100F41B5F1;Q0=49'h0160E32F4588E;
              L1=49'h0100C093AD333;L0=49'h0160E339F58B3;
            end
      8'd255: begin
              C3=49'h0015655A111AE;C2=49'h1FBFBFDA38C78;C1=49'h010080401DC4D;C0=49'h0161E3EFDA466;
              Q2=49'h1FBFDFF240135;Q1=49'h010080334DC2B;Q0=49'h0161E3EFDB550;
              L1=49'h010040134002C;L0=49'h0161E3FA80A75;
            end
     endcase
  end  // end of always block
  
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
  assign a_square = short_a * short_a;
  assign a_square_trunc = (op_width-2)<`extra_LSBs?
                          a_square << (`extra_LSBs-op_width+2):
                          a_square >> (op_width-2-`extra_LSBs);
  assign a_cube = short_a * short_a * short_a;
  assign a_cube_trunc = (2*op_width-3)<`extra_LSBs?
                        a_cube << (`extra_LSBs-2*op_width+3):
                        a_cube >> (2*op_width-3-`extra_LSBs);
  assign p3 = (arch == 0)?
              $signed(Coef3) * $signed({1'b0,short_a}) + $signed({Coef2,{op_width-1+`bits{1'b0}}}):
              $signed(Coef3) * $signed(a_cube_trunc);
  assign p3_aligned = (arch == 0)?
                      $signed(p3) >>> (op_width-1+`bits):
                      $signed(p3) >>> (op_width+`extra_LSBs+`bits);
  assign p2 = (arch == 0)?
              $signed(p3_aligned) * $signed({1'b0,short_a}) + $signed({Coef1,{op_width-1{1'b0}}}):
              $signed(Coef2) * $signed(a_square_trunc);
  assign p2_aligned = (arch == 0)?
                      $signed(p2) >>> (op_width-1):
                      $signed(p2) >>> (op_width+`extra_LSBs);
  assign p1 = (arch == 0)?
              $signed(p2_aligned) * $signed({1'b0,short_a}) + $signed({Coef0,{op_width-1{1'b0}}}):
              $signed(Coef1) * $signed({1'b0,short_a});
  assign p1_aligned = (arch == 0)?$signed(p1) >>> (op_width-1):
                      $signed(p1) >>> (op_width-1);
  assign z_int = (arch == 0)?
                 p1_aligned:
                 p3_aligned+p2_aligned+p1_aligned+Coef0;
  assign z_round =  (err_range == 1)?
                    z_int[`z_int_size-1:`extra_LSBs]+
                    z_int[`extra_LSBs-1]:
                    z_int[`z_int_size-1:`extra_LSBs];
  assign z_poly = z_round;


//------------------------------------------------------------------
// Compute the output based on multiplicative normalization method
//------------------------------------------------------------------

`define extra_bits 13
`define table2_wordsize 74
`define table2_addrsize 9
`define MSbit (op_width+`extra_bits+1)

// used for test only
//`define disp (op_width+`extra_bits+6)
`define disp (32)

function [`MSbit:0] ln_table;
  input [`table2_addrsize-1:0] addr;
  reg [`table2_wordsize-1:0] rom_out;
  
  begin
     case (addr)
      9'd4:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd5:               rom_out=74'b11100110000011001101110000010011010000000110011110110011111100101110011111;
      9'd7:               rom_out=74'b00101100010111001000010111111101111101000111001111011110100110000000110001;
      9'd8:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd9:               rom_out=74'b11110001101110000000010000011100001100101011001011101111000110110110100001;
      9'd11:               rom_out=74'b00010010011010010110001000010001001101001101101110010010100010101111001111;
      9'd12:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd13:               rom_out=74'b11111000011101100011111000100100011101010100001101000110011111011101101110;
      9'd15:               rom_out=74'b00001000100010111100011101000001000100111111001000111101111101111100101000;
      9'd16:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd17:               rom_out=74'b11111100000111101011100111100111111111011101001110101011001011111101111011;
      9'd19:               rom_out=74'b00000100001000010110011000101101011001111000111010000001101001100101110000;
      9'd20:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd21:               rom_out=74'b11111110000001111101011001001111000110000111110011001111111110010011000000;
      9'd23:               rom_out=74'b00000010000010000010101110110001001111001110100010001000100100000001001110;
      9'd24:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd25:               rom_out=74'b11111111000000011111101010111010011110000001111111100000111000001000000100;
      9'd27:               rom_out=74'b00000001000000100000010101100101100010010011010110000100011101011010010101;
      9'd28:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd29:               rom_out=74'b11111111100000000111111101010110010100111011111001100001110110111000110111;
      9'd31:               rom_out=74'b00000000100000001000000010101011101011000100011011110011100010011100100100;
      9'd32:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd33:               rom_out=74'b11111111110000000001111111101010101110101001110111101000011111110010101100;
      9'd35:               rom_out=74'b00000000010000000010000000010101011001010110001000101100110101100011101010;
      9'd36:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd37:               rom_out=74'b11111111111000000000011111111101010101100101010011101111000110010110011100;
      9'd39:               rom_out=74'b00000000001000000000100000000010101010111010101100010001001110111110111010;
      9'd40:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd41:               rom_out=74'b11111111111100000000000111111111101010101011101010100111011110000001000111;
      9'd43:               rom_out=74'b00000000000100000000001000000000010101010110010101011000100010010100001110;
      9'd44:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd45:               rom_out=74'b11111111111110000000000001111111111101010101011001010101001110111011011010;
      9'd47:               rom_out=74'b00000000000010000000000010000000000010101010101110101010110001000100111100;
      9'd48:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd49:               rom_out=74'b11111111111111000000000000011111111111101010101010111010101010011101101000;
      9'd51:               rom_out=74'b00000000000001000000000000100000000000010101010101100101010101100010011000;
      9'd52:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd53:               rom_out=74'b11111111111111100000000000000111111111111101010101010110010101010100110100;
      9'd55:               rom_out=74'b00000000000000100000000000001000000000000010101010101011101010101011001100;
      9'd56:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd57:               rom_out=74'b11111111111111110000000000000001111111111111101010101010101110101010100110;
      9'd59:               rom_out=74'b00000000000000010000000000000010000000000000010101010101011001010101011010;
      9'd60:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd61:               rom_out=74'b11111111111111111000000000000000011111111111111101010101010101100101010100;
      9'd63:               rom_out=74'b00000000000000001000000000000000100000000000000010101010101010111010101100;
      9'd64:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd65:               rom_out=74'b11111111111111111100000000000000000111111111111111101010101010101011101010;
      9'd67:               rom_out=74'b00000000000000000100000000000000001000000000000000010101010101010110010110;
      9'd68:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd69:               rom_out=74'b11111111111111111110000000000000000001111111111111111101010101010101011001;
      9'd71:               rom_out=74'b00000000000000000010000000000000000010000000000000000010101010101010101111;
      9'd72:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd73:               rom_out=74'b11111111111111111111000000000000000000011111111111111111101010101010101011;
      9'd75:               rom_out=74'b00000000000000000001000000000000000000100000000000000000010101010101010101;
      9'd76:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd77:               rom_out=74'b11111111111111111111100000000000000000000111111111111111111101010101010110;
      9'd79:               rom_out=74'b00000000000000000000100000000000000000001000000000000000000010101010101010;
      9'd80:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd81:               rom_out=74'b11111111111111111111110000000000000000000001111111111111111111101010101011;
      9'd83:               rom_out=74'b00000000000000000000010000000000000000000010000000000000000000010101010101;
      9'd84:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd85:               rom_out=74'b11111111111111111111111000000000000000000000011111111111111111111101010110;
      9'd87:               rom_out=74'b00000000000000000000001000000000000000000000100000000000000000000010101010;
      9'd88:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd89:               rom_out=74'b11111111111111111111111100000000000000000000000111111111111111111111101011;
      9'd91:               rom_out=74'b00000000000000000000000100000000000000000000001000000000000000000000010101;
      9'd92:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd93:               rom_out=74'b11111111111111111111111110000000000000000000000001111111111111111111111110;
      9'd95:               rom_out=74'b00000000000000000000000010000000000000000000000010000000000000000000000010;
      9'd96:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd97:               rom_out=74'b11111111111111111111111111000000000000000000000000100000000000000000000000;
      9'd99:               rom_out=74'b00000000000000000000000001000000000000000000000000100000000000000000000000;
      9'd100:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd101:               rom_out=74'b11111111111111111111111111100000000000000000000000001000000000000000000000;
      9'd103:               rom_out=74'b00000000000000000000000000100000000000000000000000001000000000000000000000;
      9'd104:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd105:               rom_out=74'b11111111111111111111111111110000000000000000000000000010000000000000000000;
      9'd107:               rom_out=74'b00000000000000000000000000010000000000000000000000000010000000000000000000;
      9'd108:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd109:               rom_out=74'b11111111111111111111111111111000000000000000000000000000100000000000000000;
      9'd111:               rom_out=74'b00000000000000000000000000001000000000000000000000000000100000000000000000;
      9'd112:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd113:               rom_out=74'b11111111111111111111111111111100000000000000000000000000001000000000000000;
      9'd115:               rom_out=74'b00000000000000000000000000000100000000000000000000000000001000000000000000;
      9'd116:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd117:               rom_out=74'b11111111111111111111111111111110000000000000000000000000000010000000000000;
      9'd119:               rom_out=74'b00000000000000000000000000000010000000000000000000000000000010000000000000;
      9'd120:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd121:               rom_out=74'b11111111111111111111111111111111000000000000000000000000000000100000000000;
      9'd123:               rom_out=74'b00000000000000000000000000000001000000000000000000000000000000100000000000;
      9'd124:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd125:               rom_out=74'b11111111111111111111111111111111100000000000000000000000000000001000000000;
      9'd127:               rom_out=74'b00000000000000000000000000000000100000000000000000000000000000001000000000;
      9'd128:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd129:               rom_out=74'b11111111111111111111111111111111110000000000000000000000000000000010000000;
      9'd131:               rom_out=74'b00000000000000000000000000000000010000000000000000000000000000000010000000;
      9'd132:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd133:               rom_out=74'b11111111111111111111111111111111111000000000000000000000000000000000100000;
      9'd135:               rom_out=74'b00000000000000000000000000000000001000000000000000000000000000000000100000;
      9'd136:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd137:               rom_out=74'b11111111111111111111111111111111111100000000000000000000000000000000001000;
      9'd139:               rom_out=74'b00000000000000000000000000000000000100000000000000000000000000000000001000;
      9'd140:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd141:               rom_out=74'b11111111111111111111111111111111111110000000000000000000000000000000000010;
      9'd143:               rom_out=74'b00000000000000000000000000000000000010000000000000000000000000000000000010;
      9'd144:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd145:               rom_out=74'b11111111111111111111111111111111111111000000000000000000000000000000000001;
      9'd147:               rom_out=74'b00000000000000000000000000000000000001000000000000000000000000000000000000;
      9'd148:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd149:               rom_out=74'b11111111111111111111111111111111111111100000000000000000000000000000000001;
      9'd151:               rom_out=74'b00000000000000000000000000000000000000100000000000000000000000000000000000;
      9'd152:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd153:               rom_out=74'b11111111111111111111111111111111111111110000000000000000000000000000000001;
      9'd155:               rom_out=74'b00000000000000000000000000000000000000010000000000000000000000000000000000;
      9'd156:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd157:               rom_out=74'b11111111111111111111111111111111111111111000000000000000000000000000000001;
      9'd159:               rom_out=74'b00000000000000000000000000000000000000001000000000000000000000000000000000;
      9'd160:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd161:               rom_out=74'b11111111111111111111111111111111111111111100000000000000000000000000000001;
      9'd163:               rom_out=74'b00000000000000000000000000000000000000000100000000000000000000000000000000;
      9'd164:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd165:               rom_out=74'b11111111111111111111111111111111111111111110000000000000000000000000000001;
      9'd167:               rom_out=74'b00000000000000000000000000000000000000000010000000000000000000000000000000;
      9'd168:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd169:               rom_out=74'b11111111111111111111111111111111111111111111000000000000000000000000000001;
      9'd171:               rom_out=74'b00000000000000000000000000000000000000000001000000000000000000000000000000;
      9'd172:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd173:               rom_out=74'b11111111111111111111111111111111111111111111100000000000000000000000000001;
      9'd175:               rom_out=74'b00000000000000000000000000000000000000000000100000000000000000000000000000;
      9'd176:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd177:               rom_out=74'b11111111111111111111111111111111111111111111110000000000000000000000000001;
      9'd179:               rom_out=74'b00000000000000000000000000000000000000000000010000000000000000000000000000;
      9'd180:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd181:               rom_out=74'b11111111111111111111111111111111111111111111111000000000000000000000000001;
      9'd183:               rom_out=74'b00000000000000000000000000000000000000000000001000000000000000000000000000;
      9'd184:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd185:               rom_out=74'b11111111111111111111111111111111111111111111111100000000000000000000000001;
      9'd187:               rom_out=74'b00000000000000000000000000000000000000000000000100000000000000000000000000;
      9'd188:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd189:               rom_out=74'b11111111111111111111111111111111111111111111111110000000000000000000000001;
      9'd191:               rom_out=74'b00000000000000000000000000000000000000000000000010000000000000000000000000;
      9'd192:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd193:               rom_out=74'b11111111111111111111111111111111111111111111111111000000000000000000000001;
      9'd195:               rom_out=74'b00000000000000000000000000000000000000000000000001000000000000000000000000;
      9'd196:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd197:               rom_out=74'b11111111111111111111111111111111111111111111111111100000000000000000000001;
      9'd199:               rom_out=74'b00000000000000000000000000000000000000000000000000100000000000000000000000;
      9'd200:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd201:               rom_out=74'b11111111111111111111111111111111111111111111111111110000000000000000000001;
      9'd203:               rom_out=74'b00000000000000000000000000000000000000000000000000010000000000000000000000;
      9'd204:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd205:               rom_out=74'b11111111111111111111111111111111111111111111111111111000000000000000000001;
      9'd207:               rom_out=74'b00000000000000000000000000000000000000000000000000001000000000000000000000;
      9'd208:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd209:               rom_out=74'b11111111111111111111111111111111111111111111111111111100000000000000000001;
      9'd211:               rom_out=74'b00000000000000000000000000000000000000000000000000000100000000000000000000;
      9'd212:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd213:               rom_out=74'b11111111111111111111111111111111111111111111111111111110000000000000000001;
      9'd215:               rom_out=74'b00000000000000000000000000000000000000000000000000000010000000000000000000;
      9'd216:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd217:               rom_out=74'b11111111111111111111111111111111111111111111111111111111000000000000000001;
      9'd219:               rom_out=74'b00000000000000000000000000000000000000000000000000000001000000000000000000;
      9'd220:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd221:               rom_out=74'b11111111111111111111111111111111111111111111111111111111100000000000000000;
      9'd223:               rom_out=74'b00000000000000000000000000000000000000000000000000000000100000000000000000;
      9'd224:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd225:               rom_out=74'b11111111111111111111111111111111111111111111111111111111110000000000000000;
      9'd227:               rom_out=74'b00000000000000000000000000000000000000000000000000000000010000000000000000;
      9'd228:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd229:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111000000000000000;
      9'd231:               rom_out=74'b00000000000000000000000000000000000000000000000000000000001000000000000000;
      9'd232:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd233:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111100000000000000;
      9'd235:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000100000000000000;
      9'd236:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd237:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111110000000000000;
      9'd239:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000010000000000000;
      9'd240:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd241:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111000000000000;
      9'd243:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000001000000000000;
      9'd244:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd245:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111100000000000;
      9'd247:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000100000000000;
      9'd248:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd249:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111110000000000;
      9'd251:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000010000000000;
      9'd252:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd253:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111000000000;
      9'd255:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000001000000000;
      9'd256:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd257:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111100000000;
      9'd259:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000100000000;
      9'd260:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd261:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111110000000;
      9'd263:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000010000000;
      9'd264:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd265:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111111000000;
      9'd267:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000001000000;
      9'd268:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd269:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111111100000;
      9'd271:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000100000;
      9'd272:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd273:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111111110000;
      9'd275:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000010000;
      9'd276:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd277:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111111111000;
      9'd279:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000001000;
      9'd280:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd281:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111111111100;
      9'd283:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000100;
      9'd284:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd285:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111111111110;
      9'd287:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000010;
      9'd288:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000000;
      9'd289:               rom_out=74'b11111111111111111111111111111111111111111111111111111111111111111111111111;
      9'd291:               rom_out=74'b00000000000000000000000000000000000000000000000000000000000000000000000001;
          default:     rom_out={74{1'bx}};
     endcase
    ln_table = {rom_out[`table2_wordsize-1],
                rom_out[`table2_wordsize-1:`table2_wordsize-`MSbit]};
  end
endfunction

function [1:0] selection;
  input [`MSbit:0] A;
  input [31:0] step;
  reg cmpl; // complement - 1 when negative digit
  reg mag;  // magnitude of output digit 
  reg sign;
  reg a2,a1,a0; // MS bits (besides sign)
  begin
    sign = A[`MSbit];
    a2 = A[`MSbit-1];
    a1 = A[`MSbit-2];
    a0 = A[`MSbit-3];
    cmpl = ~sign & (a2 | a1 | a0);
    mag = cmpl | (sign & (~a2 | ~a1 | ~a0));
    if (step == 1)
      selection = {(a2|a1),(a2|a1)};
    else
      selection = {cmpl,mag}; 
  end
endfunction

// Definition of signals
  reg [`MSbit:0] u;
  reg [`MSbit:0] y;
  reg [op_width-1:0] z_mult_norm; 
  reg [1:0] d;
  reg [`table2_addrsize-1:0] addr2;
  reg [`MSbit:0] cmpl_u;
  integer i;
  reg [`MSbit:0] table_info;

  always @ (a)
  begin
    u = $signed({{3{1'b0}},a[op_width-2:0],{`extra_bits{1'b0}}});
    u = u <<< 1;
    y = 0;
    z_mult_norm = 0;
    if (op_width >= `min_op_width_linear &&
        op_width < `min_op_width_normalization)
      z_mult_norm = 0;
    else 
      begin
        for (i=1; i<= op_width+`extra_bits; i=i+1)
        begin
          d = selection(u, i);
          addr2 = {i,d};
          cmpl_u = ($unsigned($signed(u) >>> i) ^ {`MSbit+1{d[1]}}) &
                    {`MSbit+1{d[0]}};
          u[`MSbit:`MSbit-2]=u[`MSbit:`MSbit-2] + d;
          u = (u + cmpl_u + d[1])<<1;
          table_info = ln_table(addr2);
          y = y + table_info;
        end  // for
        if (err_range == 1)
          z_mult_norm = y[`MSbit-3:`MSbit-op_width-2]+y[`MSbit-op_width-3];
        else
          z_mult_norm = y[`MSbit-3:`MSbit-op_width-2];
      end
  end


//------------------------------------------------------------------
// Assign output depending on the range
//------------------------------------------------------------------

assign z = (op_width < `min_op_width_linear)?z_lookup:
           (op_width < `min_op_width_normalization)?z_poly:z_mult_norm;

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
`undef z_round_MSB

`undef extra_bits
`undef table2_wordsize
`undef table2_addrsize
`undef MSbit
`undef disp

endmodule
