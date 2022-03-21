
////////////////////////////////////////////////////////////////////////////////
//---------------------------------------------------------------------------------
//
// ABSTRACT:  Right logical shift with sticky bit computation
//            This file contains a verification model for an alignment
//            unit (used in floating-point operations) that consists 
//            in a shifter and a logic to detect non-zero bits that 
//            are shifted out of range. 
//
// MODIFIED:
//
//---------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_FP_ALIGN (

// ports
                   a,
                   sh,
                   b,
                   stk

    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

//----------------------------------------------------------------------------
// main module parameters
parameter a_width    = 23;  // LOWER BOUND 1 bit
parameter sh_width   = 8;   // LOWER BOUND 1 bit

//------------------------------------------------------
//          declaration of inputs and outputs

input  [a_width-1:0] a;
input  [sh_width-1:0] sh;
output [a_width-1:0] b;
output stk;

//--------------------------------------------------------
//   Internal signals
reg [a_width-1:0] a_shifted;
reg stk_int;
reg [a_width-1:0] one_vector, mask, masked_op;

always @ (a or sh)
begin
  a_shifted = a >> sh;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << sh);
  masked_op = mask & a;
  stk_int = |masked_op;
end

assign b = a_shifted;
assign stk = stk_int;

endmodule
