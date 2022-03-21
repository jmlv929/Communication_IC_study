


////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT:  Floating-point Number Format to Integer Number Format
//            Converter
//
//              This converts a floating-point number to a signed
//              integer number.
//              Conversion to an unsigned integer number is not supported.
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              isize           integer size,      3 to 512 bits
//              ieee_compliance support the IEEE Compliance 
//                              including NaN and denormal expressions.
//                              0 - IEEE 754 compatible without denormal support
//                                  (NaN becomes Infinity, Denormal becomes Zero)
//                              1 - IEEE 754 standard compatible
//                                  (NaN and denormal numbers are supported)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              Rounding Mode Input
//              z               (isize)-bits
//                              Converted Integer Output
//              status          8 bits
//                              Status Flags Output
//
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_fp_flt2i (
  a,
  rnd,
  z,
  status
    // Embedded dc_shell script
    // _model_constraint_2
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

  
  //--------------------------------------------------------------
  parameter sig_width = 23;      // RANGE 2 TO 253
  parameter exp_width = 8;       // RANGE 3 TO 31
  parameter isize = 32;          // RANGE 3 TO 512
  parameter ieee_compliance = 0; // RANGE 0 TO 1


  `define   RND_Width    4
  `define   RND_Inc    0
  `define   RND_Inexact    1
  `define   RND_HugeInfinity    2
  `define   RND_TinyMinNorm    3
  `define   log2 ((isize>256)?((isize>4096)?((isize>16384)?((isize>32768)?16:15):((isize>8192)?14:13)):((isize>1024)?((isize>2048)?12:11):((isize>512)?10:9))):((isize>16)?((isize>64)?((isize>128)?8:7):((isize>32)?6:5)):((isize>4)?((isize>8)?4:3):((isize>2)?2:1))))
  `define   shift_width ((`log2 < (exp_width - 1)) ? `log2 : exp_width - 1)
  `define   adder_size ((`log2 > exp_width - 1) ? 1<<(exp_width - 1) : isize - 1)
  `define   hd_condition (`adder_size < isize - 1)
  `define   cor_width ((`hd_condition) ? isize - `adder_size : 1)

  //--------------------------------------------------------------
  
  input [(exp_width + sig_width):0]        a;
  input [2:0]                 rnd;
  
  output [isize - 1:0] z;
  output [8     - 1:0]     status;

  wire [exp_width - 1:0]              unpack_exp;
  wire [(sig_width - 1) + 1:0]        unpack_significand;
  wire  unpack_sign;
  
  wire [isize + sig_width - 1:0]  shifter_out;
  wire [isize + sig_width - 1:0]  shifter_mux_out;
  wire [isize - 1:0]  shifter_out_isize;
  wire [2:0]  shifter_out_grs;
  wire   sticky;
  wire  guard_bit;
  wire  round_bit;
  wire  sticky_bit;
  wire [isize - 1:0]  mux_posneg;

  wire [`adder_size:0]  rounder_inc;
  wire [`adder_size - 1:0]  rounder_noinc;
  wire [`adder_size - 1:0]  rounder_output;
  wire  rounder_ovf;
  wire  rounder_select;
  wire [isize - 1:0]  rounder_correction;
  
  wire  huge_flag_after_rounding;
  wire  huge_flag_after_conversion;
  wire  huge_flag_over_intsize;
  wire  huge_flag_at_intsize;
  
  wire  huge_flag_from_exp;
  wire  zero_flag_from_exp;
  wire  zero_flag_after_rounding;
  
  wire  huge_flag_final;
  wire  zero_flag_final;

  wire huge_flag_correct;
  wire inexact_flag_correct;
  
  wire  exp_Zero;
  wire  exp_Neg_One;
  wire  exp_Neg_Two;
  wire  sig_zero2;
  wire  all_zero_shift_mux_out;
  wire  all_one_shift_mux_out;
  wire  all_zero_after_sign;
  wire  all_one_after_sign;
  wire  all_one_after_sign_pre;
  wire  max_input;
  
  wire [isize - 1:0]  maxnumber;
  wire [isize - 1:0]  posmax;

  wire [isize - 1:`adder_size] rounder_beforemux;	// debugging

  // for ieee_compliance = 1
  wire detect_denormal;
  wire detect_nan;
  wire detect_inf;
  wire huge_flag_correct2;
  wire inexact_flag_correct2;
  wire tiny_flag;
  wire invalid_flag;
  
  reg [`RND_Width - 1:0]  RND_eval;
  
  //--------------------------------------------------------------
  
  //--------------------------------------------------
  // Unpack Implementation
  //--------------------------------------------------
  assign unpack_sign = a[(exp_width + sig_width)];
  assign unpack_exp = a[((exp_width + sig_width) - 1):sig_width];
  assign unpack_significand = {1'b1, a[(sig_width - 1):0]};
  
  //--------------------------------------------------
  // Flag Generation I
  //--------------------------------------------------
  
  assign huge_flag_from_exp = (unpack_exp == {(exp_width){1'b1}});
  
  assign exp_Zero = (unpack_exp == ((1 << (exp_width-1)) - 1));
  
  assign exp_Neg_One = (unpack_exp == (((1 << (exp_width-1)) - 1) - 1));
  
  assign exp_Neg_Two = (unpack_exp < (((1 << (exp_width-1)) - 1) - 1));
  
  assign sig_zero2 = (unpack_significand[(sig_width - 1):0] == 0) ? 1'b0 : 1'b1;
  
  assign huge_flag_over_intsize = (unpack_exp >= (((1 << (exp_width-1)) - 1) + isize - 1));
  assign huge_flag_at_intsize = (unpack_exp == (((1 << (exp_width-1)) - 1) + isize - 1));
  
  assign posmax = {1'b0, {(isize - 1){1'b1}}};
  
  assign maxnumber = (unpack_sign) ? ~posmax : posmax;

  generate
    if (ieee_compliance) begin : GEN_ic_ne_0
      assign zero_flag_from_exp = (unpack_exp == 0) & ~sig_zero2;
      assign detect_denormal = (unpack_exp == 0) & sig_zero2;
      assign detect_nan = (huge_flag_from_exp & sig_zero2);
      assign detect_inf = (huge_flag_from_exp & ~sig_zero2);
    end
    else begin : GEN_ic_eq_0
      assign zero_flag_from_exp = (unpack_exp == 0);
      assign detect_denormal = 1'b0;
      assign detect_nan = 1'b0;
      assign detect_inf = 1'b0;
    end
  endgenerate
  
  // -------------------------------------------------
  // Shifter Implementation (EXP - 2^(n+1) + 1)
  //--------------------------------------------------
  assign shifter_out = {{(isize - 1){1'b0}}, unpack_significand}
    << unpack_exp[`shift_width - 1:0];
  
  assign shifter_mux_out = {shifter_out[isize + sig_width - 2:0], 1'b0};
  
  assign shifter_out_isize = 
           (exp_Neg_One | exp_Neg_Two) ? {(isize){1'b0}} :
           (exp_Zero) ? {{(isize - 1){1'b0}}, 1'b1} :
           shifter_mux_out[isize + sig_width - 1:sig_width];
  
  assign sticky = ~(shifter_mux_out[sig_width - 2:0] == 0);
  
  assign guard_bit =   shifter_out_isize[0];
  
  assign round_bit =   (exp_Neg_One) ? 1'b1 :
    (exp_Neg_Two) ? 1'b0 :
    (exp_Zero) ? unpack_significand[(sig_width - 1)] :
    shifter_mux_out[sig_width - 1];
  
  assign sticky_bit = (zero_flag_from_exp) ? 1'b0 :
    (exp_Neg_Two) ? 1'b1 :
    (exp_Zero | exp_Neg_One) ? sig_zero2 : sticky;
  
  
  // -------------------------------------------------
  // Rounding Adder Implementation
  //--------------------------------------------------
  assign mux_posneg = (unpack_sign) ? ~shifter_out_isize :
    shifter_out_isize;
  
  assign rounder_inc[`adder_size:0] = 
           mux_posneg[`adder_size - 1:0] + {{(`adder_size - 1){1'b0}}, 1'b1};
  
  assign rounder_noinc = mux_posneg[`adder_size - 1:0];
  
  
  //--------------------------------------------------
  // Flag Generation II
  //--------------------------------------------------
  
  assign all_zero_after_sign = (mux_posneg == 0);
  
  assign all_one_after_sign_pre =
    (mux_posneg[isize - 2:0]  == {(isize - 1){1'b1}});
  
  assign all_one_after_sign = all_one_after_sign_pre & mux_posneg[isize - 1];
  
  assign max_input = all_one_after_sign_pre & ~mux_posneg[isize - 1];
  
  
  // -------------------------------------------------
  // Rounding Control Unit
  //--------------------------------------------------
  
  assign rounder_select = (unpack_sign & RND_eval[`RND_Inc]) |
    (~unpack_sign & ~RND_eval[`RND_Inc]);
  
  assign rounder_output = (rounder_select) ? rounder_noinc :
    rounder_inc[`adder_size - 1:0];
  
  assign rounder_ovf = rounder_inc[`adder_size] & ~rounder_select &
    (exp_Neg_One | exp_Neg_Two);
  
  assign rounder_beforemux[isize - 1:`adder_size] = 
    (rounder_ovf) ? {(isize - `adder_size){1'b0}} :
                    mux_posneg[isize - 1:`adder_size];

  assign rounder_correction[isize - 1 : `adder_size] = 
    (`hd_condition) ?
      ((~(rounder_inc[`adder_size] & ~unpack_sign & RND_eval[0])) ?
        rounder_beforemux[isize - 1:`adder_size] :
        {{(`cor_width){1'b0}}, rounder_inc[`adder_size]}) :
      rounder_beforemux[isize - 1:`adder_size];


  assign rounder_correction[`adder_size - 1:0] =
    rounder_output[`adder_size - 1:0];
  
  //--------------------------------------------------
  // Flag Generation III
  //--------------------------------------------------
  assign zero_flag_after_rounding = (~rounder_select) ?
    all_one_after_sign : all_zero_after_sign;

  assign zero_flag_final = (zero_flag_from_exp | zero_flag_after_rounding) &
    ~huge_flag_over_intsize;
  
  assign huge_flag_final = huge_flag_over_intsize | huge_flag_from_exp |
    (max_input & ~rounder_select);
  
  assign huge_flag_correct = (max_input & huge_flag_at_intsize & ~RND_eval[0]) ? 1'b0 : huge_flag_final;

  assign inexact_flag_correct = (zero_flag_from_exp) ? 1'b0 : (huge_flag_correct | RND_eval[1]);


  generate
    if (ieee_compliance) begin : GEN_ic_ne_0_a
      assign huge_flag_correct2 = huge_flag_correct & ~detect_inf & ~detect_nan;
      assign inexact_flag_correct2 = inexact_flag_correct & ~detect_inf & ~detect_nan;
      assign tiny_flag = detect_denormal & zero_flag_final;
      assign invalid_flag = detect_inf | detect_nan;

    end
    else begin : GEN_ic_eq_0_a
      assign huge_flag_correct2 = huge_flag_correct;
      assign inexact_flag_correct2 = inexact_flag_correct;
      assign tiny_flag = 1'b0;
      assign invalid_flag = 1'b0;
    end
  endgenerate
  
  
  //--------------------------------------------------
  // Output Generation
  //--------------------------------------------------
  
  assign z = (huge_flag_final) ? maxnumber : rounder_correction;
  
  assign status = {1'b0, huge_flag_correct2, inexact_flag_correct2, 1'b0, 
                   tiny_flag, invalid_flag, 1'b0, zero_flag_final};

  //--------------------------------------------------
  // Rounding Block Description
  //--------------------------------------------------
  
  //----------------------------------------
  // RND_eval[3] : `RND_TinyMinNorm
  // RND_eval[2] : `RND_HugeInfinity
  // RND_eval[1] : `RND_Inexact
  // RND_eval[0] : `RND_Inc
  //----------------------------------------
  
  always @(guard_bit or round_bit or sticky_bit or unpack_sign or rnd) begin
  
    RND_eval[`RND_TinyMinNorm] = 1'b0;
    RND_eval[`RND_HugeInfinity] = 1'b0;
    RND_eval[`RND_Inexact] = round_bit | sticky_bit;
    
    case (rnd)

      // ----------------------------------------
      // Round Nearest Even (RNE) Mode
      // ----------------------------------------
      3'b000: begin
        RND_eval[`RND_Inc] = round_bit & (guard_bit | sticky_bit);
      end
      
      // ----------------------------------------
      // Round to Zero (RZ) Mode
      // ----------------------------------------
      3'b001: begin
        RND_eval[`RND_Inc] = 0;
      end
      
      // ----------------------------------------
      // Round to Positive Infinity Mode
      // ----------------------------------------
      3'b010: begin
        RND_eval[`RND_Inc] = ~unpack_sign & (round_bit | sticky_bit);
      end
      
      // ----------------------------------------
      // Round to Negative Infinity Mode
      // ----------------------------------------
      3'b011: begin
        RND_eval[`RND_Inc] = unpack_sign & (round_bit | sticky_bit);
      end
      
      // ----------------------------------------
      // Round to Nearest Up (RNU) Mode
      // ----------------------------------------
      3'b100: begin
        RND_eval[`RND_Inc] = round_bit;
      end
      
      // ----------------------------------------
      // Round to Infinity (RI) Mode
      // ----------------------------------------
      3'b101: begin
        RND_eval[`RND_Inc] = round_bit | sticky_bit;
      end
      
      default: begin
        RND_eval[`RND_Inc] = 1'bx;
      end
    endcase
  end
  
  `undef   RND_Width
  `undef   RND_Inc
  `undef   RND_Inexact
  `undef   RND_HugeInfinity
  `undef   RND_TinyMinNorm
  `undef   log2
  `undef   shift_width
  `undef   adder_size
  `undef   cor_width
  `undef   hd_condition
  
endmodule
