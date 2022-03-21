
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT: Floating-point Three-term Dot-product
//           Computes the sum of products of FP numbers. For this component,
//           three products are considered. Given the FP inputs a, b, c, d, e
//           and f, it computes the FP output z = a*b + c*d + e*f. 
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
//              sig_width       significand f,  2 to 253 bits
//              exp_width       exponent e,     3 to 31 bits
//              ieee_compliance 0 or 1 (default 1)
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
//              rnd             3 bits
//                              rounding mode
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_width + exp_width + 1) bits
//                              Floating-point Number result that corresponds
//                              to a*b+c*d+e*f
//              status          byte
//                              info about FP results
//
// MODIFIED: Detection of catastrophic cancellation modified the adder output
//           Internal precision incremented (based on the Formality test)
//           Tuned QoR
//           Includes rounding mode in the detection of internal infinities
//           11/2007 AFT Fixed bug for the case when products are equal with 
//                       different sign (product cancellation). The STK bit was
//                       being incorrectly computed in this case, creating a 
//                       wrong inexact flag.
//           11/2007 AFT Fix the sign of zeros. (A-SP1)
//           04/20/08 AFT: included a new parameter (arch_type) to control
//                    the use of alternative architecture with IFP blocks
//           04/21/08 AFT: fixed some cases when the infinity status bit 
//                    should be set with invalid bit (ieee_compliance = 0)
//           1/2009 AFT - extended the coverage of arch_type to include the
//                  case when ieee_compliance = 1
//           2/2009 AFT - modified the code slightly to reduce lint messages.
//           5/2009 AFT - fixed a bug in the manipulation of sticky bits
//           10/2011 AFT - the code was not correctly adjusting the shifting
//                   distance for normalization when the expected_exponent_plus3
//                   variable has a small size. A temporary calculation is having
//                   an overflow when the num_of_zeros for normalization is very
//                   large, and the wrong decision is made to use the very large
//                   num_of_zeros as the shifting distance, causing overflow on 
//                   exponents. Althought the output of the adder is zero, the 
//                   large exponent is considered an infinity case.
//           04/2012 AFT - inexact bit was not being set when the output was
//                   rounded to MinNorm and ieee_compliance=0. This problem was
//                   only affecting the rounding modes 2, 3 and 5.
//
//-------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_fp_dp3 (

                   a,
                   b,
                   c,
                   d,
                   e,
                   f,
                   rnd,
                   z,
                   status

    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

parameter sig_width    = 23;     // RANGE 2 to 253 bits
parameter exp_width    = 8;      // RANGE 3 to 31 bits
parameter ieee_compliance = 0;   // RANGE 0 or 1
parameter arch_type = 0;         // RANGE 0 or 1
parameter adj_prec = 0;


input [sig_width+exp_width : 0] a;
input [sig_width+exp_width : 0] b;
input [sig_width+exp_width : 0] c;
input [sig_width+exp_width : 0] d;
input [sig_width+exp_width : 0] e;
input [sig_width+exp_width : 0] f;
input [2 : 0] rnd;
output [sig_width+exp_width : 0] z;
output [8    -1 : 0] status;

`define DW_shift_width  ((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>256)?((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>4096)?((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>16384)?((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>32768)?16:15):((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>8192)?14:13)):((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>1024)?((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>2048)?12:11):((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>512)?10:9))):((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>16)?((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>64)?((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>128)?8:7):((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>32)?6:5)):((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>4)?((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>8)?4:3):((((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1>2)?2:1))))

reg [8    -1:0] status_int;
wire [8    -1:0] status_int1;
reg [(exp_width + sig_width):0] z_temp;
wire [(exp_width + sig_width):0] z_temp1;
wire output_defined_from_inp;
wire S_a,S_b,S_c,S_d,S_e,S_f;
wire [exp_width-1:0] E_a,E_b,E_c,E_d,E_e,E_f;
wire [sig_width-1:0] F_a,F_b,F_c,F_d,F_e,F_f;
wire [sig_width:0] M_a,M_b,M_c,M_d,M_e,M_f;
wire [exp_width-1:0] E_a_orig,E_b_orig,E_c_orig,E_d_orig,E_e_orig,E_f_orig;

wire S_1,S_2,S_3;
wire [(exp_width+3)-1:0] E_1,E_2,E_3;
wire [(2*sig_width+2)-1:0] M_1_d, M_2_d, M_3_d;
wire [(exp_width+3)-1:0] E_1_d,E_2_d,E_3_d;
wire [(exp_width+3)-1:0] E_1_n,E_2_n,E_3_n;
wire [(2*sig_width+2)-1:0] M_1, M_2, M_3;
wire [(2*sig_width+2)-1:0] M_1_raw, M_2_raw, M_3_raw;
reg [(2*sig_width+2)+(2*sig_width+3+adj_prec)-1:0] M_1_sh, M_2_sh, M_3_sh;

wire [(exp_width+3)-1:0] max_exp_intermediate;
wire [(exp_width+3)-1:0] max_exp;
wire [(exp_width+3)-1:0] max_exp_plus3;
reg [(exp_width+3)-1:0] expected_exponent_plus3;
wire [(exp_width+3)-1:0] ediff_1, ediff_2, ediff_3;

wire [(exp_width + sig_width):0] NaNFp;

wire denormal_a, denormal_b, denormal_c, denormal_d, denormal_e, denormal_f;
wire inf_a, inf_b, inf_c, inf_d, inf_e, inf_f;
wire nan_a, nan_b, nan_c, nan_d, nan_e, nan_f;
wire zer_a, zer_b, zer_c, zer_d, zer_e, zer_f;
wire inf_1, inf_2, inf_3;
wire nan_1, nan_2, nan_3;
wire zer_1, zer_2, zer_3;
wire cancel_1, cancel_2, cancel_3;
wire nan_addition, inf_addition, zer_addition;
wire inf_add_sign;

wire [(exp_width + sig_width + 1)-1:0] z_inf_plus;
wire [(exp_width + sig_width + 1)-1:0] z_inf_minus;
wire [(exp_width + sig_width + 1)-1:0] z_large_plus;
wire [(exp_width + sig_width + 1)-1:0] z_large_minus;
wire [(exp_width + sig_width + 1)-1:0] zero_out;

reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1):0] adder_input1, adder_input2, adder_input3; 
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1):0] adder_output; 
reg adder_output_sign;
reg result_sign;
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0] adder_output_mag; 
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0] norm_input; 
reg [exp_width-1:0] int_exponent;
wire EQ12, EQ13, EQ23;
wire All_Equal;

reg [(exp_width+3)-1:0] corrected_expo1;
reg [(exp_width+3)-1:0] corrected_expo2;
reg [(exp_width+3)-1:0] corrected_expo;
reg post_rounding_normalization;
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0] a_mag;
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0] one_vector2;
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0] masked_op2;
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0] mask2;
reg [(exp_width+3)-1:0] pos_offset;
reg sticky_bit, T, Rbit, Lbit;
reg STK_denorm;
reg inexact;
reg pos_err;
wire [`DW_shift_width:0] num_of_zeros;
reg [`DW_shift_width+1:0] num_of_zeros_biased;
reg [`DW_shift_width:0] shifting_distance;
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0] a_norm;
reg a_sign;
reg rnd_incr;
reg [sig_width+1:0] a_rounded;
reg no_MS1_detection;
reg [sig_width:0] significand_z;
reg [exp_width-1:0] exponent_z;
reg denormal_result;
reg large_input_exp;
wire no_detect_1, no_detect_2, no_detect_3;

reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-3:0] mask;
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-3:0] masked_op;
reg [(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-3:0] one_vector;
reg STK_1, STK_2, STK_3;
reg STK_1_add, STK_2_add,STK_3_add;

reg inv_1, inv_2;


wire [sig_width+exp_width : 0] z_temp2;
wire [7 : 0] status_int2;

wire [sig_width+2+exp_width+6:0] ifpa;
wire [sig_width+2+exp_width+6:0] ifpb;
wire [sig_width+2+exp_width+6:0] ifpc; 
wire [sig_width+2+exp_width+6:0] ifpd;
wire [sig_width+2+exp_width+6:0] ifpe;
wire [sig_width+2+exp_width+6:0] ifpf;
wire [2*(sig_width+2+1)+exp_width+1+6:0] ifp_p1;
wire [2*(sig_width+2+1)+exp_width+1+6:0] ifp_p2;
wire [2*(sig_width+2+1)+1+exp_width+1+1+6:0] ifp_p3;
wire [2*(sig_width+2+1)+1+exp_width+1+1+6:0] ifpadd1;
wire [2*(sig_width+2+1)+1+1+exp_width+1+1+1+6:0] ifpadd2;



    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U5 ( .a(a), .z(ifpa) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U6 ( .a(b), .z(ifpb) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U7 ( .a(c), .z(ifpc) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U8 ( .a(d), .z(ifpd) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U9 ( .a(e), .z(ifpe) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U10 ( .a(f), .z(ifpf) );
    DW_ifp_mult #(sig_width+2, exp_width, 2*(sig_width+2+1), exp_width+1)
	  U11 ( .a(ifpa), .b(ifpb), .z(ifp_p1) );
    DW_ifp_mult #(sig_width+2, exp_width, 2*(sig_width+2+1), exp_width+1)
	  U12 ( .a(ifpc), .b(ifpd), .z(ifp_p2) );
    DW_ifp_mult #(sig_width+2, exp_width, 2*(sig_width+2+1)+1, exp_width+1+1)
	  U13 ( .a(ifpe), .b(ifpf), .z(ifp_p3) );
    DW_ifp_addsub #(2*(sig_width+2+1), exp_width+1, 2*(sig_width+2+1)+1, exp_width+1+1, ieee_compliance)
	  U14 ( .a(ifp_p1), .b(ifp_p2), .op(1'b0), .rnd(rnd),
               .z(ifpadd1) );
    DW_ifp_addsub #(2*(sig_width+2+1)+1, exp_width+1+1, 2*(sig_width+2+1)+1+1, exp_width+1+1+1, ieee_compliance)
	  U15 ( .a(ifpadd1), .b(ifp_p3), .op(1'b0), .rnd(rnd),
               .z(ifpadd2) );
    DW_ifp_fp_conv #(2*(sig_width+2+1)+1+1, exp_width+1+1+1, sig_width, exp_width, ieee_compliance)
          U16 ( .a(ifpadd2), .rnd(rnd), .z(z_temp2), .status(status_int2) );

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

  assign E_a_orig = a[((exp_width + sig_width) - 1):sig_width];
  assign E_b_orig = b[((exp_width + sig_width) - 1):sig_width];
  assign E_c_orig = c[((exp_width + sig_width) - 1):sig_width];
  assign E_d_orig = d[((exp_width + sig_width) - 1):sig_width];
  assign E_e_orig = e[((exp_width + sig_width) - 1):sig_width];
  assign E_f_orig = f[((exp_width + sig_width) - 1):sig_width];
  assign F_a = a[(sig_width - 1):0];
  assign F_b = b[(sig_width - 1):0];
  assign F_c = c[(sig_width - 1):0];
  assign F_d = d[(sig_width - 1):0];
  assign F_e = e[(sig_width - 1):0];
  assign F_f = f[(sig_width - 1):0];
  assign S_a = a[(exp_width + sig_width)];
  assign S_b = b[(exp_width + sig_width)];
  assign S_c = c[(exp_width + sig_width)];
  assign S_d = d[(exp_width + sig_width)];
  assign S_e = e[(exp_width + sig_width)]; 
  assign S_f = f[(exp_width + sig_width)]; 

  assign inf_a = ((E_a_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_a == 0)||(ieee_compliance == 0)));
  assign inf_b = ((E_b_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_b == 0)||(ieee_compliance == 0)));
  assign inf_c = ((E_c_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_c == 0)||(ieee_compliance == 0)));
  assign inf_d = ((E_d_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_d == 0)||(ieee_compliance == 0)));
  assign inf_e = ((E_e_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_e == 0)||(ieee_compliance == 0)));
  assign inf_f = ((E_f_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&((F_f == 0)||(ieee_compliance == 0)));

  assign nan_a = ((E_a_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_a != 0)&&(ieee_compliance == 1));
  assign nan_b = ((E_b_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_b != 0)&&(ieee_compliance == 1));
  assign nan_c = ((E_c_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_c != 0)&&(ieee_compliance == 1));
  assign nan_d = ((E_d_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_d != 0)&&(ieee_compliance == 1));
  assign nan_e = ((E_e_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_e != 0)&&(ieee_compliance == 1));
  assign nan_f = ((E_f_orig == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))&&(F_f != 0)&&(ieee_compliance == 1));

  assign zer_a = ((E_a_orig == 0) && ((F_a == 0) || (ieee_compliance == 0)));
  assign zer_b = ((E_b_orig == 0) && ((F_b == 0) || (ieee_compliance == 0)));
  assign zer_c = ((E_c_orig == 0) && ((F_c == 0) || (ieee_compliance == 0)));
  assign zer_d = ((E_d_orig == 0) && ((F_d == 0) || (ieee_compliance == 0)));
  assign zer_e = ((E_e_orig == 0) && ((F_e == 0) || (ieee_compliance == 0)));
  assign zer_f = ((E_f_orig == 0) && ((F_f == 0) || (ieee_compliance == 0)));

  assign denormal_a = ((E_a_orig == 0) & (F_a != 0) & (ieee_compliance == 1)); 
  assign denormal_b = ((E_b_orig == 0) & (F_b != 0) & (ieee_compliance == 1)); 
  assign denormal_c = ((E_c_orig == 0) & (F_c != 0) & (ieee_compliance == 1)); 
  assign denormal_d = ((E_d_orig == 0) & (F_d != 0) & (ieee_compliance == 1)); 
  assign denormal_e = ((E_e_orig == 0) & (F_e != 0) & (ieee_compliance == 1)); 
  assign denormal_f = ((E_f_orig == 0) & (F_f != 0) & (ieee_compliance == 1)); 

  assign M_a = (E_a_orig == 0 & ~denormal_a)?{sig_width+1{1'b0}}:{~denormal_a,F_a};
  assign E_a = (denormal_a)?{{exp_width-1{1'b0}},1'b1}:E_a_orig;
  assign M_b = (E_b_orig == 0 & ~denormal_b)?{sig_width+1{1'b0}}:{~denormal_b,F_b};
  assign E_b = (denormal_b)?{{exp_width-1{1'b0}},1'b1}:E_b_orig;
  assign M_c = (E_c_orig == 0 & ~denormal_c)?{sig_width+1{1'b0}}:{~denormal_c,F_c};
  assign E_c = (denormal_c)?{{exp_width-1{1'b0}},1'b1}:E_c_orig;
  assign M_d = (E_d_orig == 0 & ~denormal_d)?{sig_width+1{1'b0}}:{~denormal_d,F_d};
  assign E_d = (denormal_d)?{{exp_width-1{1'b0}},1'b1}:E_d_orig;
  assign M_e = (E_e_orig == 0 & ~denormal_e)?{sig_width+1{1'b0}}:{~denormal_e,F_e};
  assign E_e = (denormal_e)?{{exp_width-1{1'b0}},1'b1}:E_e_orig;
  assign M_f = (E_f_orig == 0 & ~denormal_f)?{sig_width+1{1'b0}}:{~denormal_f,F_f};
  assign E_f = (denormal_f)?{{exp_width-1{1'b0}},1'b1}:E_f_orig;

  assign nan_1 = ((zer_a & inf_b) | (zer_b & inf_a) | nan_a | nan_b);
  assign nan_2 = ((zer_c & inf_d) | (zer_d & inf_c) | nan_c | nan_d);
  assign nan_3 = ((zer_e & inf_f) | (zer_f & inf_e) | nan_e | nan_f);
  assign inf_1 = (inf_a & ~((nan_b | zer_b) & (ieee_compliance == 1))) | 
                 (inf_b & ~((nan_a | zer_a) & (ieee_compliance == 1)));
  assign inf_2 = (inf_c & ~((nan_d | zer_d) & (ieee_compliance == 1))) | 
                 (inf_d & ~((nan_c | zer_c) & (ieee_compliance == 1)));
  assign inf_3 = (inf_e & ~((nan_f | zer_f) & (ieee_compliance == 1))) | 
                 (inf_f & ~((nan_e | zer_e) & (ieee_compliance == 1)));
  assign zer_1 = (zer_a & ~(nan_b | inf_b)) | (zer_b & ~(nan_a | inf_a));
  assign zer_2 = (zer_c & ~(nan_d | inf_d)) | (zer_d & ~(nan_c | inf_c));
  assign zer_3 = (zer_e & ~(nan_f | inf_f)) | (zer_f & ~(nan_e | inf_e));
  assign S_1 = S_a ^ S_b;
  assign S_2 = S_c ^ S_d;
  assign S_3 = S_e ^ S_f;
  assign M_1_d = M_a * M_b;
  assign M_2_d = M_c * M_d;
  assign M_3_d = M_e * M_f;
  assign E_1_d = (zer_a || zer_b)?{{exp_width-1{1'b0}},1'b1}:E_a + E_b;
  assign E_2_d = (zer_c || zer_d)?{{exp_width-1{1'b0}},1'b1}:E_c + E_d;
  assign E_3_d = (zer_e || zer_f)?{{exp_width-1{1'b0}},1'b1}:E_e + E_f;

DW_norm #((2*sig_width+2), (2*sig_width+2), (exp_width+3), 1)
U1 ( .a(M_1_d), .exp_offset(E_1_d), .no_detect(no_detect_1), 
     .ovfl(), .b(M_1_raw), .exp_adj(E_1_n) );
DW_norm #((2*sig_width+2), (2*sig_width+2), (exp_width+3), 1)
U2 ( .a(M_2_d), .exp_offset(E_2_d), .no_detect(no_detect_2), 
     .ovfl(), .b(M_2_raw), .exp_adj(E_2_n) );
DW_norm #((2*sig_width+2), (2*sig_width+2), (exp_width+3), 1)
U3 ( .a(M_3_d), .exp_offset(E_3_d), .no_detect(no_detect_3), 
     .ovfl(), .b(M_3_raw), .exp_adj(E_3_n) );

  assign EQ12 = ({E_1_n,M_1_raw} == {E_2_n,M_2_raw});
  assign EQ13 = ({E_1_n,M_1_raw} == {E_3_n,M_3_raw});
  assign EQ23 = ({E_2_n,M_2_raw} == {E_3_n,M_3_raw});
  assign All_Equal = EQ12 & EQ13 & EQ23;
  assign cancel_1 = (EQ12&(S_1^S_2)&~All_Equal) | (EQ13&(S_1^S_3)&~All_Equal);
  assign cancel_2 = (EQ12&(S_1^S_2)&~All_Equal) | (EQ23&(S_2^S_3)&~All_Equal);
  assign cancel_3 = (EQ13&(S_1^S_3)&~All_Equal) | (EQ23&(S_2^S_3)&~All_Equal);
  assign M_1 = cancel_1?{(2*sig_width+2){1'b0}}:M_1_d;
  assign M_2 = cancel_2?{(2*sig_width+2){1'b0}}:M_2_d;
  assign M_3 = cancel_3?{(2*sig_width+2){1'b0}}:M_3_d;
  assign E_1 = cancel_1?{(exp_width+3){1'b0}}:E_1_d;
  assign E_2 = cancel_2?{(exp_width+3){1'b0}}:E_2_d;
  assign E_3 = cancel_3?{(exp_width+3){1'b0}}:E_3_d;

  assign nan_addition = (inf_1 & inf_2 & (S_1 ^ S_2)) |
                        (inf_2 & inf_3 & (S_2 ^ S_3)) |
                        (inf_1 & inf_3 & (S_1 ^ S_3)) |
                        (nan_1 | nan_2 | nan_3);
  assign inf_addition = ~nan_addition & (inf_1 | inf_2 | inf_3);
  assign zer_addition = zer_1 & zer_2 & zer_3;
  assign inf_add_sign = inf_addition & ((inf_1 & S_1) | (inf_2 & S_2) | 
                        (inf_3 & S_3));
  assign zero_out = (ieee_compliance == 1)?
                       (((S_1 == S_2) && (S_2 == S_3))?
                                 ({S_1,{sig_width+exp_width{1'b0}}}):
                                 ((rnd == 3)?{1'b1,{sig_width+exp_width{1'b0}}}:{(exp_width + sig_width + 1){1'b0}})):
                       ((rnd == 3)?{1'b1,{sig_width+exp_width{1'b0}}}:{(exp_width + sig_width + 1){1'b0}});
  assign z_temp1 = nan_addition?NaNFp:
                   (inf_addition?(inf_add_sign?z_inf_minus:z_inf_plus):
                    (zer_addition?zero_out:{(exp_width + sig_width + 1){1'b0}}));
  assign status_int1[0] = zer_addition;
  assign status_int1[1] = inf_addition | 
                                         (nan_addition & ieee_compliance == 0);
  assign status_int1[2] = nan_addition;
  assign status_int1[3] = 1'b0;
  assign status_int1[4] = status_int1[5];
  assign status_int1[5] = inf_addition & ~(inf_a | inf_b | inf_c | inf_d | inf_e | inf_f);
  assign status_int1[6] = 1'b0;
  assign status_int1[7] = 1'b0;
  assign output_defined_from_inp = nan_addition | inf_addition | zer_addition;

  assign max_exp_intermediate = ((E_1 >= E_2) && (E_1 >= E_3))?E_1:
                                (((E_2 >= E_1) && (E_2 >= E_3))?E_2:E_3); 
  assign ediff_1 = max_exp_intermediate - E_1;
  assign ediff_2 = max_exp_intermediate - E_2;
  assign ediff_3 = max_exp_intermediate - E_3;
  assign max_exp = max_exp_intermediate;
  assign max_exp_plus3 = max_exp + {{(exp_width+3)-2{1'b0}},2'b11};

always @ (ediff_1 or ediff_2 or ediff_3 or M_1 or M_2 or M_3 or E_1_n or E_2_n or E_3_n or M_1_raw or M_2_raw or M_3_raw)
begin
  M_1_sh = {M_1,{(2*sig_width+3+adj_prec){1'b0}}};
  M_1_sh = M_1_sh >> ediff_1;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << ediff_1);
  masked_op = mask & {M_1,{(2*sig_width+3+adj_prec){1'b0}}};
  STK_1 = |masked_op;
  STK_1_add = STK_1 | M_1_sh[0];  

  M_2_sh = {M_2,{(2*sig_width+3+adj_prec){1'b0}}};
  M_2_sh = M_2_sh >> ediff_2;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << ediff_2);
  masked_op = mask & {M_2,{(2*sig_width+3+adj_prec){1'b0}}};
  STK_2 = |masked_op;
  STK_2_add = STK_2 | M_2_sh[0];  

  M_3_sh = {M_3,{(2*sig_width+3+adj_prec){1'b0}}};
  M_3_sh = M_3_sh >> ediff_3;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << ediff_3);
  masked_op = mask & {M_3,{(2*sig_width+3+adj_prec){1'b0}}};
  STK_3 = |masked_op;
  STK_3_add = STK_3 | M_3_sh[0];

  if (STK_1_add & STK_2_add)
    begin
      STK_1_add = ({E_1_n,M_1_raw} > {E_2_n,M_2_raw}) & 
                  ~(E_1_n[(exp_width+3)-1]^E_2_n[(exp_width+3)-1]) |
                  (E_1_n[(exp_width+3)-1]==1'b0 & E_2_n[(exp_width+3)-1]==1'b1);
      STK_2_add = ~STK_1_add;
    end
  if (STK_1_add & STK_3_add)
    begin
      STK_1_add = ({E_1_n,M_1_raw} > {E_3_n,M_3_raw}) & 
                   ~(E_1_n[(exp_width+3)-1]^E_3_n[(exp_width+3)-1]) | 
                  (E_1_n[(exp_width+3)-1]==1'b0 & E_3_n[(exp_width+3)-1]==1'b1);
      STK_3_add =  ~STK_1_add;
    end
  if (STK_2_add & STK_3_add)
    begin
      STK_2_add = ({E_2_n,M_2_raw} > {E_3_n,M_3_raw}) & 
                   ~(E_2_n[(exp_width+3)-1]^E_3_n[(exp_width+3)-1]) |
                  (E_2_n[(exp_width+3)-1]==1'b0 & E_3_n[(exp_width+3)-1]==1'b1);
      STK_3_add =  ~STK_2_add;
    end
  M_1_sh[0] = STK_1_add;
  M_2_sh[0] = STK_2_add;
  M_3_sh[0] = STK_3_add;
  
end

always @ (M_1_sh or M_2_sh or M_3_sh or S_1 or S_2 or S_3)
begin
    inv_1 = S_1 ^ S_3;
    inv_2 = S_2 ^ S_3;
    if (inv_1 == 1'b1) 
      adder_input1 = ~{3'b0, M_1_sh};
    else 
      adder_input1 = {3'b0, M_1_sh};
    if (inv_2 == 1'b1) 
      adder_input2 = ~{3'b0, M_2_sh};
    else 
      adder_input2 = {3'b0, M_2_sh};
    adder_input3 = {3'b0, M_3_sh};

    adder_output = adder_input1 + adder_input2 + adder_input3 + inv_1 + inv_2;

    
    adder_output_sign = adder_output[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)];
    if (adder_output[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)] == 1) 
      adder_output_mag = ~adder_output[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0]+1;
    else
      adder_output_mag = adder_output[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0];
end

always @ (adder_output_sign or S_3 or adder_output_mag or 
          M_1 or M_2 or M_3 or max_exp_plus3 or E_1 or E_2 or E_3) 
begin
    norm_input = adder_output_mag;
    result_sign = adder_output_sign  ^ S_3;
    expected_exponent_plus3 = max_exp_plus3;
end

  DW_lzd #(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1) 
  U4 (.a (norm_input), 
      .enc (num_of_zeros), .dec() );
  wire adder_output_is_zero;
  assign adder_output_is_zero = &num_of_zeros;

always @ (num_of_zeros or expected_exponent_plus3)
begin
    if ((expected_exponent_plus3 <= ({exp_width{1'b1}}>>1) + 1) && (ieee_compliance == 1))
      begin
        shifting_distance = ({exp_width{1'b1}}>>1) + 1 - expected_exponent_plus3;
        denormal_result = 1'b1;
      end
    else
      begin
        denormal_result = 1'b0;
        num_of_zeros_biased = {1'b0,num_of_zeros}+({exp_width{1'b1}}>>1);
        if (expected_exponent_plus3 > num_of_zeros_biased)
          shifting_distance = num_of_zeros;
        else
          shifting_distance = expected_exponent_plus3-1-({exp_width{1'b1}}>>1);
      end
end

always @ (norm_input or expected_exponent_plus3 or result_sign or rnd 
or shifting_distance or STK_1 or STK_2 or STK_3 or denormal_result or 
adder_output_is_zero)
begin
  a_mag = norm_input[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:0];
  pos_offset = expected_exponent_plus3;
  sticky_bit = STK_1 | STK_2 | STK_3;
  a_sign = result_sign;
  a_norm = (denormal_result==1 && ieee_compliance==1)?
           a_mag >> shifting_distance:a_mag << shifting_distance;
  if (denormal_result == 1 && ieee_compliance==1)
    begin
      one_vector2 = ~$unsigned(0);
      mask2 = ~(one_vector2 << shifting_distance);
      masked_op2 = mask2 & a_mag[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-sig_width-3];
      STK_denorm = |masked_op2;
    end
  else
    STK_denorm = 1'b0;
  corrected_expo1 = (denormal_result==1 && ieee_compliance==1)? 1:
                    (adder_output_is_zero)?0:
                    $unsigned(pos_offset)-$unsigned(shifting_distance)-({exp_width{1'b1}}>>1);
  corrected_expo2 = (denormal_result==1 && ieee_compliance==1)? 1:
                    corrected_expo1 + 1;
  T = sticky_bit || STK_denorm || (|a_norm[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-sig_width-3:0]);
  Rbit = a_norm[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-sig_width-2]; 
  Lbit = a_norm[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-sig_width-1];
  rnd_incr =   (rnd == 3'd0) ? Rbit && (Lbit || T) :   
               (rnd == 3'd1) ? 1'b0 :    
               (rnd == 3'd2) ? !a_sign && (Rbit || T) :
               (rnd == 3'd3) ? a_sign && (Rbit || T) :
               (rnd == 3'd4) ? Rbit :
               (rnd == 3'd5) ? Rbit || T : 1'b0;
  a_rounded = {1'b0, a_norm[(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-1:(((2*sig_width+2)+(3)+(2*sig_width+3+adj_prec))-1)-sig_width-1]} + rnd_incr;
  post_rounding_normalization = a_rounded[sig_width+1];
  significand_z = (post_rounding_normalization == 1'b0) ? a_rounded[sig_width:0]:{1'b1, {sig_width{1'b0}}};
  corrected_expo = (post_rounding_normalization == 1'b1) ? corrected_expo2 : corrected_expo1;
  pos_err =  corrected_expo[(exp_width+3)-1];
  large_input_exp = |corrected_expo[(exp_width+3)-2:exp_width] & ~pos_err;
  exponent_z = (pos_err)?0:corrected_expo[exp_width-1:0];
  no_MS1_detection = ~(|a_rounded[sig_width+1:sig_width]);
  if (large_input_exp == 1)
    begin
      exponent_z = ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1});
      inexact = 1'b1;
    end
  else
    inexact = Rbit | T;
end

always @ (significand_z or exponent_z or no_MS1_detection or rnd or status_int1 or z_temp1 or output_defined_from_inp or result_sign or pos_err or z_inf_minus or z_inf_plus or z_large_minus or z_large_plus or inexact or S_1 or S_2 or S_3 or adder_output_is_zero)
begin
   status_int = {8{1'b0}};
   if (output_defined_from_inp == 1) 
     begin
       z_temp = z_temp1;
       status_int = status_int1;
     end
   else
    if (pos_err==0 && exponent_z==((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))
      begin
        case (rnd)
          0,4,5:
            begin 
              if (result_sign==1'b1) z_temp = z_inf_minus;
              else                   z_temp = z_inf_plus;
              status_int[1] = 1'b1;       
            end
          1:
            if (result_sign==1'b1) z_temp = z_large_minus;
            else                   z_temp = z_large_plus;
          2:
            if (result_sign==1'b1) z_temp = z_large_minus;
            else 
              begin
                z_temp = z_inf_plus;
                status_int[1] = 1'b1;  
              end
          3:
            if (result_sign==1'b1) 
              begin
                z_temp = z_inf_minus;
                status_int[1] = 1'b1;  
              end
            else              z_temp = z_large_plus;
          default: z_temp = {(exp_width + sig_width + 1){1'b0}};
        endcase
        status_int[4] = 1'b1;       
        status_int[5] = 1'b1;
      end
    else
      if ( no_MS1_detection == 1'b1 && significand_z != 0 && ieee_compliance == 1)
        begin
          int_exponent = {exp_width{1'b0}};
          z_temp = {result_sign, int_exponent, significand_z[(sig_width - 1):0]};
          status_int[5] = inexact;       
          status_int[3] = 1'b1; 
        end
    else 
      if (adder_output_is_zero == 0 && (pos_err == 1'b1 || 
          no_MS1_detection == 1'b1) && ieee_compliance == 0)
        begin
           if ((rnd == 3 && result_sign == 1) ||
               (rnd == 2 && result_sign == 0) ||
               rnd == 5)
             begin
               z_temp = {result_sign, {exp_width-1{1'b0}}, 1'b1,{sig_width{1'b0}}};
               status_int[0] = 1'b0;
               status_int[5] = 1'b1;       
             end
           else
             begin
               z_temp = {result_sign, {exp_width+sig_width{1'b0}}};
               status_int[0] = 1'b1;
               status_int[5] = 1'b1;       
             end
          status_int[3] = 1'b1; 
        end
    else
     if (no_MS1_detection == 1'b1)
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
              z_temp = {result_sign, {exp_width+sig_width{1'b0}}};
            else
              if (rnd == 3)
                z_temp = {1'b1, {exp_width+sig_width{1'b0}}};
              else
                z_temp = {1'b0, {exp_width+sig_width{1'b0}}};
          end
       end
     else     
       begin
          status_int[5] = inexact;       
          z_temp = {result_sign, exponent_z, significand_z[sig_width-1:0]};
       end 

end

assign status = (arch_type == 1)?status_int2:status_int;
assign z = (arch_type == 1)?z_temp2:z_temp;
  
`undef  DW_shift_width

endmodule
