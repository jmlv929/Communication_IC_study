

////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT: Floating-Point Inverse Square Root
//
//              DW_fp_invsqrt calculates the floating-point reciprocal of 
//              a square root. It supports six rounding modes, including 
//              four IEEE standard rounding modes.
//
//              parameters      valid values
//              ==========      ============
//              sig_width       significand f,  2 to 253 bits
//              exp_width       exponent e,     3 to 31 bits
//              ieee_compliance 0 or 1 
//                              support the IEEE Compliance 
//                              including NaN and denormal.
//                              0 - MC (module compiler) compatible
//                              1 - IEEE 754 standard compatible
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              Rounding Mode Input
//              z               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Output
//              status          8 bits
//                              Status Flags Output
//
// Modified:
//   05/05/10  (STAR 9000391410, D-2010.03-SP2)
//            Fixed that 1/sqrt(-0) = -Inf, and set divide_by_zero flag. 
//   07/08/10  (STAR 9000404527, D-2010.03-SP4)
//            Error happened with (23, 4, 1)-configuration
//            when the input is a denormal, output does not show Inf.
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_fp_invsqrt (
  a,
  rnd,
  z,
  status
  // Embedded dc_shell script
  // _model_constraint_2
  // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

  parameter sig_width = 23;   // RANGE 2 TO 253
  parameter exp_width = 8;    // RANGE 3 TO 31
  parameter ieee_compliance = 0; // RANGE 0 TO 1
  parameter prec_adj = 0;


  localparam _RND_Inc = 0;
  localparam _RND_Inexact = 1;
  localparam _RND_HugeInfinity = 2;
  localparam _RND_TinyminNorm = 3;
  localparam _log_awidth = ((sig_width + 1>65536)?((sig_width + 1>16777216)?((sig_width + 1>268435456)?((sig_width + 1>536870912)?30:29):((sig_width + 1>67108864)?((sig_width + 1>134217728)?28:27):((sig_width + 1>33554432)?26:25))):((sig_width + 1>1048576)?((sig_width + 1>4194304)?((sig_width + 1>8388608)?24:23):((sig_width + 1>2097152)?22:21)):((sig_width + 1>262144)?((sig_width + 1>524288)?20:19):((sig_width + 1>131072)?18:17)))):((sig_width + 1>256)?((sig_width + 1>4096)?((sig_width + 1>16384)?((sig_width + 1>32768)?16:15):((sig_width + 1>8192)?14:13)):((sig_width + 1>1024)?((sig_width + 1>2048)?12:11):((sig_width + 1>512)?10:9))):((sig_width + 1>16)?((sig_width + 1>64)?((sig_width + 1>128)?8:7):((sig_width + 1>32)?6:5)):((sig_width + 1>4)?((sig_width + 1>8)?4:3):((sig_width + 1>2)?2:1)))));
  localparam _small_exp_width_cond = (((1 << (exp_width-1)) - 1) < 2 * sig_width + 1);

  //-------------------------------------------------------
  input  [(exp_width + sig_width):0] a;
  input  [2:0] rnd;
  output [8    -1:0] status;
  output [(exp_width + sig_width):0] z;
  //-------------------------------------------------------

  wire signa;
  wire [exp_width - 1:0] ea;
  wire [sig_width - 1:0] sa;
  wire [sig_width:0] ma;
  wire [sig_width:0] normed_ma;
  wire [sig_width+1:0] scaled_ma;
  wire sa_zero;
  wire ea_zero;
  wire ea_inf;
  wire ea_biased_zero;
  wire ls_bit;
  wire round_bit;
  wire sticky_bit;
  wire inf_a;
  wire nan_a;
  wire zero_a;
  wire denorm_a;
  wire nan_case;
  wire inf_case;
  wire zero_case;
  wire quarter_case;
  wire normal_case;
  wire rnd_ovfl;
  wire sign;
  wire signed [exp_width + 1:0] ez;
  wire signed [exp_width + 1:0] e_adj;
  wire signed [exp_width + 1:0] em;
  wire signed [exp_width + 1:0] emplus1;
  wire signed [exp_width + 1:0] ez_adjust;
  wire signed [exp_width + 1:0] ez_adjust_plus1;
  wire signed [exp_width + 1:0] ez_adjust_final;
  wire [sig_width - 1:0] sig_result;
  wire [exp_width - 1:0] exp_result;
  wire [sig_width - 1:0] sig_inf_result;
  wire [sig_width - 1:0] sig_nan_result;
  wire [_log_awidth:0] lzd_ina;
  wire [sig_width + 1:0] invsqrt_in;
  wire [sig_width + 1:0] invsqrt_out;
  wire [sig_width + 1:0] mantissa;
  wire [sig_width:0] invsqrt_rounded;
  wire STK_bit;
  wire [exp_width - 1:0] emax;

  wire even;
  wire away;
  wire infMatch;
  wire infinity;
  wire R0_n0;
  wire R1_n0;
  wire RND_eval0_RND_Inc;
  wire RND_eval0_RND_Inexact;
  wire RND_eval0_RND_HugeInfinity;
  wire RND_eval0_RND_TinyminNorm;
  wire [3:0] RND_eval;

  // Unpack the FP Number
  assign {signa, ea, sa} = a;
  assign sign = zero_a & signa;

  // Obtain input information
  assign sa_zero = (sa == 0);
  assign ea_zero = (ea == 0);
  assign ea_biased_zero = (ea[exp_width-2:0] == ((1 << (exp_width-1)) - 1)) & 
                           ea[exp_width-1] == 0;
  assign ea_inf = (ea[exp_width-2:0] == ((1 << (exp_width-1)) - 1)) & 
                           ea[exp_width-1] == 1;

  assign inf_a = (ieee_compliance) ? ea_inf & sa_zero : ea_inf;
  assign nan_a = (ieee_compliance) ? ea_inf & ~sa_zero : 0;
  assign zero_a = (ieee_compliance) ? ea_zero & sa_zero : ea_zero;
  assign denorm_a = (ieee_compliance) ? ea_zero & ~sa_zero : 0;
  assign emax = {{(exp_width - 1){1'b1}}, 1'b0};

  // introduce hidden bit
  assign ma = (ieee_compliance & denorm_a) ? {1'b0, sa} : {1'b1, sa};

  // Check special cases
  assign nan_case = nan_a | (signa & ~zero_a);
  assign inf_case = (_small_exp_width_cond && ieee_compliance) ? 
                      zero_a | (ez_adjust_final > $signed({1'b0, emax})) :
                      zero_a;

  assign normal_case = ~nan_case & ~inf_case & ~zero_case;

  // output goes to zero when the input is a positive infinity
  assign zero_case = ~signa & inf_a;

  assign sig_inf_result = 0;
  assign sig_nan_result = (ieee_compliance) ? 1 : 0;

  // Normalization of Denormal Inputs
  DW_lzd #(sig_width + 1) U1 (
    .a(ma),
    .enc(lzd_ina)
  );

  assign normed_ma = (ieee_compliance) ? ma << lzd_ina : ma;
  assign scaled_ma = (em[0])?{1'b0,normed_ma}:{normed_ma,1'b0}; 

  // Exponent Calculation
  // The addition of denorm_a is done to make the exponent of the 
  // input have a value 1 (minimal exponent value)
  assign e_adj = (ieee_compliance)?(ea - lzd_ina + 1 + denorm_a - ((1 << (exp_width-1)) - 1)):
                                   (ea + 1 - ((1 << (exp_width-1)) - 1));
  assign em = -(e_adj);
  assign emplus1 = -(e_adj + 1);
  assign ez = (em[0])?(emplus1 >>> 1):(em >>> 1);
  assign invsqrt_in = scaled_ma;
  assign quarter_case = (ieee_compliance)?
                        ~scaled_ma[sig_width+1] & ~(|scaled_ma[sig_width-1:0]):
                        ~scaled_ma[sig_width+1] & sa_zero & normal_case;

  // DW_inv_sqrt Instantiation
  // The precision control parameter is passed to the instantiated component
  DW_inv_sqrt #(sig_width+2,prec_adj)
   U2 ( .a(invsqrt_in), .b(invsqrt_out), .t(STK_bit) );

  assign sticky_bit = (quarter_case)?0:STK_bit;
  assign mantissa = (quarter_case)?{1'b1,{sig_width+1{1'b0}}}:invsqrt_out;

  // Exponent adjustment
  assign ez_adjust = ez + ((1 << (exp_width-1)) - 1);
  assign ez_adjust_plus1 = ez_adjust + 1;
  assign ez_adjust_final = (rnd_ovfl | quarter_case) ?
                             ez_adjust_plus1 :
                             ez_adjust;

  // Final Rounding Control Setup
  assign ls_bit = mantissa[1];
  assign round_bit = mantissa[0];

  // Rounding Addition
  assign {rnd_ovfl, invsqrt_rounded} = mantissa[sig_width + 1:1] + RND_eval[_RND_Inc];

  // Status Flag Setup
  assign status[7] = zero_a;

  assign status[6] = 0; 
  assign status[5] = sticky_bit & normal_case & ~quarter_case;
  assign status[4] = 0;
  assign status[3] = 0;
  assign status[2] = nan_case;
  assign status[1] = ~nan_case & inf_case;
  assign status[0] = zero_case;

  // Output Generation
  assign sig_result = (nan_case) ? sig_nan_result :
                      (inf_case) ? sig_inf_result :
                      (zero_case) ? 0:
                      invsqrt_rounded[sig_width - 1:0];

  assign exp_result = (nan_case | inf_case) ? {(exp_width){1'b1}} :
                      (zero_case) ? 0 :
                                    ez_adjust_final[exp_width - 1:0];

  assign z = {sign, exp_result, sig_result};
 

  //--------------------------------------------------
  // Rounding Block Description
  //--------------------------------------------------
  
  assign even = (rnd == 0);
  assign away = rnd[2] & rnd[0];
  assign infMatch = rnd[1] & (sign == rnd[0]);
  assign infinity = infMatch | away;

  assign R0_n0 = ~(infinity ? sticky_bit : 0);
  assign R1_n0 = ~(even ? (ls_bit | sticky_bit) : (rnd[2] | infMatch));

  assign RND_eval0_RND_Inc = ~(round_bit ? R1_n0 : R0_n0);
  assign RND_eval0_RND_Inexact = round_bit | sticky_bit;
  assign RND_eval0_RND_HugeInfinity = infinity | (rnd[1:0] == 0);
  assign RND_eval0_RND_TinyminNorm = infinity;
  
  assign RND_eval = {RND_eval0_RND_TinyminNorm, RND_eval0_RND_HugeInfinity, RND_eval0_RND_Inexact, RND_eval0_RND_Inc};

endmodule
