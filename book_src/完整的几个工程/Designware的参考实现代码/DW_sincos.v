////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from 
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2008 - 2012 
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:      Jul. 7, 2008
//
// VERSION:   Verilog Synthesis Module for DW_sincos
//
// DesignWare_version: 55c65290
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Fixed-Point Sine/Cosine Unit
//
//             DW_sincos calculates the fixed-point sine/cosine 
//             function. 
//
//             parameters      valid values (defined in the DW manual)
//             ==========      ============
//             A_width         input,      2 to 34 bits
//             WAVE_width      output,     2 to 34 bits
//             arch            implementation select
//                             0 - area optimized (default)
//                             1 - speed optimized
//             err_range       error range of the result compared to the
//                             true result
//                             1 - 1 ulp error (default)
//                             2 - 2 ulp error
//
//             Input ports     Size & Description
//             ===========     ==================
//             A               A_width bits
//                             Fixed-point Number Input
//             SIN_COS         1 bit
//                             Operator Selector
//                             0 - sine, 1 - cosine
//             WAVE            WAVE_width bits
//                             Fixed-point Number Output
//
// MODIFIED:
//   09/04/08 
//            Improved QoR when A_width > WAVE_width
//   06/16/10  (STAR 9000400672)
//            DW_sincos has 2 ulp erros when A_width<=9, err_range=1. 
//            Fixed from D-2010.03-SP3.
//----------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////

module DW_sincos (
// ports
                   A,
                   SIN_COS,
                   WAVE
    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

parameter A_width = 24;
parameter WAVE_width = 25;
parameter arch = 0;
parameter err_range = 1;

//#define a_width_adj ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : A_width)

//#define wave_width_adj ((WAVE_width >= A_width + 1) ? WAVE_width : A_width + 1)



input [A_width - 1:0] A;
input SIN_COS;
output [WAVE_width - 1:0] WAVE;

wire [((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:0] A_adj;
wire [((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 1:0] wave_pre;
wire [((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 1:0] wave_pre_or;
wire [((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 1:0] z0;
wire [((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 1:0] z1;
wire [((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:0] a_in;
wire [((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:0] a_neg;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) == 2) ? 0 : ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 3) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 0 : ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)):0] addr;
wire [(((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) - 1:0] addr_sincos;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 0 : ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 3 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)):0] a_low;
wire [((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) - 1:0] delta;
wire [((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) - 1:0] delta_sincos;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + 2)) - 1:0] delta_sincos_trun;
wire [(2 * ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + 2))) - 1:0] x2;
wire [(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) - 1:0] x2_trun;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + 2))) : 1) - 1:0] x3;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1) - 1:0] x3_trun;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) - 1:0] c2;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1) - 1:0] c3;
wire [((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))) - 1:0] c2x2;
wire [(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1)) - 1:0] c3x3;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3)) - 1:0] c2x2_trun;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1) - 1:0] c3x3_trun;
wire [(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1) - 1:0] c1;
wire [((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1) + ((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))))) - 1:0] c1x1;
wire [(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 2) - 1:0] c1x1_trun;
wire [((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 1:0] c0;
wire [((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2):0] z_pre0;
wire [((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2):0] z_pre1;
wire [(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1)) - 1:0] m0;
wire [(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))) - 1:0] m1;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1) - 1:0] m0_trun;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) - 1:0] m1_trun;
wire [((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1) + ((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))))) - 1:0] m2;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) + (3 - ((WAVE_width >= A_width + 1) ? err_range : 1)))) - 1:0] m2_trun;
wire [((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) - 1:0] mc0;
wire [(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1) - 1:0] mc1;
wire [((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 1:0] c0_wave_pre;
wire [((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 1:0] c0_wave;
wire [((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 1:0] WAVE_adj;
wire sincos;
wire compl;
wire rounding_bit;
wire rounding_bit0;
wire a_one;
wire wave_pre_msb;
wire a_half_pi;

reg [14 - 1:0] c2_24;
reg [21 - 1:0] c1_24;
reg [29 - 1:0] c0_24;
reg [13 - 1:0] c2_15;
reg [19 - 1:0] c1_15;
reg [26 - 1:0] c0_15;
reg [15 - 1:0] c3_34;
reg [22  - 1:0] c2_34;
reg [29 - 1:0] c1_34;
reg [37 - 1:0] c0_34;

assign A_adj = (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) > A_width + 1) ? {A, {(((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) > A_width + 1) ? ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - A_width - 1 : 1)){1'b0}}} : 
                                            A[A_width - 1:((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= A_width + 1) ? 0 : A_width - ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)))];



assign sincos = (SIN_COS == 0 && (A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b00 ||
                                  A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b10) ||
                 SIN_COS == 1 && (A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b01 ||
                                  A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b11)) ?
                0 : 1;
assign compl = (SIN_COS == 0 && (A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b00 ||
                                  A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b01) ||
                 SIN_COS == 1 && (A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b00 ||
                                  A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b11)) ?
                0 : 1;

assign a_half_pi = (SIN_COS == 0 & (A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] & (A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 3:0] == 0))) |
                   (SIN_COS == 1 & (A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2:0] == 0));

assign a_neg = (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? -A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2:0] :
                           {1'b1, {(((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1){1'b0}}} - A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2:0];
assign a_in = (sincos) ? a_neg : {1'b0, A_adj[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2:0]};
assign a_one = (SIN_COS) ? (a_in[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b10) :
                          (a_in[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1:((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2] == 2'b01);

assign addr = a_in[((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) == 2) ? 0 : ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 3):((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 0 : ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))];

assign a_low = a_in[((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 0 : ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 3 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)):0];
assign delta = (((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? {a_low, 1'b0} : a_low;

assign addr_sincos = (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) < 9) ? 
                       {addr, {(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) < 9) ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) : 1)){1'b0}}} :
                       addr;
assign delta_sincos = delta;

assign delta_sincos_trun = delta_sincos[((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) - 1:((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + 2))];
assign x2 = delta_sincos_trun * delta_sincos_trun;
assign x2_trun = x2[(2 * ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + 2))) - 1:(2 * ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + 2))) - (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))];

assign x3 = x2_trun * delta_sincos_trun;
assign x3_trun = x3[((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + 2))) : 1) - 1:((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + 2))) : 1) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1)];

assign c3 = (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? c3_34[15 - 1:15 - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1)] : 0;
assign c3x3 = c3 * x3_trun;
assign c3x3_trun = (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? c3x3[(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1)) - 1:(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1)) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1)] : 0;

assign c2 = ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9)) ? 0 :
            (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? c2_34[22  - 1:22  - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))] :
            ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) == 6) ? c2_15[(((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) == 6) ? (13 - 1) : 0):(((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) == 6) ? (13 - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))) : 0)] :
                                c2_24[14 - 1:((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? 0 : 14 - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)))];
assign c2x2 = c2 * x2_trun;
assign c2x2_trun = c2x2[((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))) - 1:((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15))  ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3))];

assign c1 = (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 0 :
            (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? c1_34[29 - 1:29 - (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1)] :
            ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) == 6) ? c1_15[19 - 1:(((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) == 6) ? 19 - (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1) : 0)] :
                                c1_24[21 - 1:((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? 0 : 21 - (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1))];
assign c1x1 = c1 * delta_sincos;
assign c1x1_trun = c1x1[((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1) + ((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))))) - 1:((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1) + ((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))))) - (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 2)];

assign c0 = (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? c0_34[37 - 1:37 - ((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2)] :
            ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) == 6) ? c0_15[(((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) == 6) ? (26 - 1) : 0):(((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) == 6) ? (26 - ((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2)) : 0)] :
                                c0_24[29 - 1:((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? 0 : 29 - ((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2))];
assign z_pre1 = -c3x3_trun - c2x2_trun + c1x1_trun + c0;

assign rounding_bit = (((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? z_pre1[2] : 0;
assign z1 = (compl) ? -(z_pre1[((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2):4 - ((WAVE_width >= A_width + 1) ? err_range : 1)] + rounding_bit) :
                      z_pre1[((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2):4 - ((WAVE_width >= A_width + 1) ? err_range : 1)] + rounding_bit;

assign m0 = c3 * delta_sincos[((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) - 1:((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1)];
assign m0_trun = m0[(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1)) - 1:(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26)  ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 3) : 1) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1)) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 3 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2) : 1)];
assign mc0 = (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 26) ? m0_trun + c2 : c2;

assign m1 = mc0 * delta_sincos[((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) - 1:((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))];
assign m1_trun = m1[(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))) - 1:(((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2)) + ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) || (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 1 : ((((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - 2 * (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 2))];
assign mc1 = -m1_trun + c1;

assign m2 = mc1 * delta_sincos;
assign m2_trun = m2[((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1) + ((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))))) - 1:((((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2) - (1 + (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7)))) + 1) + ((((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))) + 1) : ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 2 - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7))))) - ((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? 1 : (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - (((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) >= 11 && ((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) <= 24) || (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) == 25 && ((WAVE_width >= A_width + 1) ? err_range : 1) == 2)) ? 6 : 7) + (3 - ((WAVE_width >= A_width + 1) ? err_range : 1))))];
assign z_pre0 = m2_trun + c0;

assign rounding_bit0 = (((WAVE_width >= A_width + 1) ? err_range : 1) == 1) ? z_pre0[2] : 0;
assign z0 = (compl) ? -(z_pre0[((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2):4 - ((WAVE_width >= A_width + 1) ? err_range : 1)] + rounding_bit0) :
                      z_pre0[((((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2) + (2 - ((WAVE_width >= A_width + 1) ? err_range : 1)) + 2):4 - ((WAVE_width >= A_width + 1) ? err_range : 1)] + rounding_bit0;

assign c0_wave_pre = {2'b00, c0_24[29 - 1:((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 9) ? (29 - (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2)) : 0)]};
assign c0_wave = (a_half_pi) ? {compl, 1'b1, {(WAVE_width - 2){1'b0}}} :
                 (compl) ? -c0_wave_pre : c0_wave_pre;


assign wave_pre = (((((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 15) ? 0 : arch) == 0) ? z0 : z1;
assign wave_pre_msb = a_one & compl;
assign wave_pre_or = {wave_pre_msb, (a_in[((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) - 1] | a_one), {(((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 2){1'b0}}}; 
assign WAVE_adj = (((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) >= 10 && ((WAVE_width >= A_width + 1) ? (WAVE_width - 1) : (((WAVE_width == A_width) || (err_range == 1)) ? A_width : WAVE_width + 1)) <= 34) ? 
                  wave_pre | wave_pre_or :
                  c0_wave;
assign WAVE = (((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) > WAVE_width) ? WAVE_adj[((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - 1:((WAVE_width >= A_width + 1) ? WAVE_width : (((WAVE_width == A_width) || (err_range == 1)) ? A_width + 1 : WAVE_width)) - WAVE_width] : WAVE_adj;
             


always @(addr_sincos) begin

  case(addr_sincos)
    6'b000000: begin
      c2_15 = 62;
      c1_15 = 411798;
      c0_15 = 5;
    end
    6'b000001: begin
      c2_15 = 185;
      c1_15 = 411674;
      c0_15 = 1646928;
    end
    6'b000010: begin
      c2_15 = 309;
      c1_15 = 411302;
      c0_15 = 3292870;
    end
    6'b000011: begin
      c2_15 = 433;
      c1_15 = 410682;
      c0_15 = 4936829;
    end
    6'b000100: begin
      c2_15 = 556;
      c1_15 = 409815;
      c0_15 = 6577813;
    end
    6'b000101: begin
      c2_15 = 680;
      c1_15 = 408701;
      c0_15 = 8214836;
    end
    6'b000110: begin
      c2_15 = 802;
      c1_15 = 407340;
      c0_15 = 9846910;
    end
    6'b000111: begin
      c2_15 = 924;
      c1_15 = 405735;
      c0_15 = 11473053;
    end
    6'b001000: begin
      c2_15 = 1046;
      c1_15 = 403885;
      c0_15 = 13092284;
    end
    6'b001001: begin
      c2_15 = 1167;
      c1_15 = 401792;
      c0_15 = 14703630;
    end
    6'b001010: begin
      c2_15 = 1287;
      c1_15 = 399456;
      c0_15 = 16306118;
    end
    6'b001011: begin
      c2_15 = 1407;
      c1_15 = 396881;
      c0_15 = 17898785;
    end
    6'b001100: begin
      c2_15 = 1526;
      c1_15 = 394066;
      c0_15 = 19480669;
    end
    6'b001101: begin
      c2_15 = 1643;
      c1_15 = 391013;
      c0_15 = 21050820;
    end
    6'b001110: begin
      c2_15 = 1760;
      c1_15 = 387725;
      c0_15 = 22608290;
    end
    6'b001111: begin
      c2_15 = 1876;
      c1_15 = 384204;
      c0_15 = 24152142;
    end
    6'b010000: begin
      c2_15 = 1990;
      c1_15 = 380451;
      c0_15 = 25681445;
    end
    6'b010001: begin
      c2_15 = 2104;
      c1_15 = 376469;
      c0_15 = 27195279;
    end
    6'b010010: begin
      c2_15 = 2216;
      c1_15 = 372260;
      c0_15 = 28692731;
    end
    6'b010011: begin
      c2_15 = 2327;
      c1_15 = 367827;
      c0_15 = 30172900;
    end
    6'b010100: begin
      c2_15 = 2436;
      c1_15 = 363173;
      c0_15 = 31634894;
    end
    6'b010101: begin
      c2_15 = 2544;
      c1_15 = 358300;
      c0_15 = 33077833;
    end
    6'b010110: begin
      c2_15 = 2650;
      c1_15 = 353210;
      c0_15 = 34500846;
    end
    6'b010111: begin
      c2_15 = 2755;
      c1_15 = 347908;
      c0_15 = 35903078;
    end
    6'b011000: begin
      c2_15 = 2858;
      c1_15 = 342397;
      c0_15 = 37283682;
    end
    6'b011001: begin
      c2_15 = 2960;
      c1_15 = 336679;
      c0_15 = 38641829;
    end
    6'b011010: begin
      c2_15 = 3059;
      c1_15 = 330759;
      c0_15 = 39976699;
    end
    6'b011011: begin
      c2_15 = 3157;
      c1_15 = 324639;
      c0_15 = 41287489;
    end
    6'b011100: begin
      c2_15 = 3253;
      c1_15 = 318324;
      c0_15 = 42573408;
    end
    6'b011101: begin
      c2_15 = 3347;
      c1_15 = 311817;
      c0_15 = 43833683;
    end
    6'b011110: begin
      c2_15 = 3439;
      c1_15 = 305122;
      c0_15 = 45067554;
    end
    6'b011111: begin
      c2_15 = 3529;
      c1_15 = 298243;
      c0_15 = 46274278;
    end
    6'b100000: begin
      c2_15 = 3616;
      c1_15 = 291185;
      c0_15 = 47453129;
    end
    6'b100001: begin
      c2_15 = 3702;
      c1_15 = 283951;
      c0_15 = 48603395;
    end
    6'b100010: begin
      c2_15 = 3785;
      c1_15 = 276546;
      c0_15 = 49724384;
    end
    6'b100011: begin
      c2_15 = 3866;
      c1_15 = 268975;
      c0_15 = 50815422;
    end
    6'b100100: begin
      c2_15 = 3945;
      c1_15 = 261241;
      c0_15 = 51875850;
    end
    6'b100101: begin
      c2_15 = 4021;
      c1_15 = 253351;
      c0_15 = 52905030;
    end
    6'b100110: begin
      c2_15 = 4095;
      c1_15 = 245307;
      c0_15 = 53902341;
    end
    6'b100111: begin
      c2_15 = 4166;
      c1_15 = 237116;
      c0_15 = 54867185;
    end
    6'b101000: begin
      c2_15 = 4235;
      c1_15 = 228782;
      c0_15 = 55798978;
    end
    6'b101001: begin
      c2_15 = 4302;
      c1_15 = 220310;
      c0_15 = 56697160;
    end
    6'b101010: begin
      c2_15 = 4365;
      c1_15 = 211706;
      c0_15 = 57561190;
    end
    6'b101011: begin
      c2_15 = 4426;
      c1_15 = 202974;
      c0_15 = 58390547;
    end
    6'b101100: begin
      c2_15 = 4485;
      c1_15 = 194120;
      c0_15 = 59184731;
    end
    6'b101101: begin
      c2_15 = 4541;
      c1_15 = 185148;
      c0_15 = 59943265;
    end
    6'b101110: begin
      c2_15 = 4594;
      c1_15 = 176066;
      c0_15 = 60665692;
    end
    6'b101111: begin
      c2_15 = 4644;
      c1_15 = 166877;
      c0_15 = 61351576;
    end
    6'b110000: begin
      c2_15 = 4691;
      c1_15 = 157588;
      c0_15 = 62000503;
    end
    6'b110001: begin
      c2_15 = 4736;
      c1_15 = 148203;
      c0_15 = 62612085;
    end
    6'b110010: begin
      c2_15 = 4778;
      c1_15 = 138730;
      c0_15 = 63185950;
    end
    6'b110011: begin
      c2_15 = 4817;
      c1_15 = 129173;
      c0_15 = 63721755;
    end
    6'b110100: begin
      c2_15 = 4853;
      c1_15 = 119538;
      c0_15 = 64219177;
    end
    6'b110101: begin
      c2_15 = 4886;
      c1_15 = 109831;
      c0_15 = 64677915;
    end
    6'b110110: begin
      c2_15 = 4916;
      c1_15 = 100058;
      c0_15 = 65097694;
    end
    6'b110111: begin
      c2_15 = 4943;
      c1_15 = 90225;
      c0_15 = 65478260;
    end
    6'b111000: begin
      c2_15 = 4967;
      c1_15 = 80337;
      c0_15 = 65819385;
    end
    6'b111001: begin
      c2_15 = 4989;
      c1_15 = 70401;
      c0_15 = 66120862;
    end
    6'b111010: begin
      c2_15 = 5007;
      c1_15 = 60423;
      c0_15 = 66382511;
    end
    6'b111011: begin
      c2_15 = 5022;
      c1_15 = 50408;
      c0_15 = 66604173;
    end
    6'b111100: begin
      c2_15 = 5034;
      c1_15 = 40363;
      c0_15 = 66785716;
    end
    6'b111101: begin
      c2_15 = 5043;
      c1_15 = 30293;
      c0_15 = 66927029;
    end
    6'b111110: begin
      c2_15 = 5049;
      c1_15 = 20205;
      c0_15 = 67028028;
    end
    6'b111111: begin
      c2_15 = 5052;
      c1_15 = 10105;
      c0_15 = 67088651;
    end
  endcase
    
  case(addr_sincos)
    7'b0000000: begin
      c2_24 = 62;
      c1_24 = 1647122;
      c0_24 = 5;
    end
    7'b0000001: begin
      c2_24 = 186;
      c1_24 = 1646998;
      c0_24 = 6588226;
    end
    7'b0000010: begin
      c2_24 = 310;
      c1_24 = 1646626;
      c0_24 = 13175466;
    end
    7'b0000011: begin
      c2_24 = 433;
      c1_24 = 1646006;
      c0_24 = 19760722;
    end
    7'b0000100: begin
      c2_24 = 557;
      c1_24 = 1645138;
      c0_24 = 26343001;
    end
    7'b0000101: begin
      c2_24 = 681;
      c1_24 = 1644022;
      c0_24 = 32921314;
    end
    7'b0000110: begin
      c2_24 = 805;
      c1_24 = 1642659;
      c0_24 = 39494669;
    end
    7'b0000111: begin
      c2_24 = 928;
      c1_24 = 1641048;
      c0_24 = 46062076;
    end
    7'b0001000: begin
      c2_24 = 1052;
      c1_24 = 1639191;
      c0_24 = 52622546;
    end
    7'b0001001: begin
      c2_24 = 1175;
      c1_24 = 1637086;
      c0_24 = 59175091;
    end
    7'b0001010: begin
      c2_24 = 1298;
      c1_24 = 1634735;
      c0_24 = 65718725;
    end
    7'b0001011: begin
      c2_24 = 1421;
      c1_24 = 1632138;
      c0_24 = 72252462;
    end
    7'b0001100: begin
      c2_24 = 1544;
      c1_24 = 1629294;
      c0_24 = 78775318;
    end
    7'b0001101: begin
      c2_24 = 1666;
      c1_24 = 1626206;
      c0_24 = 85286311;
    end
    7'b0001110: begin
      c2_24 = 1788;
      c1_24 = 1622873;
      c0_24 = 91784460;
    end
    7'b0001111: begin
      c2_24 = 1910;
      c1_24 = 1619295;
      c0_24 = 98268786;
    end
    7'b0010000: begin
      c2_24 = 2032;
      c1_24 = 1615473;
      c0_24 = 104738314;
    end
    7'b0010001: begin
      c2_24 = 2153;
      c1_24 = 1611408;
      c0_24 = 111192068;
    end
    7'b0010010: begin
      c2_24 = 2274;
      c1_24 = 1607100;
      c0_24 = 117629077;
    end
    7'b0010011: begin
      c2_24 = 2395;
      c1_24 = 1602551;
      c0_24 = 124048372;
    end
    7'b0010100: begin
      c2_24 = 2515;
      c1_24 = 1597760;
      c0_24 = 130448985;
    end
    7'b0010101: begin
      c2_24 = 2635;
      c1_24 = 1592728;
      c0_24 = 136829954;
    end
    7'b0010110: begin
      c2_24 = 2755;
      c1_24 = 1587457;
      c0_24 = 143190316;
    end
    7'b0010111: begin
      c2_24 = 2874;
      c1_24 = 1581946;
      c0_24 = 149529114;
    end
    7'b0011000: begin
      c2_24 = 2993;
      c1_24 = 1576198;
      c0_24 = 155845394;
    end
    7'b0011001: begin
      c2_24 = 3111;
      c1_24 = 1570211;
      c0_24 = 162138204;
    end
    7'b0011010: begin
      c2_24 = 3229;
      c1_24 = 1563989;
      c0_24 = 168406597;
    end
    7'b0011011: begin
      c2_24 = 3346;
      c1_24 = 1557531;
      c0_24 = 174649628;
    end
    7'b0011100: begin
      c2_24 = 3463;
      c1_24 = 1550838;
      c0_24 = 180866357;
    end
    7'b0011101: begin
      c2_24 = 3579;
      c1_24 = 1543912;
      c0_24 = 187055849;
    end
    7'b0011110: begin
      c2_24 = 3695;
      c1_24 = 1536753;
      c0_24 = 193217171;
    end
    7'b0011111: begin
      c2_24 = 3810;
      c1_24 = 1529363;
      c0_24 = 199349395;
    end
    7'b0100000: begin
      c2_24 = 3924;
      c1_24 = 1521742;
      c0_24 = 205451598;
    end
    7'b0100001: begin
      c2_24 = 4038;
      c1_24 = 1513893;
      c0_24 = 211522861;
    end
    7'b0100010: begin
      c2_24 = 4152;
      c1_24 = 1505815;
      c0_24 = 217562269;
    end
    7'b0100011: begin
      c2_24 = 4264;
      c1_24 = 1497511;
      c0_24 = 223568913;
    end
    7'b0100100: begin
      c2_24 = 4377;
      c1_24 = 1488981;
      c0_24 = 229541888;
    end
    7'b0100101: begin
      c2_24 = 4488;
      c1_24 = 1480226;
      c0_24 = 235480295;
    end
    7'b0100110: begin
      c2_24 = 4599;
      c1_24 = 1471249;
      c0_24 = 241383239;
    end
    7'b0100111: begin
      c2_24 = 4709;
      c1_24 = 1462051;
      c0_24 = 247249833;
    end
    7'b0101000: begin
      c2_24 = 4818;
      c1_24 = 1452632;
      c0_24 = 253079191;
    end
    7'b0101001: begin
      c2_24 = 4927;
      c1_24 = 1442994;
      c0_24 = 258870436;
    end
    7'b0101010: begin
      c2_24 = 5035;
      c1_24 = 1433139;
      c0_24 = 264622697;
    end
    7'b0101011: begin
      c2_24 = 5142;
      c1_24 = 1423069;
      c0_24 = 270335106;
    end
    7'b0101100: begin
      c2_24 = 5248;
      c1_24 = 1412784;
      c0_24 = 276006804;
    end
    7'b0101101: begin
      c2_24 = 5354;
      c1_24 = 1402286;
      c0_24 = 281636936;
    end
    7'b0101110: begin
      c2_24 = 5459;
      c1_24 = 1391577;
      c0_24 = 287224655;
    end
    7'b0101111: begin
      c2_24 = 5563;
      c1_24 = 1380658;
      c0_24 = 292769119;
    end
    7'b0110000: begin
      c2_24 = 5666;
      c1_24 = 1369532;
      c0_24 = 298269493;
    end
    7'b0110001: begin
      c2_24 = 5768;
      c1_24 = 1358199;
      c0_24 = 303724948;
    end
    7'b0110010: begin
      c2_24 = 5869;
      c1_24 = 1346662;
      c0_24 = 309134664;
    end
    7'b0110011: begin
      c2_24 = 5970;
      c1_24 = 1334922;
      c0_24 = 314497825;
    end
    7'b0110100: begin
      c2_24 = 6070;
      c1_24 = 1322981;
      c0_24 = 319813624;
    end
    7'b0110101: begin
      c2_24 = 6168;
      c1_24 = 1310840;
      c0_24 = 325081260;
    end
    7'b0110110: begin
      c2_24 = 6266;
      c1_24 = 1298503;
      c0_24 = 330299941;
    end
    7'b0110111: begin
      c2_24 = 6363;
      c1_24 = 1285969;
      c0_24 = 335468879;
    end
    7'b0111000: begin
      c2_24 = 6459;
      c1_24 = 1273242;
      c0_24 = 340587297;
    end
    7'b0111001: begin
      c2_24 = 6554;
      c1_24 = 1260324;
      c0_24 = 345654423;
    end
    7'b0111010: begin
      c2_24 = 6648;
      c1_24 = 1247215;
      c0_24 = 350669495;
    end
    7'b0111011: begin
      c2_24 = 6741;
      c1_24 = 1233919;
      c0_24 = 355631758;
    end
    7'b0111100: begin
      c2_24 = 6832;
      c1_24 = 1220437;
      c0_24 = 360540464;
    end
    7'b0111101: begin
      c2_24 = 6923;
      c1_24 = 1206771;
      c0_24 = 365394874;
    end
    7'b0111110: begin
      c2_24 = 7013;
      c1_24 = 1192923;
      c0_24 = 370194257;
    end
    7'b0111111: begin
      c2_24 = 7102;
      c1_24 = 1178896;
      c0_24 = 374937890;
    end
    7'b1000000: begin
      c2_24 = 7190;
      c1_24 = 1164691;
      c0_24 = 379625058;
    end
    7'b1000001: begin
      c2_24 = 7276;
      c1_24 = 1150311;
      c0_24 = 384255057;
    end
    7'b1000010: begin
      c2_24 = 7362;
      c1_24 = 1135757;
      c0_24 = 388827188;
    end
    7'b1000011: begin
      c2_24 = 7446;
      c1_24 = 1121033;
      c0_24 = 393340763;
    end
    7'b1000100: begin
      c2_24 = 7529;
      c1_24 = 1106139;
      c0_24 = 397795102;
    end
    7'b1000101: begin
      c2_24 = 7612;
      c1_24 = 1091079;
      c0_24 = 402189535;
    end
    7'b1000110: begin
      c2_24 = 7693;
      c1_24 = 1075855;
      c0_24 = 406523400;
    end
    7'b1000111: begin
      c2_24 = 7772;
      c1_24 = 1060469;
      c0_24 = 410796044;
    end
    7'b1001000: begin
      c2_24 = 7851;
      c1_24 = 1044923;
      c0_24 = 415006823;
    end
    7'b1001001: begin
      c2_24 = 7929;
      c1_24 = 1029220;
      c0_24 = 419155104;
    end
    7'b1001010: begin
      c2_24 = 8005;
      c1_24 = 1013361;
      c0_24 = 423240262;
    end
    7'b1001011: begin
      c2_24 = 8080;
      c1_24 = 997350;
      c0_24 = 427261681;
    end
    7'b1001100: begin
      c2_24 = 8154;
      c1_24 = 981189;
      c0_24 = 431218756;
    end
    7'b1001101: begin
      c2_24 = 8227;
      c1_24 = 964880;
      c0_24 = 435110892;
    end
    7'b1001110: begin
      c2_24 = 8298;
      c1_24 = 948426;
      c0_24 = 438937501;
    end
    7'b1001111: begin
      c2_24 = 8368;
      c1_24 = 931829;
      c0_24 = 442698008;
    end
    7'b1010000: begin
      c2_24 = 8437;
      c1_24 = 915092;
      c0_24 = 446391846;
    end
    7'b1010001: begin
      c2_24 = 8505;
      c1_24 = 898217;
      c0_24 = 450018459;
    end
    7'b1010010: begin
      c2_24 = 8571;
      c1_24 = 881206;
      c0_24 = 453577301;
    end
    7'b1010011: begin
      c2_24 = 8636;
      c1_24 = 864063;
      c0_24 = 457067836;
    end
    7'b1010100: begin
      c2_24 = 8700;
      c1_24 = 846790;
      c0_24 = 460489538;
    end
    7'b1010101: begin
      c2_24 = 8762;
      c1_24 = 829389;
      c0_24 = 463841892;
    end
    7'b1010110: begin
      c2_24 = 8823;
      c1_24 = 811863;
      c0_24 = 467124393;
    end
    7'b1010111: begin
      c2_24 = 8883;
      c1_24 = 794215;
      c0_24 = 470336547;
    end
    7'b1011000: begin
      c2_24 = 8942;
      c1_24 = 776448;
      c0_24 = 473477871;
    end
    7'b1011001: begin
      c2_24 = 8999;
      c1_24 = 758563;
      c0_24 = 476547890;
    end
    7'b1011010: begin
      c2_24 = 9055;
      c1_24 = 740564;
      c0_24 = 479546142;
    end
    7'b1011011: begin
      c2_24 = 9109;
      c1_24 = 722454;
      c0_24 = 482472177;
    end
    7'b1011100: begin
      c2_24 = 9162;
      c1_24 = 704235;
      c0_24 = 485325554;
    end
    7'b1011101: begin
      c2_24 = 9214;
      c1_24 = 685910;
      c0_24 = 488105842;
    end
    7'b1011110: begin
      c2_24 = 9264;
      c1_24 = 667482;
      c0_24 = 490812623;
    end
    7'b1011111: begin
      c2_24 = 9313;
      c1_24 = 648953;
      c0_24 = 493445489;
    end
    7'b1100000: begin
      c2_24 = 9360;
      c1_24 = 630326;
      c0_24 = 496004045;
    end
    7'b1100001: begin
      c2_24 = 9406;
      c1_24 = 611604;
      c0_24 = 498487904;
    end
    7'b1100010: begin
      c2_24 = 9451;
      c1_24 = 592791;
      c0_24 = 500896692;
    end
    7'b1100011: begin
      c2_24 = 9494;
      c1_24 = 573888;
      c0_24 = 503230048;
    end
    7'b1100100: begin
      c2_24 = 9536;
      c1_24 = 554898;
      c0_24 = 505487619;
    end
    7'b1100101: begin
      c2_24 = 9576;
      c1_24 = 535825;
      c0_24 = 507669065;
    end
    7'b1100110: begin
      c2_24 = 9615;
      c1_24 = 516672;
      c0_24 = 509774058;
    end
    7'b1100111: begin
      c2_24 = 9653;
      c1_24 = 497440;
      c0_24 = 511802281;
    end
    7'b1101000: begin
      c2_24 = 9689;
      c1_24 = 478134;
      c0_24 = 513753429;
    end
    7'b1101001: begin
      c2_24 = 9723;
      c1_24 = 458755;
      c0_24 = 515627207;
    end
    7'b1101010: begin
      c2_24 = 9756;
      c1_24 = 439308;
      c0_24 = 517423334;
    end
    7'b1101011: begin
      c2_24 = 9788;
      c1_24 = 419794;
      c0_24 = 519141538;
    end
    7'b1101100: begin
      c2_24 = 9818;
      c1_24 = 400218;
      c0_24 = 520781562;
    end
    7'b1101101: begin
      c2_24 = 9847;
      c1_24 = 380580;
      c0_24 = 522343158;
    end
    7'b1101110: begin
      c2_24 = 9874;
      c1_24 = 360886;
      c0_24 = 523826091;
    end
    7'b1101111: begin
      c2_24 = 9899;
      c1_24 = 341137;
      c0_24 = 525230137;
    end
    7'b1110000: begin
      c2_24 = 9924;
      c1_24 = 321337;
      c0_24 = 526555086;
    end
    7'b1110001: begin
      c2_24 = 9946;
      c1_24 = 301489;
      c0_24 = 527800738;
    end
    7'b1110010: begin
      c2_24 = 9968;
      c1_24 = 281595;
      c0_24 = 528966905;
    end
    7'b1110011: begin
      c2_24 = 9987;
      c1_24 = 261658;
      c0_24 = 530053411;
    end
    7'b1110100: begin
      c2_24 = 10005;
      c1_24 = 241682;
      c0_24 = 531060094;
    end
    7'b1110101: begin
      c2_24 = 10022;
      c1_24 = 221670;
      c0_24 = 531986800;
    end
    7'b1110110: begin
      c2_24 = 10037;
      c1_24 = 201625;
      c0_24 = 532833392;
    end
    7'b1110111: begin
      c2_24 = 10051;
      c1_24 = 181549;
      c0_24 = 533599740;
    end
    7'b1111000: begin
      c2_24 = 10063;
      c1_24 = 161446;
      c0_24 = 534285731;
    end
    7'b1111001: begin
      c2_24 = 10074;
      c1_24 = 141318;
      c0_24 = 534891260;
    end
    7'b1111010: begin
      c2_24 = 10083;
      c1_24 = 121169;
      c0_24 = 535416236;
    end
    7'b1111011: begin
      c2_24 = 10091;
      c1_24 = 101002;
      c0_24 = 535860581;
    end
    7'b1111100: begin
      c2_24 = 10097;
      c1_24 = 80820;
      c0_24 = 536224227;
    end
    7'b1111101: begin
      c2_24 = 10101;
      c1_24 = 60625;
      c0_24 = 536507119;
    end
    7'b1111110: begin
      c2_24 = 10104;
      c1_24 = 40422;
      c0_24 = 536709216;
    end
    7'b1111111: begin
      c2_24 = 10106;
      c1_24 = 20212;
      c0_24 = 536830486;
    end
  endcase



  case(addr_sincos)
    7'b0000000: begin
      c3_34 = 15'b101001010101110;
      c2_34 = 22'b0000000000000000000000;
      c1_34 = 29'b11001001000011111101101010100;
      c0_34 = 37'b0000000000000000000000000000000000000;
    end
    7'b0000001: begin
      c3_34 = 15'b101001010101011;
      c2_34 = 22'b0000000111110000000110;
      c1_34 = 29'b11001001000010111111101001110;
      c0_34 = 37'b0000001100100100001110100011111110011;
    end
    7'b0000010: begin
      c3_34 = 15'b101001010100100;
      c2_34 = 22'b0000001111100000000111;
      c1_34 = 29'b11001001000000000101101000001;
      c0_34 = 37'b0000011001001000010101010111110111101;
    end
    7'b0000011: begin
      c3_34 = 15'b101001010011011;
      c2_34 = 22'b0000010111001111111111;
      c1_34 = 29'b11001000111011001111100111011;
      c0_34 = 37'b0000100101101100001100101011101011001;
    end
    7'b0000100: begin
      c3_34 = 15'b101001010001110;
      c2_34 = 22'b0000011110111111101000;
      c1_34 = 29'b11001000110100011101101010011;
      c0_34 = 37'b0000110010001111101100101111100010000;
    end
    7'b0000101: begin
      c3_34 = 15'b101001001111110;
      c2_34 = 22'b0000100110101110111111;
      c1_34 = 29'b11001000101011101111110101101;
      c0_34 = 37'b0000111110110010101101110011110011111;
    end
    7'b0000110: begin
      c3_34 = 15'b101001001101011;
      c2_34 = 22'b0000101110011101111101;
      c1_34 = 29'b11001000100001000110001110001;
      c0_34 = 37'b0001001011010101001000001001001011001;
    end
    7'b0000111: begin
      c3_34 = 15'b101001001010101;
      c2_34 = 22'b0000110110001100011111;
      c1_34 = 29'b11001000010100100000111010110;
      c0_34 = 37'b0001010111110110110100000000101010011;
    end
    7'b0001000: begin
      c3_34 = 15'b101001000111011;
      c2_34 = 22'b0000111101111010011111;
      c1_34 = 29'b11001000000110000000000011001;
      c0_34 = 37'b0001100100010111101001101011110000101;
    end
    7'b0001001: begin
      c3_34 = 15'b101001000011111;
      c2_34 = 22'b0001000101100111111001;
      c1_34 = 29'b11000111110101100011110000001;
      c0_34 = 37'b0001110000110111100001011100011110011;
    end
    7'b0001010: begin
      c3_34 = 15'b101000111111111;
      c2_34 = 22'b0001001101010100101001;
      c1_34 = 29'b11000111100011001100001100001;
      c0_34 = 37'b0001111101010110010011100101011010101;
    end
    7'b0001011: begin
      c3_34 = 15'b101000111011100;
      c2_34 = 22'b0001010101000000101000;
      c1_34 = 29'b11000111001110111001100010010;
      c0_34 = 37'b0010001001110011111000011001110110110;
    end
    7'b0001100: begin
      c3_34 = 15'b101000110110110;
      c2_34 = 22'b0001011100101011110011;
      c1_34 = 29'b11000110111000101011111111000;
      c0_34 = 37'b0010010110010000001000001101110100011;
    end
    7'b0001101: begin
      c3_34 = 15'b101000110001101;
      c2_34 = 22'b0001100100010110000101;
      c1_34 = 29'b11000110100000100011110000010;
      c0_34 = 37'b0010100010101010111011010110001001010;
    end
    7'b0001110: begin
      c3_34 = 15'b101000101100000;
      c2_34 = 22'b0001101011111111011001;
      c1_34 = 29'b11000110000110100001000100110;
      c0_34 = 37'b0010101111000100001010001000100100010;
    end
    7'b0001111: begin
      c3_34 = 15'b101000100110001;
      c2_34 = 22'b0001110011100111101010;
      c1_34 = 29'b11000101101010100100001100101;
      c0_34 = 37'b0010111011011011101100111011110010011;
    end
    7'b0010000: begin
      c3_34 = 15'b101000011111110;
      c2_34 = 22'b0001111011001110110101;
      c1_34 = 29'b11000101001100101101011001000;
      c0_34 = 37'b0011000111110001011100000111100011010;
    end
    7'b0010001: begin
      c3_34 = 15'b101000011001000;
      c2_34 = 22'b0010000010110100110011;
      c1_34 = 29'b11000100101100111100111100100;
      c0_34 = 37'b0011010100000101010000000100101101011;
    end
    7'b0010010: begin
      c3_34 = 15'b101000010001111;
      c2_34 = 22'b0010001010011001100000;
      c1_34 = 29'b11000100001011010011001010100;
      c0_34 = 37'b0011100000010111000001001101010011111;
    end
    7'b0010011: begin
      c3_34 = 15'b101000001010011;
      c2_34 = 22'b0010010001111100111000;
      c1_34 = 29'b11000011100111110000011000000;
      c0_34 = 37'b0011101100100110100111111100101010001;
    end
    7'b0010100: begin
      c3_34 = 15'b101000000010100;
      c2_34 = 22'b0010011001011110110110;
      c1_34 = 29'b11000011000010010100111010101;
      c0_34 = 37'b0011111000110011111100101111011001000;
    end
    7'b0010101: begin
      c3_34 = 15'b100111111010010;
      c2_34 = 22'b0010100000111111010101;
      c1_34 = 29'b11000010011011000001001001110;
      c0_34 = 37'b0100000100111110111000000011100011011;
    end
    7'b0010110: begin
      c3_34 = 15'b100111110001101;
      c2_34 = 22'b0010101000011110010001;
      c1_34 = 29'b11000001110001110101011101011;
      c0_34 = 37'b0100010001000111010010011000101011000;
    end
    7'b0010111: begin
      c3_34 = 15'b100111101000100;
      c2_34 = 22'b0010101111111011100101;
      c1_34 = 29'b11000001000110110010001111001;
      c0_34 = 37'b0100011101001101000100001111110100110;
    end
    7'b0011000: begin
      c3_34 = 15'b100111011111001;
      c2_34 = 22'b0010110111010111001101;
      c1_34 = 29'b11000000011001110111111001011;
      c0_34 = 37'b0100101001010000000110001011101101010;
    end
    7'b0011001: begin
      c3_34 = 15'b100111010101010;
      c2_34 = 22'b0010111110110001000011;
      c1_34 = 29'b10111111101011000110110111111;
      c0_34 = 37'b0100110101010000010000110000101110000;
    end
    7'b0011010: begin
      c3_34 = 15'b100111001011001;
      c2_34 = 22'b0011000110001001000100;
      c1_34 = 29'b10111110111010011111100111101;
      c0_34 = 37'b0101000001001101011100100101000001011;
    end
    7'b0011011: begin
      c3_34 = 15'b100111000000100;
      c2_34 = 22'b0011001101011111001010;
      c1_34 = 29'b10111110001000000010100110011;
      c0_34 = 37'b0101001101000111100010010000100111100;
    end
    7'b0011100: begin
      c3_34 = 15'b100110110101101;
      c2_34 = 22'b0011010100110011010010;
      c1_34 = 29'b10111101010011110000010011011;
      c0_34 = 37'b0101011000111110011010011101011010101;
    end
    7'b0011101: begin
      c3_34 = 15'b100110101010010;
      c2_34 = 22'b0011011100000101010111;
      c1_34 = 29'b10111100011101101001001111000;
      c0_34 = 37'b0101100100110001111101110111010011111;
    end
    7'b0011110: begin
      c3_34 = 15'b100110011110101;
      c2_34 = 22'b0011100011010101010011;
      c1_34 = 29'b10111011100101101101111010011;
      c0_34 = 37'b0101110000100010000101001100001111100;
    end
    7'b0011111: begin
      c3_34 = 15'b100110010010101;
      c2_34 = 22'b0011101010100011000100;
      c1_34 = 29'b10111010101011111110111000001;
      c0_34 = 37'b0101111100001110101001001100010001110;
    end
    7'b0100000: begin
      c3_34 = 15'b100110000110001;
      c2_34 = 22'b0011110001101110100100;
      c1_34 = 29'b10111001110000011100101011110;
      c0_34 = 37'b0110000111110111100010101001101010110;
    end
    7'b0100001: begin
      c3_34 = 15'b100101111001011;
      c2_34 = 22'b0011111000110111101111;
      c1_34 = 29'b10111000110011000111111010010;
      c0_34 = 37'b0110010011011100101010011000111011101;
    end
    7'b0100010: begin
      c3_34 = 15'b100101101100010;
      c2_34 = 22'b0011111111111110100000;
      c1_34 = 29'b10110111110100000001001001001;
      c0_34 = 37'b0110011110111101111001010000111010100;
    end
    7'b0100011: begin
      c3_34 = 15'b100101011110101;
      c2_34 = 22'b0100000111000010110011;
      c1_34 = 29'b10110110110011001000111111101;
      c0_34 = 37'b0110101010011011001000001010110110110;
    end
    7'b0100100: begin
      c3_34 = 15'b100101010000110;
      c2_34 = 22'b0100001110000100100100;
      c1_34 = 29'b10110101110000100000000101100;
      c0_34 = 37'b0110110101110100010000000010011110000;
    end
    7'b0100101: begin
      c3_34 = 15'b100101000010100;
      c2_34 = 22'b0100010101000011101111;
      c1_34 = 29'b10110100101100000111000011111;
      c0_34 = 37'b0111000001001001001001110110000000000;
    end
    7'b0100110: begin
      c3_34 = 15'b100100110100000;
      c2_34 = 22'b0100011100000000001110;
      c1_34 = 29'b10110011100101111110100101001;
      c0_34 = 37'b0111001100011001101110100110010011000;
    end
    7'b0100111: begin
      c3_34 = 15'b100100100101000;
      c2_34 = 22'b0100100010111001111111;
      c1_34 = 29'b10110010011110000111010100011;
      c0_34 = 37'b0111010111100101110111010110111000010;
    end
    7'b0101000: begin
      c3_34 = 15'b100100010101101;
      c2_34 = 22'b0100101001110000111100;
      c1_34 = 29'b10110001010100100001111110000;
      c0_34 = 37'b0111100010101101011101001110000000010;
    end
    7'b0101001: begin
      c3_34 = 15'b100100000110000;
      c2_34 = 22'b0100110000100101000001;
      c1_34 = 29'b10110000001001001111001111010;
      c0_34 = 37'b0111101101110000011001010100101110111;
    end
    7'b0101010: begin
      c3_34 = 15'b100011110110000;
      c2_34 = 22'b0100110111010110001010;
      c1_34 = 29'b10101110111100001111110110111;
      c0_34 = 37'b0111111000101110100100110110111111011;
    end
    7'b0101011: begin
      c3_34 = 15'b100011100101101;
      c2_34 = 22'b0100111110000100010100;
      c1_34 = 29'b10101101101101100100100100000;
      c0_34 = 37'b1000000011100111111001000011101001011;
    end
    7'b0101100: begin
      c3_34 = 15'b100011010101000;
      c2_34 = 22'b0101000100101111011001;
      c1_34 = 29'b10101100011101001110000111100;
      c0_34 = 37'b1000001110011100001111001100100100010;
    end
    7'b0101101: begin
      c3_34 = 15'b100011000100000;
      c2_34 = 22'b0101001011010111010110;
      c1_34 = 29'b10101011001011001101010010101;
      c0_34 = 37'b1000011001001011100000100110101011101;
    end
    7'b0101110: begin
      c3_34 = 15'b100010110010101;
      c2_34 = 22'b0101010001111100000110;
      c1_34 = 29'b10101001110111100010111000001;
      c0_34 = 37'b1000100011110101100110101010000011010;
    end
    7'b0101111: begin
      c3_34 = 15'b100010100000111;
      c2_34 = 22'b0101011000011101100110;
      c1_34 = 29'b10101000100010001111101011110;
      c0_34 = 37'b1000101110011010011010110001111011110;
    end
    7'b0110000: begin
      c3_34 = 15'b100010001110111;
      c2_34 = 22'b0101011110111011110001;
      c1_34 = 29'b10100111001011010100100001110;
      c0_34 = 37'b1000111000111001110110011100110101101;
    end
    7'b0110001: begin
      c3_34 = 15'b100001111100100;
      c2_34 = 22'b0101100101010110100101;
      c1_34 = 29'b10100101110010110010010000001;
      c0_34 = 37'b1001000011010011110011001100100110011;
    end
    7'b0110010: begin
      c3_34 = 15'b100001101001110;
      c2_34 = 22'b0101101011101101111011;
      c1_34 = 29'b10100100011000101001101101010;
      c0_34 = 37'b1001001101101000001010100110011011100;
    end
    7'b0110011: begin
      c3_34 = 15'b100001010110110;
      c2_34 = 22'b0101110010000001110001;
      c1_34 = 29'b10100010111100111011110000110;
      c0_34 = 37'b1001010111110110110110010010111111010;
    end
    7'b0110100: begin
      c3_34 = 15'b100001000011011;
      c2_34 = 22'b0101111000010010000011;
      c1_34 = 29'b10100001011111101001010011010;
      c0_34 = 37'b1001100001111111101111111110011100000;
    end
    7'b0110101: begin
      c3_34 = 15'b100000101111110;
      c2_34 = 22'b0101111110011110101101;
      c1_34 = 29'b10100000000000110011001110011;
      c0_34 = 37'b1001101100000010110001011000100000101;
    end
    7'b0110110: begin
      c3_34 = 15'b100000011011110;
      c2_34 = 22'b0110000100100111101011;
      c1_34 = 29'b10011110100000011010011100100;
      c0_34 = 37'b1001110101111111110100010100100011111;
    end
    7'b0110111: begin
      c3_34 = 15'b100000000111100;
      c2_34 = 22'b0110001010101100111001;
      c1_34 = 29'b10011100111110011111111001001;
      c0_34 = 37'b1001111111110110110010101001101000100;
    end
    7'b0111000: begin
      c3_34 = 15'b011111110010111;
      c2_34 = 22'b0110010000101110010100;
      c1_34 = 29'b10011011011011000100100000100;
      c0_34 = 37'b1010001001100111100110010010100001000;
    end
    7'b0111001: begin
      c3_34 = 15'b011111011110000;
      c2_34 = 22'b0110010110101011111000;
      c1_34 = 29'b10011001110110001001010000010;
      c0_34 = 37'b1010010011010010001001001101110011010;
    end
    7'b0111010: begin
      c3_34 = 15'b011111001000110;
      c2_34 = 22'b0110011100100101100001;
      c1_34 = 29'b10011000001111101111000110100;
      c0_34 = 37'b1010011100110110010101011101111100011;
    end
    7'b0111011: begin
      c3_34 = 15'b011110110011010;
      c2_34 = 22'b0110100010011011001011;
      c1_34 = 29'b10010110100111110111000010010;
      c0_34 = 37'b1010100110010100000101001001010100010;
    end
    7'b0111100: begin
      c3_34 = 15'b011110011101100;
      c2_34 = 22'b0110101000001100110011;
      c1_34 = 29'b10010100111110100010000011111;
      c0_34 = 37'b1010101111101011010010011010010001100;
    end
    7'b0111101: begin
      c3_34 = 15'b011110000111011;
      c2_34 = 22'b0110101101111010010101;
      c1_34 = 29'b10010011010011110001001100001;
      c0_34 = 37'b1010111000111011110111011111001100100;
    end
    7'b0111110: begin
      c3_34 = 15'b011101110001000;
      c2_34 = 22'b0110110011100011101111;
      c1_34 = 29'b10010001100111100101011101000;
      c0_34 = 37'b1011000010000101101110101010100011100;
    end
    7'b0111111: begin
      c3_34 = 15'b011101011010010;
      c2_34 = 22'b0110111001001000111011;
      c1_34 = 29'b10001111111001111111111001000;
      c0_34 = 37'b1011001011001000110010010010111101111;
    end
    7'b1000000: begin
      c3_34 = 15'b011101000011011;
      c2_34 = 22'b0110111110101001111000;
      c1_34 = 29'b10001110001011000001100100000;
      c0_34 = 37'b1011010100000100111100110011001111110;
    end
    7'b1000001: begin
      c3_34 = 15'b011100101100001;
      c2_34 = 22'b0111000100000110100001;
      c1_34 = 29'b10001100011010101011100010011;
      c0_34 = 37'b1011011100111010001000101010011101001;
    end
    7'b1000010: begin
      c3_34 = 15'b011100010100101;
      c2_34 = 22'b0111001001011110110011;
      c1_34 = 29'b10001010101000111110111001010;
      c0_34 = 37'b1011100101101000010000011011111101111;
    end
    7'b1000011: begin
      c3_34 = 15'b011011111100110;
      c2_34 = 22'b0111001110110010101011;
      c1_34 = 29'b10001000110101111100101111000;
      c0_34 = 37'b1011101110001111001110101111100000010;
    end
    7'b1000100: begin
      c3_34 = 15'b011011100100110;
      c2_34 = 22'b0111010100000010000101;
      c1_34 = 29'b10000111000001100110001010011;
      c0_34 = 37'b1011110110101110111110010001001101001;
    end
    7'b1000101: begin
      c3_34 = 15'b011011001100011;
      c2_34 = 22'b0111011001001100111111;
      c1_34 = 29'b10000101001011111100010011011;
      c0_34 = 37'b1011111111000111011001110001101010110;
    end
    7'b1000110: begin
      c3_34 = 15'b011010110011111;
      c2_34 = 22'b0111011110010011010101;
      c1_34 = 29'b10000011010101000000010010011;
      c0_34 = 37'b1100000111011000011100000101111111110;
    end
    7'b1000111: begin
      c3_34 = 15'b011010011011000;
      c2_34 = 22'b0111100011010101000011;
      c1_34 = 29'b10000001011100110011010000110;
      c0_34 = 37'b1100001111100010000000000111110111001;
    end
    7'b1001000: begin
      c3_34 = 15'b011010000001111;
      c2_34 = 22'b0111101000010010001000;
      c1_34 = 29'b01111111100011010110011000111;
      c0_34 = 37'b1100010111100100000000110101100010100;
    end
    7'b1001001: begin
      c3_34 = 15'b011001101000100;
      c2_34 = 22'b0111101101001010100000;
      c1_34 = 29'b01111101101000101010110101011;
      c0_34 = 37'b1100011111011110011001010001111101110;
    end
    7'b1001010: begin
      c3_34 = 15'b011001001110111;
      c2_34 = 22'b0111110001111110000111;
      c1_34 = 29'b01111011101100110001110010000;
      c0_34 = 37'b1100100111010001000100100100110010001;
    end
    7'b1001011: begin
      c3_34 = 15'b011000110101001;
      c2_34 = 22'b0111110110101100111011;
      c1_34 = 29'b01111001101111101100011011010;
      c0_34 = 37'b1100101110111011111101111010011000111;
    end
    7'b1001100: begin
      c3_34 = 15'b011000011011000;
      c2_34 = 22'b0111111011010110111001;
      c1_34 = 29'b01110111110001011011111110011;
      c0_34 = 37'b1100110110011111000000100011111110010;
    end
    7'b1001101: begin
      c3_34 = 15'b011000000000110;
      c2_34 = 22'b0111111111111011111110;
      c1_34 = 29'b01110101110010000001101001000;
      c0_34 = 37'b1100111101111010000111110111100101000;
    end
    7'b1001110: begin
      c3_34 = 15'b010111100110001;
      c2_34 = 22'b1000000100011100000111;
      c1_34 = 29'b01110011110001011110101001111;
      c0_34 = 37'b1101000101001101001111010000001000101;
    end
    7'b1001111: begin
      c3_34 = 15'b010111001011011;
      c2_34 = 22'b1000001000110111010010;
      c1_34 = 29'b01110001101111110100010000011;
      c0_34 = 37'b1101001100011000010010001101100000010;
    end
    7'b1010000: begin
      c3_34 = 15'b010110110000011;
      c2_34 = 22'b1000001101001101011011;
      c1_34 = 29'b01101111101101000011101100010;
      c0_34 = 37'b1101010011011011001100010100100001101;
    end
    7'b1010001: begin
      c3_34 = 15'b010110010101001;
      c2_34 = 22'b1000010001011110100001;
      c1_34 = 29'b01101101101001001110001110011;
      c0_34 = 37'b1101011010010101111001001111000100000;
    end
    7'b1010010: begin
      c3_34 = 15'b010101111001110;
      c2_34 = 22'b1000010101101010100000;
      c1_34 = 29'b01101011100100010101000111111;
      c0_34 = 37'b1101100001001000010100101100000010100;
    end
    7'b1010011: begin
      c3_34 = 15'b010101011110001;
      c2_34 = 22'b1000011001110001010101;
      c1_34 = 29'b01101001011110011001101010111;
      c0_34 = 37'b1101100111110010011010011111011110100;
    end
    7'b1010100: begin
      c3_34 = 15'b010101000010010;
      c2_34 = 22'b1000011101110010111111;
      c1_34 = 29'b01100111010111011101001001111;
      c0_34 = 37'b1101101110010100000110100010100011000;
    end
    7'b1010101: begin
      c3_34 = 15'b010100100110001;
      c2_34 = 22'b1000100001101111011011;
      c1_34 = 29'b01100101001111100000111000010;
      c0_34 = 37'b1101110100101101010100110011100110100;
    end
    7'b1010110: begin
      c3_34 = 15'b010100001001111;
      c2_34 = 22'b1000100101100110100110;
      c1_34 = 29'b01100011000110100110001001111;
      c0_34 = 37'b1101111010111110000001010110001101110;
    end
    7'b1010111: begin
      c3_34 = 15'b010011101101100;
      c2_34 = 22'b1000101001011000011110;
      c1_34 = 29'b01100000111100101110010011000;
      c0_34 = 37'b1110000001000110001000010011001110001;
    end
    7'b1011000: begin
      c3_34 = 15'b010011010000111;
      c2_34 = 22'b1000101101000101000001;
      c1_34 = 29'b01011110110001111010101000110;
      c0_34 = 37'b1110000111000101100101111000101111111;
    end
    7'b1011001: begin
      c3_34 = 15'b010010110100000;
      c2_34 = 22'b1000110000101100001100;
      c1_34 = 29'b01011100100110001100100000111;
      c0_34 = 37'b1110001100111100010110011010010000111;
    end
    7'b1011010: begin
      c3_34 = 15'b010010010111000;
      c2_34 = 22'b1000110100001101111101;
      c1_34 = 29'b01011010011001100101010001100;
      c0_34 = 37'b1110010010101010010110010000100110011;
    end
    7'b1011011: begin
      c3_34 = 15'b010001111001111;
      c2_34 = 22'b1000110111101010010010;
      c1_34 = 29'b01011000001100000110010001010;
      c0_34 = 37'b1110011000001111100001111001111111100;
    end
    7'b1011100: begin
      c3_34 = 15'b010001011100100;
      c2_34 = 22'b1000111011000001001001;
      c1_34 = 29'b01010101111101110000110111100;
      c0_34 = 37'b1110011101101011110101111010000111011;
    end
    7'b1011101: begin
      c3_34 = 15'b010000111111000;
      c2_34 = 22'b1000111110010010100000;
      c1_34 = 29'b01010011101110100110011100000;
      c0_34 = 37'b1110100010111111001110111010000111101;
    end
    7'b1011110: begin
      c3_34 = 15'b010000100001010;
      c2_34 = 22'b1001000001011110010101;
      c1_34 = 29'b01010001011110101000010111001;
      c0_34 = 37'b1110101000001001101001101000101001100;
    end
    7'b1011111: begin
      c3_34 = 15'b010000000011100;
      c2_34 = 22'b1001000100100100100101;
      c1_34 = 29'b01001111001101111000000001101;
      c0_34 = 37'b1110101101001011000010111001111001000;
    end
    7'b1100000: begin
      c3_34 = 15'b001111100101100;
      c2_34 = 22'b1001000111100101001111;
      c1_34 = 29'b01001100111100010110110100111;
      c0_34 = 37'b1110110010000011010111100111100110001;
    end
    7'b1100001: begin
      c3_34 = 15'b001111000111010;
      c2_34 = 22'b1001001010100000010010;
      c1_34 = 29'b01001010101010000110001010100;
      c0_34 = 37'b1110110110110010100100110001000110111;
    end
    7'b1100010: begin
      c3_34 = 15'b001110101001000;
      c2_34 = 22'b1001001101010101101010;
      c1_34 = 29'b01001000010111000111011100111;
      c0_34 = 37'b1110111011011000100111011011011001011;
    end
    7'b1100011: begin
      c3_34 = 15'b001110001010101;
      c2_34 = 22'b1001010000000101010111;
      c1_34 = 29'b01000110000011011100000110100;
      c0_34 = 37'b1110111111110101011100110001000101100;
    end
    7'b1100100: begin
      c3_34 = 15'b001101101100000;
      c2_34 = 22'b1001010010101111010111;
      c1_34 = 29'b01000011101111000101100010100;
      c0_34 = 37'b1111000100001001000010000010011110101;
    end
    7'b1100101: begin
      c3_34 = 15'b001101001101010;
      c2_34 = 22'b1001010101010011101000;
      c1_34 = 29'b01000001011010000101001100100;
      c0_34 = 37'b1111001000010011010100100101100101010;
    end
    7'b1100110: begin
      c3_34 = 15'b001100101110100;
      c2_34 = 22'b1001010111110010001000;
      c1_34 = 29'b00111111000100011100100000011;
      c0_34 = 37'b1111001100010100010001110110001000111;
    end
    7'b1100111: begin
      c3_34 = 15'b001100001111100;
      c2_34 = 22'b1001011010001010110111;
      c1_34 = 29'b00111100101110001100111010011;
      c0_34 = 37'b1111010000001011110111010101101001011;
    end
    7'b1101000: begin
      c3_34 = 15'b001011110000100;
      c2_34 = 22'b1001011100011101110010;
      c1_34 = 29'b00111010010111010111110111010;
      c0_34 = 37'b1111010011111010000010101011011000101;
    end
    7'b1101001: begin
      c3_34 = 15'b001011010001010;
      c2_34 = 22'b1001011110101010111000;
      c1_34 = 29'b00110111111111111110110011111;
      c0_34 = 37'b1111010111011110110001100100011011110;
    end
    7'b1101010: begin
      c3_34 = 15'b001010110010000;
      c2_34 = 22'b1001100000110010001000;
      c1_34 = 29'b00110101101000000011001101111;
      c0_34 = 37'b1111011010111010000001110011101100111;
    end
    7'b1101011: begin
      c3_34 = 15'b001010010010101;
      c2_34 = 22'b1001100010110011100000;
      c1_34 = 29'b00110011001111100110100010110;
      c0_34 = 37'b1111011110001011110001010001111100011;
    end
    7'b1101100: begin
      c3_34 = 15'b001001110011001;
      c2_34 = 22'b1001100100101111000000;
      c1_34 = 29'b00110000110110101010010000101;
      c0_34 = 37'b1111100001010011111101111101110010001;
    end
    7'b1101101: begin
      c3_34 = 15'b001001010011100;
      c2_34 = 22'b1001100110100100100101;
      c1_34 = 29'b00101110011101001111110101111;
      c0_34 = 37'b1111100100010010100101111011101110101;
    end
    7'b1101110: begin
      c3_34 = 15'b001000110011110;
      c2_34 = 22'b1001101000010100010000;
      c1_34 = 29'b00101100000011011000110001001;
      c0_34 = 37'b1111100111000111100111010110001100011;
    end
    7'b1101111: begin
      c3_34 = 15'b001000010100000;
      c2_34 = 22'b1001101001111101111110;
      c1_34 = 29'b00101001101001000110100001010;
      c0_34 = 37'b1111101001110011000000011101100001010;
    end
    7'b1110000: begin
      c3_34 = 15'b000111110100001;
      c2_34 = 22'b1001101011100001101111;
      c1_34 = 29'b00100111001110011010100101011;
      c0_34 = 37'b1111101100010100101111100111111110110;
    end
    7'b1110001: begin
      c3_34 = 15'b000111010100010;
      c2_34 = 22'b1001101100111111100011;
      c1_34 = 29'b00100100110011010110011101000;
      c0_34 = 37'b1111101110101100110011010001110100000;
    end
    7'b1110010: begin
      c3_34 = 15'b000110110100010;
      c2_34 = 22'b1001101110010111010111;
      c1_34 = 29'b00100010010111111011100111110;
      c0_34 = 37'b1111110000111011001001111101001110000;
    end
    7'b1110011: begin
      c3_34 = 15'b000110010100010;
      c2_34 = 22'b1001101111101001001011;
      c1_34 = 29'b00011111111100001011100101100;
      c0_34 = 37'b1111110010111111110010010010011001000;
    end
    7'b1110100: begin
      c3_34 = 15'b000101110100001;
      c2_34 = 22'b1001110000110100111110;
      c1_34 = 29'b00011101100000000111110110010;
      c0_34 = 37'b1111110100111010101010111111100000111;
    end
    7'b1110101: begin
      c3_34 = 15'b000101010011111;
      c2_34 = 22'b1001110001111010110000;
      c1_34 = 29'b00011011000011110001111010011;
      c0_34 = 37'b1111110110101011110010111000110010100;
    end
    7'b1110110: begin
      c3_34 = 15'b000100110011110;
      c2_34 = 22'b1001110010111010100000;
      c1_34 = 29'b00011000100111001011010010010;
      c0_34 = 37'b1111111000010011001000111000011100000;
    end
    7'b1110111: begin
      c3_34 = 15'b000100010011011;
      c2_34 = 22'b1001110011110100001101;
      c1_34 = 29'b00010110001010010101011110100;
      c0_34 = 37'b1111111001110000101011111110101101100;
    end
    7'b1111000: begin
      c3_34 = 15'b000011110011001;
      c2_34 = 22'b1001110100100111110111;
      c1_34 = 29'b00010011101101010001111111111;
      c0_34 = 37'b1111111011000100011011010001111010000;
    end
    7'b1111001: begin
      c3_34 = 15'b000011010010110;
      c2_34 = 22'b1001110101010101011101;
      c1_34 = 29'b00010001010000000010010111010;
      c0_34 = 37'b1111111100001110010101111110010111100;
    end
    7'b1111010: begin
      c3_34 = 15'b000010110010011;
      c2_34 = 22'b1001110101111100111111;
      c1_34 = 29'b00001110110010101000000101100;
      c0_34 = 37'b1111111101001110011011010110100000000;
    end
    7'b1111011: begin
      c3_34 = 15'b000010010010000;
      c2_34 = 22'b1001110110011110011101;
      c1_34 = 29'b00001100010101000100101100000;
      c0_34 = 37'b1111111110000100101010110010110001101;
    end
    7'b1111100: begin
      c3_34 = 15'b000001110001100;
      c2_34 = 22'b1001110110111001110101;
      c1_34 = 29'b00001001110111011001101011101;
      c0_34 = 37'b1111111110110001000011110001101111000;
    end
    7'b1111101: begin
      c3_34 = 15'b000001010001001;
      c2_34 = 22'b1001110111001111001000;
      c1_34 = 29'b00000111011001101000100101111;
      c0_34 = 37'b1111111111010011100101110111111111101;
    end
    7'b1111110: begin
      c3_34 = 15'b000000110000101;
      c2_34 = 22'b1001110111011110010110;
      c1_34 = 29'b00000100111011110010111011111;
      c0_34 = 37'b1111111111101100010000110000010000011;
    end
    7'b1111111: begin
      c3_34 = 15'b000000010000001;
      c2_34 = 22'b1001110111100111011111;
      c1_34 = 29'b00000010011101111010001111001;
      c0_34 = 37'b1111111111111011000100001011010011010;
    end
  endcase

end

endmodule
