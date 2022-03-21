

////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT: Floating-Point Sine/Cosine Unit
//
//              DW_fp_sincos calculates the floating-point sine/cosine 
//              function. 
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand,  2 to 33 bits
//              exp_width       exponent,     3 to 31 bits
//              ieee_compliance support the IEEE Compliance 
//                              including NaN and denormal expressions.
//                              0 - MC (module compiler) compatible
//                              1 - IEEE 754 standard compatible
//              pi_multiple     angle is multipled by pi
//                              0 - sin(x) or cos(x)
//                              1 - sin(pi * x) or cos(pi * x)
//              arch            implementation select
//                              0 - area optimized
//                              1 - speed optimized
//                              2 - compatible with 0712 version. (default)
//                                  arch=2 will be obsolete in near future.
//              err_range       error range of the result compared to the
//                              true result. It is effective only when arch = 0
//                              and 1, and ignored when arch = 2
//                              1 - 1 ulp error (default)
//                              2 - 2 ulp error
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              sin_cos         1 bit
//                              Operator Selector
//                              0 - sine, 1 - cosine
//              z               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Output
//              status          8 bits
//                              Status Flags Output
//
// MODIFIED:  07/23/08
//           Added new parameters, arch and err_range
//            06/16/10 (STAR 9000400674, D-2010.03-SP3)
//           Fixed bugs of DW_fp_sincos when sig_width<=9
//            08/10/10 (STAR 9000409629, D-2010.03-SP4)
//           Fixed bugs of (sig_width=23, exp_width=4 and ieee_compliance=1)-
//           parameter
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_fp_sincos (
  a,
  sin_cos,
  z,
  status
  // Embedded dc_shell script
  // _model_constraint_2
  // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

  parameter sig_width = 23;      // RANGE 2 TO 33
  parameter exp_width = 8;       // RANGE 3 TO 31
  parameter ieee_compliance = 0; // RANGE 0 TO 1
  parameter pi_multiple = 1;     // RANGE 0 TO 1
                                 // pi_multiple = 1, sincos(pi * x)
                                 // pi_multiple = 0, sincos(x)
  parameter arch = 2;            // arch = 0, 1 with DW_sincos
                                 // arch = 2 with DW02_sincos
  parameter err_range = 1;       // effective when arch = 0 and 1


  localparam _lzd_a_width = ((sig_width + 1>65536)?((sig_width + 1>16777216)?((sig_width + 1>268435456)?((sig_width + 1>536870912)?30:29):((sig_width + 1>67108864)?((sig_width + 1>134217728)?28:27):((sig_width + 1>33554432)?26:25))):((sig_width + 1>1048576)?((sig_width + 1>4194304)?((sig_width + 1>8388608)?24:23):((sig_width + 1>2097152)?22:21)):((sig_width + 1>262144)?((sig_width + 1>524288)?20:19):((sig_width + 1>131072)?18:17)))):((sig_width + 1>256)?((sig_width + 1>4096)?((sig_width + 1>16384)?((sig_width + 1>32768)?16:15):((sig_width + 1>8192)?14:13)):((sig_width + 1>1024)?((sig_width + 1>2048)?12:11):((sig_width + 1>512)?10:9))):((sig_width + 1>16)?((sig_width + 1>64)?((sig_width + 1>128)?8:7):((sig_width + 1>32)?6:5)):((sig_width + 1>4)?((sig_width + 1>8)?4:3):((sig_width + 1>2)?2:1)))));
  localparam _arch_dw = ((arch == 2) ? 1 : arch);
  localparam _large_sig_cond = (sig_width > ((1 << (exp_width-1)) - 1));
  localparam _em_width = (_large_sig_cond) ? exp_width + 1 : exp_width;

  input  [sig_width + exp_width:0] a;
  input  sin_cos;                // sin_cos = 0, sin(x)
                                 // sin_cos = 1, cos(x)
  output [sig_width + exp_width:0] z;
  output [7:0] status;

  wire sign;
  wire signout;
  wire [exp_width - 1:0] ea;
  wire [sig_width - 1:0] siga;
  wire [98:0] recip_pi_value;
  wire [98:0] pi_value;
  wire [sig_width:0] recip_pi;
  wire [sig_width:0] pi;
  wire [sig_width:0] sincos_in;
  wire [sig_width:0] sincos_in_pre;
  wire [sig_width + 1:0] sincos_out;
  wire [sig_width + 1:0] sincos_out_old;
  wire [sig_width + 1:0] sincos_out_new;
  wire [sig_width:0] norm_in;
  wire [sig_width:0] norm_out;
  wire [sig_width:0] norm_out_t;
  wire zero_a;
  wire denorm_a;
  wire max_exp_a;
  wire [exp_width + sig_width:0] nan_reg;
  wire [exp_width + sig_width:0] inf_reg;
  wire [_lzd_a_width:0] lzd_ma;
  wire [_lzd_a_width:0] lzd_norm_in;
  wire [_lzd_a_width:0] shift_amt_norm;
  wire [sig_width:0] ma;
  wire [sig_width:0] norm_ma;
  wire [sig_width:0] sincos_in_pi_1;
  wire signed [_em_width:0] em;
  wire signed [_em_width:0] em_pi;
  wire signed [_em_width:0] em_adj;
  wire signed [_em_width:0] em_neg;
  wire signed [_em_width:0] em_out;
  wire [2 * sig_width + 1:0] ma_rcp_pi;
  wire pick_msb;
  wire [2 * sig_width + 1:0] norm_ma_rcp_pi;
  wire [sig_width:0] norm_ma_rcp_pi_reduced;
  wire [2 * sig_width + 1:0] sincos_in_pi_0;
  wire [sig_width:0] sincos_in_pi_0_reduced;
  wire status_tiny;
  wire status_invalid;
  wire status_inexact;
  wire status_zero;
  wire em_pos;
  wire s_out;
  wire [exp_width - 1:0] ez_out;
  wire [sig_width - 1:0] frac_out;

  assign {sign, ea, siga} = a;

  assign zero_a = (ieee_compliance == 1) ? (ea == 0) & (siga == 0) : (ea == 0);
  assign denorm_a = (ieee_compliance == 1) ? (ea == 0) & (siga != 0) : 0;
  assign max_exp_a = (ea == {(exp_width){1'b1}});

  assign nan_reg = (ieee_compliance == 1) ? 
                   {1'b0, {(exp_width){1'b1}}, {(sig_width - 1){1'b0}}, 1'b1} :
                   {1'b0, {(exp_width){1'b1}}, {(sig_width){1'b0}}};
  assign inf_reg = {1'b0, {(exp_width){1'b1}}, {(sig_width){1'b0}}};

  assign ma = (ieee_compliance == 1) ? 
                ((denorm_a) ? {1'b0, siga} : {1'b1, siga}) :
                {1'b1, siga};

  assign pi_value = 99'b110010010000111111011010101000100010000101101000110000100011010011000100110001100110001010001011100;
  assign pi = pi_value[98:98 - sig_width];

  assign recip_pi_value = 99'b101000101111100110000011011011100100111001000100000101010010100111111100001001110101011111010001111;
  assign recip_pi = recip_pi_value[98:98 - sig_width];

  // LZD for significand
  DW_lzd #(sig_width + 1) U1 (
    .a(ma),
    .enc(lzd_ma)
  );

  // Normalization of the denormal number
  assign norm_ma = (ieee_compliance == 1) ? ma << lzd_ma : ma;

  assign em = (ieee_compliance == 1) ? $signed({1'b0, ea}) - $signed({1'b0, lzd_ma}) + $signed({1'b0, denorm_a}) - $signed({1'b0, ((1 << (exp_width-1)) - 1)}) :
                                  $signed({1'b0, ea}) - $signed({1'b0, ((1 << (exp_width-1)) - 1)});
  assign em_pi = (pi_multiple) ? em : em - 2 + $signed({1'b0, pick_msb});
  assign em_adj = em_pi;
  assign em_neg = -em_adj;

  // 1/pi multiplication
  assign ma_rcp_pi = norm_ma * recip_pi;

  assign pick_msb = ((sig_width == 4) |
                     (sig_width == 5) |
                     (sig_width == 17) |
                     (sig_width == 18) |
                     (sig_width == 19) |
                     (sig_width == 20) |
                     (sig_width == 21) |
                     (sig_width == 27) |
                     (sig_width == 31) |
                     (sig_width == 32) |
                     (sig_width == 34) |
                     (sig_width == 35) |
                     (sig_width == 39) |
                     (sig_width == 40)) ? (norm_ma >= (pi + 1)) :
                                          (norm_ma >= (pi + 2));

  assign norm_ma_rcp_pi = (pick_msb) ? ma_rcp_pi :
                                       {ma_rcp_pi[2 * sig_width:0], 1'b0};

  assign norm_ma_rcp_pi_reduced = (pick_msb) ? 
                                    ma_rcp_pi[2 * sig_width + 1:sig_width + 1] :
                                    ma_rcp_pi[2 * sig_width:sig_width];

  assign em_pos = (em_adj >= 0);

  assign sincos_in_pi_1 = (em_pos) ? norm_ma << em_adj :
                                     norm_ma >> em_neg;
  assign sincos_in_pi_0 = (em_pos) ? norm_ma_rcp_pi << em_adj :
                                     norm_ma_rcp_pi >> em_neg;
  assign sincos_in_pi_0_reduced = (em_pos) ? 
                                    norm_ma_rcp_pi_reduced << em_adj :
                                    norm_ma_rcp_pi_reduced >> em_neg;


  assign sincos_in = (pi_multiple) ? sincos_in_pi_1 : 
                                     sincos_in_pi_0[2 * sig_width + 1:sig_width + 1];

  // Fixed-point SINCOS for arch = 2
  DW02_sincos #(sig_width + 1, sig_width + 2) U2 (
    .A(sincos_in),
    .SIN_COS(sin_cos),
    .WAVE(sincos_out_old)
  );

  //---------------------------------------
  // Modified by Kyung @ 07/23/08
  // Includes the new DW_sincos for the integer sincos operation
  //---------------------------------------
  // for arch = 0 or 1
  DW_sincos #(sig_width + 1, sig_width + 2, _arch_dw, err_range) U3 (
    .A(sincos_in),
    .SIN_COS(sin_cos),
    .WAVE(sincos_out_new)
  );

  assign sincos_out = (arch == 2) ? sincos_out_old : sincos_out_new;

  assign signout = (sin_cos) ? sincos_out[sig_width + 1] :
                               sincos_out[sig_width + 1] ^ sign;

  assign norm_in = (sincos_out[sig_width + 1]) ?
                     ~sincos_out[sig_width:0] + 1 :
                     sincos_out[sig_width:0];

  // LZD for normalization
  DW_lzd #(sig_width + 1) U4 (
    .a(norm_in),
    .enc(lzd_norm_in)
  );

  generate
    // check if _large_sig_cond = sig_width>((1 << (exp_width-1)) - 1) or sig_width+2>((1 << (exp_width-1)) - 1)
    if ((ieee_compliance == 1) && _large_sig_cond) begin : GEN_ie1_lg
      assign shift_amt_norm = (em_out <= 0) ? ((1 << (exp_width-1)) - 1) - 1 : lzd_norm_in;
    end
    else begin : GEN_not_ie1_lg
      assign shift_amt_norm = lzd_norm_in;
    end
  endgenerate

  generate
    if ((ieee_compliance == 1) && (sig_width + 2 > ((1 << (exp_width-1)) - 1))) begin : GEN_ie1_swltb
      assign norm_out_t = norm_in << shift_amt_norm;
    end
    else begin : GEN_not_ie1_swltb
      assign norm_out_t = norm_in << lzd_norm_in;
    end
  endgenerate

  assign norm_out = norm_out_t;

  assign em_out = (norm_in[sig_width:1] == 0) ? 0 : $signed({1'b0, ((1 << (exp_width-1)) - 1)}) - $signed({1'b0, lzd_norm_in});

  assign status_tiny = (em_out <= 0) & ~zero_a & ~max_exp_a;

  generate 
    if ((ieee_compliance == 0) && _large_sig_cond) begin : GEN_ie0_lg
      assign status_zero = ((em_out <= 0) & ~max_exp_a) | (zero_a & ~sin_cos) | ((sig_width < 10) & (em_out == 0) & ~max_exp_a);
    end
    else begin : GEN_not_id0_lg
      assign status_zero = ((em_out == 0) & (norm_out == 0) & ~max_exp_a) | (zero_a & ~sin_cos) | ((ieee_compliance == 0) & (sig_width < 10) & (em_out == 0) & ~max_exp_a);
    end
  endgenerate

  assign status_invalid = max_exp_a;
  assign status_inexact = ~zero_a & ~max_exp_a;

  generate
    if ((ieee_compliance == 1) && _large_sig_cond) begin : GEN_ie1lrg
      assign ez_out = (max_exp_a) ? {(exp_width){1'b1}} :
                      (zero_a) ? 
                        ((sin_cos) ? {1'b0, {(exp_width - 1){1'b1}}} :
                                     {(exp_width){1'b0}}) :
                      (em_out <= 0) ? 0 :
                        em_out[exp_width - 1:0];
      assign frac_out = (max_exp_a) ? {{(sig_width - 1){1'b0}}, 1'b1} :
                        (zero_a) ? {(sig_width){1'b0}} :
                                   norm_out[sig_width - 1:0];
      assign s_out = (max_exp_a) ? 0 : signout;

      assign z = {s_out, ez_out, frac_out};
    end
    else if ((ieee_compliance == 0) && _large_sig_cond) begin : GEN_ie0lrg
      assign ez_out = (max_exp_a) ? {(exp_width){1'b1}} :
                      (zero_a) ? 
                        ((sin_cos) ? {1'b0, {(exp_width - 1){1'b1}}} :
                                     {(exp_width){1'b0}}) :
                      (em_out < 0) ? 0 :
                                     em_out[exp_width - 1:0];
      assign frac_out = (max_exp_a) ? 0 :
                        (em_out <= 0) ? 0 :
                        (zero_a) ? {(sig_width){1'b0}} :
                                   norm_out[sig_width - 1:0];
      assign s_out = (max_exp_a) ? 0 : signout;

      assign z = {s_out, ez_out, frac_out};
    end
    else begin : GEN_not_lrg
      assign z = ((sig_width < 10) & (em_out <= 0) & ~max_exp_a) ?
                   {signout, {(exp_width + sig_width){1'b0}}} :
                 (max_exp_a) ? nan_reg :
                 (zero_a) ? 
                   ((sin_cos) ? {2'b0, {(exp_width - 1){1'b1}}, {(sig_width){1'b0}}} :
                                {signout, {(sig_width + exp_width){1'b0}}}) :
                 {signout, em_out[exp_width - 1:0], norm_out[sig_width - 1:0]};
    end
  endgenerate
  assign status = {2'b0, status_inexact, 1'b0, status_tiny, status_invalid, 1'b0, status_zero};

endmodule
