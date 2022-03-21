

////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT: Floating-Point Sequencial Divider
//
//              DW_fp_div_seq calculates the floating-point division
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
//              num_cyc         Number of cycles required for the FP sequential
//                              division operation including input and output 
//                              register. Actual number of clock cycle is 
//                              num_cyc - (1 - input_mode) - (1 - output_mode)
//                               - early_start + internal_reg
//              rst_mode        Synchronous / Asynchronous reset 
//                              0 - Asynchronous reset
//                              1 - Synchronous reset
//              input_mode      Input register setup
//                              0 - No input register
//                              1 - Input registers are implemented
//              output_mode     Output register setup
//                              0 - No output register
//                              1 - Output registers are implemented
//              early_start     Computation start (only when input_mode = 1)
//                              0 - start computation in the 2nd cycle
//                              1 - start computation in the 1st cycle (forwarding)
//                              early_start should be 0 when input_mode = 0
//              internal_reg    Insert a register between an integer sequential divider
//                              and a normalization unit
//                              0 - No internal register
//                              1 - Internal register is implemented
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              b               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              Rounding Mode Input
//              clk             Clock
//              rst_n           Reset. (active low)
//              start           Start operation
//                              A new operation is started by setting start=1
//                              for 1 clock cycle
//              z               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Output
//              status          8 bits
//                              Status Flags Output
//              complete        Operation completed
//
// MODIFIED: 5/08/07 (0703-SP2)
//           1. Fixed the rounding error of denormal numbers 
//              when ieee_compliance = 1
//           2. NaN has always + sign.
//
//           6/05/07 (0703-SP3)
//           The legal range of num_cyc parameter widened
//
//           10/18/07 (0712)
//           Fixed 'divide by zero' flag when 0/0
//
//           3/21/08 (0712-SP3)
//           1. Fixed the reset error
//           2. Fixed Async/Sync behavior (STAR 9000232636)
//      
//           1/29/10 (D-2010.03)
//           1. Removed synchronous DFF when rst_mode = 0 (STAR 9000367314)
//           2. Fixed complete signal error at the reset  (STAR 9000371212)
//           3. Fixed divide_by_zero flag error           (STAR 9000371212)
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_fp_div_seq (
  a,
  b,
  rnd,
  clk,
  rst_n,
  start,
  z,
  status,
  complete
  // Embedded dc_shell script
  // _model_constraint_2
  // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

  parameter sig_width = 23;   // RANGE 2 TO 253
  parameter exp_width = 8;    // RANGE 3 TO 31
  parameter ieee_compliance = 0; // RANGE 0 TO 1
  parameter num_cyc = 4;         // RANGE 4 TO (2 * sig_width + 3)
  parameter rst_mode = 0;        // RANGE 0 TO 1
  parameter input_mode = 1;      // RANGE 0 TO 1
  parameter output_mode = 1;     // RANGE 0 TO 1
  parameter early_start = 0;     // RANGE 0 TO 1
  parameter internal_reg = 1;    // RANGE 0 TO 1


  `define RND_Width  4
  `define RND_Inc  0
  `define RND_Inexact  1
  `define RND_HugeInfinity  2
  `define RND_TinyminNorm  3

  `define dw_div_a_size (2 * (sig_width + 1) + 1)
  `define dw_div_b_size (sig_width + 1)
  `define log_awidth ((sig_width + 1>65536)?((sig_width + 1>16777216)?((sig_width + 1>268435456)?((sig_width + 1>536870912)?30:29):((sig_width + 1>67108864)?((sig_width + 1>134217728)?28:27):((sig_width + 1>33554432)?26:25))):((sig_width + 1>1048576)?((sig_width + 1>4194304)?((sig_width + 1>8388608)?24:23):((sig_width + 1>2097152)?22:21)):((sig_width + 1>262144)?((sig_width + 1>524288)?20:19):((sig_width + 1>131072)?18:17)))):((sig_width + 1>256)?((sig_width + 1>4096)?((sig_width + 1>16384)?((sig_width + 1>32768)?16:15):((sig_width + 1>8192)?14:13)):((sig_width + 1>1024)?((sig_width + 1>2048)?12:11):((sig_width + 1>512)?10:9))):((sig_width + 1>16)?((sig_width + 1>64)?((sig_width + 1>128)?8:7):((sig_width + 1>32)?6:5)):((sig_width + 1>4)?((sig_width + 1>8)?4:3):((sig_width + 1>2)?2:1)))))
  `define int_num_cyc (num_cyc - 1)

  //-------------------------------------------------------
  input  [(exp_width + sig_width):0] a;
  input  [(exp_width + sig_width):0] b;
  input  [2:0] rnd;
  input  clk;
  input  rst_n;
  input  start;

  output [(exp_width + sig_width):0] z;
  output [8    -1:0] status;
  output complete;

  wire signed [exp_width + 1:0] ez;
  wire signed [exp_width + 1:0] ez_norm;
  wire signed [exp_width + 1:0] ez_norm_modified; // z0703-SP2
  wire [`dw_div_a_size - 1:0] diva;
  wire [`dw_div_a_size - 1:0] quo;
  wire [`dw_div_a_size - 1:0] quo_out;
  wire [`log_awidth:0] lzd_ina;
  wire [`log_awidth:0] lzd_inb;
  wire [`log_awidth:0] lzd_ina_pre;
  wire [`log_awidth:0] lzd_inb_pre;
  wire [exp_width - 1:0] ea;
  wire [exp_width - 1:0] ea_pre;
  wire [exp_width - 1:0] eb;
  wire [exp_width - 1:0] eb_pre;
  wire [exp_width + 1:0] rshift_amount;
  wire [exp_width - 1:0] exp_result;
  wire [sig_width - 1:0] sa;
  wire [sig_width - 1:0] sb;
  wire [sig_width:0] ma;
  wire [sig_width:0] mb;
  wire [sig_width:0] normed_ma;
  wire [sig_width:0] normed_mb;
  wire [sig_width:0] ma_lzd;
  wire [sig_width:0] mb_lzd;
  wire [sig_width:0] rem_out;
  wire [sig_width:0] mz;
  wire [sig_width:0] div_out;
  wire [sig_width:0] mz_rounded;
  wire [sig_width - 1:0] sig_result;
  wire [sig_width - 1:0] sig_inf_result;
  wire [sig_width - 1:0] sig_nan_result;
  wire [sig_width:0] rem;
  wire [2 * sig_width + 1 : 0] rshift_out;
  wire [(exp_width + sig_width):0] z_pre;
  wire [(exp_width + sig_width):0] a_in;
  wire [(exp_width + sig_width):0] b_in;
  wire [8    -1:0] status_pre;
  wire [2:0] rnd_in;
  wire signa;
  wire signa_pre;
  wire signb;
  wire signb_pre;
  wire sa_zero;
  wire sa_zero_pre;
  wire sb_zero;
  wire sb_zero_pre;
  wire ea_zero;
  wire eb_zero;
  wire ea_inf;
  wire eb_inf;
  wire mz_guard_bit;
  wire mz_round_bit;
  wire mz_sticky_bit;
  wire guard_bit;
  wire round_bit;
  wire sticky_bit;
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
  wire dzero;
  wire shift_req;
  wire shift_req_pre;
  wire stk_check_from_rem;
  wire rnd_ovfl;
  wire over_inf;
  wire below_zero;
  wire max_norm;
  wire min_norm;
  wire infinity;
  wire zero;
  wire exp_zero;
  wire rshift_ovfl;
  wire sig_below_zero;
  wire start_in;
  wire complete_out;
  wire complete_ffin;
  wire denorm_a_pre;
  wire denorm_b_pre;
  wire ea_pre_zero;
  wire eb_pre_zero;
  wire complete_pre;
  wire check_ez;
  wire check_mz;

  reg [`log_awidth:0] lzd_ina_ff;
  reg [`log_awidth:0] lzd_inb_ff;
  reg [`dw_div_a_size - 1:0] quo_ff;
  reg [`RND_Width - 1:0] RND_eval;
  reg [exp_width - 1:0] ea_ff;
  reg [exp_width - 1:0] eb_ff;
  reg [sig_width:0] rem_ff;
  reg [(exp_width + sig_width):0] a_inreg;
  reg [(exp_width + sig_width):0] b_inreg;
  reg [(exp_width + sig_width):0] z_outreg;
  reg [8    -1:0] status_outreg;
  reg [2:0] rnd_inreg;
  reg signa_ff;
  reg signb_ff;
  reg sa_zero_ff;
  reg sb_zero_ff;
  reg shift_req_ff;
  reg complete_pre_ff;
  reg start_next;
  reg complete_outreg;

  reg rst_n_clk;
  reg reset_st;
  reg reset_st_ff;
  wire [8    -1:0] status_pre2;
  wire [(exp_width + sig_width):0] z_pre2;
  wire reset_st2;
  

  generate
    if (rst_mode == 1) begin : GEN_rm_eq_1 // synchronous design
      always @(posedge clk) begin
        if (~rst_n) begin
          a_inreg <= {((exp_width + sig_width)+1){1'b0}};
          b_inreg <= {((exp_width + sig_width)+1){1'b0}};
          rnd_inreg <= 3'b000;
          start_next <= 1'b0;
	  rst_n_clk <= 1'b0;
        end else begin
	  if (start) begin
	    a_inreg <= a;
	    b_inreg <= b;
	    rnd_inreg <= rnd;
	  end
	  start_next <= start;
	  rst_n_clk  <= rst_n;
	end
      end
    end else begin : GEN_rm_ne_1 // asynchronous design
      always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
          a_inreg <= {((exp_width + sig_width)+1){1'b0}};
          b_inreg <= {((exp_width + sig_width)+1){1'b0}};
          rnd_inreg <= 3'b000;
          start_next <= 1'b0;
	  rst_n_clk <= 1'b0;
        end else begin
	  if (start) begin
	    a_inreg <= a;
	    b_inreg <= b;
	    rnd_inreg <= rnd;
	  end
	  start_next <= start;
	  rst_n_clk <= 1'b0;
	end
      end
    end
  endgenerate

  assign a_in = (input_mode == 0) ? a :
                (early_start == 0) ? a_inreg :
                (start == 1) ? a : a_inreg;
  assign b_in = (input_mode == 0) ? b :
                (early_start == 0) ? b_inreg :
                (start == 1) ? b : b_inreg;

  assign rnd_in = (input_mode == 1) ? rnd_inreg : rnd;

  // Unpack the FP Numbers
  assign {signa_pre, ea_pre, sa} = a_in;
  assign {signb_pre, eb_pre, sb} = b_in;

  assign ma = (ieee_compliance & denorm_a_pre) ? {1'b0, sa} : {1'b1, sa};
  assign mb = (ieee_compliance & denorm_b_pre) ? {1'b0, sb} : {1'b1, sb};
  assign ma_lzd = (ieee_compliance & denorm_a) ? {1'b0, sa} : {1'b1, sa};
  assign mb_lzd = (ieee_compliance & denorm_b) ? {1'b0, sb} : {1'b1, sb};

  // from z0703-SP2, NaN has always + sign.
  assign sign = (nan_case) ? 0 : signa ^ signb;

  assign ea = (internal_reg) ? ea_ff : ea_pre;
  assign eb = (internal_reg) ? eb_ff : eb_pre;
  assign signa = (internal_reg) ? signa_ff : signa_pre;
  assign signb = (internal_reg) ? signb_ff : signb_pre;
  assign sa_zero = (internal_reg) ? sa_zero_ff : sa_zero_pre;
  assign sb_zero = (internal_reg) ? sb_zero_ff : sb_zero_pre;
  assign shift_req = (internal_reg) ? shift_req_ff : shift_req_pre;
  assign lzd_ina = (internal_reg) ? lzd_ina_ff : lzd_ina_pre;
  assign lzd_inb = (internal_reg) ? lzd_inb_ff : lzd_inb_pre;

  // Check Special Inputs
  assign sa_zero_pre = (sa == 0);
  assign sb_zero_pre = (sb == 0);
  assign ea_zero = (ea == 0);
  assign eb_zero = (eb == 0);
  assign ea_inf = (ea == ((((1 << (exp_width-1)) - 1) * 2) + 1));
  assign eb_inf = (eb == ((((1 << (exp_width-1)) - 1) * 2) + 1));
  assign ea_pre_zero = (ea_pre == 0);
  assign eb_pre_zero = (eb_pre == 0);

  assign inf_a = (ieee_compliance) ? ea_inf & sa_zero : ea_inf;
  assign inf_b = (ieee_compliance) ? eb_inf & sb_zero : eb_inf;
  assign nan_a = (ieee_compliance) ? ea_inf & ~sa_zero : 0;
  assign nan_b = (ieee_compliance) ? eb_inf & ~sb_zero : 0;
  assign zero_a = (ieee_compliance) ? ea_zero & sa_zero : ea_zero;
  assign zero_b = (ieee_compliance) ? eb_zero & sb_zero : eb_zero;
  assign denorm_a = (ieee_compliance) ? ea_zero & ~sa_zero : 0;
  assign denorm_b = (ieee_compliance) ? eb_zero & ~sb_zero : 0;
  assign denorm_a_pre = (ieee_compliance) ? ea_pre_zero & ~sa_zero_pre : 0;
  assign denorm_b_pre = (ieee_compliance) ? eb_pre_zero & ~sb_zero_pre : 0;

  assign nan_case = nan_a | nan_b | (inf_a & inf_b) | (zero_a & zero_b);
  assign inf_case = inf_a | zero_b;
  assign zero_case = zero_a | inf_b;
  assign normal_case = ~nan_case & ~inf_case & ~zero_case;

  // Need to be changed later with DW_fp_div together (10/27 by kyung)
  // Correct Representation
  assign sig_inf_result = 0;
  assign sig_nan_result = (ieee_compliance) ? 1 : 0;
  // Wrong Representation
  //assign sig_inf_result = (ieee_compliance) ? 0 : {(sig_width){1'b1}};
  //assign sig_nan_result = (ieee_compliance) ? 1 : {(sig_width){1'b1}};

  // Exponent Calculation
  assign ez = (ieee_compliance) ?
              (ea - lzd_ina + denorm_a - eb + lzd_inb - denorm_b + ((1 << (exp_width-1)) - 1)) :
              ea - eb + ((1 << (exp_width-1)) - 1);

  // Normalization of Denormal Inputs
  // Two LZD and two left shifters are required
  DW_lzd #(sig_width + 1) U1 (
    .a(ma),
    .enc(lzd_ina_pre)
  );

  DW_lzd #(sig_width + 1) U2 (
    .a(mb),
    .enc(lzd_inb_pre)
  );

  assign normed_ma = (ieee_compliance) ? ma << lzd_ina_pre : ma;
  assign normed_mb = (ieee_compliance) ? mb << lzd_inb_pre : mb;

  // DW_div Instantiation
  assign diva = {normed_ma, {(sig_width + 2){1'b0}}};

  assign start_in = (input_mode & ~early_start) ? start_next : start;

  DW_div_seq #(`dw_div_a_size, `dw_div_b_size, 0, `int_num_cyc, rst_mode, 0, 0, 0) U3 (
      .clk(clk),
      .rst_n(rst_n),
      .hold(1'b0),
      .start(start_in),
      .a(diva),
      .b(normed_mb),
      .complete(complete_out),
      .divide_by_0(dzero),
      .quotient(quo_out),
      .remainder(rem_out)
  );

  //------------------------------------------------
  // Internal Registers 
  //------------------------------------------------
  generate
    if (internal_reg == 1 && rst_mode == 1) begin : GEN_ir1_rm1 // synchronous
        always @(posedge clk) begin
          if (~rst_n) begin
            quo_ff <= {`dw_div_a_size{1'b0}};
            rem_ff <= {(sig_width+1){1'b0}};
            complete_pre_ff <= 1'b0;
            ea_ff <= {exp_width{1'b0}};
            eb_ff <= {exp_width{1'b0}};
            signa_ff <= 1'b0;
            signb_ff <= 1'b0;
            sa_zero_ff <= 1'b0;
            sb_zero_ff <= 1'b0;
            shift_req_ff <= 1'b0;
            lzd_ina_ff <= {(`log_awidth+1){1'b0}};
            lzd_inb_ff <= {(`log_awidth+1){1'b0}};
            reset_st_ff <= 1'b0;
          end
          else begin : GEN_not_ir1_rm1
            quo_ff <= quo_out;
            rem_ff <= rem_out;
            complete_pre_ff <= complete_out;
            ea_ff <= ea_pre;
            eb_ff <= eb_pre;
            signa_ff <= signa_pre;
            signb_ff <= signb_pre;
            sa_zero_ff <= sa_zero_pre;
            sb_zero_ff <= sb_zero_pre;
            shift_req_ff <= shift_req_pre;
            lzd_ina_ff <= lzd_ina_pre;
            lzd_inb_ff <= lzd_inb_pre;
            reset_st_ff <= reset_st;
          end
        end
    end
    else if (internal_reg == 1 && rst_mode == 0) begin : GEN_ir1_rm0 // asynchronous
        always @(posedge clk or negedge rst_n) begin
          if (~rst_n) begin
            quo_ff <= {`dw_div_a_size{1'b0}};
            rem_ff <= {(sig_width+1){1'b0}};
            complete_pre_ff <= 1'b0;
            ea_ff <= {exp_width{1'b0}};
            eb_ff <= {exp_width{1'b0}};
            signa_ff <= 1'b0;
            signb_ff <= 1'b0;
            sa_zero_ff <= 1'b0;
            sb_zero_ff <= 1'b0;
            shift_req_ff <= 1'b0;
            lzd_ina_ff <= {(`log_awidth+1){1'b0}};
            lzd_inb_ff <= {(`log_awidth+1){1'b0}};
            reset_st_ff <= 1'b0;
          end
          else begin
            quo_ff <= quo_out;
            rem_ff <= rem_out;
            complete_pre_ff <= complete_out;
            ea_ff <= ea_pre;
            eb_ff <= eb_pre;
            signa_ff <= signa_pre;
            signb_ff <= signb_pre;
            sa_zero_ff <= sa_zero_pre;
            sb_zero_ff <= sb_zero_pre;
            shift_req_ff <= shift_req_pre;
            lzd_ina_ff <= lzd_ina_pre;
            lzd_inb_ff <= lzd_inb_pre;
            reset_st_ff <= reset_st;
          end
        end // end of always
    end // end of else if (rst_mode == 0)
  endgenerate


  assign reset_st2 = (internal_reg) ? reset_st_ff : reset_st;

  // internal_reg parameter
  assign quo = (internal_reg) ? quo_ff : quo_out;
  assign rem = (internal_reg) ? rem_ff : rem_out;
  assign complete_pre = (internal_reg) ? complete_pre_ff : complete_out;

  // sticky check from rem
  assign stk_check_from_rem = (rem != 0);
  
  // 1b Shift (Normalization by mux)
  assign shift_req_pre = (normed_ma < normed_mb);
  assign mz = (~shift_req) ? quo[sig_width + 2:2] : quo[sig_width + 1:1];

  // Exponent Normalization
  assign ez_norm = ez - shift_req;

  // Rounding Control Setup for Normal Division
  assign mz_guard_bit = (~shift_req) ? quo[2] : quo[1];
  assign mz_round_bit = (~shift_req) ? quo[1] : quo[0];
  assign mz_sticky_bit = stk_check_from_rem | (quo[0] & ~shift_req);

  // Denorma Output Support
  assign rshift_ovfl = (sig_width + ez_norm + 1 < 0); // -ez > f + 1
  assign rshift_amount = (ieee_compliance) ?
             ((ez_norm[exp_width + 1] | (ez_norm == 0)) ?
               ((rshift_ovfl) ? sig_width + 2 : 1 - ez_norm) :
               0) :
             0;

  assign rshift_out = (ieee_compliance) ? 
           {mz, {(sig_width + 1){1'b0}}} >> rshift_amount :
           0;

  // Final Division Out
  assign div_out = (ieee_compliance) ? 
           rshift_out[2 * sig_width + 1:sig_width + 1] :
           mz;

  // Final Rounding Control Setup
  assign guard_bit = (ieee_compliance) ? div_out[0] : mz_guard_bit;
  assign round_bit = (ieee_compliance) ? 
           ((div_out[sig_width]) ? mz_round_bit : rshift_out[sig_width]) :
           mz_round_bit;
  assign sticky_bit = (ieee_compliance) ?
           (|rshift_out[sig_width - 1:0]) | mz_sticky_bit :
           mz_sticky_bit;

  // Rounding Addition
  assign {rnd_ovfl, mz_rounded} = div_out + RND_eval[`RND_Inc];

  // Exponent Adjust from z0703-SP2
  assign check_ez = (ez_norm == 0);
  assign check_mz = mz_rounded[sig_width];
  assign ez_norm_modified = (ieee_compliance & (ez_norm == 0) & mz_rounded[sig_width]) ?
                              1 : ez_norm;

  // Huge, Tiny Setup
  assign over_inf = (ez_norm[exp_width:0] >= ((((1 << (exp_width-1)) - 1) * 2) + 1)) & ~ez_norm[exp_width + 1];
  assign below_zero = (ez_norm == 0) | ez_norm[exp_width + 1];
  assign sig_below_zero = (ieee_compliance) ? 0 : below_zero;

  assign infinity = over_inf & RND_eval[`RND_HugeInfinity];
  assign max_norm = over_inf & ~RND_eval[`RND_HugeInfinity];
  assign min_norm = (ieee_compliance) ? 0 : below_zero & RND_eval[`RND_TinyminNorm];

  // from z0703-SP2
  assign exp_zero = (ieee_compliance) ? 
                      below_zero & (~(check_ez & check_mz)) : 
                      below_zero & ~RND_eval[`RND_TinyminNorm];

  assign zero = (ieee_compliance) ?
           (sig_result == 0) & (exp_result == 0) : // need to improve more
           exp_zero;

  // Status Flag Setup
  //assign status_pre[7] = zero_b & ~zero_a;
  assign status_pre[7] = (ieee_compliance) ?
            zero_b & ~(zero_a | nan_a | inf_a) :
            zero_b & ~(zero_a | nan_a); 

  assign status_pre[6] = 0;
  assign status_pre[5] = normal_case & (over_inf | sig_below_zero | RND_eval[`RND_Inexact]);
  assign status_pre[4] = normal_case & over_inf;
  assign status_pre[3] = normal_case & below_zero;
  assign status_pre[2] = nan_case;
  assign status_pre[1] = ~nan_case & ((infinity & ~zero_case) | inf_case);
  assign status_pre[0] = ~nan_case & (zero | zero_case) & ~zero_b;
  assign status_pre2 = status_pre & {8{~reset_st2}}; //

  // Output Generation
  assign sig_result = (nan_case) ? 
           sig_nan_result :
           (inf_case | (infinity & ~zero_case)) ?
             sig_inf_result :
             (zero_case | sig_below_zero) ?
               0 :
               (max_norm) ?
                 {(sig_width){1'b1}} :
                 mz_rounded[sig_width - 1:0];

  assign exp_result = (nan_case | inf_case | (infinity & ~zero_case)) ?
           {(exp_width){1'b1}} :
           (exp_zero | zero_case) ?
             0 :
             (max_norm) ?
               {{(exp_width - 1){1'b1}}, 1'b0} :
               (min_norm) ?
                 1 :
                 ez_norm_modified[exp_width - 1:0];

  assign z_pre = {sign, exp_result, sig_result};
  assign z_pre2 = z_pre & {((exp_width + sig_width) + 1){~reset_st2}};

  // Output Register
  assign complete_ffin = complete_pre;
  
  generate
    if ((rst_mode != 0) && (output_mode == 1)) begin : GEN_rmne0_om1
      always @(posedge clk) begin
        if (~rst_n) begin
          z_outreg <= {((exp_width + sig_width)+1){1'b0}};
          status_outreg <= 8'b00000000;
          complete_outreg <= 1'b0;
        end
        else begin
          z_outreg <= z_pre2;
          status_outreg <= status_pre2;
          complete_outreg <= complete_ffin;
        end
      end

      assign z        = (reset_st==1'b1)? {((exp_width + sig_width)+1){1'b0}} : z_outreg;
      assign status   = (reset_st==1'b1)? 8'b0000000           : status_outreg;
      assign complete = complete_outreg;
    end
  endgenerate

  generate
    if ((rst_mode == 0) && (output_mode == 1)) begin : GEN_rm0_om1 // asynchronous
      always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
          z_outreg <= {((exp_width + sig_width)+1){1'b0}};
          status_outreg <= 8'b00000000;
          complete_outreg <= 1'b0;
        end
        else begin
          z_outreg <= z_pre2;
          status_outreg <= status_pre2;
          complete_outreg <= complete_ffin;
        end
      end

      assign z        = (reset_st==1'b1)? {((exp_width + sig_width)+1){1'b0}} : z_outreg;
      assign status   = (reset_st==1'b1)? 8'b0000000           : status_outreg;
      assign complete = complete_outreg;
    end
  endgenerate

  generate
    if (output_mode != 1) begin : GEN_om_eq_1
      assign z        = (reset_st==1'b1)? {((exp_width + sig_width)+1){1'b0}} : z_pre2;
      assign status   = (reset_st==1'b1)? 8'b0000000           : status_pre2;
      assign complete = complete_ffin;
    end
  endgenerate


  //--------------------------------------------------
  // Rounding Block Description
  //--------------------------------------------------
  
  //----------------------------------------
  // RND_eval[3] : RND_TinyminNorm
  // RND_eval[2] : RND_HugeInfinity
  // RND_eval[1] : RND_Inexact
  // RND_eval[0] : RND_Inc
  //----------------------------------------

  always @(guard_bit or round_bit or sticky_bit or sign or rnd_in) begin
  
    RND_eval[`RND_TinyminNorm] = 0;
    RND_eval[`RND_HugeInfinity] = 0;
    RND_eval[`RND_Inexact] = round_bit | sticky_bit;
    RND_eval[`RND_Inc] = 0;

    case (rnd_in)

      // ----------------------------------------
      // Round Nearest Even (RNE) Mode
      // ----------------------------------------
      3'b000: begin
        RND_eval[`RND_Inc] = round_bit & (guard_bit | sticky_bit);
        RND_eval[`RND_HugeInfinity] = 1;
        RND_eval[`RND_TinyminNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Zero (RZ) Mode
      // ----------------------------------------
      3'b001: begin
        RND_eval[`RND_Inc] = 0;
        RND_eval[`RND_HugeInfinity] = 0;
        RND_eval[`RND_TinyminNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Positive Infinity Mode
      // ----------------------------------------
      3'b010: begin
        RND_eval[`RND_Inc] = ~sign & (round_bit | sticky_bit);
        RND_eval[`RND_HugeInfinity] = ~sign;
        RND_eval[`RND_TinyminNorm] = ~sign;
      end
      
      // ----------------------------------------
      // Round to Negative Infinity Mode
      // ----------------------------------------
      3'b011: begin
        RND_eval[`RND_Inc] = sign & (round_bit | sticky_bit);
        RND_eval[`RND_HugeInfinity] = sign;
        RND_eval[`RND_TinyminNorm] = sign;
      end
      
      // ----------------------------------------
      // Round to Nearest Up (RNU) Mode
      // ----------------------------------------
      3'b100: begin
        RND_eval[`RND_Inc] = round_bit;
        RND_eval[`RND_HugeInfinity] = 1;
        RND_eval[`RND_TinyminNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Infinity (RI) Mode
      // ----------------------------------------
      3'b101: begin
        RND_eval[`RND_Inc] = round_bit | sticky_bit;
        RND_eval[`RND_HugeInfinity] = 1;
        RND_eval[`RND_TinyminNorm] = 1;
      end
      
      default: begin
        RND_eval[`RND_Inc] = 1'bx;
        RND_eval[`RND_HugeInfinity] = 1'bx;
        RND_eval[`RND_TinyminNorm] = 1'bx;
      end
    endcase
  end

  generate
    if (rst_mode == 1) begin : GEN_rm_eq_1_a // synchronous
      always @(posedge clk) begin
        if (~rst_n_clk) begin
          reset_st <= 1'b1;
        end else begin
          if (reset_st == 0) begin
            reset_st <= 1'b0;
          end else begin
            reset_st <= ~start;
          end
        end
      end
    end
    else if (rst_mode == 0) begin : GEN_rm_eq_0_a // asynchronous
      always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
          reset_st <= 1'b1;
        end else begin
          if (reset_st == 0) begin
            reset_st <= 1'b0;
          end else begin
            reset_st <= ~start;
          end
        end
      end
    end
  endgenerate

  `undef RND_Width
  `undef RND_Inc
  `undef RND_Inexact
  `undef RND_HugeInfinity
  `undef RND_TinyminNorm
  `undef dw_div_a_size
  `undef dw_div_b_size
  `undef log_awidth

    
endmodule
