
////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-point Exponential
//           Computes the exponential of a Floating-point number
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 60 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance 0 or 1
//              arch            implementation select
//                              0 - area optimized
//                              1 - speed optimized
//                              2 - uses 2007.12 sub-components (default)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_width + exp_width + 1) bits
//                              Floating-point Number that represents exp2(a)
//              status          byte
//                              Status information about FP operation
//
// MODIFIED:
//          August 2008 - AFT - included new parameter (arch) and fixed other
//                issues related to accuracy.
//
//-------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////

module DW_fp_exp (

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
parameter sig_width       = 10;
parameter exp_width	  =  5; 
parameter ieee_compliance =  0;
parameter arch = 2;

//------------------------------------------------------
//          declaration of inputs and outputs
input  [sig_width + exp_width:0] a;
output [sig_width + exp_width:0] z;
output [7:0] status;

// definitions used in the code
 
// declaration of signals
  wire [(exp_width + sig_width + 1)-1:0] z_temp1, z_temp2;
  wire [8    -1:0] status1, status2;
  wire [62:0] log2_e_val;
  assign log2_e_val = 63'b101110001010101000111011001010010101110000010111111100001011101;
  wire [sig_width+exp_width:0] log2_e_trunc;
  wire a_sign;
  wire [sig_width+exp_width:0] M1;
  wire [(2*(sig_width+exp_width+1)-1):0] M2_long;
  wire [exp_width-1:0] a_exp;
  wire [exp_width-1:0] a_exp_actual;
  wire [sig_width-1:0] a_frac;
  wire signed [exp_width:0] a_exp_unbiased;
  wire zero_exp;
  wire zero_a, inf_a, nan_a, denormal_a;
// the alignment unit receives e+1 integer bit positions and f+1 fractional
// bit positions.
  wire [(sig_width+2*exp_width) :0] alignment_input, alignment_output;
  wire alignment_overflow;
  wire [exp_width-1:0] InfExp_vec;
  wire [(exp_width + sig_width + 1)-1:0] NANfp;    // Not-a-number   
  wire [(exp_width + sig_width + 1)-1:0] MinusInf; // minus infinity 
  wire [(exp_width + sig_width + 1)-1:0] PlusInf;  // plus infinity  
  wire [(exp_width + sig_width + 1)-1:0] FPOne;    // plus infinity  
  wire [sig_width-1:0] zero_f;
  wire [exp_width:0] zero_e;
  wire [exp_width-2:0] bias_vector;  
  wire sticky_bit;
  wire signed [exp_width:0] I;
  wire [sig_width+1:0] frac;
  wire [sig_width+2:0] frac_ext;
  wire zer_frac;
  wire signed [exp_width+1:0] initial_result_exponent;
  wire signed [exp_width+1:0] biased_result_exponent;
  wire signed [exp_width+1:0] biased_result_exponent_corr;
  wire signed [exp_width+1:0] shifting_distance;
  wire [sig_width+2:0] dw_exp2_input;
  wire [sig_width+2:0] dw_exp2_output;
  wire [sig_width+2:0] dw_exp2_output2;
  wire [sig_width+2:0] denormalized_out_mant;
  wire overflow;
  wire underflow;
  wire denormal_output;
  wire [sig_width:0] final_significand;
  wire RND_bit;
  wire all_ones;
  wire [sig_width+2:0] mask;

    assign InfExp_vec = $unsigned(((((1 << (exp_width-1)) - 1) * 2) + 1));
    assign zero_f = 0;
    assign zero_e = 0;
    assign bias_vector = $unsigned(((1 << (exp_width-1)) - 1));
    assign a_sign = a[(exp_width + sig_width)];
    assign a_exp = a[((exp_width + sig_width) - 1):sig_width];
    assign a_frac = a[(sig_width - 1):0];
    assign a_exp_actual = (denormal_a)?1:a_exp;
    assign zero_exp = ~|a_exp;
    assign zero_a = (ieee_compliance)?zero_exp & ~|a_frac:zero_exp;
    assign inf_a = (ieee_compliance)? &a_exp & ~|a_frac:&a_exp;
    assign nan_a = (ieee_compliance)? &a_exp & |a_frac: 1'b0;
    assign denormal_a = (ieee_compliance)?zero_exp & |a_frac:1'b0;

    assign NANfp = (ieee_compliance == 0)?{1'b0, InfExp_vec, zero_f}:
                                          {1'b0, InfExp_vec, {sig_width-1{1'b0}},1'b1};
    assign MinusInf = {1'b1,  InfExp_vec, zero_f};
    assign PlusInf = {1'b0,  InfExp_vec, zero_f};
    assign FPOne = {2'b0, bias_vector, zero_f};

    assign z_temp1 = (nan_a)?NANfp:               // NaN input
                     (inf_a & ~a_sign)?PlusInf:   // Positive infinity
                     (inf_a & a_sign)?0:          // Negative infinity
                     (zero_a)?FPOne:               // Zero input
                     0;
    assign status1[0] = inf_a & a_sign;
    assign status1[1] = inf_a & ~a_sign;
    assign status1[2] = nan_a;
    assign status1[3] = 1'b0;
    assign status1[4] = 1'b0;
    assign status1[5] = 1'b0;
    assign status1[6] = 1'b0;
    assign status1[7] = 1'b0;


    assign M1 = (zero_exp)?(ieee_compliance?{1'b0,a_frac,{exp_width{1'b0}}}:0):
                                            {1'b1,a_frac,{exp_width{1'b0}}};

    assign log2_e_trunc = log2_e_val[62:62-sig_width-exp_width];

    assign M2_long = M1 * log2_e_trunc;

    assign a_exp_unbiased = $signed({1'b0,a_exp_actual}) - 
                            $signed({1'b0,bias_vector});

    assign alignment_input={{exp_width-1{1'b0}}, M2_long[(2*(sig_width+exp_width+1)-1):(2*(sig_width+exp_width+1)-1)-sig_width-exp_width-1]};
    DW01_ash #((sig_width+2*exp_width) +1,exp_width+1) U1 (.A(alignment_input), 
                               .DATA_TC(1'b0), 
                               .SH(a_exp_unbiased),
                               .SH_TC(1'b1),
                               .B(alignment_output) );

  // Detect the overflow condition
    assign alignment_overflow = (a_exp_unbiased >= $signed({1'b0,exp_width})) |
                                alignment_output[(sig_width+2*exp_width) ];

    assign sticky_bit = ~(zero_a | inf_a | nan_a);


    assign I = $signed({1'b0,alignment_output[(sig_width+2*exp_width) -1:(sig_width+2*exp_width) -exp_width]});
    assign frac = alignment_output[(sig_width+2*exp_width) -exp_width-1:(sig_width+2*exp_width) -exp_width-sig_width-2]; 
    assign frac_ext = {frac,1'b0};
    assign zer_frac = (frac_ext == 0);

    assign initial_result_exponent = (a_sign)?
                                     -(I+$signed({{exp_width+1{1'b0}},~zer_frac})):
                                     I;
  // END OF ALIGNMENT PHASE

    assign dw_exp2_input = (a_sign & ~zer_frac)?$unsigned(~frac_ext) + 1:
                                                frac_ext;


  // instantiate the DW_exp2 component - fixed-point exponential    
    DW_exp2 #(sig_width+3,arch,1) U2 (.a(dw_exp2_input), .z(dw_exp2_output));
  wire inexact_exponent_cal;
  assign inexact_exponent_cal = |dw_exp2_input | sticky_bit;

  // Once the fixed-point exp2 is computed (the output is always normalized)
  // complete the computation of the FP value.                                 
  // obtain the biased exponent value for the result 
    assign biased_result_exponent = initial_result_exponent + $signed({2'b0,((1 << (exp_width-1)) - 1)});
    assign biased_result_exponent_corr = biased_result_exponent + all_ones;

  // Denormalize the result when biased_result_exponent is still less
  // than 1 (negative or zero) and ieee_compliance is 1
    assign shifting_distance = ((ieee_compliance == 1) & 
                                (biased_result_exponent[exp_width+1] |
                                 ~|biased_result_exponent[exp_width:0]))?
                               1 - biased_result_exponent:0;
  // First, round the result from the fixed-point operation
    assign dw_exp2_output2 = dw_exp2_output + dw_exp2_output[0];
    assign denormalized_out_mant = dw_exp2_output2 >> ($unsigned(shifting_distance) & ~{exp_width+2{shifting_distance[exp_width+1]}});
    assign denormal_output = (shifting_distance > 0) & (ieee_compliance == 1) &
                             ~all_ones;
    assign RND_bit = denormalized_out_mant[1];

    assign final_significand = denormalized_out_mant[sig_width+1:2] + RND_bit;
    assign all_ones = &denormalized_out_mant[sig_width+1:2] & RND_bit;

  // Determine overflow condition:
  //   1. alignment overflow
  //   2. biased exponent of the result exceeds maximum norm exponent and the input
  //      is positive
    assign overflow = (alignment_overflow |  
                       (~biased_result_exponent_corr[exp_width+1] & 
                        (|biased_result_exponent_corr[exp_width:exp_width] |
                         &biased_result_exponent_corr[exp_width-1:0]))) & ~a_sign;

  // detect underflow condition when the biased result exponent is zero or a negative
  // value. Underflow only happens when ieee_compliance = 0.
    assign underflow = (alignment_overflow | 
                        (biased_result_exponent_corr[exp_width+1] |
                         ~(|biased_result_exponent_corr[exp_width-1:0]))) & 
                         a_sign & ~denormal_output;

  // Define the output after processing the exp2 function
    assign z_temp2 = (overflow)? PlusInf:
                     (underflow | (denormal_output & alignment_overflow) )?0:     
                     (denormal_output)?{1'b0, {exp_width{1'b0}}, final_significand[sig_width-1:0]}:
                     {1'b0, biased_result_exponent_corr[exp_width-1:0], final_significand[sig_width-1:0]};
    assign status2[0] = underflow | 
                                  ((ieee_compliance == 1) & denormal_output & 
                                   ~(|z_temp2[sig_width-1:0]));
    assign status2[1] = overflow;
    assign status2[2] = 1'b0;
    assign status2[3] = underflow & (ieee_compliance == 0) |
                                   (denormal_output & ~status2[0]);
    assign status2[4] = overflow;
    assign status2[5] = inexact_exponent_cal | 
                                      underflow |
                                      status2[4] |  
                                      (status2[0] & ~zero_a);
    assign status2[6] = 1'b0;
    assign status2[7] = 1'b0;
    
  // assign the final outputs
  assign z = (status1 != 0 || z_temp1 != 0) ? z_temp1:z_temp2;
  assign status = (status1 != 0 || z_temp1 != 0) ? status1:status2;





endmodule
