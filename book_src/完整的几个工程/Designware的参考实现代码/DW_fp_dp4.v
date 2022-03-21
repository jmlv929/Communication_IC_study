
////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-point Four-term Dot-product
//           Computes the sum of products of FP numbers. For this component,
//           four products are considered. Given the FP inputs a, b, c, d, e
//           f, g and h, it computes the FP output z = a*b + c*d + e*f + g*h. 
//           The format of the FP numbers is defined by the number of bits 
//           in the significand (sig_width) and the number of bits in the 
//           exponent (exp_width).
//           The total number of bits in the FP number is sig_width+exp_width+1
//           since the sign bit takes the place of the MS bits in the significand
//           which is always 1 (unless the number is a denormal; a condition 
//           that can be detected testing the exponent value).
//           The output is a FP number and status flags with information about
//           special number representations and exceptions. Rounding mode may 
//           also be defined by an input port.
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand,  2 to 253 bits
//              exp_width       exponent,     3 to 31 bits
//              ieee_compliance 0 or 1 (default 0)
//              arch_type       0 or 1 (default 0)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              b               (sig_width + exp_width) + 1-bits
//                              Floating-point Number Input
//              c               (sig_width + exp_width) + 1-bits
//                              Floating-point Number Input
//              d               (sig_width + exp_width) + 1-bits
//                              Floating-point Number Input
//              e               (sig_width + exp_width) + 1-bits
//                              Floating-point Number Input
//              f               (sig_width + exp_width) + 1-bits
//                              Floating-point Number Input
//              g               (sig_width + exp_width) + 1-bits
//                              Floating-point Number Input
//              h               (sig_width + exp_width) + 1-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              rounding mode
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_width + exp_width + 1) bits
//                              Floating-point Number result that corresponds
//                              to a*b+c*d+e*f+g*h
//              status          byte
//                              info about FP results
//
// MODIFIED:
//           11/12/07 - AFT - Includes modifications to deal with the sign of zeros
//                   according to specification regarding the addition of zeros 
//                   (A-SP1)
//           11/13/07 - AFT - also eliminated the internal detection of infinities.
//                   The method was not giving any benefit in terms of QoR, and was
//                   husting accuracy. 
//           04/25/08 - AFT - included a new parameter (arch_type) to control
//                   the use of alternative architecture with IFP blocks
//           01/2009 - AFT - expanded the use of parameters to accept 
//                     ieee_compliance=1 when arch_type=1
//           02/2009 - AFT - modifications to reduce lint warning messages
//           07/2009 - AFT - corrected a problem with the computation of stk when
//                     there are multiple stk bits set during alignment
//           09/2011 - AFT - adjusted the internal precision for the case when
//                     the exponent is less than a given threshold (see notes in the
//                     code). Star 9000492788. New threshold condition was imposed.
//           09/2011 - AFT - also fixed the problem with an adjustment done on 
//                     some internal product exponent variable, such as, E_P1_d
//                     and E_P2_d (around line 553). The adjustment is done based on 
//                     the significand size, while the size of the variables is based
//                     the exponent size. Under this condition, for some parameters, 
//                     an overflow occurs when the adjustment is done. We have issues
//                     in the previous code when ceil(log2(2f+2))>=e+2
//                     where (e+2) is the size of exponents for internal products and
//                     (2f+2) is the size of a product.
//           10/2011 AFT - the code is checking the case when normalization is
//                     is going to cause underflow in the exponent values, however,
//                     it is not checking when the exponent is going to have an 
//                     overflow with a zero output. In this case, the addition of
//                     products leads to zero, and the normalization shift value 
//                     is large enough to cause an overflow (shows up when the 
//                     exponent size is small). With the overflow detection the
//                     output is set to infinity, when it should be simply zero,
//                     because the addition of products is zero.
//           11/2011 AFT - fixed the cancellation of sticky bit STK3 in the situation 
//                     when the third product is partially shifted out during alignment.
//                     When the third product is partially shifted out, and the 
//                     second produt does not have a sticky bit, we keep the sticky 
//                     bit of the third product (during the assignment of M_3_sh).
//           04/2012 AFT - star 9000532273
//                     All the issues related to normalization and rounding:
//                     (1) when normalizing, this component was shifting the sticky
//                         bit with the others, however, when big cancellation occurs
//                         (cancellation of the largest 3 products), and the fourth
//                         smallest product is partially in range, the sticky bit 
//                         may be in a position to affect rounding. The fix consists
//                         in avoid the sticky bit during normalization.
//                     (2) the detection of big cancellation (cancellation of
//                         the largest 3 products) was not correct. The test was being
//                         done on all the adder bits (besides sticky bit). However, 
//                         when the fourth product is in range, the adder output is 
//                         a non-zero value, and the big cancellation is not properly
//                         detected, allowing for normalization of part of the fourth 
//                         product. The fix consists in reducing the range used to 
//                         test for zeros at adder output, avoiding the area where 
//                         the fourth product may be, if it is partially in the adder
//                         range. If the fourth product has all the bits required for
//                         rounding in the adder range, there is no problem.
//                     (3) When a result is a denormalized value (ieee_compliance=1)
//                         at the end, we may need to get the final result using 
//                         denormalization or normalization shift. The previous code 
//                         was only using denormalization, but in some cases, a small 
//                         normalization of 1 bit is required, and if not done, 
//                         generates incorrect significand.
//
//-------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_fp_dp4 (

// ports
                   a,
                   b,
                   c,
                   d,
                   e,
                   f,
                   g,
                   h,
                   rnd,
                   z,
                   status

    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

//----------------------------------------------------------------------------
// main module parameters
parameter sig_width    = 23;     // RANGE 2 to 253 bits
parameter exp_width    = 8;      // RANGE 3 to 31 bits
parameter ieee_compliance = 0;   // RANGE 0 or 1
parameter arch_type = 0;         // RANGE 0 or 1
parameter adj_prec = 0;


//------------------------------------------------------
// declaration of inputs and outputs
input [sig_width+exp_width : 0] a;
input [sig_width+exp_width : 0] b;
input [sig_width+exp_width : 0] c;
input [sig_width+exp_width : 0] d;
input [sig_width+exp_width : 0] e;
input [sig_width+exp_width : 0] f;
input [sig_width+exp_width : 0] g;
input [sig_width+exp_width : 0] h;
input [2 : 0] rnd;
output [sig_width+exp_width : 0] z;
output [8    -1 : 0] status;

//--------------------------------------------------------
// compute the threshold margin to define internal precision
//
`define d (sig_width*4+8)
`define log_d (((`d>16)?((`d>64)?((`d>128)?8:7):((`d>32)?6:5)):((`d>4)?((`d>8)?4:3):((`d>2)?2:1))))
`define precision ((exp_width<(`log_d-1))?4*({exp_width{1'b1}}>>1)+(2*sig_width+2)-1+(3)+adj_prec:6*sig_width+5+(3)+adj_prec)
`define log_prod_size ((((2*sig_width+2)>256)?(((2*sig_width+2)>4096)?(((2*sig_width+2)>16384)?(((2*sig_width+2)>32768)?16:15):(((2*sig_width+2)>8192)?14:13)):(((2*sig_width+2)>1024)?(((2*sig_width+2)>2048)?12:11):(((2*sig_width+2)>512)?10:9))):(((2*sig_width+2)>16)?(((2*sig_width+2)>64)?(((2*sig_width+2)>128)?8:7):(((2*sig_width+2)>32)?6:5)):(((2*sig_width+2)>4)?(((2*sig_width+2)>8)?4:3):(((2*sig_width+2)>2)?2:1)))))
`define prod_exp_size (((exp_width+2)<`log_prod_size)?(`log_prod_size+1):(exp_width+3))
// adder width is composed of
//     --------------------------------------------------
//     | (3) | multiple of (2*sig_width+2) S_bits   |
//     |       3       |   6f+5                         |
//     | <-----------        precision     -----------> |
//     --------------------------------------------------
`define DW_shift_width  ((((`precision)-1>256)?(((`precision)-1>4096)?(((`precision)-1>16384)?(((`precision)-1>32768)?16:15):(((`precision)-1>8192)?14:13)):(((`precision)-1>1024)?(((`precision)-1>2048)?12:11):(((`precision)-1>512)?10:9))):(((`precision)-1>16)?(((`precision)-1>64)?(((`precision)-1>128)?8:7):(((`precision)-1>32)?6:5)):(((`precision)-1>4)?(((`precision)-1>8)?4:3):(((`precision)-1>2)?2:1)))))
`define lzd_big_cancel_width  ((((`precision)-1-(sig_width+5)>256)?(((`precision)-1-(sig_width+5)>4096)?(((`precision)-1-(sig_width+5)>16384)?(((`precision)-1-(sig_width+5)>32768)?16:15):(((`precision)-1-(sig_width+5)>8192)?14:13)):(((`precision)-1-(sig_width+5)>1024)?(((`precision)-1-(sig_width+5)>2048)?12:11):(((`precision)-1-(sig_width+5)>512)?10:9))):(((`precision)-1-(sig_width+5)>16)?(((`precision)-1-(sig_width+5)>64)?(((`precision)-1-(sig_width+5)>128)?8:7):(((`precision)-1-(sig_width+5)>32)?6:5)):(((`precision)-1-(sig_width+5)>4)?(((`precision)-1-(sig_width+5)>8)?4:3):(((`precision)-1-(sig_width+5)>2)?2:1)))))

reg [8    -1:0] status_int;
reg [8    -1:0] status_int1;
reg [(exp_width + sig_width):0] z_temp;
reg [(exp_width + sig_width):0] z_temp1;
reg output_defined_from_inp;
wire S_a,S_b,S_c,S_d,S_e,S_f,S_g,S_h;          // sign bits
wire [exp_width-1:0] E_a,E_b,E_c,E_d,E_e,E_f,E_g,E_h; // Exponents
wire [exp_width-1:0] E_a_orig,E_b_orig,E_c_orig,E_d_orig,
             E_e_orig,E_f_orig,E_g_orig,E_h_orig; 
wire [sig_width-1:0] F_a,F_b,F_c,F_d,F_e,F_f,F_g,F_h; // fraction bits
wire [sig_width-1:0] F_a_orig,F_b_orig,F_c_orig,F_d_orig,
             F_e_orig,F_f_orig,F_g_orig,F_h_orig; 
wire [sig_width:0] M_a,M_b,M_c,M_d,M_e,M_f,M_g,M_h;   // Mantissas

// internal FP values (products)
wire S_P1,S_P2,S_P3,S_P4;                            // sign bits
wire [(2*sig_width+2)-1:0] M_P1_d, M_P2_d, M_P3_d,M_P4_d;  // denormalized mantissas
wire [`prod_exp_size-1:0] E_P1_d,E_P2_d,E_P3_d,E_P4_d;// Exponents
wire [`prod_exp_size-1:0] E_P1_n,E_P2_n,E_P3_n,E_P4_n;// Exponents
wire [`prod_exp_size-1:0] E_P1_nf,E_P2_nf,E_P3_nf,E_P4_nf;// Exponents
wire [(2*sig_width+2)-1:0] M_P1_raw, M_P2_raw, M_P3_raw, M_P4_raw; // Normalized mantissas
// the shifted internal mantissas have "(`precision-(2*sig_width+2)-(3))" extra bits 
// that account for significand overlap and sticky bit
reg [(2*sig_width+2)+(`precision-(2*sig_width+2)-(3))-1:0] M_1_sh, M_2_sh, M_3_sh, M_4_sh;

// The biggest possible exponent for addition/subtraction
// The intermediate value has 2*Bias added to it.
wire [`prod_exp_size-1:0] max_exp_i;
wire [`prod_exp_size-1:0] max_exp;
wire [`prod_exp_size-1:0] ediff_12, ediff_13, ediff_14;
wire [(`precision-(2*sig_width+2)-(3))-1:0] zero_vec;
reg completely_shifted_out_2, completely_shifted_out_3;

wire [(exp_width + sig_width):0] NaNFp;               // NaN FP number

// indication of special cases for the inputs
wire denormal_a, denormal_b, denormal_c, denormal_d; 
wire denormal_e, denormal_f, denormal_g, denormal_h;
wire inf_a, inf_b, inf_c, inf_d, inf_e, inf_f, inf_g, inf_h;
wire nan_a, nan_b, nan_c, nan_d, nan_e, nan_f, nan_g, nan_h;
wire zer_a, zer_b, zer_c, zer_d, zer_e, zer_f, zer_g, zer_h;
wire inf_P1, inf_P2, inf_P3, inf_P4;
wire nan_P1, nan_P2, nan_P3, nan_P4;
wire zer_P1, zer_P2, zer_P3, zer_P4;
wire [(exp_width + sig_width + 1)-1:0] z_inf_plus;
wire [(exp_width + sig_width + 1)-1:0] z_inf_minus;
wire [(exp_width + sig_width + 1)-1:0] z_large_plus;
wire [(exp_width + sig_width + 1)-1:0] z_large_minus;
wire [(exp_width + sig_width + 1)-1:0] zero_out;
wire [(exp_width + sig_width + 1)-1:0] pluszero;              // plus zero
wire [(exp_width + sig_width + 1)-1:0] negzero;               // negative zero

// internal variables
reg [((`precision)-1):0] adder_input1, adder_input2, adder_input3, adder_input4; 
reg [((`precision)-1):0] adder_output; 
reg adder_output_sign;
wire adder_sign;
reg [((`precision)-1)-1:0] adder_output_mag; 
wire [((`precision)-1)-1:0] adder_mag; 
reg [exp_width-1:0] int_exponent;

//--------------------------------------------------------------
// signals used in the normalization and rounding block
//
reg [`prod_exp_size:0] corrected_expo1;
reg [`prod_exp_size:0] corrected_expo2;
reg [`prod_exp_size:0] corrected_expo;
reg post_rounding_normalization;
reg [((`precision)-1)-1:0] a_mag;
reg sticky_bit, T, R_bit, L_bit;
reg inexact;
reg pos_err;           // indicates that the exponent is out
                       // of range
// Controls the manipulation of
// exponents in the DW_norm_rnd component
wire [`DW_shift_width:0] num_of_zeros;
reg [`DW_shift_width+2:0] num_of_zeros_biased;
reg [`DW_shift_width:0] shifting_distance;
// the shifting distance is based on the size of the adder, which is 
// declared as a function of sig_width. However, the shifting distance
// is defined as a function of the exponent too, and therefore, we need
// a larger veriable to track these large values
reg [exp_width+`DW_shift_width:0] lp_shift_dist;
reg [((`precision)-1)-1:0] a_norm;
reg [sig_width+2:0] a_denorm; // keeps f+2 bits for significand and Rbit
reg a_sign;
reg rnd_incr;
reg [sig_width+1:0] a_rounded;
reg no_MS1_detection;
reg [sig_width:0] significand_z;
reg [exp_width-1:0] exponent_z;
reg large_input_exp;
wire no_detect_P1, no_detect_P2, no_detect_P3, no_detect_P4;
wire [`lzd_big_cancel_width:0] num_of_zeros_adder; // used in lzd component
wire large_normalization;
wire big_cancellation;
reg denormal_result;
reg denormalization_shift;

//--------------------------------------------------------------
// variables used for alignment of significand of small FP values
reg [((`precision)-1)-3:0] mask;
reg [((`precision)-1)-3:0] masked_op;
reg [((`precision)-1)-3:0] one_vector;
reg STK_1, STK_2, STK_3, STK_4;
reg STK_denorm;
reg cancel_STK_2,cancel_STK_3,cancel_STK_4;
reg [sig_width+2:0] mask2;
reg [sig_width+2:0] masked_op2;
reg [sig_width+2:0] one_vector2;

// Sorted values
wire [(2*sig_width+2)+`prod_exp_size:0] Max1L1,Max2L1,MaxL2,Min1L1,Min2L1,MinL2; 
// EQOpMaxProd is 1 when the two largest products have the same magnitude with
// opposite signs
// EQOpMinProd is 1 when the two smallest products have the same magnitude with
// opposite signs
// EQOpMidProd is 1 when the two middle products (in the sorted list) have the
// same magnitude with opposite signs
wire EQOpMaxProd, EQOpMinProd, EQOpMidProd;
wire [(2*sig_width+2)-1:0] M_1,M_2,M_3,M_4;   // Sorted mantissa vectors
wire S_1,S_2,S_3,S_4;          // sign bits
wire [`prod_exp_size-1:0] E_1,E_2,E_3,E_4; // Exponents
wire C0, C1, C2, C3, C4;  // state of maxmin blocks during sort

//--------------------------------------------------------------
// variables to indicate negation of adder inputs

reg inv_1, inv_2, inv_3;

//---------------------------------------------------------------
// The following portion of the code describes DW_fp_dp2 when
// arch_type = 1
//---------------------------------------------------------------


wire [sig_width+exp_width : 0] z_temp2;
wire [7 : 0] status_int2;

wire [sig_width+2+exp_width+6:0] ifpa;
wire [sig_width+2+exp_width+6:0] ifpb;
wire [sig_width+2+exp_width+6:0] ifpc; 
wire [sig_width+2+exp_width+6:0] ifpd;
wire [sig_width+2+exp_width+6:0] ifpe;
wire [sig_width+2+exp_width+6:0] ifpf;
wire [sig_width+2+exp_width+6:0] ifpg;
wire [sig_width+2+exp_width+6:0] ifph;
wire [2*(sig_width+2+1)+exp_width+1+6:0] ifp_p1; // partial products
wire [2*(sig_width+2+1)+exp_width+1+6:0] ifp_p2;
wire [2*(sig_width+2+1)+exp_width+1+6:0] ifp_p3; 
wire [2*(sig_width+2+1)+exp_width+1+6:0] ifp_p4;
wire [2*(sig_width+2+1)+1+exp_width+1+1+6:0] ifpadd1; // result of p1+p2
wire [2*(sig_width+2+1)+1+exp_width+1+1+6:0] ifpadd2; // result of p3+p4   
wire [2*(sig_width+2+1)+1+1+exp_width+1+1+1+6:0] ifpadd3; // result of padd1+padd2



  // Instances of DW_fp_ifp_conv  -- format converters
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U1 ( .a(a), .z(ifpa) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U2 ( .a(b), .z(ifpb) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U3 ( .a(c), .z(ifpc) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U4 ( .a(d), .z(ifpd) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U5 ( .a(e), .z(ifpe) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U6 ( .a(f), .z(ifpf) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U7 ( .a(g), .z(ifpg) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U8 ( .a(h), .z(ifph) );
  // Instances of DW_ifp_mult
    DW_ifp_mult #(sig_width+2, exp_width, 2*(sig_width+2+1), exp_width+1)
	  U9  ( .a(ifpa), .b(ifpb), .z(ifp_p1) );
    DW_ifp_mult #(sig_width+2, exp_width, 2*(sig_width+2+1), exp_width+1)
	  U10 ( .a(ifpc), .b(ifpd), .z(ifp_p2) );
    DW_ifp_mult #(sig_width+2, exp_width, 2*(sig_width+2+1), exp_width+1)
	  U11 ( .a(ifpe), .b(ifpf), .z(ifp_p3) );
    DW_ifp_mult #(sig_width+2, exp_width, 2*(sig_width+2+1), exp_width+1)
	  U12 ( .a(ifpg), .b(ifph), .z(ifp_p4) );
   // Instances of DW_ifp_addsub
    DW_ifp_addsub #(2*(sig_width+2+1), exp_width+1, 2*(sig_width+2+1)+1, exp_width+1+1, ieee_compliance)
	  U13 ( .a(ifp_p1), .b(ifp_p2), .op(1'b0), .rnd(rnd),
               .z(ifpadd1) );
    DW_ifp_addsub #(2*(sig_width+2+1), exp_width+1, 2*(sig_width+2+1)+1, exp_width+1+1, ieee_compliance)
	  U14 ( .a(ifp_p3), .b(ifp_p4), .op(1'b0), .rnd(rnd),
               .z(ifpadd2) );
    DW_ifp_addsub #(2*(sig_width+2+1)+1, exp_width+1+1, 2*(sig_width+2+1)+1+1, exp_width+1+1+1, ieee_compliance)
	  U15 ( .a(ifpadd1), .b(ifpadd2), .op(1'b0), .rnd(rnd),
               .z(ifpadd3) );
  // Instance of DW_ifp_fp_conv  -- format converter
    DW_ifp_fp_conv #(2*(sig_width+2+1)+1+1, exp_width+1+1+1, sig_width, exp_width, ieee_compliance)
          U16 ( .a(ifpadd3), .rnd(rnd), .z(z_temp2), .status(status_int2) );

//-------------------------------------------------------------------
// The following code is used to describe the DW_fp_dp2 component
// when arch_type = 0
//-------------------------------------------------------------------
// setup some of special variables...
assign NaNFp[sig_width+exp_width:1] = {1'b0,{exp_width{1'b1}},{sig_width-1{1'b0}}};
assign NaNFp[0] = (ieee_compliance == 1)?1'b1:1'b0;
assign z_inf_plus[(exp_width + sig_width)] = 1'b0;
assign z_inf_plus[((exp_width + sig_width) - 1):sig_width] = {exp_width{1'b1}};
assign z_inf_plus[(sig_width - 1):0] = {sig_width{1'b0}};
assign z_inf_minus[(exp_width + sig_width)] = 1'b1;
assign z_inf_minus[((exp_width + sig_width) - 1):sig_width] = {exp_width{1'b1}};
assign z_inf_minus[(sig_width - 1):0] = {sig_width{1'b0}};
assign z_large_plus[(exp_width + sig_width)] = 1'b0;
assign z_large_plus[((exp_width + sig_width) - 1):sig_width] = (({exp_width{1'b1}}>>1) << 1);
assign z_large_plus[(sig_width - 1):0] = {sig_width{1'b1}};
assign z_large_minus[(exp_width + sig_width)] = 1'b1;
assign z_large_minus[((exp_width + sig_width) - 1):sig_width] = (({exp_width{1'b1}}>>1) << 1);
assign z_large_minus[(sig_width - 1):0] = {sig_width{1'b1}};
assign zero_vec = {(`precision-(2*sig_width+2)-(3)){1'b0}};
assign pluszero = {(exp_width + sig_width + 1){1'b0}};
assign negzero = {1'b1,{exp_width+sig_width{1'b0}}};

// unpack input operands and analyze special cases
assign E_a_orig = a[((exp_width + sig_width) - 1):sig_width];
assign E_b_orig = b[((exp_width + sig_width) - 1):sig_width];
assign E_c_orig = c[((exp_width + sig_width) - 1):sig_width];
assign E_d_orig = d[((exp_width + sig_width) - 1):sig_width];
assign E_e_orig = e[((exp_width + sig_width) - 1):sig_width];
assign E_f_orig = f[((exp_width + sig_width) - 1):sig_width];
assign E_g_orig = g[((exp_width + sig_width) - 1):sig_width];
assign E_h_orig = h[((exp_width + sig_width) - 1):sig_width];
assign F_a_orig = a[(sig_width - 1):0];
assign F_b_orig = b[(sig_width - 1):0];
assign F_c_orig = c[(sig_width - 1):0];
assign F_d_orig = d[(sig_width - 1):0];
assign F_e_orig = e[(sig_width - 1):0];
assign F_f_orig = f[(sig_width - 1):0];
assign F_g_orig = g[(sig_width - 1):0];
assign F_h_orig = h[(sig_width - 1):0];
assign S_a = a[(exp_width + sig_width)];
assign S_b = b[(exp_width + sig_width)];
assign S_c = c[(exp_width + sig_width)]; 
assign S_d = d[(exp_width + sig_width)]; 
assign S_e = e[(exp_width + sig_width)]; 
assign S_f = f[(exp_width + sig_width)]; 
assign S_g = g[(exp_width + sig_width)];
assign S_h = h[(exp_width + sig_width)];

// analyze special input values
// infinities
assign inf_a = ((E_a_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_a_orig == 0)||(ieee_compliance == 0)));
assign inf_b = ((E_b_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_b_orig == 0)||(ieee_compliance == 0)));
assign inf_c = ((E_c_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_c_orig == 0)||(ieee_compliance == 0)));
assign inf_d = ((E_d_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_d_orig == 0)||(ieee_compliance == 0)));
assign inf_e = ((E_e_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_e_orig == 0)||(ieee_compliance == 0)));
assign inf_f = ((E_f_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_f_orig == 0)||(ieee_compliance == 0)));
assign inf_g = ((E_g_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_g_orig == 0)||(ieee_compliance == 0)));
assign inf_h = ((E_h_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_h_orig == 0)||(ieee_compliance == 0)));
// nan
assign nan_a = ((E_a_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_a_orig != 0)&&(ieee_compliance == 1));
assign nan_b = ((E_b_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_b_orig != 0)&&(ieee_compliance == 1));
assign nan_c = ((E_c_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_c_orig != 0)&&(ieee_compliance == 1));
assign nan_d = ((E_d_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_d_orig != 0)&&(ieee_compliance == 1));
assign nan_e = ((E_e_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_e_orig != 0)&&(ieee_compliance == 1));
assign nan_f = ((E_f_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_f_orig != 0)&&(ieee_compliance == 1));
assign nan_g = ((E_g_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_g_orig != 0)&&(ieee_compliance == 1));
assign nan_h = ((E_h_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_h_orig != 0)&&(ieee_compliance == 1));
// zeros
assign zer_a = ((E_a_orig == 0) && ((F_a_orig == 0) || (ieee_compliance == 0)));
assign zer_b = ((E_b_orig == 0) && ((F_b_orig == 0) || (ieee_compliance == 0)));
assign zer_c = ((E_c_orig == 0) && ((F_c_orig == 0) || (ieee_compliance == 0)));
assign zer_d = ((E_d_orig == 0) && ((F_d_orig == 0) || (ieee_compliance == 0)));
assign zer_e = ((E_e_orig == 0) && ((F_e_orig == 0) || (ieee_compliance == 0)));
assign zer_f = ((E_f_orig == 0) && ((F_f_orig == 0) || (ieee_compliance == 0)));
assign zer_g = ((E_g_orig == 0) && ((F_g_orig == 0) || (ieee_compliance == 0)));
assign zer_h = ((E_h_orig == 0) && ((F_h_orig == 0) || (ieee_compliance == 0)));
// denormals
assign denormal_a = ((E_a_orig == {exp_width{1'b0}}) && (F_a_orig != 0) && (ieee_compliance == 1));
assign denormal_b = ((E_b_orig == {exp_width{1'b0}}) && (F_b_orig != 0) && (ieee_compliance == 1));
assign denormal_c = ((E_c_orig == {exp_width{1'b0}}) && (F_c_orig != 0) && (ieee_compliance == 1));
assign denormal_d = ((E_d_orig == {exp_width{1'b0}}) && (F_d_orig != 0) && (ieee_compliance == 1));
assign denormal_e = ((E_e_orig == {exp_width{1'b0}}) && (F_e_orig != 0) && (ieee_compliance == 1));
assign denormal_f = ((E_f_orig == {exp_width{1'b0}}) && (F_f_orig != 0) && (ieee_compliance == 1));
assign denormal_g = ((E_g_orig == {exp_width{1'b0}}) && (F_g_orig != 0) && (ieee_compliance == 1));
assign denormal_h = ((E_h_orig == {exp_width{1'b0}}) && (F_h_orig != 0) && (ieee_compliance == 1));

// Correct exponent and significand values based on special cases
assign E_a = (denormal_a)?{{exp_width-1{1'b0}},1'b1}:E_a_orig;
assign E_b = (denormal_b)?{{exp_width-1{1'b0}},1'b1}:E_b_orig;
assign E_c = (denormal_c)?{{exp_width-1{1'b0}},1'b1}:E_c_orig;
assign E_d = (denormal_d)?{{exp_width-1{1'b0}},1'b1}:E_d_orig;
assign E_e = (denormal_e)?{{exp_width-1{1'b0}},1'b1}:E_e_orig;
assign E_f = (denormal_f)?{{exp_width-1{1'b0}},1'b1}:E_f_orig;
assign E_g = (denormal_g)?{{exp_width-1{1'b0}},1'b1}:E_g_orig;
assign E_h = (denormal_h)?{{exp_width-1{1'b0}},1'b1}:E_h_orig;
assign F_a = ((E_a == {exp_width{1'b0}}) && (F_a_orig != 0) && (ieee_compliance == 0))?
             {sig_width{1'b0}}:F_a_orig;
assign F_b = ((E_b == {exp_width{1'b0}}) && (F_b_orig != 0) && (ieee_compliance == 0))?
             {sig_width{1'b0}}:F_b_orig;
assign F_c = ((E_c == {exp_width{1'b0}}) && (F_c_orig != 0) && (ieee_compliance == 0))?
             {sig_width{1'b0}}:F_c_orig;
assign F_d = ((E_d == {exp_width{1'b0}}) && (F_d_orig != 0) && (ieee_compliance == 0))?
             {sig_width{1'b0}}:F_d_orig;
assign F_e = ((E_e == {exp_width{1'b0}}) && (F_e_orig != 0) && (ieee_compliance == 0))?
             {sig_width{1'b0}}:F_e_orig;
assign F_f = ((E_f == {exp_width{1'b0}}) && (F_f_orig != 0) && (ieee_compliance == 0))?
             {sig_width{1'b0}}:F_f_orig;
assign F_g = ((E_g == {exp_width{1'b0}}) && (F_g_orig != 0) && (ieee_compliance == 0))?
             {sig_width{1'b0}}:F_g_orig;
assign F_h = ((E_h == {exp_width{1'b0}}) && (F_h_orig != 0) && (ieee_compliance == 0))?
             {sig_width{1'b0}}:F_h_orig;
//------------------------------------------------------------------------
// Generate the mantissa values for main inputs
//
assign M_a = (denormal_a == 1 || zer_a == 1)?((ieee_compliance == 1)?
             {1'b0,F_a}:{sig_width+1{1'b0}}):{1'b1,F_a};
assign M_b = (denormal_b == 1 || zer_b == 1)?((ieee_compliance == 1)?
             {1'b0,F_b}:{sig_width+1{1'b0}}):{1'b1,F_b};
assign M_c = (denormal_c == 1 || zer_c == 1)?((ieee_compliance == 1)?
             {1'b0,F_c}:{sig_width+1{1'b0}}):{1'b1,F_c};
assign M_d = (denormal_d == 1 || zer_d == 1)?((ieee_compliance == 1)?
             {1'b0,F_d}:{sig_width+1{1'b0}}):{1'b1,F_d};
assign M_e = (denormal_e == 1 || zer_e == 1)?((ieee_compliance == 1)?
             {1'b0,F_e}:{sig_width+1{1'b0}}):{1'b1,F_e};
assign M_f = (denormal_f == 1 || zer_f == 1)?((ieee_compliance == 1)?
             {1'b0,F_f}:{sig_width+1{1'b0}}):{1'b1,F_f};
assign M_g = (denormal_g == 1 || zer_g == 1)?((ieee_compliance == 1)?
             {1'b0,F_g}:{sig_width+1{1'b0}}):{1'b1,F_g};
assign M_h = (denormal_h == 1 || zer_h == 1)?((ieee_compliance == 1)?
             {1'b0,F_h}:{sig_width+1{1'b0}}):{1'b1,F_h};

//------------------------------------------------------------------
//  compute the flags and fields for product terms
//
// For the case of ieee_compliance = 0 we have to consider that the
// internal product terms follow the same rules as the inputs: when
// the product is supposed to be nan, it is treated as infinity.
// Since the input conditions are processed for the case ieee_compliance
// = 0, the processing at this step is simplified.
//
assign nan_P1 = ((zer_a & inf_b) | (zer_b & inf_a) | nan_a | nan_b);
assign nan_P2 = ((zer_c & inf_d) | (zer_d & inf_c) | nan_c | nan_d);
assign nan_P3 = ((zer_e & inf_f) | (zer_f & inf_e) | nan_e | nan_f);
assign nan_P4 = ((zer_g & inf_h) | (zer_h & inf_g) | nan_g | nan_h);
assign inf_P1 = (inf_a & ~((nan_b | zer_b) & (ieee_compliance == 1))) | 
               (inf_b & ~((nan_a | zer_a) & (ieee_compliance == 1)));
assign inf_P2 = (inf_c & ~((nan_d | zer_d) & (ieee_compliance == 1))) | 
               (inf_d & ~((nan_c | zer_c) & (ieee_compliance == 1)));
assign inf_P3 = (inf_e & ~((nan_f | zer_f) & (ieee_compliance == 1))) | 
               (inf_f & ~((nan_e | zer_e) & (ieee_compliance == 1)));
assign inf_P4 = (inf_g & ~((nan_h | zer_h) & (ieee_compliance == 1))) | 
               (inf_h & ~((nan_g | zer_g) & (ieee_compliance == 1)));
// a product is considered zero when the exponent value goes negative
assign zer_P1 = (zer_a & ~(nan_b | inf_b)) | (zer_b & ~(nan_a | inf_a)) |
                no_detect_P1;
assign zer_P2 = (zer_c & ~(nan_d | inf_d)) | (zer_d & ~(nan_c | inf_c)) |
                no_detect_P2;
assign zer_P3 = (zer_e & ~(nan_f | inf_f)) | (zer_f & ~(nan_e | inf_e)) |
                no_detect_P3;
assign zer_P4 = (zer_g & ~(nan_h | inf_h)) | (zer_h & ~(nan_g | inf_g)) |
                no_detect_P4;
assign S_P1 = (S_a ^ S_b);
assign S_P2 = (S_c ^ S_d);
assign S_P3 = (S_e ^ S_f);
assign S_P4 = (S_g ^ S_h);
assign M_P1_d = M_a * M_b;
assign M_P2_d = M_c * M_d;
assign M_P3_d = M_e * M_f;
assign M_P4_d = M_g * M_h;
// the extra bias is used to reduce the chances of having negative
// exponents in this biased system after normalization. 
assign E_P1_d = (zer_a || zer_b)?2*sig_width+2:E_a + E_b + 2*sig_width+2;
assign E_P2_d = (zer_c || zer_d)?2*sig_width+2:E_c + E_d + 2*sig_width+2;
assign E_P3_d = (zer_e || zer_f)?2*sig_width+2:E_e + E_f + 2*sig_width+2;
assign E_P4_d = (zer_g || zer_h)?2*sig_width+2:E_g + E_h + 2*sig_width+2;

//-------------------------------------------------------------------
// Normalization of intermediate value
// 
// For this component we need to compare the intermediate value for
// two reasons:
// 1. detect the catastrophic cancellation of intermediate products
// 2. perform the appropriate operations on STK bits
// 
// The normalized value has always 2 integer bits.
DW_norm #((2*sig_width+2), (2*sig_width+2), `prod_exp_size, 1)
U17 ( .a(M_P1_d), .exp_offset(E_P1_d), .no_detect(no_detect_P1), 
      .ovfl(), .b(M_P1_raw), .exp_adj(E_P1_n) );
DW_norm #((2*sig_width+2), (2*sig_width+2), `prod_exp_size, 1)
U18 ( .a(M_P2_d), .exp_offset(E_P2_d), .no_detect(no_detect_P2), 
      .ovfl(), .b(M_P2_raw), .exp_adj(E_P2_n) );
DW_norm #((2*sig_width+2), (2*sig_width+2), `prod_exp_size, 1)
U19 ( .a(M_P3_d), .exp_offset(E_P3_d), .no_detect(no_detect_P3), 
      .ovfl(), .b(M_P3_raw), .exp_adj(E_P3_n) );
DW_norm #((2*sig_width+2), (2*sig_width+2), `prod_exp_size, 1)
U20 ( .a(M_P4_d), .exp_offset(E_P4_d), .no_detect(no_detect_P4), 
      .ovfl(), .b(M_P4_raw), .exp_adj(E_P4_n) );

//--------------------------------------------------------------------
// Filter the exponent values to account for negative values
//
assign E_P1_nf = (no_detect_P1==1)?{{exp_width-1{1'b0}},1'b1}:E_P1_n;
assign E_P2_nf = (no_detect_P2==1)?{{exp_width-1{1'b0}},1'b1}:E_P2_n;
assign E_P3_nf = (no_detect_P3==1)?{{exp_width-1{1'b0}},1'b1}:E_P3_n;
assign E_P4_nf = (no_detect_P4==1)?{{exp_width-1{1'b0}},1'b1}:E_P4_n;

//--------------------------------------------------------------------
//  Sort FP values, according to exponent and mantissas (magnitude)
//  Detect cancellation and eliminate equal products with opposite
//  signs.
//  Sorted values are (S_i,E_i,M_i) with i=1,2,3,4
assign {Max1L1,Min1L1,C0} = ({E_P1_nf,M_P1_raw} >= {E_P2_nf,M_P2_raw}) ? 
                    {{S_P1,E_P1_nf,M_P1_raw},{S_P2,E_P2_nf,M_P2_raw},1'b0}:
                    {{S_P2,E_P2_nf,M_P2_raw},{S_P1,E_P1_nf,M_P1_raw},1'b1};
assign {Max2L1,Min2L1,C1} = ({E_P3_nf,M_P3_raw} >= {E_P4_nf,M_P4_raw}) ? 
                    {{S_P3,E_P3_nf,M_P3_raw},{S_P4,E_P4_nf,M_P4_raw},1'b0}:
                    {{S_P4,E_P4_nf,M_P4_raw},{S_P3,E_P3_nf,M_P3_raw},1'b1};
assign {{S_1,E_1,M_1},MinL2,C2} = (Max1L1[(2*sig_width+2)+`prod_exp_size-1:0] >= 
                              Max2L1[(2*sig_width+2)+`prod_exp_size-1:0]) ?
                              {Max1L1,Max2L1,1'b0} : {Max2L1,Max1L1,1'b1};
assign {MaxL2,{S_4,E_4,M_4},C3} = (Min1L1[(2*sig_width+2)+`prod_exp_size-1:0] >= 
                              Min2L1[(2*sig_width+2)+`prod_exp_size-1:0]) ?
                              {Min1L1,Min2L1,1'b0} : {Min2L1,Min1L1,1'b1};
assign {{S_2,E_2,M_2},{S_3,E_3,M_3},C4} = (MinL2[(2*sig_width+2)+`prod_exp_size-1:0] >=
                                      MaxL2[(2*sig_width+2)+`prod_exp_size-1:0])? 
                                      {MinL2,MaxL2,1'b0}:{MaxL2,MinL2,1'b1};
assign EQOpMaxProd = ({~S_1,E_1,M_1}==MinL2)&~C4 | ({~S_1,E_1,M_1}==MaxL2)&C4;
assign EQOpMinProd = ({~S_4,E_4,M_4}==MinL2)&C4 | ({~S_4,E_4,M_4}==MaxL2)&~C4;
assign EQOpMidProd = ({MinL2[(2*sig_width+2)+`prod_exp_size],MinL2[(2*sig_width+2)+`prod_exp_size-1:0]} ==
                      {~MaxL2[(2*sig_width+2)+`prod_exp_size],MaxL2[(2*sig_width+2)+`prod_exp_size-1:0]});

//--------------------------------------------------------------------
// Compute the difference between sorted exponents before the 
// alignment is done.
// The largest products cancel each other...
// We are going to eliminate them during alignment
assign max_exp_i = (EQOpMaxProd)?E_3:E_1;
assign ediff_12 = max_exp_i - E_2;
assign ediff_13 = max_exp_i - E_3;
assign ediff_14 = max_exp_i - E_4;

//--------------------------------------------------------------------------------
// Shift mantissas to the right with sticky bit
// Process the sticky bits to be used during addition
// Cancel the mantissas that are equal with opposite signs.
always @ (ediff_12 or ediff_13 or ediff_14 or zero_vec or M_1 or M_2 or M_3 or M_4 or S_2 or S_3 or S_4 or C1 or C2 or C3 or C4 or EQOpMaxProd or EQOpMinProd or EQOpMidProd)
begin
  // eliminate the mantissa when there is cancellation between the two
  // largest products
  M_1_sh = (EQOpMaxProd)?0:{M_1,zero_vec};
  STK_1 = 1'b0;

  // eliminate the second largest mantissa when there is cancellation between the two
  // largest products, or there is a cancellation between the 2 middle products
  M_2_sh = (EQOpMaxProd | EQOpMidProd)?0:{M_2,zero_vec};
  M_2_sh = M_2_sh >> ediff_12;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << ediff_12);
  completely_shifted_out_2 = ~|M_2_sh[(`precision)-1-3:1];
  masked_op = mask & {M_2,zero_vec};
  STK_2 = (EQOpMaxProd | EQOpMidProd)?0:|masked_op;
  cancel_STK_2 = STK_2 & ~completely_shifted_out_2;
  M_2_sh[0] = M_2_sh[0] | STK_2;
  STK_2 = M_2_sh[0];
  M_2_sh[0] = M_2_sh[0] & ~cancel_STK_2;

  // eliminate the third largest mantissa when there is cancellation between the two
  // smallest products and not in the middle products  OR
  // the middle products are cancelled
  M_3_sh = ((EQOpMinProd & ~EQOpMidProd) | (EQOpMidProd & ~EQOpMaxProd))?0:{M_3,zero_vec};
  M_3_sh = M_3_sh >> ediff_13;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << ediff_13);
  completely_shifted_out_3 =  ~|M_3_sh[(`precision)-1-3:1];
  masked_op = mask & {M_3,zero_vec};
  STK_3 = ((EQOpMinProd & ~EQOpMidProd) | (EQOpMidProd & ~EQOpMaxProd))?0:|masked_op;
  cancel_STK_3 = cancel_STK_2 | STK_2;
  M_3_sh[0] = M_3_sh[0] | STK_3;
  STK_3 = M_3_sh[0];
  M_3_sh[0] = M_3_sh[0] & ~cancel_STK_3;

  // eliminate the smallest product when it is equivalent (opposite sign) with the 
  // third largest product and there was no elimination of middle products
  M_4_sh = (EQOpMinProd & ~EQOpMidProd)?0:{M_4,zero_vec};
  M_4_sh = M_4_sh >> ediff_14;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << ediff_14);
  masked_op = mask & {M_4,zero_vec};
  STK_4 = (EQOpMinProd & ~EQOpMidProd)?0:|masked_op;
  cancel_STK_4 = cancel_STK_2 | cancel_STK_3 | (STK_2 | STK_3);
  M_4_sh[0] = M_4_sh[0] | STK_4;
  STK_4 = M_4_sh[0];
  M_4_sh[0] = M_4_sh[0] & ~cancel_STK_4;

  // sticky bit of last aligned product after sorting
//  STK = C1&C2&STK_1 | (C1&~C2&~C4 | ~C1&C3&C4)&STK_2 | 
//        (C1&~C2&C4 | ~C1&C3&~C4)&STK_3 | ~C1&~C3&STK_4;
end

//-------------------------------------------------------------------
// Analyze the inputs and make decision about the output, if possible
//
always @ (nan_P1 or nan_P2 or nan_P3 or nan_P4 or inf_P1 or inf_P2 or inf_P3 
          or inf_P4 or S_P1 or S_P2 or S_P3 or S_P4 or NaNFp or zer_P1 
          or zer_P2 or zer_P3 or zer_P4 or rnd or z_inf_plus or z_inf_minus
          or inf_a or inf_b or inf_c or inf_d or inf_e or inf_f or inf_g 
          or inf_h or negzero or pluszero)
begin
  z_temp1 = 1'b0;
  status_int1 = 1'b0;
  output_defined_from_inp = 1'b1;
  // When one input is NaN, the output is NaN
  if ((nan_P1 == 1) || (nan_P2 == 1) || (nan_P3 == 1) || (nan_P4 == 1)) 
    begin
      z_temp1 = NaNFp;
      status_int1[2] = 1'b1;
      status_int1[1] = (ieee_compliance == 0);
    end

  // Zero Inputs
  // Zero inputs 
  else if ((zer_P1 == 1) && (zer_P2 == 1) && (zer_P3 == 1) && (zer_P4 == 1) && 
           (ieee_compliance == 1)) 
    begin
      if (S_P1 == S_P2 & S_P2 == S_P3 & S_P3 == S_P4)
        z_temp1 = {S_P1,{sig_width+exp_width{1'b0}}};
      else
        z_temp1 = (rnd == 3)?negzero:pluszero;
      status_int1[0] = 1'b1;
    end

  // when one of the inputs is infinity, the result is infinity,
  // unless we have -inf+inf, causing the output to be NaN
  else if (((inf_P1 == 1) && (inf_P2 == 1) && (S_P1 != S_P2)) ||
           ((inf_P1 == 1) && (inf_P3 == 1) && (S_P1 != S_P3)) ||
           ((inf_P1 == 1) && (inf_P4 == 1) && (S_P1 != S_P4)) ||
           ((inf_P2 == 1) && (inf_P3 == 1) && (S_P2 != S_P3)) ||
           ((inf_P2 == 1) && (inf_P4 == 1) && (S_P2 != S_P4)) ||
           ((inf_P3 == 1) && (inf_P4 == 1) && (S_P3 != S_P4)))
      begin // result is Not a number
        z_temp1 =NaNFp;
        status_int1[2] = 1'b1;
        status_int1[1] = (ieee_compliance == 0);
      end
  else if (inf_P1 == 1 || inf_P2 == 1 || inf_P3 == 1 || inf_P4 == 1) 
      begin
        // Infinity in this case can only happen when one of the 
        // inputs is infinity.
        status_int1[1] = 1'b1;
        z_temp1 = ((inf_P1 & S_P1)|(inf_P2 & S_P2)|(inf_P3 & S_P3)|
                   (inf_P4 & S_P4))?z_inf_minus:z_inf_plus;
      end

  else output_defined_from_inp = 1'b0;

end

//------------------------------------------------------------------------------
// addition of aligned significands
//
always @ (M_1_sh or M_2_sh or M_3_sh or M_4_sh or S_1 or S_2 or S_3 or S_4 or 
          big_cancellation or M_4 or zero_vec)
begin
    // Transform operands to two's complement form 
    // A good way to do that is to consider the sign of 
    // input 4 to be always positive, and we adjust the sign of the
    // others accordingly. 
    inv_1 = S_1 ^ S_4;
    inv_2 = S_2 ^ S_4;
    inv_3 = S_3 ^ S_4;
    adder_input4 = {3'b0, M_4_sh};
    if (inv_1 == 1'b1) 
      adder_input1 = ~{3'b0, M_1_sh};
    else
      adder_input1 = M_1_sh;
    if (inv_2 == 1'b1) 
      adder_input2 = ~{3'b0, M_2_sh};
    else
      adder_input2 = M_2_sh;
    if (inv_3 == 1'b1) 
      adder_input3 = ~{3'b0, M_3_sh};
    else
      adder_input3 = M_3_sh;

    // add the operands
    adder_output = adder_input1 + inv_1 + adder_input2 + inv_2 + 
                   adder_input3 + inv_3 + adder_input4;

    
    // Obtain the S&M format of the adder output
    // It depends on the sign of input 4.
    adder_output_sign = adder_output[((`precision)-1)] ^ S_4;
    if (adder_output[((`precision)-1)] == 1) 
      adder_output_mag = ~adder_output[((`precision)-1)-1:0]+1;
    else
      adder_output_mag = adder_output[((`precision)-1)-1:0];

end

assign adder_sign = (big_cancellation)?S_4:adder_output_sign;
assign adder_mag = (big_cancellation)?{M_4,zero_vec}:adder_output_mag;
assign max_exp = (big_cancellation)?E_4:max_exp_i;

//-------------------------------------------------------------------
//   Instance of Leading one detector used in the normalization 
//   and rounding procedure 
//
  DW_lzd #((`precision)-1) 
  U21 (.a (adder_mag), 
       .enc (num_of_zeros), .dec() );
  wire adder_output_is_zero;
  assign adder_output_is_zero = &num_of_zeros;

//--------------------------------------------------------------------
//  Compute the number of bits to be used in the normalization shift
//
always @ (num_of_zeros or max_exp or adder_output_is_zero)
begin
  // correct the number of zeros generated by DW_lzd
  // if the ieee_compliance is off, the number of zeros is used as 
  // detected.
  if (ieee_compliance == 0)
    begin
      shifting_distance = (adder_output_is_zero)?max_exp+2:num_of_zeros;
      denormal_result = 1'b0;
      denormalization_shift = 1'b0;
    end  
  else
    // Test the expected result exponent when denormals are allowed
    // and the adder output is normalized.
    // When max_exp + 3 - (({exp_width{1'b1}}>>1) + 2f + 2) - num_of_zeros < 1 the value is a 
    // denormal which translates to max_exp < ({exp_width{1'b1}}>>1) + 2f + num_of_zeros
    if (max_exp < (2*sig_width+({exp_width{1'b1}}>>1)+num_of_zeros))
      begin
        denormal_result = 1'b1;
        lp_shift_dist = 2*sig_width + ({exp_width{1'b1}}>>1) + num_of_zeros - max_exp;
        if (lp_shift_dist <= num_of_zeros)
          begin
            lp_shift_dist = num_of_zeros - lp_shift_dist;
            denormalization_shift = 1'b0;
          end
        else
          begin
            lp_shift_dist = lp_shift_dist - num_of_zeros;
            denormalization_shift = 1'b1;
          end
        if (lp_shift_dist >= (1<<(`DW_shift_width+1)))
          // the value exceeds the number that can fit in the shifting_distance
          // variable and has to be limited to the maximum value that the 
          // variable can store.
	  shifting_distance = {`DW_shift_width{1'b1}};
        else
          shifting_distance = lp_shift_dist;
      end
    else
      begin
        // the expected exponent is 1 or more, therefore, the expected
        // result is not a denormalized value
        denormal_result = 1'b0;
        denormalization_shift = 1'b0;
        // make sure that the normalization shift is going to be limited
        // to the amount that makes the exponent be at least 1
        // Thus max_exp+3 - num_of_zeros - (({exp_width{1'b1}}>>1) + 2f + 2) >= 1
        // which is equivalent to the following test:
        num_of_zeros_biased = {1'b0,num_of_zeros} + 2*sig_width - 1 + ({exp_width{1'b1}}>>1);
        if (max_exp > num_of_zeros_biased)
          // we can normalize using all the leading zeros
          shifting_distance = num_of_zeros;
        else
          // the shifting distance is limited to make the result exponent
          // become a value of 1
          shifting_distance = max_exp - 2*sig_width - ({exp_width{1'b1}}>>1);
      end
end

//----------------------------------------------------------------------
//   Perform normalization and rounding
//
//  This section of the code is a replica of the DW_norm_rnd code. The
//  objective of having it here is to tune up the implementation of the
//  component to the needs of the FP SUM4.
always @ (adder_mag or max_exp or adder_sign 
          or rnd or shifting_distance or STK_1 or STK_2 or STK_3 or STK_4 or
          denormalization_shift or denormal_result or big_cancellation or 
          E_4 or adder_output_is_zero)
begin
  a_mag = adder_mag[((`precision)-1)-1:0];
  sticky_bit = (big_cancellation)?|a_mag[((`precision)-1)-sig_width-4:0]:STK_1 | STK_2 | STK_3 | STK_4 | 
               ((denormalization_shift == 1) & |a_mag[((`precision)-1)-sig_width-4:0] & (ieee_compliance == 1));
  a_sign = adder_sign;
  // normalize or denormalize the adder output based on the 
  // limited shifting_distance variable and the test on the exponent
  // value.
  if (ieee_compliance == 1)
    begin
      if (denormalization_shift == 1)
        begin
          a_denorm = a_mag[((`precision)-1)-1:((`precision)-1)-sig_width-3];
          a_denorm = a_denorm >> shifting_distance;
          one_vector2 = ~$unsigned(0);
          mask2 = ~(one_vector2 << shifting_distance);
          masked_op2 = mask2 & a_mag[((`precision)-1)-1:((`precision)-1)-sig_width-3];
          STK_denorm = |masked_op2 & denormalization_shift;
        end
      else
        begin
          a_denorm = a_mag[((`precision)-1)-1:((`precision)-1)-sig_width-3];
          STK_denorm = 1'b0;
        end
    end
  else
    begin
      a_denorm = 0;
      STK_denorm = 1'b0;
    end
  // AFT 04/2012 : fix bug during normalization. The STK bit
  // is being shifted with the other bits, causing an improper
  // rounded result. For this fix we zero out the stick bit before
  // normalization
  a_norm = (denormalization_shift==1 && ieee_compliance==1)?
           {a_denorm,{((`precision)-1)-sig_width-3{1'b0}}}:
           {a_mag[((`precision)-1)-1:1],1'b0} << shifting_distance;
  // correct the exponent based on the shifting distance
  // Since the exponents up to now have 2Bias+(2*sig_width+2), we remove 
  // this bias from the value to get the required integer representation
  corrected_expo1 = (denormal_result==1 && ieee_compliance==1)? 1:
                    (adder_output_is_zero)?0:
                    max_exp-$unsigned(shifting_distance)-(({exp_width{1'b1}}>>1)+2*sig_width+2)+3;
  corrected_expo2 = (denormal_result==1 && ieee_compliance==1)? 1:
                    corrected_expo1 + 1;
  // if any other bits are left in the LS bit positions after 
  // normalization/denormalization, combine then with the sticky bit.
  T =  sticky_bit |  (|a_norm[((`precision)-1)-sig_width-3:0]) | STK_denorm;
  R_bit = a_norm[((`precision)-1)-sig_width-2]; 
  L_bit = a_norm[((`precision)-1)-sig_width-1];
  rnd_incr =   (rnd == 3'd0) ? R_bit && (L_bit || T) :   
               (rnd == 3'd1) ? 1'b0 :    
               (rnd == 3'd2) ? !a_sign && (R_bit || T) :
               (rnd == 3'd3) ? a_sign && (R_bit || T) :
               (rnd == 3'd4) ? R_bit :
               (rnd == 3'd5) ? R_bit || T : 1'b0;
  a_rounded = {1'b0, a_norm[((`precision)-1)-1:((`precision)-1)-sig_width-1]} + rnd_incr;
  // detects the special case of post-normalization and generate outputs
  post_rounding_normalization = a_rounded[sig_width+1];
  significand_z = (post_rounding_normalization == 1'b0)? 
                  a_rounded[sig_width:0]:{1'b1, {sig_width{1'b0}}};
  corrected_expo = (post_rounding_normalization == 1'b1)? 
                  corrected_expo2 : corrected_expo1;
  pos_err =  corrected_expo[`prod_exp_size-1]; // exponent became negative
  large_input_exp = |corrected_expo[`prod_exp_size-2:exp_width] & ~pos_err;
  exponent_z = (pos_err)?0:corrected_expo[exp_width-1:0];
  no_MS1_detection = ~(|a_rounded[sig_width+1:sig_width]);
  // special case - exponent is still too large after normalization
  if (large_input_exp == 1)
    begin
      exponent_z = ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1});
      inexact = 1'b1;
    end
  else
    inexact = R_bit | T;
end

//-------------------------------------------------------------------
//   Instance of Leading one detector used in the special case of
//   operand cancellation (3 of the larger products are cancelling
//   each other)
//
// AFT - 04/2012 - reduced the range used for test of zeros, when
// detecting the big cancellation. This way we avoid checking positions
// where the fourth product may be, especially if the fourth product
// is partially in the adder range.
  DW_lzd #((`precision)-1-(sig_width+5)) 
  U22 (.a (adder_output_mag[((`precision)-1)-1:sig_width+5]), 
       .enc (num_of_zeros_adder), .dec() );
  assign large_normalization = &num_of_zeros_adder;
  assign big_cancellation = large_normalization & STK_4;

//----------------------------------------------------------------
// Handle exceptions and output generation
//
always @ (significand_z or exponent_z or no_MS1_detection or rnd or 
          status_int1 or z_temp1 or output_defined_from_inp or 
          adder_sign or pos_err or z_inf_minus or z_inf_plus or 
          z_large_minus or z_large_plus or inexact)
begin
   status_int = 0;
   // check if the input values already defined the output 
   if (output_defined_from_inp == 1) 
     begin
       z_temp = z_temp1;
       status_int = status_int1;
     end
   else
    // The output may also become an infinity value as a result of addition the
    // test on pos_err is done to avoid the case when the exponent reaches a
    // all-one vector decrementing the exponent offset provided as input.
    if (pos_err==0 && exponent_z==((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))
      // actual result depends on rounding mode
      begin
        case (rnd)
          0,4,5:                    // RNE, up, away
            begin 
              if (adder_sign==1'b1) z_temp = z_inf_minus;
              else              z_temp = z_inf_plus;
              status_int[1] = 1'b1;       
            end
          1:                    // toward zero
            if (adder_sign==1'b1) z_temp = z_large_minus;
            else              z_temp = z_large_plus;
          2:                    // toward +inf
            if (adder_sign==1'b1) z_temp = z_large_minus;
            else 
              begin
                z_temp = z_inf_plus;
                status_int[1] = 1'b1;  
              end
          3:                    // toward -inf
            if (adder_sign==1'b1) 
              begin
                z_temp = z_inf_minus;
                status_int[1] = 1'b1;  
              end
            else              z_temp = z_large_plus;
          default: z_temp = 0;
        endcase
        status_int[4] = 1'b1;       
        status_int[5] = 1'b1;       
      end
    else
      if ( no_MS1_detection == 1'b1 && significand_z != 0 )
        begin
          int_exponent = {exp_width{1'b0}};
          if ( ieee_compliance == 1)
            begin
              z_temp = {adder_sign, int_exponent, significand_z[(sig_width - 1):0]};
              status_int[5] = inexact;       
            end
          else
           if ((rnd == 3 && adder_sign == 1) ||
               (rnd == 2 && adder_sign == 0) ||
               rnd == 5)
             begin  // use minimum FP value
               z_temp = {adder_sign, {exp_width-1{1'b0}}, 1'b1,{sig_width{1'b0}}};
               status_int[0] = 1'b0;
               status_int[5] = 1'b1;       
             end
           else
             begin
               z_temp = {adder_sign, {exp_width+sig_width{1'b0}}};
               status_int[0] = 1'b1;
               status_int[5] = 1'b1;       
             end
          status_int[3] = 1'b1; 
        end
    else 
      if (no_MS1_detection == 1'b0 && (pos_err ==1'b1 || exponent_z == 0) && 
          ieee_compliance == 0)
        begin
           if ((rnd == 3 && adder_sign == 1) ||
               (rnd == 2 && adder_sign == 0) ||
               rnd == 5)
             begin  // use minimum FP value
               z_temp = {adder_sign, {exp_width-1{1'b0}}, 1'b1,{sig_width{1'b0}}};
               status_int[0] = 1'b0;
             end
           else
             begin
               z_temp = {adder_sign, {exp_width+sig_width{1'b0}}};
               status_int[0] = 1'b1;
             end
          status_int[3] = 1'b1; 
          status_int[5] = 1'b1;       
      end
    else
     if (no_MS1_detection == 1'b1)
     // Normalization was not possible. 
       begin    
         status_int[0] = 1'b1;
         status_int[3] = inexact; 
         status_int[5] = inexact;       
         if (ieee_compliance == 0)
           begin
             if (rnd == 3) 
               z_temp = {1'b1, {exp_width+sig_width{1'b0}}};
             else
               z_temp = {1'b0, {exp_width+sig_width{1'b0}}};
           end
         else
           begin
             if (status_int[5])
               // use the sign of the result
               z_temp = {adder_sign, {exp_width+sig_width{1'b0}}};
             else // the result is an exact zero
               if (rnd == 3)
                 z_temp = {1'b1, {exp_width+sig_width{1'b0}}};
               else
                 z_temp = {1'b0, {exp_width+sig_width{1'b0}}};
           end
       end
    else     
      begin
         //
         // Reconstruct the floating point format.
          status_int[5] = inexact;       
          z_temp = {adder_sign, exponent_z[exp_width-1:0], significand_z[sig_width-1:0]};
       end 

end

assign status = (arch_type == 1)?status_int2:status_int;
assign z = (arch_type == 1)?z_temp2:z_temp;
  
`undef  DW_shift_width
`undef  lzd_big_cancel_width 
`undef  d
`undef  log_d
`undef  precision

endmodule
