
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT: Floating-Point Square
//
//              DW_fp_square calculates the floating-point square operation
//              while supporting six rounding modes, including four IEEE
//              standard rounding modes.
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance support the IEEE Compliance 
//                              including NaN and denormal expressions.
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
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_fp_square (
  a,
  rnd,
  z,
  status
  // Embedded dc_shell script
  // _model_constraint_2
);

  parameter sig_width = 23;   // RANGE 2 TO 253
  parameter exp_width = 8;    // RANGE 3 TO 31
  parameter ieee_compliance = 0; // RANGE 0 TO 1



  `define RND_Width  4
  `define RND_Inc  0
  `define RND_Inexact  1
  `define RND_HugeInfinity  2
  `define RND_TinyminNorm  3

  `define Msb (2 * (sig_width + 1) - 1)
  `define Mhalf (sig_width + 1)
  `define log_awidth ((sig_width + 1>65536)?((sig_width + 1>16777216)?((sig_width + 1>268435456)?((sig_width + 1>536870912)?30:29):((sig_width + 1>67108864)?((sig_width + 1>134217728)?28:27):((sig_width + 1>33554432)?26:25))):((sig_width + 1>1048576)?((sig_width + 1>4194304)?((sig_width + 1>8388608)?24:23):((sig_width + 1>2097152)?22:21)):((sig_width + 1>262144)?((sig_width + 1>524288)?20:19):((sig_width + 1>131072)?18:17)))):((sig_width + 1>256)?((sig_width + 1>4096)?((sig_width + 1>16384)?((sig_width + 1>32768)?16:15):((sig_width + 1>8192)?14:13)):((sig_width + 1>1024)?((sig_width + 1>2048)?12:11):((sig_width + 1>512)?10:9))):((sig_width + 1>16)?((sig_width + 1>64)?((sig_width + 1>128)?8:7):((sig_width + 1>32)?6:5)):((sig_width + 1>4)?((sig_width + 1>8)?4:3):((sig_width + 1>2)?2:1)))))

  //-------------------------------------------------------
  input  [(exp_width + sig_width):0] a;
  input  [2:0] rnd;

  output [8    -1:0] status;
  output [(exp_width + sig_width):0] z;

  wire [sig_width:0] ma;
  wire [exp_width - 1:0] ea;
  wire sa;


  wire [2 * (sig_width + 1) - 1:0] mul_out;
  wire [2 * (sig_width + 1) - 1:0] mul_out_pre;
  wire [2 * (sig_width + 1) - 1:0] mul_out_pre2;
  wire [2 * (sig_width + 1) - 1:0] mul_sticky;
  wire [2 * (sig_width + 1) - 1:0] rshout;
  wire [2 * (sig_width + 1) - 1:0] lshout;
  wire [2 * (sig_width + 1) - 1:0] denorm_shifterout;
  wire sign;

  wire signed [exp_width + 1:0] exp_cal0;
  wire signed [exp_width + 1:0] exp_cal1;
  wire signed [exp_width + 1:0] exp_lsh;
  wire signed [exp_width + 1:0] exp_rsh;
  wire signed [exp_width + 1:0] exp_lsh2;

  wire [`Msb:`Mhalf  - 1] round_in;
  wire [`Msb:`Mhalf] round_out;
  wire [`Msb:`Mhalf] round_out1;
  wire [`Msb:`Mhalf - 1] round_added;

  wire guard_bit0;
  wire round_bit0;
  wire sticky_bit0;
  wire guard_bit1;
  wire round_bit1;
  wire sticky_bit1;
  wire carry_round;
  wire carry_round_dummy;

  wire inf_inputs;
  wire zero_inputs;
  wire exp0_lessoreq_zero;
  wire exp0_moreoreq_inf;
  wire exp1_lessoreq_zero;
  wire exp1_moreoreq_inf;

  wire [exp_width + 1:0] exp0_zero;
  wire [exp_width + 1:0] exp0_inf;
  wire [exp_width + 1:0] exp0_modified;
  wire [exp_width + 1:0] exp1_zero;
  wire [exp_width + 1:0] exp1_inf;
  wire [exp_width + 1:0] exp1_modified;
  wire [exp_width - 1:0] exp_result;
  wire [exp_width:0] denorm_shift;
  wire [exp_width:0] rshift_amount;

  wire [sig_width:0] rounder_in;
  wire [sig_width:0] rounder_out;
  wire [sig_width - 1:0] sig_result;
  wire [sig_width - 1:0] sig_nan_rep;
  wire [sig_width - 1:0] sig_inf_rep;
  wire [sig_width - 1:0] special_outputs;
  wire [sig_width - 1:0] special_outputs_denormal;

  wire flag_moreoreq_inf;
  wire flag_lessoreq_zero;
  wire flag_lessoreq_zero_new;

  wire status_infinity;
  wire status_huge;
  wire status_zero;
  wire status_invalid;
  wire status_tiny;
  wire status_tiny_correct;
  wire status_inexact;

  wire sig_inf_sel;
  wire sig_zero_sel;
  wire sig_inf_sel2;
  wire sig_zero_sel2;

  wire [sig_width - 1:0] siga;
  wire [sig_width - 1:0] sigb;
  wire inf_siga;
  wire inf_sigb;
  wire nan_case;
  wire inf_case;
  wire denorm_a;
  wire denorm_b;
  wire inf_ea;
  wire inf_eb;
  wire zero_ea;
  wire zero_eb;
  wire [`log_awidth + 1:0] lzd_in;
  wire [`log_awidth:0] lzd_ina;
  wire [`log_awidth:0] lzd_inb;
  wire [`log_awidth:0] rev_lzd_ma;
  wire [`log_awidth:0] rev_lzd_mb;
  wire signed [exp_width + 1:0] total_rev_zero;
  wire [`Msb:`Mhalf] round_out_denormal;
  wire dummy;
  wire ovfl_case;
  wire ovfl_case_denormal;
  wire ovfl_case_normal;
  wire ctrl_sig;
  wire rnd_inexact;

  wire [1:0] round_inc;

  // Rounding Logic Signals
  wire even;
  wire away;
  wire infMatch;
  wire infinity;
  wire R0_n0;
  wire R1_n0;
  wire R0_n1;
  wire R1_n1;
  wire RND_eval0_RND_Inc;
  wire RND_eval1_RND_Inc;
  wire RND_eval0_RND_Inexact;
  wire RND_eval1_RND_Inexact;
  wire RND_eval0_RND_HugeInfinity;
  wire RND_eval1_RND_HugeInfinity;
  wire RND_eval0_RND_TinyminNorm;
  wire RND_eval1_RND_TinyminNorm;
  wire [3:0] RND_eval0;
  wire [3:0] RND_eval1;

  // Exponent
  wire exp0_le_zer;
  wire exp0_lt_zer;
  wire exp0_ge_max;
  wire exp0_gt_max;
  wire exp1_ge_max;
  wire compute;

  wire e0s1;
  wire e0s0;
  wire e1s1;
  wire e1s0;

  wire [1:0] exp1_sel;
  wire [1:0] exp0_sel;

  wire [exp_width - 1:0] hugeexp;
  wire [exp_width - 1:0] tinyexp;
  wire [exp_width - 1:0] noncomputeexp;
  wire [exp_width - 1:0] exp1;
  wire [exp_width - 1:0] exp0;
  wire [exp_width - 1:0] exp0_rndhuge;

  wire check_denormal_zero;
  wire mul_out_msb;
  wire [sig_width:0] msb_cal;

  reg [sig_width:0] rev_ma;
  reg [sig_width:0] rev_mb;

  //-------------------------------------------------------

  //assign msb_cal = (1 << sig_width) * 1.4142135623;
  assign msb_cal = (sig_width == 4) ?  5'b10110 :
                   (sig_width == 9) ?  10'b1011010100 :
                   (sig_width == 10) ? 11'b10110101000 :
                   (sig_width == 16) ? 17'b10110101000001001 :
                   (sig_width == 23) ? 24'b101101010000010011110011 :
                   (sig_width == 52) ? 53'b10110101000001001111001100110011111110011101111001101 :
                   0;

  assign sa = a[(exp_width + sig_width)];
  assign ea = a[((exp_width + sig_width) - 1):sig_width];
  assign siga = a[(sig_width - 1):0];

  // Check if the valid inputs
  assign inf_siga = (siga == 0);
  assign inf_ea = (ea == ((((1 << (exp_width-1)) - 1) * 2) + 1));
  assign zero_ea = (ea == 0);
  assign inf_inputs = inf_ea;

  assign nan_case = (inf_ea & ~inf_siga) | (zero_inputs & inf_inputs);
  assign inf_case = (ieee_compliance) ? 
           (inf_ea & inf_siga) :
           inf_inputs;
  assign sig_nan_rep = (ieee_compliance) ? 1 : 0;
  assign sig_inf_rep = 0;

  assign denorm_a = (ieee_compliance) ? zero_ea & ~inf_siga : 0;
  assign zero_inputs = (ieee_compliance) ?
             (zero_ea & inf_siga) :
             zero_ea;

  // Denormal Support for ma and mb
  assign ma = (ieee_compliance & denorm_a) ? {1'b0, siga} : {1'b1, siga};

  // Exponent Calculation
  assign exp_cal0 = (ieee_compliance & denorm_a) ? 
           {ea, 1'b0} - ((1 << (exp_width-1)) - 1) - lzd_in + {denorm_a, 1'b0} :
           {ea, 1'b0} - ((1 << (exp_width-1)) - 1);
  assign exp_cal1 = exp_cal0 + 1;

  // Exponent Calculation for Shifter
  assign exp_lsh = {ea, 1'b0} + {denorm_a, 1'b0} - (((1 << (exp_width-1)) - 1) + 1);
  assign exp_rsh = -exp_lsh;
  // In case of exp_width >= log_awidth
  // need to modify for the case of exp_width < log_awidth
  assign exp_lsh2 = (exp0_le_zer) ? exp_lsh : lzd_in;

  // Exponent Calculation
  assign exp0_le_zer = (exp_cal0 <= 0);
  assign exp0_lt_zer = (exp_cal0 < 0);
  assign exp0_ge_max = ~exp0_lt_zer & (exp_cal0[exp_width:0] >= ((((1 << (exp_width-1)) - 1) * 2) + 1));
  assign exp0_gt_max = ~exp0_lt_zer & (exp_cal0[exp_width:0] > ((((1 << (exp_width-1)) - 1) * 2) + 1));
  assign exp1_ge_max = ~exp0_lt_zer & (exp_cal0[exp_width:0] >= (((((1 << (exp_width-1)) - 1) * 2) + 1) - 1));
  assign compute = ~(inf_inputs | zero_inputs);

  assign e0s1 = (exp0_gt_max | exp0_le_zer) & compute;
  assign e0s0 = ~compute | exp0_gt_max;
  assign e1s1 = (exp1_ge_max | exp0_lt_zer) & compute;
  assign e1s0 = ~compute | exp1_ge_max;

  assign exp1_sel = {e1s1, e1s0};
  assign exp0_sel = {e0s1, e0s0};

  assign hugeexp = RND_eval0[`RND_HugeInfinity] ? ((((1 << (exp_width-1)) - 1) * 2) + 1) : ((((1 << (exp_width-1)) - 1) * 2) + 1) - 1;

  // modified @ 9/12
  assign tinyexp = (ieee_compliance) ? 0 + round_out[`Msb] :
                   RND_eval0[`RND_TinyminNorm] ? 0 + 1 : 0;

  assign noncomputeexp = inf_inputs ? ((((1 << (exp_width-1)) - 1) * 2) + 1) : 0;

  assign exp1 = (exp1_sel == 2'b11) ? hugeexp :
                (exp1_sel == 2'b10) ? tinyexp :
                (exp1_sel == 2'b01) ? noncomputeexp :
                exp_cal1;

  assign exp0 = (exp0_sel == 2'b11) ? hugeexp :
                (exp0_sel == 2'b10) ? tinyexp :
                (exp0_sel == 2'b01) ? noncomputeexp :
                exp_cal0;

  assign exp0_rndhuge = (exp0 == ((((1 << (exp_width-1)) - 1) * 2) + 1)) ? exp1 : exp0;

  assign exp_result = (ovfl_case) ? exp1 : exp0_rndhuge;

  assign exp0_lessoreq_zero = exp0_le_zer;
  assign exp0_moreoreq_inf = exp0_ge_max;
  assign exp1_lessoreq_zero = exp0_lt_zer;
  assign exp1_moreoreq_inf = exp1_ge_max;


  // Denormal Support : LZD for denormal inputs
  DW_lzd #(sig_width + 1) U1 (
    .a(ma),
    .enc(lzd_ina)
  );

  assign lzd_in = (ieee_compliance) ? 
             {lzd_ina[`log_awidth - 1:0], 1'b0} :
             0;

  // LZD for sticky calculation
  always @(ma) begin : PROC_1
    integer i;

    for (i = 0; i <= sig_width; i = i + 1) begin
      rev_ma[i] = ma[sig_width - i];
    end
  end

  DW_lzd #(sig_width + 1) U3 (
    .a(rev_ma),
    .enc(rev_lzd_ma)
  );

  assign total_rev_zero = (ieee_compliance) ?
           ((exp_rsh[exp_width + 1]) ? 
             {rev_lzd_ma, 1'b0} + exp_lsh2 :
             {rev_lzd_ma, 1'b0} - exp_rsh) :
           {rev_lzd_ma, 1'b0};
 
  // Multiplication
  DW_square #(sig_width + 1) U2 (
                      .a(ma),
                      .tc(1'b0),
                      .square(mul_out_pre) );


  // Denormal Support with parallel shifter implementation
  // can be optimized more with rshout
  assign rshout = mul_out_pre >> exp_rsh;
  assign lshout = mul_out_pre << exp_lsh2[`log_awidth + 1:0];

  assign denorm_shifterout = (exp_rsh[exp_width + 1]) ? 
           lshout : rshout;

  assign mul_out = (ieee_compliance) ? 
             denorm_shifterout : mul_out_pre;

  // MSB pre-calculation
  assign mul_out_msb = (ieee_compliance) ? 
                         mul_out[`Msb] :
                         (sig_width == 4 | sig_width == 9 | sig_width == 10 | sig_width == 16 | sig_width == 23 | sig_width == 52) ? (ma > msb_cal) : mul_out[`Msb];


  // 1b shift
  assign round_in = (mul_out_msb) ? 
             mul_out[`Msb:`Mhalf - 1] :
             mul_out[`Msb - 1:`Mhalf - 2];

  // Rounding g, r, s bits
  assign guard_bit0 = mul_out[`Mhalf - 1];
  assign round_bit0 = mul_out[`Mhalf - 2];
  assign sticky_bit0 = (total_rev_zero < `Mhalf - 2);

  assign guard_bit1 = mul_out[`Mhalf];
  assign round_bit1 = mul_out[`Mhalf - 1];
  assign sticky_bit1 = (total_rev_zero < `Mhalf - 1);
  

  // Rounding Adder
  assign round_inc = {RND_eval1[`RND_Inc] & mul_out_msb, RND_eval0[`RND_Inc] & ~mul_out_msb};
  assign {carry_round_dummy, round_added} = mul_out[`Msb:`Mhalf - 1] + round_inc;
  assign round_out = (mul_out_msb) ? round_added[`Msb:`Mhalf] :
                                       round_added[`Msb - 1:`Mhalf - 1];

  // Overflow check
  assign ovfl_case_denormal = ieee_compliance & (exp_cal0 == 0) & round_out[`Msb];

  assign ovfl_case_normal = mul_out_msb | (~mul_out_msb & RND_eval0[`RND_Inc] & (&mul_out[`Msb - 1:`Mhalf - 1]));

  assign ovfl_case = (ieee_compliance) ?
           ovfl_case_denormal | ovfl_case_normal :
           ovfl_case_normal;

  // Check mantissa part is zero when ieee_compliance = 1
  assign check_denormal_zero = (ieee_compliance) ?
             ((lzd_in + exp_rsh[exp_width:0] >= sig_width + 1) & ~exp_rsh[exp_width + 1] & ~round_out[`Mhalf] & ~mul_out[`Mhalf - 1]) : 1;

  // Sig Final Selection
  assign sig_inf_sel = (inf_inputs | ovfl_case) ?
             exp1_moreoreq_inf : exp0_moreoreq_inf;
  assign sig_inf_sel2 = (ovfl_case) ?
             exp1_moreoreq_inf : exp0_moreoreq_inf;

  assign sig_zero_sel = (zero_inputs | ovfl_case) ?
             exp1_lessoreq_zero : exp0_lessoreq_zero;
  assign sig_zero_sel2 = (ovfl_case) ?
             exp1_lessoreq_zero : exp0_lessoreq_zero;

  assign ctrl_sig = (ieee_compliance) ?
             nan_case | inf_case | zero_inputs | flag_moreoreq_inf :
             inf_case | zero_inputs | flag_lessoreq_zero | flag_moreoreq_inf; 

  assign special_outputs = (flag_moreoreq_inf & ~RND_eval0[`RND_HugeInfinity] & ~inf_inputs) ? 
                           {(sig_width){1'b1}} : 0;

  assign special_outputs_denormal = (flag_moreoreq_inf & ~RND_eval0[`RND_HugeInfinity] & ~inf_inputs) ? 
                           {(sig_width){1'b1}} : {{(sig_width - 1){1'b0}}, nan_case};

  assign sig_result = (ieee_compliance) ?  
             ((ctrl_sig) ? special_outputs_denormal : round_out[`Msb - 1:`Mhalf]) :
             ((ctrl_sig) ? special_outputs : round_out[`Msb - 1:`Mhalf]);

  // Status Flag Setup
  assign flag_moreoreq_inf = (ovfl_case) ?
             exp1_moreoreq_inf :
             exp0_moreoreq_inf;
  assign flag_lessoreq_zero = (ovfl_case) ?
             exp1_lessoreq_zero :
             exp0_lessoreq_zero;
  assign flag_lessoreq_zero_new = (ieee_compliance) ?
             flag_lessoreq_zero & (sig_result == 0) :
             flag_lessoreq_zero;

  assign rnd_inexact = (mul_out_msb) ? RND_eval1[`RND_Inexact] :
                                         RND_eval0[`RND_Inexact];

  assign status_infinity = (ieee_compliance) ? 
           (inf_case | (flag_moreoreq_inf & RND_eval0[`RND_HugeInfinity])) & ~nan_case :
           inf_case | (flag_moreoreq_inf & RND_eval0[`RND_HugeInfinity]) | nan_case;

  assign status_zero = status_tiny & ~RND_eval0[`RND_TinyminNorm] & check_denormal_zero | (zero_inputs & ~(inf_case | nan_case));

  assign status_invalid = (inf_inputs & zero_inputs) | (ieee_compliance & nan_case);
  assign status_huge = flag_moreoreq_inf & ~inf_inputs;

  assign status_tiny = (ovfl_case) ? 
                       exp1_lessoreq_zero & ~(inf_case | zero_inputs | nan_case) :
                       exp0_lessoreq_zero & ~(inf_case | zero_inputs | nan_case);
  assign status_tiny_correct = (ieee_compliance) ? 
                       status_tiny & ~round_out[`Msb] :
                       status_tiny;

  assign status_inexact = (flag_moreoreq_inf | flag_lessoreq_zero_new | rnd_inexact) & ~inf_inputs & ~zero_inputs;

  // Final Output Setup
  assign z = {1'b0, exp_result, sig_result};
  assign status = {2'b0, status_inexact, status_huge, status_tiny_correct, status_invalid, status_infinity, status_zero};


  //---------------------------------------------------------------

  assign even = (rnd == 0);
  assign away = rnd[2] & rnd[0];
  assign infMatch = rnd[1] & (rnd[0] == 0);
  assign infinity = infMatch | away;

  assign R0_n0 = ~(infinity ? sticky_bit0 : 0);
  assign R1_n0 = ~(even ? (guard_bit0 | sticky_bit0) : (rnd[2] | infMatch));
  assign R0_n1 = ~(infinity ? sticky_bit1 : 0);
  assign R1_n1 = ~(even ? (guard_bit1 | sticky_bit1) : (rnd[2] | infMatch));

  assign RND_eval0_RND_Inc = ~(round_bit0 ? R1_n0 : R0_n0);
  assign RND_eval1_RND_Inc = ~(round_bit1 ? R1_n1 : R0_n1);

  assign RND_eval0_RND_Inexact = round_bit0 | sticky_bit0;
  assign RND_eval1_RND_Inexact = round_bit1 | sticky_bit1;

  assign RND_eval0_RND_HugeInfinity = infinity | (rnd[1:0] == 0);
  assign RND_eval1_RND_HugeInfinity = RND_eval0[`RND_HugeInfinity];

  assign RND_eval0_RND_TinyminNorm = infinity;
  assign RND_eval1_RND_TinyminNorm = RND_eval0[`RND_TinyminNorm];
  

  assign RND_eval0 = {RND_eval0_RND_TinyminNorm, RND_eval0_RND_HugeInfinity, RND_eval0_RND_Inexact, RND_eval0_RND_Inc};
  assign RND_eval1 = {RND_eval1_RND_TinyminNorm, RND_eval1_RND_HugeInfinity, RND_eval1_RND_Inexact, RND_eval1_RND_Inc};
  

  `undef RND_Width
  `undef RND_Inc
  `undef RND_Inexact
  `undef RND_HugeInfinity
  `undef RND_TinyminNorm

  `undef Msb
  `undef Mhalf
  `undef log_awidth
    
endmodule
