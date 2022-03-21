
//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-Point Divider
//
//              DW_fp_div calculates the floating-point division
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
//              faithful_round  select the faithful_rounding that admits 1 ulp error
//                              0 - default value. it keeps all rounding modes
//                              1 - z has 1 ulp error. RND input does not affect
//                                  the output
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              b               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              Rounding Mode Input
//
//              Output ports    Size & Description
//              ============    ==================
//              z               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Output
//              status          8 bits
//                              Status Flags Output
//
// Modified:
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_fp_div (
  a,
  b,
  rnd,
  z,
  status
  // Embedded dc_shell script
  // _model_constraint_2
  // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

  parameter sig_width = 23;      // RANGE 2 TO 60
  parameter exp_width = 8;       // RANGE 3 TO 31
  parameter ieee_compliance = 0; // RANGE 0 TO 1
  parameter faithful_round = 0;  // RANGE 0 TO 1


  `define RND_Width  4
  `define RND_Inc  0
  `define RND_Inexact  1
  `define RND_HugeInfinity  2
  `define RND_TinyminNorm  3

  `define f_sig_width ((faithful_round == 1) ? sig_width : sig_width + 1)
  `define log_awidth ((sig_width + 1>65536)?((sig_width + 1>16777216)?((sig_width + 1>268435456)?((sig_width + 1>536870912)?30:29):((sig_width + 1>67108864)?((sig_width + 1>134217728)?28:27):((sig_width + 1>33554432)?26:25))):((sig_width + 1>1048576)?((sig_width + 1>4194304)?((sig_width + 1>8388608)?24:23):((sig_width + 1>2097152)?22:21)):((sig_width + 1>262144)?((sig_width + 1>524288)?20:19):((sig_width + 1>131072)?18:17)))):((sig_width + 1>256)?((sig_width + 1>4096)?((sig_width + 1>16384)?((sig_width + 1>32768)?16:15):((sig_width + 1>8192)?14:13)):((sig_width + 1>1024)?((sig_width + 1>2048)?12:11):((sig_width + 1>512)?10:9))):((sig_width + 1>16)?((sig_width + 1>64)?((sig_width + 1>128)?8:7):((sig_width + 1>32)?6:5)):((sig_width + 1>4)?((sig_width + 1>8)?4:3):((sig_width + 1>2)?2:1)))))
  `define sig_sub_25 ((`f_sig_width >= 25) ? `f_sig_width - 25 : 0)
  `define sig_mul2_sub_47 ((`f_sig_width >= 24) ? 2 * `f_sig_width - 47 : 0)
  `define sig_mul2_sub_21 ((`f_sig_width >= 11) ? 2 * `f_sig_width - 21 : 0)
  `define sig_sub_11 ((`f_sig_width >= 11) ? `f_sig_width - 11 : 0)
  `define x2de4_t_range_1 ((`f_sig_width >= 25) ? 2 * `f_sig_width - 47 : 0)
  `define x2de4_t_range_2 ((`f_sig_width >= 25) ? `f_sig_width - 22 : 0)
  `define de2h_t_range_1 ((`f_sig_width >= 25) ? `f_sig_width - 11 : 0)
  `define de2h_t_range_2 ((`f_sig_width >= 25) ? 13 : 0)
  `define x2de4_range_1 ((`f_sig_width >= 25) ? `f_sig_width + 3 : 0)
  `define x2de4_range_2 ((`f_sig_width >= 25) ? 27 : 0)
  `define x2de4_range_3 ((`f_sig_width >= 25) ? 2 * `f_sig_width - 47 : 0)
  `define x2de4_range_4 ((`f_sig_width >= 25) ? `f_sig_width - 23 : 0)
  `define de2_range_1 ((`f_sig_width >= 11) ? `f_sig_width + 1 : 0)
  `define de2_range_2 ((`f_sig_width >= 11) ? 12 : 0)
  `define de2h_range_1 ((`f_sig_width >= 11) ? 2 * `f_sig_width - 21 : 0)
  `define de2h_range_2 ((`f_sig_width >= 11) ? `f_sig_width - 10 : 0)
  `define x1de2_range_1 ((`f_sig_width >= 11) ? `f_sig_width + 3 : 0)
  `define x1de2_range_2 ((`f_sig_width >= 11) ? 14 : 0)
  `define log_sigwidth ((`f_sig_width + 1>65536)?((`f_sig_width + 1>16777216)?((`f_sig_width + 1>268435456)?((`f_sig_width + 1>536870912)?30:29):((`f_sig_width + 1>67108864)?((`f_sig_width + 1>134217728)?28:27):((`f_sig_width + 1>33554432)?26:25))):((`f_sig_width + 1>1048576)?((`f_sig_width + 1>4194304)?((`f_sig_width + 1>8388608)?24:23):((`f_sig_width + 1>2097152)?22:21)):((`f_sig_width + 1>262144)?((`f_sig_width + 1>524288)?20:19):((`f_sig_width + 1>131072)?18:17)))):((`f_sig_width + 1>256)?((`f_sig_width + 1>4096)?((`f_sig_width + 1>16384)?((`f_sig_width + 1>32768)?16:15):((`f_sig_width + 1>8192)?14:13)):((`f_sig_width + 1>1024)?((`f_sig_width + 1>2048)?12:11):((`f_sig_width + 1>512)?10:9))):((`f_sig_width + 1>16)?((`f_sig_width + 1>64)?((`f_sig_width + 1>128)?8:7):((`f_sig_width + 1>32)?6:5)):((`f_sig_width + 1>4)?((`f_sig_width + 1>8)?4:3):((`f_sig_width + 1>2)?2:1)))))
  `define x0_rbit ((`f_sig_width > 8) ? 0 : 8 - `f_sig_width - 1)
  `define nine_mf ((`f_sig_width >= 9) ? 1 : 9 - `f_sig_width)
  `define nine_index ((`f_sig_width >= 9) ? `f_sig_width - 9 : 0)
  `define eight_mf ((`f_sig_width >= 8) ? 1 : 8 - `f_sig_width)
  `define q0de_size (`f_sig_width - 3)

  //-------------------------------------------------------
  input  [(exp_width + sig_width):0] a;
  input  [(exp_width + sig_width):0] b;
  input  [2:0] rnd;

  output [8    -1:0] status;
  output [(exp_width + sig_width):0] z;

  wire  [2:0] rndi;
  wire [exp_width - 1:0] ea;
  wire [exp_width - 1:0] eb;
  wire [sig_width - 1:0] sa;
  wire [sig_width - 1:0] sb;
  wire signa;
  wire signb;
  wire [sig_width:0] ma;
  wire [sig_width:0] mb;
  wire [sig_width:0] normed_ma;
  wire [sig_width:0] normed_mb;
  wire [`f_sig_width:0] divd;
  wire sa_zero;
  wire sb_zero;
  wire ea_zero;
  wire eb_zero;
  wire ea_inf;
  wire eb_inf;
  wire mz_guard_bit0;
  wire mz_round_bit0;
  wire mz_sticky_bit0;
  wire mz_guard_bit1;
  wire mz_round_bit1;
  wire mz_sticky_bit1;
  wire guard_bit0;
  wire round_bit0;
  wire sticky_bit0;
  wire guard_bit1;
  wire round_bit1;
  wire sticky_bit1;
  wire sign;
  wire inf_a;
  wire inf_b;
  wire nan_a;
  wire nan_b;
  wire zero_a;
  wire zero_b;
  wire denorm_a;
  wire denorm_b;
  wire nan_case;
  wire inf_case;
  wire zero_case;
  wire normal_case;
  wire [`f_sig_width:0] quo;
  wire [`f_sig_width+3:0] quo_pre;
  wire [sig_width:0] rem;
  wire dzero;
  wire shift_req;
  wire stk_check_from_rem;
  wire [sig_width:0] mz;
  wire [sig_width:0] div_out;
  wire [sig_width:0] mz_rounded;
  wire [`f_sig_width:0] mz_rounded_pre;
  wire signed [exp_width + 1:0] ez;
  wire signed [exp_width + 1:0] ez_norm;
  wire signed [exp_width + 1:0] ez_norm_pre;
  wire signed [exp_width + 1:0] ez_norm_modified;
  wire signed [exp_width + 1:0] ez_norm_mod;
  wire [exp_width + 1:0] rshift_amount;
  wire over_inf;
  wire below_zero;
  wire max_norm;
  wire min_norm;
  wire infinity;
  wire zero;
  wire exp_zero;
  wire [sig_width - 1:0] sig_result;
  wire [exp_width - 1:0] exp_result;
  wire [sig_width - 1:0] sig_inf_result;
  wire [sig_width - 1:0] sig_nan_result;
  wire [`log_awidth:0] lzd_ina;
  wire [`log_awidth:0] lzd_inb;
  wire rshift_ovfl;
  wire [sig_width + `f_sig_width + 1 : 0] rshift_out;
  wire sig_below_zero;
  wire [(exp_width + sig_width):0] b;
  wire mb_zero;
  wire check_ez;
  wire check_mz;
  wire rshift_amount_one;
  wire [8:0] addr; // 9b ROM input
  wire [7:0] rom_out; // 8b ROM output
  wire [8:0] x0;
  wire [`f_sig_width + 3:0] x1;
  wire [`f_sig_width + 3:0] x2;
  wire [`f_sig_width + 3:0] x3;
  wire [`f_sig_width + 9:0] y0;
  wire [`f_sig_width:0] sig;
  wire [sig_width:0] sig_pre;
  wire [`f_sig_width + 1:0] de;
  wire [`sig_mul2_sub_21:0] de2;
  wire [`sig_sub_11:0] de2h;
  wire [`f_sig_width + 10:0] x0de;
  wire [`sig_mul2_sub_21:0] x1de2;
  wire [2 * `f_sig_width + 3:0] de2_g;
  wire [`sig_sub_25:0] de2h_t;
  wire [4 * `f_sig_width + 7:0] de4_g;
  wire [3 * `f_sig_width + 6:0] x1de2_g;
  wire [`sig_mul2_sub_47:0] de4;
  wire [`sig_mul2_sub_47:0] x2de4;
  wire [`sig_sub_25:0] x2de4_t;
  wire qd_m;
  wire [2 * `f_sig_width + 1:0] qd1;
  wire [`f_sig_width:0] quo1;
  wire quo1_msb;
  wire [`f_sig_width + 1:0] quo_in;
  wire [`f_sig_width + 1:0] quo1_in;
  wire [`f_sig_width:0] quo2;
  wire [`f_sig_width:0] quo3;
  wire [`f_sig_width:0] quo_sel0;
  wire [`f_sig_width:0] quo_sel1;
  wire [`f_sig_width:0] quo_final;
  wire inc0;
  wire inc1;
  wire [`f_sig_width:0] quo_rshout;
  wire [`f_sig_width:0] quo1_rshout;
  wire [sig_width:0] quo_rsh_rounded;
  wire [sig_width:0] quo1_rsh_rounded;
  wire [sig_width:0] quo_rsh_final;
  wire sig_zero;
  wire [8:0] x0_inc;
  wire [8:0] q0_out;
  wire [`f_sig_width + 3:0] x1_inc;
  wire [`f_sig_width + 3:0] x2_inc;
  wire [`f_sig_width + 3:0] x3_inc;
  wire [8:8 - `f_sig_width] x0_rounded;
  wire [`f_sig_width:0] x1_rounded;
  wire [`f_sig_width:0] x2_rounded;
  wire [`f_sig_width:0] x3_rounded;
  wire [`f_sig_width + 9:0] q0;
  wire [`f_sig_width + 3:0] x1_0;
  wire [`f_sig_width + 3:0] x1_1;
  wire [`f_sig_width + 3:0] x1_pre;
  wire x1_pre_msb;
  wire q0_msb;
  wire carry_msb;
  wire quo_final_ovfl;
  wire inputs_equal;
  wire rshift_amount_nonzero;
  wire rshift_denormal_sticky;
  wire rshift_denormal_round;
  wire below_zero_pre;
  wire [sig_width - 1:0] quo_sticky;
  wire [sig_width - 1:0] quo1_sticky;
  wire quo_sticky_check;
  wire quo1_sticky_check;
  wire [2 * `q0de_size - 1:0] q0de;
  wire [2 * `f_sig_width + 11:0] q0de_g;
  wire [`f_sig_width + 3:0] x2_pre;
  wire x2_pre_msb;
  wire [`f_sig_width + 3:0] x3_pre;
  wire x3_pre_msb;
  wire qd_m_faith;
  wire [1:0] divd10;
  wire [1:0] qd10;
  wire qd1_r_zero;
  wire qd1_d_equal;
  wire qd1_d_equal_pre;
  wire [sig_width:0] dummy_ul1;
  wire [sig_width:0] dummy_ul2;
  wire dummy1;
  wire dummy2;

  wire [`RND_Width - 1:0] RND_eval;
  reg [`RND_Width - 1:0] RND_eval0;
  reg [`RND_Width - 1:0] RND_eval1;

  //assign rndi = 1; // RZ mode
  //assign rndi = (faithful_round) ? 1 : rnd;
  assign rndi = rnd;

  // Unpack the FP Numbers
  assign {signa, ea, sa} = a; // dividend
  assign {signb, eb, sb} = b; // divisor

  assign ma = (ieee_compliance & denorm_a) ? {1'b0, sa} : {1'b1, sa};
  assign mb = (ieee_compliance & denorm_b) ? {1'b0, sb} : {1'b1, sb};

  // from z0703-SP2, NAN has always + sign. (by kyung)
  assign sign = (nan_case) ? 1'b0 : signa ^ signb;

  // Check Special Inputs
  assign sa_zero = (sa == 0);
  assign sb_zero = (sb == 0);
  assign ea_zero = (ea == 0);
  assign eb_zero = (eb == 0);
  assign ea_inf = (ea == ((((1 << (exp_width-1)) - 1) * 2) + 1));
  assign eb_inf = (eb == ((((1 << (exp_width-1)) - 1) * 2) + 1));

  assign inf_a = (ieee_compliance) ? ea_inf & sa_zero : ea_inf;
  assign inf_b = (ieee_compliance) ? eb_inf & sb_zero : eb_inf;
  assign nan_a = (ieee_compliance) ? ea_inf & ~sa_zero : 1'b0;
  assign nan_b = (ieee_compliance) ? eb_inf & ~sb_zero : 1'b0;
  assign zero_a = (ieee_compliance) ? ea_zero & sa_zero : ea_zero;
  assign zero_b = (ieee_compliance) ? eb_zero & sb_zero : eb_zero;
  assign denorm_a = (ieee_compliance) ? ea_zero & ~sa_zero : 1'b0;
  assign denorm_b = (ieee_compliance) ? eb_zero & ~sb_zero : 1'b0;

  assign nan_case = nan_a | nan_b | (inf_a & inf_b) | (zero_a & zero_b);
  assign inf_case = inf_a | zero_b;
  assign zero_case = zero_a | inf_b;
  assign normal_case = ~nan_case & ~inf_case & ~zero_case;

  assign sig_inf_result = {sig_width{1'b0}};
  assign sig_nan_result = (ieee_compliance) ? {{(sig_width-1){1'b0}}, 1'b1} : {sig_width{1'b0}};

  // Exponent Calculation
  assign ez = (ieee_compliance) ?
              (ea - lzd_ina + denorm_a - eb + lzd_inb - denorm_b + 
                {(exp_width - 1){1'b1}}) :
              ea - eb + {(exp_width - 1){1'b1}};

  // Normalization of Denormal Inputs
  // Two LZD and two left shifters are required
  DW_lzd #(sig_width + 1) UL1 (
    .a(ma),
    .enc(lzd_ina),
    .dec(dummy_ul1)
  );

  DW_lzd #(sig_width + 1) UL2 (
    .a(mb),
    .enc(lzd_inb),
    .dec(dummy_ul2)
  );

  generate
    if (ieee_compliance == 1) begin : GEN_04A
      assign normed_ma = ma << lzd_ina;
      assign normed_mb = mb << lzd_inb;
      assign mb_zero = (normed_mb[sig_width - 1:0] == 0);
    end
    else begin : GEN_04B
      assign normed_ma = ma;
      assign normed_mb = mb;
      assign mb_zero = sb_zero;
    end
  endgenerate

  assign inputs_equal = (normed_ma == normed_mb);

  //////////////////////////////////////////////////////
  // Integer Division by Newton-Raphson Method
  //////////////////////////////////////////////////////
  // Division of D / d
  // Dividend D
  assign divd = (faithful_round) ? normed_ma : {normed_ma, 1'b0};

  assign sig_pre = (ieee_compliance) ? 
                     normed_mb :
                     {1'b1, sb[sig_width - 1:0]};
  assign sig = (faithful_round) ? sig_pre : {sig_pre, 1'b0};
  assign sig_zero = (sig[`f_sig_width - 1:0] == 0);
  

  // ROM Lookup Table
  generate
    if (`f_sig_width >= 9) begin : GEN_05A
      assign addr = sig[`f_sig_width - 1:`nine_index];
    end
    else begin : GEN_05B
      assign addr = {sig[`f_sig_width - 1:0], {(`nine_mf){1'b0}}};
    end
  endgenerate

  assign x0 = {1'b1, rom_out};

  //--------------------------------------
  // Stage 1
  //--------------------------------------

  // M1:[9b x (f'+1)b] = (f'+10)b
  assign q0 = x0 * divd;

  assign q0_msb = q0[`f_sig_width + 9];
  assign q0_out = (q0_msb) ? q0[`f_sig_width + 9:`f_sig_width + 1] :
                             q0[`f_sig_width + 8:`f_sig_width];

  // M2:[9b x (f'+1)b] = (f'+10)b
  // y0 = LUT x d = 1 - de
  assign y0 = sig * x0; // [9b x (f'+1)b] = (f'+10)b

  assign de = ~y0[`f_sig_width + 1:0]; // de = 0.00000000x1x2x3... [25b]


  // M3:q0de: [(f'-3)b x (f'-3)b] = 2f' - 6
  generate
    if (`f_sig_width <= 8) begin : GEN_sw_le_8
      assign q0de = 0;
    end
    else begin : GEN_sw_gt_8
      assign q0de = q0[`f_sig_width + 9:`f_sig_width + 9 - `q0de_size + 1] *
                    de[`f_sig_width + 1:`f_sig_width + 1 - `q0de_size + 1];
    end
  endgenerate

  assign q0de_g = q0 * de;

  assign x1_0 = q0[`f_sig_width + 9:6];
  assign x1_1 = {6'b0, q0de[2 * `q0de_size - 1:2 * `q0de_size - 1 - `f_sig_width + 5 - 1]};
  assign x1_pre = x1_0 + x1_1;
  assign x1_pre_msb = x1_pre[`f_sig_width + 3];

  generate
    if (`f_sig_width <= 14) begin : GEN_06A
      assign x1 = (x1_pre_msb) ? x1_pre : {x1_pre[`f_sig_width + 2:0], 1'b0};
    end
    else begin : GEN_06B
      assign x1 = x1_pre;
    end
  endgenerate

  //--------------------------------------
  // Stage 2
  //--------------------------------------
  generate
    if (`f_sig_width >= 11) begin : GEN_13A
      // de2 = de * de, [(f-10)b x (f-10)b]
      assign de2 = de[`de2_range_1:`de2_range_2] * de[`de2_range_1:`de2_range_2];
      assign de2h = de2[`de2h_range_1:`de2h_range_2];
      // x1de2 = x1 * de2, [(f-10)b x (f-10)b]
      assign x1de2 = x1[`x1de2_range_1:`x1de2_range_2] * de2h;
    end
    else begin : GEN_13B
      assign de2 = 0;
      assign de2h = 0;
      assign x1de2 = 0;
    end
  endgenerate

  assign de2_g = de * de;
  assign x1de2_g = x1 * de2_g;

  // x2 Result

  assign x2_pre = x1 + x1de2[`de2h_range_1:`de2h_range_2];
  assign x2_pre_msb = x2_pre[`f_sig_width + 3];

  generate
    if (`f_sig_width <= 30) begin : GEN_07A
      assign x2 = (x2_pre_msb) ? x2_pre : {x2_pre[`f_sig_width + 2:0], 1'b0};
    end
    else begin : GEN_07B
      assign x2 = x2_pre;
    end
  endgenerate

  //--------------------------------------
  // Stage 3
  //--------------------------------------
  // de4 = de2 * de2
  assign de4_g = de2_g * de2_g;
  // (f - 24)b = f - 11 - 13 + 1 = f - 23b
  // 28b = 29b
  assign de4 = de2h_t * de2h_t;

  generate
    if (`f_sig_width >= 25) begin : GEN_08A
      assign de2h_t = de2h[`de2h_t_range_1:`de2h_t_range_2];
      assign x2de4 = x2[`x2de4_range_1:`x2de4_range_2] * de4[`x2de4_range_3:`x2de4_range_4];
      assign x2de4_t = x2de4[`x2de4_t_range_1:`x2de4_t_range_2];
    end
    else begin : GEN_08B
      assign de2h_t = {`sig_sub_25+1{1'b0}};
      assign x2de4 = {`sig_mul2_sub_47+1{1'b0}};
      assign x2de4_t = {`sig_sub_25+1{1'b0}};
    end
  endgenerate

  // x3 result
  assign x3_pre = x2 + x2de4_t;
  assign x3_pre_msb = x3_pre[`f_sig_width + 3];
  assign x3 = ((x3_pre_msb) ? x3_pre : {x3_pre[`f_sig_width + 2:0], 1'b0});

  //--------------------------------------
  // RNU Logic
  //--------------------------------------
  generate 
    if (`f_sig_width == 8) begin : GEN_09A
      assign x0_inc = q0_out + 1;
    end
    else if (`f_sig_width < 8) begin : GEN_09B
      assign x0_inc = q0_out + {1'b1, {(`x0_rbit + 1){1'b0}}};
    end
    else begin : GEN_09C
      assign x0_inc = 9'b0;
    end
  endgenerate

  assign x1_inc = x1 + 4'b1000;
  assign x2_inc = x2 + 4'b1000;
  assign x3_inc = x3 + 4'b1000;

  assign x0_rounded = (`f_sig_width == 8) ? q0_out[8:`x0_rbit + 1] :
                      (q0_out[`x0_rbit]) ? x0_inc[8:`x0_rbit + 1] :
                                       q0_out[8:`x0_rbit + 1];
  assign x1_rounded = (x1[2]) ? x1_inc[`f_sig_width + 3:3] :
                                x1[`f_sig_width + 3:3];
  assign x2_rounded = (x2[2]) ? x2_inc[`f_sig_width + 3:3] :
                                x2[`f_sig_width + 3:3];
  assign x3_rounded = (x3[2]) ? x3_inc[`f_sig_width + 3:3] :
                                x3[`f_sig_width + 3:3];

  generate
    if (faithful_round == 1) begin : GEN_03A
      assign quo = (`f_sig_width <= 8) ?  x0_rounded :
                   (`f_sig_width <= 14) ? x1_rounded :
                   (`f_sig_width <= 30) ? x2_rounded :
                                          x3_rounded;
    end
    else begin : GEN_03B
      assign quo = (`f_sig_width <= 8) ?  q0_out[8:`eight_mf] :
                   (`f_sig_width <= 14) ? x1[`f_sig_width + 3:3] :
                   (`f_sig_width <= 30) ? x2[`f_sig_width + 3:3] :
                                          x3[`f_sig_width + 3:3];
    end
  endgenerate

  assign carry_msb = (`f_sig_width <= 8) ? q0_msb:
                     (`f_sig_width <= 14) ? x1_pre_msb :
                     (`f_sig_width <= 30) ? x2_pre_msb :
                                            x3_pre_msb;

  assign rem = ~inputs_equal;

  ///////////////////////
  // For the Test
  ///////////////////////
  //assign quo_pre = (`f_sig_width <= 8) ? x0[8:8 - `f_sig_width - 3] :
  //             (`f_sig_width <= 14) ? x1[`f_sig_width + 3:0] :
  //             (`f_sig_width <= 30) ? x2[`f_sig_width + 3:0] :
  //                                    x3[`f_sig_width + 3:0];
  //wire [2 * sig_width + 1:0] z_gdiv;

  //assign z_gdiv = {divd, {(2 * sig_width + 2){1'b0}}} / sig;


  //wire [2 * sig_width + exp_width + 1:0] z_recip;

  //DW_fp_recip #(2 * sig_width + 1, exp_width, 0, 0) Urecip (
  //  .a({a, {(sig_width + 1){1'b0}}}),
  //  .rnd(rnd),
  //  .z(z_recip),
  //  .status(status_recip)
  //);

  //wire [2 * sig_width:0] sig_quo;
  //wire [2 * sig_width:0] sig_recip;
  //wire [2 * sig_width:0] sig_diff;
  //wire ulp1;
  //wire ulph;
  //wire ulpq;

  //assign sig_quo = {quo_pre, {(sig_width - 2){1'b0}}};
  //assign sig_recip = z_recip[2 * sig_width:0];
  //assign sig_diff = (sig_recip >= sig_quo) ? sig_recip - sig_quo :
  //                                           sig_quo - sig_recip;
  //assign ulp1 = (normal_case & ~sig_below_zero) ? sig_diff[sig_width + 1] : 0;
  //assign ulph = (normal_case & ~sig_below_zero) ? sig_diff[sig_width] : 0;
  //assign ulpq = (normal_case & ~sig_below_zero) ? sig_diff[sig_width - 1] : 0;
  //////////////////////////////////////////////////////
  // End of Integer Reciprocal with NR
  //////////////////////////////////////////////////////

  assign  divd10 = divd[1:0];
  assign  qd10 = (carry_msb) ? qd1[sig_width + 2:sig_width + 1] :
                            qd1[sig_width + 3:sig_width + 2];

  assign {quo1_msb ,quo1} = quo + 1'b1;
  assign quo2 = quo + 2'b10;
  assign quo3 = quo + 2'b11;

  assign qd1 = quo1 * sig;

  assign qd1_r_zero = (carry_msb) ? (qd1[`f_sig_width-1:0] == 0) :
                                    (qd1[`f_sig_width:0] == 0);

  // Need to optimize the qor 
  assign qd1_d_equal_pre = (carry_msb) ? 
                             (qd1[`f_sig_width + 1:`f_sig_width + 0] == divd[1:0]) :
                             (qd1[`f_sig_width + 2:`f_sig_width + 1] == divd[1:0]);
  assign qd1_d_equal = qd1_d_equal_pre & qd1_r_zero & ~quo1_msb;
                          
  assign qd_m_faith = (carry_msb) ? 
                        (qd1[sig_width + 2] == (divd[1] == divd[0])) &
                        (qd1[sig_width + 1] != divd[0]) :
                        (qd1[sig_width + 3] == (divd[1] == divd[0])) &
                        (qd1[sig_width + 2] != divd[0]);

  generate
    if (faithful_round) begin : GEN_10A
      assign qd_m = qd1[`f_sig_width + 2];
    end
    else begin : GEN_10B
      assign qd_m = qd_m_faith | qd1_d_equal | inputs_equal;
    end
  endgenerate

  // logics for ieee_compliance = 1 and faithful_round = 0
  assign quo_in = (inputs_equal) ? {1'b1, {(`f_sig_width + 1){1'b0}}} :
                                   {2'b01, quo[`f_sig_width - 1:0]};
  assign quo1_in = (inputs_equal) ? {1'b1, {(`f_sig_width + 1){1'b0}}} :
                   (sig_zero) ? {1'b0, normed_ma, 1'b0} :
                                {2'b01, quo1[`f_sig_width - 1:0]};

  assign {dummy1, quo_rshout, quo_sticky} = {quo_in, {(sig_width){1'b0}}} >> rshift_amount;

  assign {dummy2, quo1_rshout, quo1_sticky} = {quo1_in, {(sig_width){1'b0}}} >> rshift_amount;

  assign quo_sticky_check = (ieee_compliance) ? (quo_sticky != 0) : 1'b1;
  assign quo1_sticky_check = (ieee_compliance) ? (quo1_sticky != 0) : 1'b1;

  assign quo_rsh_rounded = quo_rshout[`f_sig_width:1] + (inc0);
  assign quo1_rsh_rounded = quo1_rshout[`f_sig_width:1] + (inc1);
  assign quo_rsh_final = (sig_zero) ? quo1_rsh_rounded :
                         (qd_m | inputs_equal) ? quo1_rsh_rounded : quo_rsh_rounded;
  
  // sticky check from rem
  assign stk_check_from_rem = (rem != 0);
  
  // 1b Shift (Normalization by mux) //
  // check: can be optimized more for the reciprocal
  assign shift_req = (normed_ma < normed_mb);

  generate
    if (faithful_round == 1) begin : GEN_12A
      assign mz = quo;
    end
    else begin : GEN_12B
      assign mz = quo[`f_sig_width:1];
    end
  endgenerate

  // Exponent Normalization
  assign ez_norm_pre = ez - shift_req;
  //assign ez_norm = ez - shift_req + quo_final_ovfl;
  assign ez_norm = ez_norm_pre;
  assign ez_norm_mod = ez_norm + quo_final_ovfl;

  // Rounding Control Setup for Normal Division, ieee_compliance = 0
  assign mz_guard_bit0 = quo[1];
  assign mz_round_bit0 = quo[0];
  assign mz_sticky_bit0 = stk_check_from_rem;
  assign mz_guard_bit1 = quo1[1];
  assign mz_round_bit1 = quo1[0];
  assign mz_sticky_bit1 = stk_check_from_rem;

  // Denorma Output Support
  assign rshift_ovfl = (`f_sig_width + ez_norm + 1 + inputs_equal < 0); // -ez > f + 1

  generate
    if (ieee_compliance == 1) begin : GEN_01A
      assign rshift_amount = 
               (ez_norm_pre[exp_width + 1] | (ez_norm_pre == 0)) ?
                 ((rshift_ovfl) ? sig_width + 2 : 1 - ez_norm_pre + inputs_equal) : 0;
      assign rshift_amount_nonzero = (rshift_amount != 0);
      assign rshift_denormal_round = (rshift_amount > sig_width);
      assign rshift_denormal_sticky = (rshift_amount > sig_width + 1 + inputs_equal);
      assign rshift_out = {mz, {(`f_sig_width + 1){1'b0}}} >> rshift_amount;
      assign div_out = rshift_out[sig_width + `f_sig_width + 1:`f_sig_width + 1];
    end
    else begin : GEN_01B
      assign rshift_amount = {exp_width+2{1'b0}};
      assign rshift_amount_nonzero = 1'b0;
      assign rshift_denormal_round = 1'b0;
      assign rshift_denormal_sticky = 1'b0;
      assign rshift_out = {sig_width + `f_sig_width + 2{1'b0}};
      assign div_out = mz;
    end
  endgenerate

  assign rshift_amount_one = (rshift_amount == 1);

  // Final Rounding Control Setup
  assign guard_bit0 = (faithful_round) ? 1'b0 :
                      (inputs_equal) ? 1'b0 :
                      (ieee_compliance) ?  
                        quo_rshout[1] :
                        (sig_zero) ? 1'b0 : mz_guard_bit0;
  assign round_bit0 = (faithful_round) ? 1'b0 :
                      (inputs_equal) ? 1'b0 :
                      (ieee_compliance) ? 
                        quo_rshout[0] :
                        (sig_zero) ? 1'b0 : mz_round_bit0;
  assign sticky_bit0 = (faithful_round) ? 1'b1 :
                       (rshift_denormal_sticky) ? 1'b1 :
                       (inputs_equal) ? 1'b0 :
                       (sig_zero) ? 
                         ((rshift_amount_nonzero) ? quo_sticky_check : 1'b0) :
                         1'b1;
  assign guard_bit1 = (faithful_round) ? 1'b0 :
                      (inputs_equal) ? 1'b0 :
                      (ieee_compliance) ? 
                        quo1_rshout[1] :
                        (sig_zero | qd1_d_equal) ? 1'b0 : mz_guard_bit1;
  assign round_bit1 = (faithful_round) ? 1'b0 :
                      (inputs_equal & ~ieee_compliance) ? 1'b0 :
                      (ieee_compliance) ? 
                        quo1_rshout[0] :
                        (sig_zero | qd1_d_equal) ? 1'b0 : mz_round_bit1;
  assign sticky_bit1 = (faithful_round) ? 1'b1 :
                       (rshift_denormal_sticky) ? 1'b1 :
                       (inputs_equal) ? 1'b0 :
                       (sig_zero | qd1_d_equal) ? 
                         ((rshift_amount_nonzero) ? quo1_sticky_check : 1'b0) :
                         1'b1;

  // Output Selection
  assign inc0 = RND_eval0[`RND_Inc];
  assign inc1 = RND_eval1[`RND_Inc];

  assign quo_sel0 = (inc0 | inputs_equal) ? quo2 : quo;
  assign quo_sel1 = (inc1 | inputs_equal) ? quo3 : quo1; /////////

  assign quo_final = (qd_m) ? quo_sel1 : quo_sel0;
  assign RND_eval = (qd_m) ? RND_eval1 : RND_eval0;

  generate
    if ((ieee_compliance == 1) & (faithful_round == 0)) begin : GEN_02A
      assign quo_final_ovfl = (quo_final[`f_sig_width] != quo[`f_sig_width]) & ~inputs_equal;
    end
    else begin : GEN_02B
      assign quo_final_ovfl = 1'b0;
    end
  endgenerate

  // Rounding Addition
  assign mz_rounded_pre = (mb_zero & ~ieee_compliance) ? 
                            divd :
                          (faithful_round) ? div_out : quo_final;

  generate
    if (faithful_round == 1) begin : GEN_11A
      assign mz_rounded = mz_rounded_pre;
    end
    else if (ieee_compliance == 1) begin : GEN_11B
      assign mz_rounded = quo_rsh_final;
    end
    else begin : GEN_11C
      assign mz_rounded = mz_rounded_pre[`f_sig_width:1];
    end
  endgenerate

  // Huge, Tiny Setup
  assign over_inf = (ez_norm_mod[exp_width:0] >= ((((1 << (exp_width-1)) - 1) * 2) + 1)) & ~ez_norm_mod[exp_width + 1];
  assign below_zero = (ez_norm_mod == 0) | ez_norm_mod[exp_width + 1];
  assign below_zero_pre = (ez_norm_pre == 0) | ez_norm_pre[exp_width + 1];
  assign sig_below_zero = (ieee_compliance) ? 1'b0 : below_zero;

  assign infinity = over_inf & RND_eval0[`RND_HugeInfinity];
  assign max_norm = over_inf & ~RND_eval0[`RND_HugeInfinity];
  assign min_norm = (ieee_compliance) ? 1'b0 : below_zero & RND_eval0[`RND_TinyminNorm];
  assign exp_zero = (ieee_compliance) ? 
                      below_zero & (~(check_ez & check_mz)) : 
                      below_zero & ~RND_eval0[`RND_TinyminNorm]; // need to verify more
  assign zero = (ieee_compliance) ?
           (sig_result == 0) & (exp_result == 0) : // need to improve more
           exp_zero;

  assign check_ez = (ez_norm_mod == 0);
  assign check_mz = mz_rounded[sig_width];
  assign ez_norm_modified = (ieee_compliance & (ez_norm_mod == 0) & mz_rounded[sig_width]) ? 
                              {{(exp_width+1){1'b0}}, 1'b1} : ez_norm_mod;

  // Status Flag Setup
  assign status[7] = zero_b & ~(zero_a | nan_a | (inf_a & (ieee_compliance == 1)));
  assign status[6] = 1'b0;
  assign status[5] = (faithful_round) ?
    normal_case & (over_inf | sig_below_zero | RND_eval[`RND_Inexact] & (~inputs_equal & ~mb_zero | rshift_amount_nonzero)) :
    normal_case & (over_inf | sig_below_zero | RND_eval[`RND_Inexact] & (~qd1_d_equal & ~inputs_equal & ~mb_zero | rshift_amount_nonzero));
  assign status[4] = normal_case & over_inf;
  assign status[3] = normal_case & below_zero_pre;
  assign status[2] = nan_case;
  assign status[1] = ~nan_case & ((infinity & ~zero_case) | inf_case);
  assign status[0] = ~nan_case & (zero | zero_case) & ~zero_b;

  // Output Generation
  assign sig_result = (nan_case) ?  sig_nan_result :
                      (inf_case | (infinity & ~zero_case)) ?  sig_inf_result :
                      (max_norm) ? {(sig_width){1'b1}} :
                      (zero_case | sig_below_zero |
                       inputs_equal & ~rshift_amount_nonzero) ?  {sig_width{1'b0}} :
                        mz_rounded[sig_width - 1:0];

  assign exp_result = (nan_case | inf_case | (infinity & ~zero_case)) ?  {(exp_width){1'b1}} :
                      (exp_zero | zero_case) ? {exp_width{1'b0}} :
                      (max_norm) ?  {{(exp_width - 1){1'b1}}, 1'b0} :
                      (min_norm) ?  {{(exp_width-1){1'b0}}, 1'b1} :
                                    ez_norm_modified[exp_width - 1:0];

  assign z = {sign, exp_result, sig_result};
 


  //--------------------------------------------------
  // Rounding Block Description
  //--------------------------------------------------
  
  //----------------------------------------
  // RND_eval[3] : RND_TinyminNorm
  // RND_eval[2] : RND_HugeInfinity
  // RND_eval[1] : RND_Inexact
  // RND_eval[0] : RND_Inc
  //----------------------------------------

  always @* begin : G_02
  
    RND_eval0[`RND_TinyminNorm] = 0;
    RND_eval0[`RND_HugeInfinity] = 0;
    RND_eval0[`RND_Inexact] = round_bit0 | sticky_bit0;
    RND_eval0[`RND_Inc] = 0;

    case (rndi)

      // ----------------------------------------
      // Round Nearest Even (RNE) Mode
      // ----------------------------------------
      3'b000: begin
        RND_eval0[`RND_Inc] = round_bit0 & (guard_bit0 | sticky_bit0);
        RND_eval0[`RND_HugeInfinity] = 1;
        RND_eval0[`RND_TinyminNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Zero (RZ) Mode
      // ----------------------------------------
      3'b001: begin
        RND_eval0[`RND_Inc] = 0;
        RND_eval0[`RND_HugeInfinity] = 0;
        RND_eval0[`RND_TinyminNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Positive Infinity Mode
      // ----------------------------------------
      3'b010: begin
        RND_eval0[`RND_Inc] = ~sign & (round_bit0 | sticky_bit0);
        RND_eval0[`RND_HugeInfinity] = ~sign;
        RND_eval0[`RND_TinyminNorm] = ~sign;
      end
      
      // ----------------------------------------
      // Round to Negative Infinity Mode
      // ----------------------------------------
      3'b011: begin
        RND_eval0[`RND_Inc] = sign & (round_bit0 | sticky_bit0);
        RND_eval0[`RND_HugeInfinity] = sign;
        RND_eval0[`RND_TinyminNorm] = sign;
      end
      
      // ----------------------------------------
      // Round to Nearest Up (RNU) Mode
      // ----------------------------------------
      3'b100: begin
        RND_eval0[`RND_Inc] = round_bit0;
        RND_eval0[`RND_HugeInfinity] = 1;
        RND_eval0[`RND_TinyminNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Infinity (RI) Mode
      // ----------------------------------------
      3'b101: begin
        RND_eval0[`RND_Inc] = round_bit0 | sticky_bit0;
        RND_eval0[`RND_HugeInfinity] = 1;
        RND_eval0[`RND_TinyminNorm] = 1;
      end
      
      default: begin
        RND_eval0[`RND_Inc] = 1'bx;
        RND_eval0[`RND_HugeInfinity] = 1'bx;
        RND_eval0[`RND_TinyminNorm] = 1'bx;
      end
    endcase
  end

  always @* begin : G_01
  
    RND_eval1[`RND_TinyminNorm] = 0;
    RND_eval1[`RND_HugeInfinity] = 0;
    RND_eval1[`RND_Inexact] = round_bit1 | sticky_bit1;
    RND_eval1[`RND_Inc] = 0;

    case (rndi)

      // ----------------------------------------
      // Round Nearest Even (RNE) Mode
      // ----------------------------------------
      3'b000: begin
        RND_eval1[`RND_Inc] = round_bit1 & (guard_bit1 | sticky_bit1);
        RND_eval1[`RND_HugeInfinity] = 1;
        RND_eval1[`RND_TinyminNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Zero (RZ) Mode
      // ----------------------------------------
      3'b001: begin
        RND_eval1[`RND_Inc] = 0;
        RND_eval1[`RND_HugeInfinity] = 0;
        RND_eval1[`RND_TinyminNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Positive Infinity Mode
      // ----------------------------------------
      3'b010: begin
        RND_eval1[`RND_Inc] = ~sign & (round_bit1 | sticky_bit1);
        RND_eval1[`RND_HugeInfinity] = ~sign;
        RND_eval1[`RND_TinyminNorm] = ~sign;
      end
      
      // ----------------------------------------
      // Round to Negative Infinity Mode
      // ----------------------------------------
      3'b011: begin
        RND_eval1[`RND_Inc] = sign & (round_bit1 | sticky_bit1);
        RND_eval1[`RND_HugeInfinity] = sign;
        RND_eval1[`RND_TinyminNorm] = sign;
      end
      
      // ----------------------------------------
      // Round to Nearest Up (RNU) Mode
      // ----------------------------------------
      3'b100: begin
        RND_eval1[`RND_Inc] = round_bit1;
        RND_eval1[`RND_HugeInfinity] = 1;
        RND_eval1[`RND_TinyminNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Infinity (RI) Mode
      // ----------------------------------------
      3'b101: begin
        RND_eval1[`RND_Inc] = round_bit1 | sticky_bit1;
        RND_eval1[`RND_HugeInfinity] = 1;
        RND_eval1[`RND_TinyminNorm] = 1;
      end
      
      default: begin
        RND_eval1[`RND_Inc] = 1'bx;
        RND_eval1[`RND_HugeInfinity] = 1'bx;
        RND_eval1[`RND_TinyminNorm] = 1'bx;
      end
    endcase
  end
  //////////////////////////////////////////////////////
  // ROM Implementation
  //////////////////////////////////////////////////////

    // begin product term assignments

    `define pt_1 ( ~addr[8] & ~addr[6] & ~addr[4] & ~addr[2] & ~addr[1])
    `define pt_2 ( ~addr[8] & ~addr[6] & ~addr[4] & ~addr[3])
    `define pt_3 ( ~addr[8] & ~addr[6] & ~addr[5])
    `define pt_4 ( ~addr[8] & ~addr[7])
    `define pt_5 ( ~addr[8] & addr[6] & ~addr[5] & ~addr[4] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_6 ( ~addr[8] & ~addr[6] & addr[5] & addr[3] & addr[2])
    `define pt_7 ( ~addr[8] & ~addr[6] & addr[5] & addr[3] & addr[1])
    `define pt_8 ( ~addr[8] & addr[6] & ~addr[5] & ~addr[4] & ~addr[3])
    `define pt_9 ( ~addr[8] & ~addr[6] & addr[5] & addr[4])
    `define pt_10 ( ~addr[7] & ~addr[6] & ~addr[5])
    `define pt_11 ( ~addr[7] & ~addr[6] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_12 ( ~addr[8] & addr[7] & addr[6])
    `define pt_13 ( ~addr[7] & ~addr[6] & ~addr[3] & ~addr[2] & ~addr[0])
    `define pt_14 ( ~addr[7] & ~addr[6] & ~addr[4])
    `define pt_15 ( ~addr[8] & addr[6] & ~addr[5] & addr[3] & addr[2])
    `define pt_16 ( ~addr[8] & ~addr[7] & addr[5] & ~addr[4] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_17 ( ~addr[8] & addr[6] & ~addr[5] & addr[3] & addr[1])
    `define pt_18 ( ~addr[7] & addr[6] & addr[4] & ~addr[3] & ~addr[1])
    `define pt_19 ( ~addr[8] & addr[6] & ~addr[5] & addr[3] & addr[0])
    `define pt_20 ( ~addr[7] & addr[6] & addr[4] & ~addr[3] & ~addr[2])
    `define pt_21 ( ~addr[8] & addr[6] & addr[5] & ~addr[4] & ~addr[3])
    `define pt_22 ( ~addr[8] & addr[6] & ~addr[5] & addr[4])
    `define pt_23 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[2])
    `define pt_24 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[1])
    `define pt_25 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[3])
    `define pt_26 ( ~addr[8] & addr[7] & ~addr[6] & addr[5] & addr[4])
    `define pt_27 ( ~addr[8] & addr[7] & ~addr[6] & addr[5] & addr[3] & addr[1])
    `define pt_28 ( ~addr[8] & addr[7] & ~addr[6] & addr[5] & addr[3] & addr[2])
    `define pt_29 ( addr[8] & ~addr[7] & addr[5] & addr[4] & addr[3])
    `define pt_30 ( addr[8] & ~addr[7] & addr[5] & addr[4] & addr[2])
    `define pt_31 ( addr[8] & ~addr[7] & addr[5] & addr[4] & addr[1] & addr[0])
    `define pt_32 ( addr[8] & ~addr[7] & addr[6])
    `define pt_33 ( ~addr[8] & addr[7] & addr[6] & ~addr[5])
    `define pt_34 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[5])
    `define pt_35 ( ~addr[7] & addr[6] & addr[5] & ~addr[4])
    `define pt_36 ( addr[8] & ~addr[6] & addr[5] & addr[4] & addr[1] & addr[0])
    `define pt_37 ( ~addr[8] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[0])
    `define pt_38 ( addr[7] & addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & ~addr[2] & ~addr[0])
    `define pt_39 ( ~addr[7] & ~addr[5] & ~addr[4] & addr[3] & ~addr[2] & addr[1])
    `define pt_40 ( addr[7] & addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_41 ( ~addr[8] & ~addr[6] & ~addr[4] & addr[3] & addr[2] & ~addr[1])
    `define pt_42 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[4] & addr[1])
    `define pt_43 ( addr[7] & ~addr[6] & addr[5] & addr[3] & addr[1])
    `define pt_44 ( ~addr[7] & ~addr[5] & ~addr[4] & addr[3] & ~addr[2] & addr[0])
    `define pt_45 ( ~addr[8] & ~addr[7] & addr[6] & addr[4] & ~addr[3] & addr[2] & addr[1])
    `define pt_46 ( ~addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[3])
    `define pt_47 ( ~addr[8] & addr[6] & addr[5] & addr[4] & addr[3])
    `define pt_48 ( addr[8] & ~addr[7] & addr[6] & ~addr[5] & ~addr[3])
    `define pt_49 ( ~addr[7] & addr[6] & ~addr[5] & addr[4] & ~addr[2])
    `define pt_50 ( ~addr[7] & addr[6] & ~addr[5] & ~addr[4] & addr[3] & addr[2])
    `define pt_51 ( ~addr[7] & addr[6] & ~addr[5] & addr[4] & ~addr[1])
    `define pt_52 ( ~addr[8] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[2])
    `define pt_53 ( addr[8] & ~addr[7] & ~addr[5] & ~addr[4] & ~addr[2])
    `define pt_54 ( ~addr[8] & addr[7] & addr[5] & addr[4])
    `define pt_55 ( ~addr[8] & addr[7] & ~addr[5] & ~addr[4] & ~addr[3])
    `define pt_56 ( ~addr[8] & addr[7] & addr[6] & addr[5] & addr[3])
    `define pt_57 ( addr[8] & ~addr[6] & addr[5] & addr[4] & addr[2])
    `define pt_58 ( addr[8] & addr[7] & ~addr[6] & addr[5])
    `define pt_59 ( addr[8] & addr[7] & ~addr[6] & addr[4])
    `define pt_60 ( addr[8] & ~addr[6] & addr[5] & addr[4] & addr[3])
    `define pt_61 ( addr[8] & addr[7] & ~addr[6] & addr[3] & addr[2] & addr[1])
    `define pt_62 ( ~addr[8] & ~addr[6] & addr[5] & addr[4] & ~addr[3] & ~addr[2])
    `define pt_63 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[4] & addr[2])
    `define pt_64 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[4] & addr[3])
    `define pt_65 ( addr[8] & addr[7] & addr[6] & ~addr[5] & addr[1] & addr[0])
    `define pt_66 ( addr[8] & ~addr[7] & addr[6] & addr[5] & ~addr[3] & ~addr[1] & ~addr[0])
    `define pt_67 ( addr[7] & ~addr[5] & ~addr[4] & addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_68 ( ~addr[8] & addr[6] & ~addr[5] & ~addr[4] & addr[3] & addr[0])
    `define pt_69 ( ~addr[8] & ~addr[7] & ~addr[6] & addr[5] & addr[3] & ~addr[2] & ~addr[0])
    `define pt_70 ( ~addr[6] & ~addr[5] & addr[4] & ~addr[3])
    `define pt_71 ( addr[8] & ~addr[6] & ~addr[5] & addr[4] & ~addr[1])
    `define pt_72 ( ~addr[8] & addr[6] & addr[5] & addr[3] & ~addr[2] & ~addr[1])
    `define pt_73 ( ~addr[8] & ~addr[6] & addr[4] & addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_74 ( addr[8] & ~addr[6] & ~addr[5] & ~addr[4] & addr[3] & addr[2] & addr[1])
    `define pt_75 ( ~addr[8] & ~addr[7] & addr[5] & addr[4] & addr[3] & ~addr[1])
    `define pt_76 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[4] & ~addr[3] & addr[1])
    `define pt_77 ( ~addr[8] & ~addr[7] & addr[6] & addr[5] & addr[4] & addr[2] & addr[1])
    `define pt_78 ( addr[8] & ~addr[7] & ~addr[6] & addr[4] & ~addr[2] & addr[1] & addr[0])
    `define pt_79 ( addr[8] & ~addr[7] & ~addr[6] & ~addr[5] & addr[3] & addr[2] & ~addr[1])
    `define pt_80 ( addr[8] & addr[7] & addr[6] & ~addr[5] & addr[2])
    `define pt_81 ( ~addr[8] & ~addr[7] & addr[5] & addr[4] & addr[3] & ~addr[2])
    `define pt_82 ( ~addr[7] & addr[6] & ~addr[5] & addr[4] & addr[3] & addr[2] & addr[1])
    `define pt_83 ( addr[7] & addr[6] & ~addr[5] & ~addr[4] & addr[3])
    `define pt_84 ( ~addr[7] & addr[6] & addr[5] & ~addr[4] & ~addr[3])
    `define pt_85 ( addr[8] & ~addr[6] & ~addr[5] & addr[4] & ~addr[0])
    `define pt_86 ( ~addr[7] & ~addr[6] & addr[4] & ~addr[3] & addr[2])
    `define pt_87 ( addr[8] & ~addr[7] & ~addr[6] & addr[5] & addr[4] & addr[3])
    `define pt_88 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[3] & addr[2])
    `define pt_89 ( addr[8] & addr[7] & ~addr[5] & addr[4])
    `define pt_90 ( addr[8] & ~addr[7] & addr[6] & addr[5] & ~addr[4])
    `define pt_91 ( ~addr[8] & addr[7] & addr[5] & ~addr[4] & addr[3] & addr[1])
    `define pt_92 ( ~addr[8] & addr[7] & addr[5] & ~addr[4] & addr[3] & addr[2])
    `define pt_93 ( addr[8] & addr[7] & ~addr[6] & addr[5] & ~addr[4] & ~addr[3])
    `define pt_94 ( ~addr[8] & ~addr[7] & addr[5] & addr[3] & ~addr[2] & ~addr[1])
    `define pt_95 ( ~addr[8] & addr[6] & ~addr[5] & ~addr[4] & addr[3] & addr[1])
    `define pt_96 ( ~addr[8] & addr[6] & ~addr[5] & ~addr[4] & addr[3] & addr[2])
    `define pt_97 ( ~addr[8] & ~addr[6] & ~addr[5] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_98 ( addr[8] & ~addr[7] & addr[6] & ~addr[4] & ~addr[3])
    `define pt_99 ( ~addr[8] & addr[7] & addr[4] & ~addr[3])
    `define pt_100 ( addr[8] & ~addr[7] & addr[6] & addr[5] & ~addr[3] & ~addr[2])
    `define pt_101 ( addr[7] & ~addr[6] & ~addr[5] & addr[4] & ~addr[2])
    `define pt_102 ( ~addr[8] & ~addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_103 ( ~addr[8] & ~addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[0])
    `define pt_104 ( addr[7] & ~addr[6] & ~addr[5] & addr[4] & ~addr[3] & ~addr[1] & ~addr[0])
    `define pt_105 ( addr[8] & ~addr[5] & ~addr[4] & addr[3] & addr[2] & addr[1])
    `define pt_106 ( ~addr[8] & ~addr[6] & ~addr[5] & ~addr[3] & ~addr[2] & addr[1])
    `define pt_107 ( ~addr[8] & addr[6] & ~addr[5] & addr[4] & addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_108 ( ~addr[8] & ~addr[7] & ~addr[5] & addr[4] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_109 ( addr[8] & ~addr[7] & addr[5] & addr[4] & addr[3] & ~addr[1] & ~addr[0])
    `define pt_110 ( addr[8] & ~addr[6] & addr[4] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_111 ( ~addr[7] & ~addr[6] & ~addr[5] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_112 ( addr[7] & ~addr[4] & addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_113 ( ~addr[7] & ~addr[6] & ~addr[5] & ~addr[3] & ~addr[2] & ~addr[0])
    `define pt_114 ( addr[8] & ~addr[7] & addr[5] & ~addr[3] & addr[2] & addr[0])
    `define pt_115 ( addr[8] & ~addr[7] & addr[5] & addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_116 ( addr[8] & addr[6] & ~addr[5] & ~addr[4] & addr[3])
    `define pt_117 ( addr[6] & ~addr[5] & ~addr[4] & addr[3] & addr[2] & ~addr[1])
    `define pt_118 ( ~addr[8] & ~addr[6] & addr[5] & addr[3] & addr[2] & addr[1])
    `define pt_119 ( addr[8] & ~addr[6] & addr[4] & ~addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_120 ( ~addr[8] & ~addr[6] & ~addr[4] & ~addr[3] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_121 ( addr[8] & ~addr[7] & addr[6] & addr[5] & addr[4] & addr[3])
    `define pt_122 ( addr[6] & ~addr[5] & ~addr[4] & addr[3] & ~addr[2] & addr[0])
    `define pt_123 ( ~addr[8] & ~addr[7] & addr[6] & ~addr[4] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_124 ( ~addr[8] & ~addr[7] & addr[5] & ~addr[4] & ~addr[2] & addr[1] & addr[0])
    `define pt_125 ( ~addr[7] & ~addr[6] & addr[5] & ~addr[3] & addr[2] & ~addr[1])
    `define pt_126 ( ~addr[8] & ~addr[7] & addr[6] & ~addr[4] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_127 ( ~addr[7] & addr[5] & addr[4] & ~addr[3] & addr[2] & addr[1])
    `define pt_128 ( addr[8] & ~addr[7] & addr[5] & ~addr[4] & ~addr[3])
    `define pt_129 ( addr[8] & addr[6] & addr[5] & ~addr[4] & ~addr[3])
    `define pt_130 ( ~addr[8] & addr[5] & ~addr[4] & addr[3] & addr[2])
    `define pt_131 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & addr[4] & ~addr[3])
    `define pt_132 ( addr[8] & ~addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_133 ( ~addr[8] & ~addr[7] & addr[6] & ~addr[5] & addr[4] & ~addr[3] & addr[2])
    `define pt_134 ( ~addr[6] & ~addr[5] & addr[4] & ~addr[3] & ~addr[2])
    `define pt_135 ( addr[8] & addr[7] & ~addr[6] & addr[4] & ~addr[3] & ~addr[2])
    `define pt_136 ( addr[8] & addr[7] & addr[6] & ~addr[4] & addr[2])
    `define pt_137 ( ~addr[8] & addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & addr[2])
    `define pt_138 ( addr[8] & ~addr[7] & ~addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[0])
    `define pt_139 ( ~addr[8] & addr[7] & addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_140 ( ~addr[8] & addr[7] & addr[4] & addr[3] & addr[2])
    `define pt_141 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & addr[4] & ~addr[2] & ~addr[1])
    `define pt_142 ( addr[8] & ~addr[7] & ~addr[5] & addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_143 ( addr[8] & ~addr[6] & ~addr[5] & ~addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_144 ( ~addr[8] & ~addr[6] & ~addr[5] & addr[4] & addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_145 ( ~addr[8] & addr[7] & addr[6] & ~addr[5] & addr[3])
    `define pt_146 ( addr[8] & addr[7] & addr[6] & ~addr[4] & addr[1] & addr[0])
    `define pt_147 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[5] & ~addr[2] & addr[0])
    `define pt_148 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & addr[4] & ~addr[2] & ~addr[0])
    `define pt_149 ( ~addr[8] & addr[7] & ~addr[6] & addr[5] & ~addr[4] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_150 ( ~addr[8] & addr[7] & ~addr[6] & addr[5] & addr[4] & addr[3] & addr[0])
    `define pt_151 ( addr[8] & ~addr[7] & addr[5] & addr[4] & addr[3] & ~addr[2])
    `define pt_152 ( addr[8] & ~addr[7] & ~addr[5] & ~addr[4] & addr[3] & addr[2])
    `define pt_153 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[5] & ~addr[2] & addr[1])
    `define pt_154 ( ~addr[7] & addr[6] & addr[5] & addr[4] & addr[3] & ~addr[2])
    `define pt_155 ( ~addr[8] & addr[7] & addr[5] & addr[3] & addr[1])
    `define pt_156 ( ~addr[7] & addr[5] & addr[4] & addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_157 ( addr[8] & addr[7] & addr[5] & ~addr[4] & addr[3])
    `define pt_158 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[2])
    `define pt_159 ( addr[7] & addr[6] & ~addr[4] & addr[3])
    `define pt_160 ( ~addr[8] & ~addr[6] & addr[5] & ~addr[4] & ~addr[3] & addr[2] & addr[1] & ~addr[0])
    `define pt_161 ( addr[7] & ~addr[6] & addr[5] & addr[3] & ~addr[2] & addr[1])
    `define pt_162 ( ~addr[8] & ~addr[7] & addr[4] & addr[3] & addr[2] & addr[1] & ~addr[0])
    `define pt_163 ( ~addr[8] & addr[7] & ~addr[4] & ~addr[2] & addr[1] & addr[0])
    `define pt_164 ( addr[7] & addr[6] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_165 ( addr[8] & ~addr[7] & ~addr[4] & addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_166 ( addr[8] & ~addr[7] & addr[6] & addr[5] & ~addr[4] & addr[3] & addr[1] & ~addr[0])
    `define pt_167 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & addr[4] & ~addr[2] & addr[1] & addr[0])
    `define pt_168 ( addr[8] & ~addr[7] & ~addr[6] & addr[5] & addr[4] & addr[2] & addr[0])
    `define pt_169 ( ~addr[8] & addr[6] & ~addr[4] & ~addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_170 ( ~addr[8] & addr[6] & addr[5] & addr[4] & ~addr[3] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_171 ( addr[8] & ~addr[7] & addr[6] & addr[5] & addr[3] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_172 ( addr[8] & ~addr[7] & addr[6] & addr[5] & addr[3] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_173 ( addr[8] & ~addr[7] & ~addr[6] & addr[5] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_174 ( addr[8] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_175 ( ~addr[8] & addr[7] & addr[5] & addr[4] & ~addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_176 ( ~addr[8] & addr[7] & addr[6] & ~addr[3] & ~addr[2] & addr[0])
    `define pt_177 ( ~addr[8] & ~addr[6] & ~addr[5] & addr[4] & ~addr[3] & ~addr[1] & addr[0])
    `define pt_178 ( addr[7] & ~addr[6] & ~addr[5] & addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_179 ( ~addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_180 ( addr[7] & ~addr[6] & addr[5] & ~addr[4] & addr[3] & addr[2] & ~addr[1])
    `define pt_181 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & ~addr[1] & addr[0])
    `define pt_182 ( addr[7] & addr[6] & addr[4] & ~addr[3] & ~addr[2] & addr[1])
    `define pt_183 ( addr[8] & ~addr[7] & addr[5] & ~addr[4] & addr[3] & ~addr[1] & addr[0])
    `define pt_184 ( ~addr[7] & addr[6] & addr[5] & addr[4] & addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_185 ( addr[6] & ~addr[5] & addr[4] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_186 ( addr[8] & ~addr[6] & ~addr[5] & addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_187 ( addr[8] & addr[5] & ~addr[4] & ~addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_188 ( ~addr[7] & addr[6] & addr[5] & ~addr[4] & addr[3] & ~addr[2] & addr[1])
    `define pt_189 ( addr[8] & ~addr[7] & addr[4] & ~addr[3] & addr[2] & addr[1])
    `define pt_190 ( ~addr[8] & addr[7] & ~addr[5] & addr[4] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_191 ( ~addr[8] & addr[6] & ~addr[5] & addr[4] & addr[3] & ~addr[2] & addr[0])
    `define pt_192 ( ~addr[8] & addr[7] & ~addr[5] & ~addr[4] & addr[3] & ~addr[2])
    `define pt_193 ( ~addr[8] & addr[6] & ~addr[5] & addr[3] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_194 ( ~addr[8] & ~addr[6] & addr[5] & addr[4] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_195 ( addr[6] & ~addr[5] & ~addr[4] & addr[3] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_196 ( ~addr[8] & ~addr[6] & addr[5] & addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_197 ( ~addr[7] & addr[5] & ~addr[4] & addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_198 ( ~addr[8] & ~addr[7] & addr[5] & ~addr[3] & addr[2] & addr[1] & ~addr[0])
    `define pt_199 ( addr[8] & ~addr[6] & ~addr[5] & ~addr[4] & addr[2] & addr[1] & ~addr[0])
    `define pt_200 ( ~addr[8] & ~addr[7] & ~addr[6] & addr[4] & addr[3] & addr[1] & ~addr[0])
    `define pt_201 ( ~addr[7] & addr[6] & ~addr[5] & addr[4] & ~addr[3] & addr[2] & ~addr[1])
    `define pt_202 ( addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & ~addr[2] & addr[1])
    `define pt_203 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & addr[4] & ~addr[3] & ~addr[2])
    `define pt_204 ( addr[8] & ~addr[7] & addr[4] & ~addr[3] & addr[2] & addr[0])
    `define pt_205 ( ~addr[7] & ~addr[6] & addr[5] & addr[4] & ~addr[3] & addr[2] & ~addr[1])
    `define pt_206 ( ~addr[7] & ~addr[6] & addr[5] & addr[4] & addr[3] & addr[2] & addr[1])
    `define pt_207 ( ~addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & addr[2] & ~addr[1])
    `define pt_208 ( addr[8] & ~addr[7] & addr[6] & ~addr[4] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_209 ( ~addr[8] & ~addr[7] & addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_210 ( addr[8] & ~addr[7] & addr[6] & ~addr[5] & ~addr[4] & addr[3] & ~addr[2])
    `define pt_211 ( addr[8] & ~addr[7] & addr[5] & ~addr[4] & ~addr[2] & addr[1])
    `define pt_212 ( addr[8] & addr[7] & addr[6] & ~addr[3] & addr[2])
    `define pt_213 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[5] & ~addr[1] & addr[0])
    `define pt_214 ( ~addr[8] & ~addr[7] & ~addr[5] & ~addr[3] & ~addr[1] & ~addr[0])
    `define pt_215 ( addr[8] & ~addr[7] & addr[5] & ~addr[4] & ~addr[2] & addr[0])
    `define pt_216 ( addr[7] & ~addr[6] & ~addr[5] & addr[4] & addr[3] & addr[2])
    `define pt_217 ( ~addr[8] & ~addr[7] & addr[6] & ~addr[5] & addr[3] & addr[2] & addr[1])
    `define pt_218 ( ~addr[8] & addr[6] & addr[5] & addr[4] & addr[3] & addr[2] & ~addr[1])
    `define pt_219 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[4] & addr[3] & ~addr[1] & ~addr[0])
    `define pt_220 ( addr[8] & addr[5] & addr[4] & ~addr[3] & addr[2] & addr[1])
    `define pt_221 ( addr[8] & addr[7] & ~addr[6] & addr[5] & addr[3] & ~addr[2])
    `define pt_222 ( addr[7] & addr[6] & ~addr[5] & addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_223 ( ~addr[8] & addr[7] & ~addr[6] & ~addr[5] & addr[4] & addr[2] & addr[1])
    `define pt_224 ( addr[8] & addr[5] & addr[4] & ~addr[3] & addr[2] & addr[0])
    `define pt_225 ( ~addr[7] & addr[6] & addr[5] & addr[4] & ~addr[3] & addr[2] & addr[1])
    `define pt_226 ( ~addr[8] & ~addr[7] & ~addr[6] & addr[5] & ~addr[4] & ~addr[3] & addr[1])
    `define pt_227 ( addr[8] & ~addr[7] & ~addr[6] & ~addr[5] & addr[4] & addr[3] & ~addr[2] & ~addr[1])
    `define pt_228 ( ~addr[8] & ~addr[7] & addr[6] & ~addr[4] & ~addr[3] & addr[2] & ~addr[1])
    `define pt_229 ( ~addr[8] & addr[7] & addr[6] & ~addr[4] & ~addr[2])
    `define pt_230 ( ~addr[8] & addr[7] & ~addr[6] & addr[5] & ~addr[4] & addr[2] & ~addr[1])
    `define pt_231 ( addr[8] & addr[7] & addr[6] & addr[5] & ~addr[3])
    `define pt_232 ( ~addr[8] & addr[6] & ~addr[5] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_233 ( ~addr[8] & addr[7] & addr[5] & addr[4] & ~addr[2] & addr[1])
    `define pt_234 ( addr[7] & addr[6] & addr[5] & addr[4] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_235 ( ~addr[8] & addr[6] & ~addr[5] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_236 ( addr[7] & ~addr[6] & addr[5] & ~addr[4] & addr[3] & addr[1] & ~addr[0])
    `define pt_237 ( addr[6] & ~addr[5] & addr[4] & addr[3] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_238 ( addr[7] & addr[6] & ~addr[5] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_239 ( addr[8] & addr[7] & addr[5] & addr[4] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_240 ( ~addr[8] & ~addr[7] & ~addr[6] & addr[5] & addr[4] & ~addr[3] & addr[2] & addr[0])
    `define pt_241 ( ~addr[8] & ~addr[7] & addr[4] & addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_242 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[3] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_243 ( ~addr[8] & addr[6] & ~addr[5] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_244 ( addr[8] & addr[7] & addr[6] & addr[3] & ~addr[2] & addr[1])
    `define pt_245 ( ~addr[8] & ~addr[7] & ~addr[6] & addr[5] & addr[4] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_246 ( ~addr[8] & ~addr[7] & addr[6] & addr[5] & ~addr[4] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_247 ( addr[8] & ~addr[7] & addr[6] & ~addr[4] & addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_248 ( addr[8] & addr[7] & ~addr[6] & ~addr[4] & addr[3] & addr[1] & ~addr[0])
    `define pt_249 ( ~addr[8] & addr[6] & addr[5] & addr[4] & ~addr[3] & addr[2] & addr[1] & ~addr[0])
    `define pt_250 ( ~addr[8] & addr[7] & addr[5] & ~addr[4] & addr[3] & addr[2] & addr[1] & ~addr[0])
    `define pt_251 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[4] & ~addr[3] & addr[1] & ~addr[0])
    `define pt_252 ( ~addr[8] & addr[7] & addr[4] & ~addr[3] & addr[2] & ~addr[1] & addr[0])
    `define pt_253 ( addr[8] & ~addr[7] & ~addr[5] & ~addr[4] & addr[3] & addr[2] & ~addr[1] & addr[0])
    `define pt_254 ( addr[8] & addr[7] & addr[5] & ~addr[4] & addr[3] & ~addr[2] & ~addr[0])
    `define pt_255 ( ~addr[8] & ~addr[7] & ~addr[6] & addr[5] & ~addr[4] & addr[3] & ~addr[2] & addr[0])
    `define pt_256 ( addr[8] & ~addr[7] & addr[6] & addr[5] & addr[4] & ~addr[3] & addr[2] & addr[1])
    `define pt_257 ( ~addr[8] & ~addr[7] & addr[5] & ~addr[4] & addr[3] & addr[2] & ~addr[1] & addr[0])
    `define pt_258 ( addr[8] & ~addr[7] & ~addr[6] & ~addr[5] & addr[4] & ~addr[3] & ~addr[1] & addr[0])
    `define pt_259 ( ~addr[7] & ~addr[6] & ~addr[5] & addr[4] & ~addr[3] & addr[1] & ~addr[0])
    `define pt_260 ( addr[8] & ~addr[6] & ~addr[5] & addr[4] & addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_261 ( ~addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & addr[3] & ~addr[1] & ~addr[0])
    `define pt_262 ( addr[8] & addr[5] & ~addr[4] & addr[3] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_263 ( addr[8] & addr[6] & addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[1])
    `define pt_264 ( addr[8] & addr[5] & ~addr[4] & addr[3] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_265 ( addr[8] & ~addr[7] & addr[6] & addr[5] & addr[4] & addr[2] & ~addr[1] & addr[0])
    `define pt_266 ( addr[8] & addr[6] & ~addr[5] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_267 ( ~addr[8] & ~addr[7] & addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_268 ( addr[8] & ~addr[7] & ~addr[5] & addr[4] & addr[3] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_269 ( addr[8] & addr[7] & ~addr[6] & ~addr[4] & ~addr[3] & ~addr[2] & addr[1])
    `define pt_270 ( ~addr[7] & addr[6] & addr[5] & addr[4] & addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_271 ( ~addr[8] & ~addr[7] & ~addr[6] & addr[5] & addr[4] & addr[3] & addr[1] & ~addr[0])
    `define pt_272 ( addr[8] & addr[7] & ~addr[6] & ~addr[4] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_273 ( addr[8] & ~addr[6] & addr[5] & addr[4] & addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_274 ( addr[8] & ~addr[7] & ~addr[6] & addr[5] & addr[4] & addr[3] & ~addr[1] & addr[0])
    `define pt_275 ( addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & addr[3] & ~addr[2] & ~addr[1])
    `define pt_276 ( ~addr[8] & ~addr[5] & ~addr[4] & addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_277 ( addr[7] & ~addr[6] & addr[4] & ~addr[3] & addr[2] & addr[1] & ~addr[0])
    `define pt_278 ( ~addr[7] & addr[6] & ~addr[5] & addr[3] & addr[2] & addr[1] & ~addr[0])
    `define pt_279 ( addr[7] & addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_280 ( ~addr[6] & ~addr[5] & addr[4] & ~addr[3] & ~addr[2] & ~addr[1] & ~addr[0])
    `define pt_281 ( addr[8] & ~addr[7] & addr[6] & ~addr[5] & addr[3] & ~addr[2] & ~addr[1])
    `define pt_282 ( addr[8] & addr[7] & ~addr[6] & ~addr[5] & addr[4] & addr[2] & ~addr[1])
    `define pt_283 ( ~addr[8] & addr[7] & addr[6] & addr[5] & addr[4] & addr[3] & addr[1])
    `define pt_284 ( ~addr[8] & ~addr[7] & ~addr[6] & addr[4] & addr[2] & addr[1] & addr[0])
    `define pt_285 ( addr[8] & addr[7] & ~addr[6] & addr[5] & addr[4] & addr[2] & addr[0])
    `define pt_286 ( ~addr[8] & addr[7] & ~addr[6] & addr[4] & addr[3] & ~addr[1] & addr[0])
    `define pt_287 ( ~addr[7] & ~addr[5] & addr[4] & addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_288 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[5] & addr[4] & addr[3] & addr[0])
    `define pt_289 ( addr[7] & ~addr[6] & addr[4] & addr[3] & addr[2] & ~addr[1])
    `define pt_290 ( ~addr[8] & addr[7] & addr[6] & ~addr[4] & ~addr[1])
    `define pt_291 ( ~addr[8] & ~addr[7] & ~addr[5] & ~addr[3] & addr[2] & ~addr[0])
    `define pt_292 ( ~addr[7] & ~addr[4] & ~addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_293 ( addr[8] & ~addr[6] & addr[5] & addr[3] & addr[2] & addr[1])
    `define pt_294 ( addr[8] & addr[7] & addr[6] & addr[5] & ~addr[2])
    `define pt_295 ( ~addr[8] & ~addr[7] & addr[6] & addr[5] & ~addr[4] & ~addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_296 ( addr[8] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & addr[1] & addr[0])
    `define pt_297 ( addr[8] & addr[6] & addr[5] & addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_298 ( addr[8] & ~addr[7] & addr[5] & ~addr[4] & ~addr[3] & addr[2] & ~addr[1])
    `define pt_299 ( ~addr[8] & ~addr[7] & addr[6] & addr[4] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_300 ( addr[8] & ~addr[7] & addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & ~addr[2] & addr[1])
    `define pt_301 ( addr[8] & ~addr[7] & ~addr[6] & addr[5] & addr[4] & ~addr[3] & ~addr[2] & addr[1] & addr[0])
    `define pt_302 ( ~addr[8] & ~addr[7] & addr[6] & ~addr[5] & ~addr[4] & ~addr[2] & addr[0])
    `define pt_303 ( ~addr[8] & addr[7] & ~addr[6] & addr[5] & ~addr[4] & addr[1] & addr[0])
    `define pt_304 ( addr[8] & addr[7] & addr[6] & ~addr[5] & ~addr[4] & ~addr[3] & addr[2] & ~addr[0])
    `define pt_305 ( addr[7] & ~addr[6] & ~addr[4] & addr[3] & addr[2] & addr[1] & addr[0])
    `define pt_306 ( ~addr[8] & ~addr[7] & ~addr[6] & ~addr[5] & ~addr[4] & ~addr[0])
    `define pt_307 ( addr[6] & ~addr[5] & ~addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_308 ( ~addr[8] & ~addr[6] & ~addr[5] & ~addr[3] & addr[1] & ~addr[0])
    `define pt_309 ( ~addr[8] & addr[6] & ~addr[4] & ~addr[3] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_310 ( addr[7] & addr[6] & ~addr[5] & ~addr[4] & addr[2] & ~addr[1])
    `define pt_311 ( ~addr[8] & addr[7] & ~addr[6] & ~addr[5] & ~addr[3] & ~addr[2] & addr[1])
    `define pt_312 ( addr[8] & ~addr[7] & addr[5] & ~addr[4] & ~addr[3] & ~addr[1] & ~addr[0])
    `define pt_313 ( addr[8] & addr[7] & addr[6] & addr[4] & ~addr[2] & addr[1])
    `define pt_314 ( ~addr[7] & ~addr[6] & addr[5] & ~addr[3] & addr[2] & ~addr[1] & ~addr[0])
    `define pt_315 ( ~addr[8] & addr[7] & ~addr[5] & ~addr[3] & addr[2] & ~addr[1] & addr[0])
    `define pt_316 ( ~addr[8] & ~addr[7] & addr[4] & addr[3] & ~addr[2] & ~addr[1] & addr[0])
    `define pt_317 ( ~addr[8] & addr[7] & addr[6] & ~addr[5] & ~addr[1])
    `define pt_318 ( ~addr[8] & addr[7] & ~addr[6] & addr[4] & ~addr[2] & addr[1] & ~addr[0])
    `define pt_319 ( ~addr[8] & addr[7] & addr[5] & ~addr[4] & ~addr[3] & ~addr[1] & ~addr[0])

    // begin summing assignments

    assign rom_out[7] = `pt_1 | `pt_2 | `pt_3 | `pt_4;

    assign rom_out[6] = `pt_5 | `pt_6 | `pt_7 | `pt_8 |
			`pt_9 | `pt_10 | `pt_11 | `pt_12 |
			`pt_13 | `pt_14;

    assign rom_out[5] = `pt_15 | `pt_16 | `pt_17 | `pt_18 |
			`pt_19 | `pt_20 | `pt_21 | `pt_22 |
			`pt_23 | `pt_24 | `pt_25 | `pt_26 |
			`pt_27 | `pt_28 | `pt_29 | `pt_30 |
			`pt_31 | `pt_32 | `pt_33 | `pt_34 |
			`pt_35;

    assign rom_out[4] = `pt_36 | `pt_37 | `pt_38 | `pt_39 |
			`pt_40 | `pt_41 | `pt_42 | `pt_43 |
			`pt_44 | `pt_45 | `pt_46 | `pt_47 |
			`pt_48 | `pt_49 | `pt_50 | `pt_51 |
			`pt_52 | `pt_53 | `pt_54 | `pt_55 |
			`pt_56 | `pt_57 | `pt_58 | `pt_59 |
			`pt_60 | `pt_61 | `pt_62 | `pt_63 |
			`pt_64;

    assign rom_out[3] = `pt_65 | `pt_66 | `pt_67 | `pt_68 |
			`pt_69 | `pt_70 | `pt_71 | `pt_72 |
			`pt_73 | `pt_74 | `pt_75 | `pt_76 |
			`pt_77 | `pt_78 | `pt_79 | `pt_80 |
			`pt_81 | `pt_82 | `pt_83 | `pt_84 |
			`pt_85 | `pt_86 | `pt_87 | `pt_88 |
			`pt_89 | `pt_90 | `pt_91 | `pt_92 |
			`pt_93 | `pt_94 | `pt_95 | `pt_96 |
			`pt_97 | `pt_98 | `pt_99 | `pt_100 |
			`pt_101 | `pt_102 | `pt_103;

    assign rom_out[2] = `pt_104 | `pt_105 | `pt_106 | `pt_107 |
			`pt_108 | `pt_109 | `pt_110 | `pt_111 |
			`pt_112 | `pt_113 | `pt_114 | `pt_115 |
			`pt_116 | `pt_117 | `pt_118 | `pt_119 |
			`pt_120 | `pt_82 | `pt_121 | `pt_122 |
			`pt_123 | `pt_124 | `pt_125 | `pt_126 |
			`pt_127 | `pt_128 | `pt_129 | `pt_130 |
			`pt_131 | `pt_132 | `pt_133 | `pt_134 |
			`pt_135 | `pt_136 | `pt_137 | `pt_138 |
			`pt_139 | `pt_140 | `pt_141 | `pt_142 |
			`pt_143 | `pt_144 | `pt_145 | `pt_146 |
			`pt_147 | `pt_148 | `pt_149 | `pt_150 |
			`pt_151 | `pt_152 | `pt_153 | `pt_154 |
			`pt_155 | `pt_156 | `pt_157 | `pt_158 |
			`pt_159;

    assign rom_out[1] = `pt_160 | `pt_161 | `pt_162 | `pt_163 |
			`pt_164 | `pt_165 | `pt_166 | `pt_167 |
			`pt_168 | `pt_169 | `pt_170 | `pt_171 |
			`pt_172 | `pt_173 | `pt_174 | `pt_175 |
			`pt_176 | `pt_177 | `pt_178 | `pt_179 |
			`pt_180 | `pt_181 | `pt_182 | `pt_183 |
			`pt_184 | `pt_185 | `pt_186 | `pt_82 |
			`pt_187 | `pt_188 | `pt_189 | `pt_190 |
			`pt_191 | `pt_192 | `pt_193 | `pt_194 |
			`pt_195 | `pt_196 | `pt_197 | `pt_198 |
			`pt_199 | `pt_200 | `pt_201 | `pt_202 |
			`pt_203 | `pt_204 | `pt_205 | `pt_206 |
			`pt_207 | `pt_208 | `pt_209 | `pt_210 |
			`pt_211 | `pt_212 | `pt_213 | `pt_214 |
			`pt_215 | `pt_216 | `pt_217 | `pt_218 |
			`pt_219 | `pt_220 | `pt_221 | `pt_222 |
			`pt_223 | `pt_224 | `pt_225 | `pt_226 |
			`pt_227 | `pt_228 | `pt_229 | `pt_230 |
			`pt_231 | `pt_232 | `pt_233;

    assign rom_out[0] = `pt_234 | `pt_235 | `pt_236 | `pt_237 |
			`pt_238 | `pt_239 | `pt_240 | `pt_241 |
			`pt_242 | `pt_243 | `pt_244 | `pt_245 |
			`pt_246 | `pt_247 | `pt_248 | `pt_249 |
			`pt_250 | `pt_251 | `pt_252 | `pt_253 |
			`pt_254 | `pt_255 | `pt_256 | `pt_257 |
			`pt_258 | `pt_259 | `pt_260 | `pt_261 |
			`pt_262 | `pt_263 | `pt_264 | `pt_265 |
			`pt_266 | `pt_267 | `pt_268 | `pt_269 |
			`pt_270 | `pt_271 | `pt_272 | `pt_273 |
			`pt_274 | `pt_275 | `pt_276 | `pt_277 |
			`pt_278 | `pt_279 | `pt_280 | `pt_281 |
			`pt_282 | `pt_283 | `pt_284 | `pt_285 |
			`pt_286 | `pt_287 | `pt_288 | `pt_289 |
			`pt_290 | `pt_291 | `pt_292 | `pt_293 |
			`pt_294 | `pt_295 | `pt_296 | `pt_297 |
			`pt_298 | `pt_299 | `pt_300 | `pt_301 |
			`pt_302 | `pt_303 | `pt_304 | `pt_305 |
			`pt_306 | `pt_307 | `pt_308 | `pt_309 |
			`pt_310 | `pt_311 | `pt_312 | `pt_313 |
			`pt_314 | `pt_315 | `pt_316 | `pt_317 |
			`pt_318 | `pt_319;


    `undef pt_1
    `undef pt_2
    `undef pt_3
    `undef pt_4
    `undef pt_5
    `undef pt_6
    `undef pt_7
    `undef pt_8
    `undef pt_9
    `undef pt_10
    `undef pt_11
    `undef pt_12
    `undef pt_13
    `undef pt_14
    `undef pt_15
    `undef pt_16
    `undef pt_17
    `undef pt_18
    `undef pt_19
    `undef pt_20
    `undef pt_21
    `undef pt_22
    `undef pt_23
    `undef pt_24
    `undef pt_25
    `undef pt_26
    `undef pt_27
    `undef pt_28
    `undef pt_29
    `undef pt_30
    `undef pt_31
    `undef pt_32
    `undef pt_33
    `undef pt_34
    `undef pt_35
    `undef pt_36
    `undef pt_37
    `undef pt_38
    `undef pt_39
    `undef pt_40
    `undef pt_41
    `undef pt_42
    `undef pt_43
    `undef pt_44
    `undef pt_45
    `undef pt_46
    `undef pt_47
    `undef pt_48
    `undef pt_49
    `undef pt_50
    `undef pt_51
    `undef pt_52
    `undef pt_53
    `undef pt_54
    `undef pt_55
    `undef pt_56
    `undef pt_57
    `undef pt_58
    `undef pt_59
    `undef pt_60
    `undef pt_61
    `undef pt_62
    `undef pt_63
    `undef pt_64
    `undef pt_65
    `undef pt_66
    `undef pt_67
    `undef pt_68
    `undef pt_69
    `undef pt_70
    `undef pt_71
    `undef pt_72
    `undef pt_73
    `undef pt_74
    `undef pt_75
    `undef pt_76
    `undef pt_77
    `undef pt_78
    `undef pt_79
    `undef pt_80
    `undef pt_81
    `undef pt_82
    `undef pt_83
    `undef pt_84
    `undef pt_85
    `undef pt_86
    `undef pt_87
    `undef pt_88
    `undef pt_89
    `undef pt_90
    `undef pt_91
    `undef pt_92
    `undef pt_93
    `undef pt_94
    `undef pt_95
    `undef pt_96
    `undef pt_97
    `undef pt_98
    `undef pt_99
    `undef pt_100
    `undef pt_101
    `undef pt_102
    `undef pt_103
    `undef pt_104
    `undef pt_105
    `undef pt_106
    `undef pt_107
    `undef pt_108
    `undef pt_109
    `undef pt_110
    `undef pt_111
    `undef pt_112
    `undef pt_113
    `undef pt_114
    `undef pt_115
    `undef pt_116
    `undef pt_117
    `undef pt_118
    `undef pt_119
    `undef pt_120
    `undef pt_121
    `undef pt_122
    `undef pt_123
    `undef pt_124
    `undef pt_125
    `undef pt_126
    `undef pt_127
    `undef pt_128
    `undef pt_129
    `undef pt_130
    `undef pt_131
    `undef pt_132
    `undef pt_133
    `undef pt_134
    `undef pt_135
    `undef pt_136
    `undef pt_137
    `undef pt_138
    `undef pt_139
    `undef pt_140
    `undef pt_141
    `undef pt_142
    `undef pt_143
    `undef pt_144
    `undef pt_145
    `undef pt_146
    `undef pt_147
    `undef pt_148
    `undef pt_149
    `undef pt_150
    `undef pt_151
    `undef pt_152
    `undef pt_153
    `undef pt_154
    `undef pt_155
    `undef pt_156
    `undef pt_157
    `undef pt_158
    `undef pt_159
    `undef pt_160
    `undef pt_161
    `undef pt_162
    `undef pt_163
    `undef pt_164
    `undef pt_165
    `undef pt_166
    `undef pt_167
    `undef pt_168
    `undef pt_169
    `undef pt_170
    `undef pt_171
    `undef pt_172
    `undef pt_173
    `undef pt_174
    `undef pt_175
    `undef pt_176
    `undef pt_177
    `undef pt_178
    `undef pt_179
    `undef pt_180
    `undef pt_181
    `undef pt_182
    `undef pt_183
    `undef pt_184
    `undef pt_185
    `undef pt_186
    `undef pt_187
    `undef pt_188
    `undef pt_189
    `undef pt_190
    `undef pt_191
    `undef pt_192
    `undef pt_193
    `undef pt_194
    `undef pt_195
    `undef pt_196
    `undef pt_197
    `undef pt_198
    `undef pt_199
    `undef pt_200
    `undef pt_201
    `undef pt_202
    `undef pt_203
    `undef pt_204
    `undef pt_205
    `undef pt_206
    `undef pt_207
    `undef pt_208
    `undef pt_209
    `undef pt_210
    `undef pt_211
    `undef pt_212
    `undef pt_213
    `undef pt_214
    `undef pt_215
    `undef pt_216
    `undef pt_217
    `undef pt_218
    `undef pt_219
    `undef pt_220
    `undef pt_221
    `undef pt_222
    `undef pt_223
    `undef pt_224
    `undef pt_225
    `undef pt_226
    `undef pt_227
    `undef pt_228
    `undef pt_229
    `undef pt_230
    `undef pt_231
    `undef pt_232
    `undef pt_233
    `undef pt_234
    `undef pt_235
    `undef pt_236
    `undef pt_237
    `undef pt_238
    `undef pt_239
    `undef pt_240
    `undef pt_241
    `undef pt_242
    `undef pt_243
    `undef pt_244
    `undef pt_245
    `undef pt_246
    `undef pt_247
    `undef pt_248
    `undef pt_249
    `undef pt_250
    `undef pt_251
    `undef pt_252
    `undef pt_253
    `undef pt_254
    `undef pt_255
    `undef pt_256
    `undef pt_257
    `undef pt_258
    `undef pt_259
    `undef pt_260
    `undef pt_261
    `undef pt_262
    `undef pt_263
    `undef pt_264
    `undef pt_265
    `undef pt_266
    `undef pt_267
    `undef pt_268
    `undef pt_269
    `undef pt_270
    `undef pt_271
    `undef pt_272
    `undef pt_273
    `undef pt_274
    `undef pt_275
    `undef pt_276
    `undef pt_277
    `undef pt_278
    `undef pt_279
    `undef pt_280
    `undef pt_281
    `undef pt_282
    `undef pt_283
    `undef pt_284
    `undef pt_285
    `undef pt_286
    `undef pt_287
    `undef pt_288
    `undef pt_289
    `undef pt_290
    `undef pt_291
    `undef pt_292
    `undef pt_293
    `undef pt_294
    `undef pt_295
    `undef pt_296
    `undef pt_297
    `undef pt_298
    `undef pt_299
    `undef pt_300
    `undef pt_301
    `undef pt_302
    `undef pt_303
    `undef pt_304
    `undef pt_305
    `undef pt_306
    `undef pt_307
    `undef pt_308
    `undef pt_309
    `undef pt_310
    `undef pt_311
    `undef pt_312
    `undef pt_313
    `undef pt_314
    `undef pt_315
    `undef pt_316
    `undef pt_317

  `undef RND_Width
  `undef RND_Inc
  `undef RND_Inexact
  `undef RND_HugeInfinity
  `undef RND_TinyminNorm
  `undef log_awidth
  `undef sig_sub_25
  `undef sig_mul2_sub_47
  `undef sig_mul2_sub_21
  `undef sig_sub_11
  `undef x2de4_t_range_1
  `undef x2de4_t_range_2
  `undef de2h_t_range_1
  `undef de2h_t_range_2
  `undef x2de4_range_1
  `undef x2de4_range_2
  `undef x2de4_range_3
  `undef x2de4_range_4
  `undef de2_range_1
  `undef de2_range_2
  `undef de2h_range_1
  `undef de2h_range_2
  `undef x1de2_range_1
  `undef x1de2_range_2
  `undef f_sig_width
  `undef x0_rbit
  `undef nine_mf
  `undef nine_index
  `undef eight_mf
  `undef q0de_size
    
endmodule
