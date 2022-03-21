

////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-point two-operand Subtractor
//           Computes the subtraction of two FP numbers. The format of the FP
//           numbers is defined by the number of bits in the significand 
//           (sig_width) and the number of bits in the exponent (exp_width).
//           The total number of bits in the FP number is sig_width+exp_width+1
//           since the sign bit takes the place of the MS bits in the significand
//           which is always 1 (unless the number is a denormal; a condition 
//           that can be detected testing the exponent value).
//           The output is a FP number and status flags with information about
//           special number representations and exceptions. 
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance 0 or 1
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              b               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              rounding mode
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_width + exp_width + 1) bits
//                              Floating-point Number result
//              status          byte
//                              info about FP results
//
// MODIFIED:
//
//-------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_fp_sub (

                   a,
                   b,
                   rnd,
                   z,
                   status

    // Embedded dc_shell script
    // _model_constraint_2
);

parameter sig_width    = 23;
parameter exp_width    = 8;
parameter ieee_compliance = 0;

input  [exp_width + sig_width:0] a,b;
input  [2:0] rnd;
output [7:0] status;
output [exp_width + sig_width:0] z;

wire [sig_width+exp_width : 0] z_int;
wire [7 : 0] status_flags_int;
DW_fp_addsub #(sig_width, exp_width, ieee_compliance) U1
     (.a (a),
      .b (b),
      .rnd (rnd),
      .op (1'b1),
      .z (z_int),
      .status (status_flags_int));



assign  z = z_int;
assign status = status_flags_int;         


endmodule
