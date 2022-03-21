
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT: Floating-Point Square-Root
//
//              DW_fp_sqrt calculates the floating-point square-root
//              while supporting six rounding modes, including four IEEE
//              standard rounding modes.
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance support the IEEE Compliance 
//                              0 - IEEE 754 compatible without denormal support
//                                  (NaN becomes Infinity, Denormal becomes Zero)
//                              1 - IEEE 754 compatible with denormal support
//                                  (NaN and denormal numbers are supported)
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
// MODIFIED: 4/25/07, from z0703-SP2
//           Corrected DW_fp_sqrt(-0) = -0
//           7/19/10, STAR 9000404523
//           Removed bugs with (23,4,1)-configuration
//
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_fp_sqrt (
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


  `define RND_Width  4
  `define RND_Inc  0
  `define RND_Inexact  1
  `define RND_HugeInfinity  2
  `define RND_TinyminNorm  3
  `define sqrt_in_width (2 * sig_width + 4)
  `define log_awidth ((sig_width + 1>65536)?((sig_width + 1>16777216)?((sig_width + 1>268435456)?((sig_width + 1>536870912)?30:29):((sig_width + 1>67108864)?((sig_width + 1>134217728)?28:27):((sig_width + 1>33554432)?26:25))):((sig_width + 1>1048576)?((sig_width + 1>4194304)?((sig_width + 1>8388608)?24:23):((sig_width + 1>2097152)?22:21)):((sig_width + 1>262144)?((sig_width + 1>524288)?20:19):((sig_width + 1>131072)?18:17)))):((sig_width + 1>256)?((sig_width + 1>4096)?((sig_width + 1>16384)?((sig_width + 1>32768)?16:15):((sig_width + 1>8192)?14:13)):((sig_width + 1>1024)?((sig_width + 1>2048)?12:11):((sig_width + 1>512)?10:9))):((sig_width + 1>16)?((sig_width + 1>64)?((sig_width + 1>128)?8:7):((sig_width + 1>32)?6:5)):((sig_width + 1>4)?((sig_width + 1>8)?4:3):((sig_width + 1>2)?2:1)))))

  localparam _lzd_a_width = ((sig_width + 2>65536)?((sig_width + 2>16777216)?((sig_width + 2>268435456)?((sig_width + 2>536870912)?30:29):((sig_width + 2>67108864)?((sig_width + 2>134217728)?28:27):((sig_width + 2>33554432)?26:25))):((sig_width + 2>1048576)?((sig_width + 2>4194304)?((sig_width + 2>8388608)?24:23):((sig_width + 2>2097152)?22:21)):((sig_width + 2>262144)?((sig_width + 2>524288)?20:19):((sig_width + 2>131072)?18:17)))):((sig_width + 2>256)?((sig_width + 2>4096)?((sig_width + 2>16384)?((sig_width + 2>32768)?16:15):((sig_width + 2>8192)?14:13)):((sig_width + 2>1024)?((sig_width + 2>2048)?12:11):((sig_width + 2>512)?10:9))):((sig_width + 2>16)?((sig_width + 2>64)?((sig_width + 2>128)?8:7):((sig_width + 2>32)?6:5)):((sig_width + 2>4)?((sig_width + 2>8)?4:3):((sig_width + 2>2)?2:1)))));

  //-------------------------------------------------------
  input  [(exp_width + sig_width):0] a;
  input  [2:0] rnd;

  output [8    -1:0] status;
  output [(exp_width + sig_width):0] z;

  wire [exp_width - 1:0] ea;
  wire [sig_width - 1:0] sa;
  wire signa;
  wire [sig_width:0] ma;
  wire [sig_width:0] normed_ma;
  wire sa_zero;
  wire ea_zero;
  wire ea_inf;
  wire guard_bit;
  wire round_bit;
  wire sticky_bit;
  wire sign;
  wire inf_a;
  wire nan_a;
  wire zero_a;
  wire denorm_a;
  wire nan_case;
  wire inf_case;
  wire zero_case;
  wire normal_case;
  wire stk_check_from_rem;
  wire rnd_ovfl;
  wire signed [exp_width + 1:0] ez;
  wire signed [exp_width + 2:0] ez_bias;
  wire signed [exp_width + 1:0] ez_bias2;
  wire signed [exp_width:0] ez_adjust;
  wire signed [exp_width:0] ez_adjust2;
  wire [sig_width - 1:0] sig_result;
  wire [exp_width - 1:0] exp_result;
  wire [sig_width - 1:0] sig_inf_result;
  wire [sig_width - 1:0] sig_nan_result;
  wire [`log_awidth:0] lzd_ina;
  wire [`sqrt_in_width - 1:0] sqrt_in;
  wire [sig_width + 1:0] sqrt_out;
  wire [sig_width + 1:0] sqrt_out_denorm;
  wire [sig_width + 2:0] remainder_out;
  wire [sig_width:0] sqrt_rounded;
  wire [sig_width - 1:0] sqrt_adjust;

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
  wire neg_a;
  wire neg_az;
  wire signed [exp_width + 1:0] z_f1_post_sh_signed;
  wire signed [_lzd_a_width:0] z_f1_post_sh;

  // Unpack the FP Numbers
  assign {signa, ea, sa} = a;

  assign ma = (ieee_compliance & denorm_a) ? {1'b0, sa} : {1'b1, sa};
  assign sign = 1'b0;

  // Check Special Inputs
  assign sa_zero = (sa == 0);
  assign ea_zero = (ea == 0);
  assign ea_inf = (ea == ((((1 << (exp_width-1)) - 1) * 2) + 1));

  assign inf_a = (ieee_compliance) ? ea_inf & sa_zero : ea_inf;
  assign nan_a = (ieee_compliance) ? ea_inf & ~sa_zero : 0;
  assign zero_a = (ieee_compliance) ? ea_zero & sa_zero : ea_zero;
  assign denorm_a = (ieee_compliance) ? ea_zero & ~sa_zero : 0;

  //assign nan_case = nan_a | signa;
  // z-SP2 modification: 4/25/07 kyung
  assign neg_a = ~zero_a & signa;
  assign neg_az = zero_a & signa;
  assign nan_case = nan_a | neg_a;

  assign inf_case = inf_a;
  assign zero_case = zero_a;
  assign normal_case = ~nan_case & ~inf_case & ~zero_case;

  assign sig_inf_result = 0;
  assign sig_nan_result = (ieee_compliance) ? 1 : 0;

  // Exponent Calculation
  assign ez = (ieee_compliance) ?
              (ea - lzd_ina + denorm_a - ((1 << (exp_width-1)) - 1)) :
              ea - ((1 << (exp_width-1)) - 1);

  // Normalization of Denormal Inputs
  DW_lzd #(sig_width + 1) U1 (
    .a(ma),
    .enc(lzd_ina)
  );

  assign normed_ma = (ieee_compliance) ? ma << lzd_ina : ma;

  // DW_sqrt Instantiation
  assign sqrt_in = (ieee_compliance) ?
            ((ez[0] == 0) ? {1'b0, normed_ma, {(sig_width + 2){1'b0}}} :
                            {normed_ma, {(sig_width + 3){1'b0}}}) :
            ((ea[0] == 1) ? {1'b0, normed_ma, {(sig_width + 2){1'b0}}} :
                            {normed_ma, {(sig_width + 3){1'b0}}});

  // Instantiated the internal DW component DW_sqrt_rem
  DW_sqrt_rem #(`sqrt_in_width, 0) U2 (
    .a(sqrt_in),
    .root(sqrt_out),
    .remainder(remainder_out)
  );

  // sticky check from rem
  assign stk_check_from_rem = (remainder_out != 0);

  // denormal number modification
  assign sqrt_out_denorm = (ieee_compliance && (ez_bias2 == 0 | ez_bias2 < 0)) ?
           {1'b0, sqrt_out[sig_width + 1:1]} :
           sqrt_out;

  // Final Rounding Control Setup
  assign guard_bit = sqrt_out_denorm[1];
  assign round_bit = sqrt_out_denorm[0];
  assign sticky_bit = (ieee_compliance && (ez_bias2 == 0 | ez_bias2 < 0)) ?
           stk_check_from_rem | sqrt_out[0] :
           stk_check_from_rem;

  // Rounding Addition
  assign {rnd_ovfl, sqrt_rounded} = sqrt_out_denorm[sig_width + 1:1] + RND_eval[`RND_Inc];

  wire ez_adjust_neg;

  // Exponent adjustment
  assign ez_bias = ez + $signed({1'b0, (((1 << (exp_width-1)) - 1) << 1)});
  assign ez_bias2 = ez_bias[exp_width + 2:1];
  assign ez_adjust = ez_bias2 + $signed({1'b0, rnd_ovfl});
  assign ez_adjust_neg = (ez_adjust < 0);
  assign ez_adjust2 = (ieee_compliance & ez_adjust_neg) ?
                        0 : ez_adjust;

  // Significand adjustment in case of rnd_ovfl
  assign sqrt_adjust = (rnd_ovfl) ? 0 : sqrt_rounded[sig_width - 1:0];

  // Status Flag Setup
  assign status[7] = 0;
  assign status[6] = 0; // check
  assign status[5] = normal_case & RND_eval[`RND_Inexact];
  assign status[4] = 0;
  assign status[3] = ~(nan_case | zero_case) & (ez_adjust[exp_width - 1:0] == 0) ;
  assign status[2] = nan_case;
  assign status[1] = ~nan_case & inf_case;
  assign status[0] = ~nan_case & zero_case;

  // Output Generation
  generate 
    if (ieee_compliance == 0) begin : GEN_ic_eq_0
      assign sig_result = (nan_case) ? sig_nan_result :
                        (inf_case) ? sig_inf_result :
                        (zero_case) ? 0 :
                        sqrt_rounded[sig_width - 1:0];
    end
    else begin : GEN_ic_ne_0
      //-----------------------------------------------
      // bias >= 2f + 1 : there is no denormal output
      //-----------------------------------------------
      assign z_f1_post_sh_signed = -ez_bias2;
      assign z_f1_post_sh = (exp_width > _lzd_a_width) ? 
                              z_f1_post_sh_signed[_lzd_a_width:0] :
                              z_f1_post_sh_signed[exp_width:0];

      if (((1 << (exp_width-1)) - 1) >= 2 * sig_width + 1) begin : GEN_ic1_biascase1 // (23, 8, 1)-config
        assign sig_result = (nan_case) ? sig_nan_result :
                            (inf_case) ? sig_inf_result :
                            (zero_case) ? 0 :
                              sqrt_rounded[sig_width - 1:0];
      end
      else begin : GEN_ic1_biascase2 // (23, 4, 1)-config
        assign sig_result = (nan_case) ? sig_nan_result :
                            (inf_case) ? sig_inf_result :
                            (zero_case) ? 0 :
                            (ez_bias2 <= 0) ?
                              sqrt_rounded[sig_width - 1:0] >> z_f1_post_sh :
                              sqrt_rounded[sig_width - 1:0];
      end
    end
  endgenerate

  assign exp_result = (nan_case | inf_case) ? {(exp_width){1'b1}} :
                      (zero_case) ? 0 :
                      ez_adjust2[exp_width - 1:0];

  assign z = {neg_az, exp_result, sig_result};
 

  //--------------------------------------------------
  // Rounding Block Description
  //--------------------------------------------------
  
  assign even = (rnd == 0);
  assign away = rnd[2] & rnd[0];
  assign infMatch = rnd[1] & (sign == rnd[0]);
  assign infinity = infMatch | away;

  assign R0_n0 = ~(infinity ? sticky_bit : 0);
  assign R1_n0 = ~(even ? (guard_bit | sticky_bit) : (rnd[2] | infMatch));

  assign RND_eval0_RND_Inc = ~(round_bit ? R1_n0 : R0_n0);
  assign RND_eval0_RND_Inexact = round_bit | sticky_bit;
  assign RND_eval0_RND_HugeInfinity = infinity | (rnd[1:0] == 0);
  assign RND_eval0_RND_TinyminNorm = infinity;
  
  assign RND_eval = {RND_eval0_RND_TinyminNorm, RND_eval0_RND_HugeInfinity, RND_eval0_RND_Inexact, RND_eval0_RND_Inc};

  `undef RND_Width
  `undef RND_Inc
  `undef RND_Inexact
  `undef RND_HugeInfinity
  `undef RND_TinyminNorm
  `undef sqrt_in_width
  `undef log_awidth
    
endmodule
