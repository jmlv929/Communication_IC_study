
////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-point Natural Logarithm
//           Computes the natural logarithm of a FP number
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 60 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance 0 or 1
//              extra_prec      0 to 60-sig_width bits
//              arch            implementation select
//                              0 - area optimized
//                              1 - speed optimized
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_width + exp_width + 1) bits
//                              Floating-point Number that represents ln(a)
//              status          byte
//                              Status information about FP operation
//
// MODIFIED:
//
//-------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////

module DW_fp_ln (

// ports
                   a,
                   z,
                   status

    // Embedded dc_shell script
    // set_local_link_library {dw01.sldb dw02.sldb}
    // _model_constraint_2
);

//------------------------------------------------------
// main module parameters
parameter sig_width    = 10;
parameter exp_width    = 5;
parameter ieee_compliance = 0;
parameter extra_prec = 0;
parameter arch = 0;

//------------------------------------------------------
//          declaration of inputs and outputs

input  [sig_width + exp_width:0] a;
output [sig_width + exp_width:0] z;
output [7:0] status;

// definitions used in the code
 
// declaration of signals
`define internal_prec (sig_width+extra_prec+1)
`define internal_prec2 (`internal_prec+exp_width+1)
wire sign;
wire [sig_width-1:0] fa;
wire [exp_width-1:0] ea;
wire all_ones_short_exp;
wire bias_exp;
wire all_ones_exp;
wire zero_exp;
wire One_input;
wire inf, nan, zero, denormal; // special input conditions
wire [sig_width:0] Ma;
wire [sig_width:0] Ma_norm;
wire [exp_width:0] ea_extended;
wire [exp_width:0] adj_ea; 
wire no_msone_detect;
wire ovfl_case;
wire [sig_width:0] Ma_norm_select;
wire [`internal_prec-1:0] Ma_norm_select_ext;
wire [`internal_prec-1:0] ln_output;
wire signed [exp_width:0] ln_exponent_init;
wire signed [`internal_prec2-1:0] ln_exponent_scaled;
wire signed [`internal_prec2-1:0] ln_exponent_init2;
wire [`internal_prec2-1:0] ln_output_corrected_signed;
wire output_sign;
wire [`internal_prec2-1:0] ln_output_mag;
wire [`internal_prec2-1:0] ln_output_mag_norm;
wire [exp_width:0] adj_ea2; 
wire [exp_width:0] exponent_offset;
`define num_of_zeros_size (((`internal_prec2>256)?((`internal_prec2>4096)?((`internal_prec2>16384)?((`internal_prec2>32768)?16:15):((`internal_prec2>8192)?14:13)):((`internal_prec2>1024)?((`internal_prec2>2048)?12:11):((`internal_prec2>512)?10:9))):((`internal_prec2>16)?((`internal_prec2>64)?((`internal_prec2>128)?8:7):((`internal_prec2>32)?6:5)):((`internal_prec2>4)?((`internal_prec2>8)?4:3):((`internal_prec2>2)?2:1))))+1)
wire [exp_width:0] limited_shift_dist;
wire [`num_of_zeros_size-1:0] num_of_zeros;
wire [`internal_prec2-1:0] ln_output_mag_denorm;
wire [`internal_prec2-1:0] ln_output_mag_sel;
wire [sig_width+1:0] ln_output_rounded;
wire [sig_width:0] ln_output_normal;
wire [exp_width-1:0] ln_exponent;
wire [exp_width:0] adj_ea2_plus1;
wire denormal_output;
wire [(exp_width + sig_width + 1)-1:0] NaNFp, PlusInf, MinusInf;

// Scaling factor for the exponent 
`define ln_of_2_vecsize 93
`define ln_of_2_MSB  (`ln_of_2_vecsize - 1)
  wire [`ln_of_2_MSB:0] ln_of_2_val = `ln_of_2_vecsize'b010110001011100100001011111110111110100011100111101111001101010111100100111100011101100111001;
  wire [`internal_prec-1:0] ln_of_2_rnd_val;
  assign ln_of_2_rnd_val = ln_of_2_val[`ln_of_2_MSB-1:`ln_of_2_MSB-`internal_prec]+ln_of_2_val[`ln_of_2_MSB-`internal_prec-1];

// Extrac basic information from the FP input 
  assign sign = a[(exp_width + sig_width)];
  assign fa = a[(sig_width - 1):0];
  assign ea = a[((exp_width + sig_width) - 1):sig_width];

// Detect special values of fields and FP numbers 
  assign all_ones_short_exp = (ea[exp_width-2:0]==$unsigned(((1 << (exp_width-1)) - 1)));
  assign bias_exp = ~ea[exp_width-1] & all_ones_short_exp;
  assign all_ones_exp = ea[exp_width-1] & all_ones_short_exp;
  assign zero_exp = (ea == 0);
  assign One_input = bias_exp & ~|fa;

  assign inf = ((all_ones_exp == 1) && (ieee_compliance == 0 || (fa == 0)))?1'b1:1'b0;
  assign nan = ((all_ones_exp == 1) && (ieee_compliance == 1) && (fa != 0))?1'b1:1'b0;
  assign zero = ((zero_exp == 1) && (ieee_compliance == 0 || (fa == 0)))?1'b1:1'b0;
  assign denormal = ((zero_exp == 1) && (ieee_compliance == 1) && (fa != 0))?1'b1:1'b0;

assign Ma = (zero || inf)?0:{~denormal,fa};

// Normalize the input and correct exponent 
// This step is meaningful only when ieee_compliance = 1
  assign ea_extended = {1'b0,ea} | {{exp_width{1'b0}},denormal};

  DW_norm #(sig_width+1, sig_width+1, exp_width+1, 1)
  U1 ( .a(Ma), .exp_offset(ea_extended),.no_detect(no_msone_detect), 
       .ovfl(ovfl_case), .b(Ma_norm), .exp_adj(adj_ea) );
  assign Ma_norm_select = (ieee_compliance == 1)?Ma_norm:Ma;
  assign Ma_norm_select_ext = Ma_norm_select << extra_prec;

// compute the logarithm of the significand
  DW_ln #(`internal_prec,arch) U2 (.a(Ma_norm_select_ext), .z(ln_output));

// transform exponent to signed value
  assign ln_exponent_init = $signed(adj_ea) - $signed($unsigned(((1 << (exp_width-1)) - 1)));
  assign ln_exponent_init2 = $signed(ln_exponent_init);
  assign ln_exponent_scaled = ln_exponent_init2 * $unsigned(ln_of_2_rnd_val);

// add exponent value and fixed-point ln output
  assign ln_output_corrected_signed = $unsigned(ln_exponent_scaled) + ln_output;

// extract the sign and obtain the magnitude of the logarithm
  assign output_sign = ln_output_corrected_signed[`internal_prec2-1];
  assign ln_output_mag = (output_sign)?-ln_output_corrected_signed:
                                          ln_output_corrected_signed;

// Normalize the output
  assign exponent_offset = $unsigned(((1 << (exp_width-1)) - 1)) + exp_width;

// By definition, the encoded ouptut of LZD must have the bitsize of the
// input operand (ln(`internal_prec2))
  DW_lzd #(`internal_prec2) U4 (.a(ln_output_mag[`internal_prec2-1:0]),.enc(num_of_zeros));

// we know that in normal operation, there must be a 1 in the search window
// Thus, the comparison between num_of_zeros and the value of the exponent is
// enough to find out if the output became too small
  assign limited_shift_dist = (num_of_zeros > exponent_offset - 1)?exponent_offset-1:
                             num_of_zeros;
  assign ln_output_mag_denorm = ln_output_mag << limited_shift_dist;

// This normalization unit works for the regular case
  DW_norm #(`internal_prec2, `internal_prec2, exp_width+1, 1)
  U3 ( .a(ln_output_mag), .exp_offset(exponent_offset),.no_detect(), 
       .ovfl(), .b(ln_output_mag_norm), .exp_adj(adj_ea2) );

assign ln_output_mag_sel = (ieee_compliance == 1)?ln_output_mag_denorm:
                             ln_output_mag_norm;

// Rounding
  assign ln_output_rounded = {1'b0,ln_output_mag_sel[`internal_prec2-1:exp_width+1+extra_prec]}+
                               ln_output_mag_sel[exp_width+extra_prec];
// takes care of post-rounding normalization
  assign ln_output_normal = (ln_output_rounded[sig_width+1]==1)?ln_output_rounded[sig_width+1:1]:
                              ln_output_rounded[sig_width:0];
  assign adj_ea2_plus1 = adj_ea2+1;
  assign ln_exponent = (ln_output_rounded[sig_width+1]==1)?adj_ea2_plus1:adj_ea2;

// Detect the denormal output
// Happens when the final exponent is still under value 1, after rounding.
// or the ln_output_normal has a MS bit = 0
// Care must be taken when the input to the ln is 1, and the output is 
// an exact zero.
  assign denormal_output = ((ln_output_normal[sig_width]==1'b0) | (ln_exponent == 0) | (adj_ea2[exp_width])) & ~One_input;

// generate the final output considering the special cases
  assign NaNFp = (ieee_compliance==1)?{1'b0,{exp_width{1'b1}},{sig_width-1{1'b0}},1'b1}:
                                    {1'b0,{exp_width{1'b1}},{sig_width-1{1'b0}},1'b0};
  assign MinusInf = {1'b1,{exp_width{1'b1}},{sig_width{1'b0}}};
  assign PlusInf = {1'b0,{exp_width{1'b1}},{sig_width{1'b0}}};
// Need to take care of denormal outputs...
  assign z = (nan==1 || sign==1)?NaNFp:
             (inf==1)?PlusInf:
             (zero==1)?MinusInf:
             ((denormal_output==1 && ieee_compliance==0)|(One_input==1))?0:
             (denormal_output==1 && ieee_compliance==1)?
             {output_sign,{exp_width{1'b0}},ln_output_normal[sig_width-1:0]}:
             {output_sign,ln_exponent,ln_output_normal[sig_width-1:0]};
  assign status[0] = (((denormal_output == 1) & (ieee_compliance == 0)) | (ln_output_normal == 0)) & ~(inf | zero | nan | sign);
  assign status[1] = (inf  | zero) & ~sign;
  assign status[2] = nan | sign;
  assign status[3] = denormal_output & ~(inf | zero | nan | sign);
  assign status[4] = 0;
  assign status[5] = ~status[1] & 
                                   ~status[2] &
                                   ~(status[0] & 
                                     ~status[3]);
  assign status[6] = 0;
  assign status[7] = 0;

`undef num_of_zeros_size
`undef internal_prec
`undef internal_prec2
`undef ln_of_2_vecsize
`undef ln_of_2_MSB

endmodule
