
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT:  Integer Number Format to Floating-Point Number Format
//            Converter
//
//              This converts an integer number to a floating-point
//              number.
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              isize           integer size,      3 to 512 bits
//              isign           signed/unsigned integer
//                              0 - unsigned, 1 - signed integer (2's complement)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (isize)-bits 
//                              Integer Input
//              rnd             3 bits
//                              Rounding Mode Input
//              z               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Output
//              status          8 bits
//                              Status Flags Output
//
// Modified:
//   3/24/08 KYUNG (STAR 9000233504)
//           Fixed array index problem for 24b-to-16b conversion
//           Removed VCS SIOB, ZONMCM Warning messages
//   3/23/12 Kyung (STAR 9000513334)
//           1. Removed VCS TFIPC (Too few instance port connections) 
//              warning message due to unconnected .dec() port of DW_lzd
//           2. Removed VCS SIOB (Select index out of bounds)
//              warning message when #(15,8,1,17)
//           3. Removed functional bugs when a = 1 with #(15,8,1,17)
//              when a = 1, z became 0 which is wrong.
//           4. Removed Lint messages
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_fp_i2flt (
  a,
  rnd,
  z,
  status
  // Embedded dc_shell script
  // _model_constraint_1
  // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

  parameter sig_width = 23;  // RANGE 2 TO 253
  parameter exp_width = 8;   // RANGE 3 TO 31
  parameter isize = 32;      // RANGE 3 TO 512
  parameter isign = 1;	     // RANGE 0 TO 1
                             // 1 : signed, 0 : unsigned


  `define RND_Width  4
  `define RND_Inc  0
  `define RND_Inexact  1
  `define RND_HugeInfinity  2
  `define RND_TinyMinNorm  3
  `define log2_isize ((isize>256)?((isize>4096)?((isize>16384)?((isize>32768)?16:15):((isize>8192)?14:13)):((isize>1024)?((isize>2048)?12:11):((isize>512)?10:9))):((isize>16)?((isize>64)?((isize>128)?8:7):((isize>32)?6:5)):((isize>4)?((isize>8)?4:3):((isize>2)?2:1))))
  `define log2_isize_1 ((isize - 1 >256)?((isize - 1 >4096)?((isize - 1 >16384)?((isize - 1 >32768)?16:15):((isize - 1 >8192)?14:13)):((isize - 1 >1024)?((isize - 1 >2048)?12:11):((isize - 1 >512)?10:9))):((isize - 1 >16)?((isize - 1 >64)?((isize - 1 >128)?8:7):((isize - 1 >32)?6:5)):((isize - 1 >4)?((isize - 1 >8)?4:3):((isize - 1 >2)?2:1))))
  `define log2_lzdsize ((isign) ? `log2_isize_1 : `log2_isize)
  `define lzd_size ((isign) ? isize - 1 : isize)
  `define shifter_bit ((isign) ? `lzd_size + ((1 << (`log2_isize_1 - 1)) - 1) : `lzd_size)
  `define larger_f ((`lzd_size < sig_width + 1) ? 1 : 0)
  `define lsb_bnorm ((`larger_f) ? 0 : ((isign) ? 0 : `lzd_size - sig_width - 1))
  `define msb_bnorm ((`larger_f) ? sig_width - 1 : `lzd_size - 2)
  `define msb_corr ((`lzd_size - sig_width - 3 >= 0) ? `lzd_size - sig_width - 3 : 0)
  `define exp_constant (`lzd_size + ((1 << (exp_width-1)) - 1) - 1)
  //`define exp_inf_case ((exp_width - 1 <= `log2_isize) ? 1 : 0)
  `define exp_inf_case ((exp_width - 1 <= `log2_lzdsize) ? 1 : 0)
  `define exp_size ((exp_width <= `log2_isize) ? `log2_isize : exp_width)

  `define concat_size ((`larger_f) ? sig_width - `lzd_size + 1 : 1)

  `define msb_corr2 ((`lzd_size - sig_width - 3 >= 0) ? `lzd_size - sig_width - 2 : 1)
  `define guard_index1 ((`larger_f) ? 0 : `lzd_size - sig_width - 1)
  `define guard_index2 (((`larger_f == 0) && (isign == 1)) ? ((`lzd_size - sig_width - 2 < 0) ? 0 : `lzd_size - sig_width - 2) : 1)
  `define round_index2 ((`lzd_size - sig_width - 2 < 0) ? 0 : `lzd_size - sig_width - 2)
  `define ovfl_index ((`lzd_size <= sig_width + 1) ? 0 : `lzd_size - sig_width - 2)
  `define b_norm_carry_index1 ((`larger_f == 0) ? `lzd_size - 2 : 0)
  `define b_norm_carry_index2 (((`larger_f == 0) && (isign == 0)) ? `lzd_size - sig_width - 1 : 0)
  `define final_mantissa_index1 ((`larger_f == 0) ? `lzd_size - 2 : 0)
  `define final_mantissa_index2 ((`larger_f == 0) ? `lzd_size - sig_width - 1 : 0)

  localparam exception_case = ((isign == 1) && ((isize == 3) || (isize == 5) || (isize == 9) || (isize == 17) || (isize == 33) || (isize == 65) || (isize == 129) || (isize == 257)));
  localparam norm_output_lsb = (1 << (`log2_lzdsize - 1)) - 1;
  localparam norm_output_msb = norm_output_lsb + `lzd_size - 1;

  //-------------------------------------------------------

  input  [isize-1:0] a;
  input  [2:0] rnd; 

  output [(exp_width + sig_width):0] z;
  output [8    -1:0] status; 

  wire sign;
  wire [`lzd_size - 1:0] data;
  wire [`lzd_size - 1:0] a_inv;
  wire [`lzd_size - 1:0] a_compl;
  wire [`msb_bnorm:`lsb_bnorm] b_norm;
  wire stk_zd;
  wire guard_bit;
  wire round_bit;
  wire sticky_bit;
  wire status_zero_flag;
  wire status_inexact_flag;
  wire status_huge_flag;
  wire status_infinity_flag;
  wire status_inexact_flag_final;
  wire [`lzd_size - 1:0] norm_input;
  wire [`lzd_size - 1:0] norm_output;
  wire [`log2_lzdsize - 1:0] lzd_enc;
  wire [`lzd_size - 1:0] a_norm;
  wire [`exp_size - 1:0] exp_adj;
  wire [`exp_size - 1:0] exp_adj_inf;
  wire [exp_width - 1:0] final_exp;
  wire sign_adj;
  wire dummy;
  wire [`lzd_size - 1:0] shift4;
  wire [(1 << (`log2_lzdsize - 1)) - 2:0] UNCON;
  wire [(1 << (`log2_lzdsize - 2)) - 1:0] lzd_in;
  wire check_ovfl_compl;
  wire RND_Inc_wire;
  wire b_norm_carry;
  wire check_stk_allone;
  wire check_stk_allzero;
  wire [`shifter_bit - 1:0] shifter_input;
  wire [`shifter_bit - 1:0] shifter_output;
  wire exp_carry;
  wire exp_ovfl;
  wire [sig_width - 1:0] final_mantissa;
  wire [`lzd_size - 1:0] b_norm_add_f;
  wire [31:0] exp_const;
  wire [31:0] exp_lhs_32b;
  wire [31:0] infexp = ((((1 << (exp_width-1)) - 1) * 2) + 1);
  wire [31:0] infexp_m1 = ((((1 << (exp_width-1)) - 1) * 2) + 1) - 1;
  wire all_one_in;
  wire [(1 << (`log2_lzdsize - 2)) - 1:0] lzd_in_a;
  wire [(1 << (`log2_lzdsize - 2)) - 1:0] lzd_in_b;

  reg [`RND_Width - 1:0] RND_eval;

  //---------------------------------------------------------------
  
  // Unpack the input
  assign sign = (isign) ? a[isize - 1] : 1'b0;
  assign data = a[`lzd_size - 1:0];

  // Complementation
  assign a_inv = (sign) ? ~data : data;

  // DW_norm Implmentation
  assign norm_input = (isign) ? a_inv : a[`lzd_size - 1:0];

  // This is the optimal structure of 32b DW_norm with sign extension
  assign lzd_enc[`log2_lzdsize - 1] = (norm_input[`lzd_size - 1:`lzd_size - (1 << (`log2_lzdsize - 1))] == 0);
      assign lzd_enc[`log2_lzdsize - 2] = (shift4[`lzd_size - 1:`lzd_size - (1 << (`log2_lzdsize - 2))] == 0);

  assign lzd_in_a = shift4[`lzd_size - (1 << (`log2_lzdsize - 2)) - 1:`lzd_size - (1 << (`log2_lzdsize - 1))];
  assign lzd_in_b = shift4[`lzd_size - 1:`lzd_size - (1 << (`log2_lzdsize - 2))];
  assign lzd_in = (lzd_enc[`log2_lzdsize - 2]) ? lzd_in_a : lzd_in_b;

  generate
    if (`log2_lzdsize >= 4) begin : GEN_07A
      DW_lzd #((1 << (`log2_lzdsize - 2))) U1 (
        .a(lzd_in),
        .enc({dummy, lzd_enc[`log2_lzdsize - 3:0]}),
        .dec()
      );
    end
    else if (`log2_lzdsize == 3) begin : GEN_07B
      DW_lzd #((1 << (`log2_lzdsize - 2))) U1 (
        .a(lzd_in),
        .enc({dummy, lzd_enc[0]}),
        .dec()
      );
    end
  endgenerate

  assign shift4 = (lzd_enc[`log2_lzdsize - 1]) ? 
                    {norm_input[`lzd_size - (1 << (`log2_lzdsize - 1)) - 1:0], {((1 << (`log2_lzdsize - 1))){sign}}} : 
                    norm_input;

  assign shifter_output = shifter_input << lzd_enc[`log2_lzdsize - 2:0];

  generate
    if (isign == 1) begin : GEN_02A
      assign shifter_input = {shift4, {((1 << (`log2_lzdsize - 1)) - 1){sign}}};
      assign norm_output = shifter_output[norm_output_msb:norm_output_lsb];
    end
    else begin : GEN_02B
      assign shifter_input = shift4;
      assign norm_output = shifter_output[`shifter_bit - 1 : 0];
    end
  endgenerate

  // status flag setup when exp >= InfExp
  assign status_inexact_flag = ((check_ovfl_compl) ?
    1'b0 : 
    (sign) ? 1'b1 : RND_eval[`RND_Inexact]);
  assign status_huge_flag = (`exp_inf_case & exp_ovfl) ? 1'b1 : 1'b0;
  assign status_infinity_flag = (`exp_inf_case & exp_ovfl & RND_eval[`RND_HugeInfinity]) ?
    1'b1 : 1'b0;

  assign status_inexact_flag_final = (`exp_inf_case & exp_ovfl) ? 
    1'b1 : status_inexact_flag;
    

  // Rounding Control Implementation
  assign check_stk_allone = (`lzd_size - sig_width - 3 < 0) ?
    sign :
    ((isign) ?
      (norm_output[`msb_corr:0] == {(`msb_corr2){1'b1}}) :

      1'b0);

  assign check_stk_allzero = (`lzd_size - sig_width - 3 < 0) ?
    1'b1 :
    (norm_output[`msb_corr:0] == 0);

  assign guard_bit = (`larger_f) ?
    1'b0 :
    (isign) ?
      ((check_stk_allone & norm_output[`guard_index2] & sign) ?
        ~norm_output[`guard_index1] :
        norm_output[`guard_index1]) :
      norm_output[`guard_index1];

  assign round_bit = (`lzd_size - sig_width - 2 < 0) ?
    1'b0 :
    ((isign) ?
      ((check_stk_allone & sign) ? 
        ~norm_output[`round_index2] :
        norm_output[`round_index2]) :
      norm_output[`round_index2]);
    
  assign sticky_bit = (`larger_f) ?
    1'b0 :
    (isign) ? 
      ((check_stk_allone & sign) ? 
        1'b0 :
        ~check_stk_allzero | (check_stk_allzero & sign)) :
      ~check_stk_allzero;

  // Check Rounding after Complementation 
  assign check_ovfl_compl = (`lzd_size <= sig_width + 1) ? 
    1'b1 :
    (check_stk_allone & norm_output[`ovfl_index]) & sign;

  assign RND_Inc_wire = (`larger_f) ?
    1'b0 :
    (isign) ? 
      ((check_ovfl_compl) ? 1'b0 : RND_eval[0]) :
      RND_eval[0];

  // Final Adder Implementation
  assign b_norm_add_f = norm_output[`lzd_size - 2:0] + sign;

  generate
    if (`guard_index2 <= 0) begin : GEN_01A
      if (`larger_f) begin : GEN_01A_1
        assign {b_norm_carry, b_norm} = {b_norm_add_f, {(`concat_size){1'b0}}};
      end
      else if (isign) begin : GEN_01A_2
        assign {b_norm_carry, b_norm} = norm_output[`b_norm_carry_index1:0] + {RND_Inc_wire, sign};
      end
      else begin : GEN_01A_3
        assign {b_norm_carry, b_norm} = norm_output[`b_norm_carry_index1:`b_norm_carry_index2] + RND_Inc_wire;
      end
    end
    else begin : GEN_01B
      if (`larger_f) begin : GEN_01B_1
        assign {b_norm_carry, b_norm} = {b_norm_add_f, {(`concat_size){1'b0}}};
      end
      else if (isign) begin : GEN_01B_2
        assign {b_norm_carry, b_norm} = norm_output[`b_norm_carry_index1:0] + {RND_Inc_wire, {(`guard_index2){1'b0}}, sign};
      end
      else begin : GEN_01B_3
        assign {b_norm_carry, b_norm} = norm_output[`b_norm_carry_index1:`b_norm_carry_index2] + RND_Inc_wire;
      end
    end
  endgenerate

  generate
    if (`larger_f) begin : GEN_05A
      assign final_mantissa = b_norm;
    end
    else if (`exp_inf_case) begin : GEN_05B
      //assign final_mantissa = (exp_ovfl) ? {(sig_width){1'b1}} :
      assign final_mantissa = (exp_ovfl) ? {(sig_width){~RND_eval[`RND_HugeInfinity]}} :
        b_norm[`final_mantissa_index1:`final_mantissa_index2];
    end
    else begin : GEN_05C
      assign final_mantissa = b_norm[`final_mantissa_index1:`final_mantissa_index2];
    end
  endgenerate

  // Exponent Calculation
  assign exp_const = `exp_constant;
  assign exp_lhs_32b = exp_const - lzd_enc[`log2_lzdsize - 1:0] + b_norm_carry; 
  assign {exp_carry, exp_adj} = (status_zero_flag) ? {(`exp_size + 1){1'b0}} : exp_lhs_32b[`exp_size:0];

  generate
    if (`exp_inf_case) begin : GEN_06A
      if (exp_width <= `log2_isize) begin : GEN_06B
      //if (exp_width <= `log2_lzdsize) begin : GEN_06B
        assign exp_ovfl = exp_carry | (exp_adj >= {(exp_width){1'b1}});
      end
      else begin : GEN_06C
        assign exp_ovfl = exp_carry | (exp_adj[exp_width - 1:0] == ({(exp_width){1'b1}}));
      end
    end
    else begin : GEN_06D
      assign exp_ovfl = 1'b0;
    end
  endgenerate

  assign exp_adj_inf = (`exp_inf_case & exp_ovfl) ? 
    ((RND_eval[`RND_HugeInfinity]) ? infexp[`exp_size - 1:0] : infexp_m1[`exp_size - 1:0]) : 
    exp_adj;

  generate
    if (exception_case) begin : GEN_04A
      assign all_one_in = (a == {(isize){1'b1}});
      assign final_exp = (all_one_in) ?  {1'b0, {(exp_width - 1){1'b1}}} :
                         (`exp_inf_case) ? exp_adj_inf : 
                                           exp_adj;
      assign sign_adj = (all_one_in) ? 1'b1 :
                        (status_zero_flag) ? 1'b0 : sign;
      assign status_zero_flag = (all_one_in) ? 1'b0 : (norm_output[`lzd_size - 1] == 0);
    end
    else begin : GEN_04B
      assign final_exp = (`exp_inf_case) ? exp_adj_inf : exp_adj;
      assign sign_adj = (status_zero_flag) ? 1'b0 : sign;
      assign status_zero_flag = (norm_output[`lzd_size - 1] == 0);
    end
  endgenerate

  // Output Format
  assign z = {sign_adj, final_exp, final_mantissa};

  assign status = {2'b0, status_inexact_flag_final, status_huge_flag, 2'b0, status_infinity_flag, status_zero_flag};

  //--------------------------------------------------
  // Rounding Block Description
  //--------------------------------------------------
  
  //----------------------------------------
  // RND_eval[3] : `RND_TinyMinNorm
  // RND_eval[2] : `RND_HugeInfinity
  // RND_eval[1] : `RND_Inexact
  // RND_eval[0] : `RND_Inc
  //----------------------------------------
  
  always @(guard_bit or round_bit or sticky_bit or sign or rnd) begin
  
    RND_eval[`RND_TinyMinNorm] = 0;
    RND_eval[`RND_HugeInfinity] = 0;
    RND_eval[`RND_Inexact] = round_bit | sticky_bit;
    RND_eval[`RND_Inc] = 0;

    case (rnd)

      // ----------------------------------------
      // Round Nearest Even (RNE) Mode
      // ----------------------------------------
      3'b000: begin
        RND_eval[`RND_Inc] = round_bit & (guard_bit | sticky_bit);
        RND_eval[`RND_HugeInfinity] = 1;
        RND_eval[`RND_TinyMinNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Zero (RZ) Mode
      // ----------------------------------------
      3'b001: begin
        RND_eval[`RND_Inc] = 0;
        RND_eval[`RND_HugeInfinity] = 0;
        RND_eval[`RND_TinyMinNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Positive Infinity Mode
      // ----------------------------------------
      3'b010: begin
        RND_eval[`RND_Inc] = ~sign & (round_bit | sticky_bit);
        RND_eval[`RND_HugeInfinity] = ~sign;
        RND_eval[`RND_TinyMinNorm] = ~sign;
      end
      
      // ----------------------------------------
      // Round to Negative Infinity Mode
      // ----------------------------------------
      3'b011: begin
        RND_eval[`RND_Inc] = sign & (round_bit | sticky_bit);
        RND_eval[`RND_HugeInfinity] = sign;
        RND_eval[`RND_TinyMinNorm] = sign;
      end
      
      // ----------------------------------------
      // Round to Nearest Up (RNU) Mode
      // ----------------------------------------
      3'b100: begin
        RND_eval[`RND_Inc] = round_bit;
        RND_eval[`RND_HugeInfinity] = 1;
        RND_eval[`RND_TinyMinNorm] = 0;
      end
      
      // ----------------------------------------
      // Round to Infinity (RI) Mode
      // ----------------------------------------
      3'b101: begin
        RND_eval[`RND_Inc] = round_bit | sticky_bit;
        RND_eval[`RND_HugeInfinity] = 1;
        RND_eval[`RND_TinyMinNorm] = 1;
      end
      
      default: begin
        RND_eval[`RND_Inc] = 1'bx;
        RND_eval[`RND_HugeInfinity] = 1'bx;
        RND_eval[`RND_TinyMinNorm] = 1'bx;
      end
    endcase
  end

  `undef RND_Width
  `undef RND_Inc
  `undef RND_Inexact
  `undef RND_HugeInfinity
  `undef RND_TinyMinNorm
  `undef log2_isize
  `undef log2_isize_1
  `undef log2_lzdsize
  `undef lzd_size
  `undef shifter_bit
  `undef larger_f
  `undef lsb_bnorm
  `undef msb_bnorm
  `undef msb_corr
  `undef exp_constant
  `undef concat_size
  `undef exp_inf_case
  `undef exp_size
  `undef msb_corr2
  `undef guard_index1
  `undef guard_index2
  `undef round_index2
  `undef ovfl_index
  `undef b_norm_carry_index1
  `undef b_norm_carry_index2
  `undef final_mantissa_index1
  `undef final_mantissa_index2
    
endmodule
