
////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-point Base-2 Exponential
//           Computes the base-2 exponential of a Floating-point number
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 60 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance 0 or 1
//              arch            implementation select
//                              0 - area optimized
//                              1 - speed optimized
//                              2 - 2007.12 implementation (default)
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
//          05/2008 - AFT - Fixed the inexact status bit.
//                    Fixed the tiny bit when ieee_compliance = 1. This bit
//                    must be set to 1 whenever the output is a denormal.
//          08/2008 - AFT - Included new parameter (arch) and fixed some issues
//                    with accuracy and status information.
//
//-------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////

module DW_fp_exp2 (

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
parameter arch            =  2;

//------------------------------------------------------
//          declaration of inputs and outputs
input  [sig_width + exp_width:0] a;
output [sig_width + exp_width:0] z;
output [7:0] status;

// definitions used in the code
 
// declaration of signals
  wire [(exp_width + sig_width + 1)-1:0] z_temp1, z_temp2;
  wire [8    -1:0] status1, status2;
  wire [sig_width+1:0] dw_exp2_input;
  wire [sig_width+1:0] dw_exp2_output;
  wire signed [exp_width:0] a_exponent;
  wire signed [exp_width+1:0] initial_result_exponent;
  wire a_sign;
  
  wire signed [exp_width:0] Ea;
  wire signed [exp_width:0] Ea_actual;
  wire [sig_width:0] Ma;
  wire [sig_width-1:0] Fa;
  wire [sig_width-1:0] zero_f;
  wire [exp_width:0] zero_e;
  wire zer_a, denormal_a, inf_a, nan_a;
  wire [exp_width-1:0] InfExp_vec;
  wire [(exp_width + sig_width + 1)-1:0] NANfp;    // Not-a-number   
  wire [(exp_width + sig_width + 1)-1:0] MinusInf; // minus infinity 
  wire [(exp_width + sig_width + 1)-1:0] PlusInf;  // plus infinity  
  wire [(exp_width + sig_width + 1)-1:0] FPOne;    // plus infinity  
  wire [exp_width-2:0] bias_vector;  
  wire signed [exp_width+1:0] I;
  wire [sig_width+1:0] frac;
  wire zer_frac;
  wire [sig_width+exp_width+3:0] alignment_input, alignment_output;
  wire alignment_overflow;

  wire signed [exp_width+1:0] shifting_distance;
  wire signed [exp_width+1:0] biased_result_exponent;
  wire [sig_width+1:0] denormalized_out_mant;
  wire overflow;
  wire underflow;
  wire denormal_output;
  wire [sig_width:0] final_significand;
  wire RND_bit;
  wire sticky_bit;

  // Start Preprocessing information 
    assign InfExp_vec = $unsigned(((((1 << (exp_width-1)) - 1) * 2) + 1));
    assign zero_f = 0;
    assign zero_e = 0;
    assign bias_vector = $unsigned(((1 << (exp_width-1)) - 1));
    assign Ea = $signed({1'b0,a[((exp_width + sig_width) - 1):sig_width]});
    assign Fa = a[(sig_width - 1):0];
  // mantissa of NaN value is 1 when ieee_complaince = 1
    assign NANfp = (ieee_compliance == 0)?{1'b0, InfExp_vec, zero_f}:
                                          {1'b0, InfExp_vec, {sig_width-1{1'b0}},1'b1};
    assign MinusInf = {1'b1,  InfExp_vec, zero_f};
    assign PlusInf = {1'b0,  InfExp_vec, zero_f};
    assign FPOne = {2'b0, bias_vector, zero_f};
      
  // set the bit that indicates the zero input condition
    assign zer_a = ((ieee_compliance == 1) & (Ea == 0) & (Fa == 0)) | 
                   ((ieee_compliance == 0) & (Ea == 0));
  // set the bit that indicates the denormal input condition and adjust the exponent 
  // to be used for the main input
    assign denormal_a = (ieee_compliance == 1) & (Ea == 0) & (Fa != 0);
    assign Ea_actual = (denormal_a)?1:Ea;
    assign Ma = (denormal_a)?{1'b0, Fa}:
                (zer_a)?0:{1'b1, Fa};
    assign inf_a = (Ea[exp_width-1:0] == $unsigned(((((1 << (exp_width-1)) - 1) * 2) + 1))) & 
                   ((ieee_compliance == 0) | (Fa == 0)); 
    assign nan_a = (Ea[exp_width-1:0] == $unsigned(((((1 << (exp_width-1)) - 1) * 2) + 1))) & (ieee_compliance == 1) & (Fa != 0); 
  
    assign a_sign = a[(exp_width + sig_width)];         
      

  // Set the output values (including status) based on the input conditions, whenever
  // possible
    assign z_temp1 = (nan_a)?NANfp:               // NaN input
                     (inf_a & ~a_sign)?PlusInf:   // Positive infinity
                     (inf_a & a_sign)?0:          // Negative infinity
                     (zer_a)?FPOne:               // Zero input
                     0;
    assign status1[0] = inf_a & a_sign;
    assign status1[1] = inf_a & ~a_sign;
    assign status1[2] = nan_a;
    assign status1[3] = 1'b0;
    assign status1[4] = 1'b0;
    assign status1[5] = 1'b0;
    assign status1[6] = 1'b0;
    assign status1[7] = 1'b0;

  // Prepare the input to be applied to fixed-point
    assign a_exponent = $signed({1'b0,Ea_actual}) - $signed({1'b0,((1 << (exp_width-1)) - 1)});

  
    assign alignment_input = {{exp_width+2{1'b0}}, Ma, 2'b0};

  // using a shifter... when a_exponent is positive, the significand is shifted
  // to the left by a_exponent positions. When a_exponent is negative, the
  // significand is shifted to the right, making the value smaller 
    DW01_ash #(sig_width+exp_width+4,exp_width+1) U1 (.A(alignment_input), 
                               .DATA_TC(1'b0), 
                               .SH(a_exponent),
                               .SH_TC(1'b1),
                               .B(alignment_output) );
  
  // The result will be inexact when the significand is shifted to the right
  // (exponent is negative), the input is a non-zero value, and the shifted
  // fractional value is a zero.
  assign sticky_bit = zer_frac & a_exponent[exp_width] & ~zer_a;

  // Detect the overflow condition
  // When a_exponent is larger than exp_width and positive, an overflow occurred
  // Since a_exponent is already signed, it will be always less than exp_width when
  // negative, and performing the alignment shifting to the right. 
    assign alignment_overflow = (a_exponent >= $signed({1'b0,exp_width}));

    assign I = $signed({1'b0,alignment_output[sig_width+exp_width+2:sig_width+2]});
    assign frac = alignment_output[sig_width+1:0]; // sig_width+2 bits are fractional bits
    assign zer_frac = (frac == 0);
    assign initial_result_exponent = (a_sign)?-(I+$signed({{exp_width+1{1'b0}},~zer_frac})):
                                               I;
    assign dw_exp2_input = (a_sign & ~zer_frac)?$unsigned(~frac) + 1:
                                                frac;

  // END OF ALIGNMENT PHASE

  // instantiate the DW_exp2 component - fixed-point exponential    
    DW_exp2 #(sig_width+2,arch,1) U2 (.a(dw_exp2_input), .z(dw_exp2_output));
  wire inexact_exponent_cal;
  assign inexact_exponent_cal = |dw_exp2_input | sticky_bit;
  wire all_one_exp2_output;
  assign all_one_exp2_output = &dw_exp2_output;

  // Once the fixed-point exp2 is computed (the output is always normalized)
  // complete the computation of the FP value.                                 
  // obtain the biased exponent value for the result 
  // When the output of DW_exp2 is all ones, rounding is going to make the
  // significand be all zeros, and the exponent is incremented by 1.
    assign biased_result_exponent = initial_result_exponent + $signed({2'b0,((1 << (exp_width-1)) - 1)}) + all_one_exp2_output;
    wire [sig_width:0] mantissa;
    assign mantissa = (all_one_exp2_output)?{1'b1,{sig_width{1'b0}}}:
                                    dw_exp2_output[sig_width+1:1] + dw_exp2_output[0];

  // Denormalize the result when biased_result_exponent is still less
  // than 1
    assign shifting_distance = ((ieee_compliance == 1) & ~alignment_overflow)?
                               1 - biased_result_exponent:0;
    assign denormalized_out_mant = {mantissa,1'b0} >> ($unsigned(shifting_distance) & ~{exp_width+2{shifting_distance[exp_width+1]}});
    assign denormal_output = (shifting_distance > 0) & (ieee_compliance == 1);
    assign RND_bit = denormalized_out_mant[0];
    assign final_significand = denormalized_out_mant[sig_width+1:1] + RND_bit;
         
  // Determine overflow condition:
  //   1. alignment overflow
  //   2. biased exponent of the result exceeds maximum norm exponent and the input
  //      is positive
    assign overflow = (alignment_overflow |  (~biased_result_exponent[exp_width+1] & 
                      (|biased_result_exponent[exp_width:exp_width] |
                       &biased_result_exponent[exp_width-1:0]))) & ~a_sign;

  // detect underflow condition when the biased result exponent is zero or a negative
  // value. Underflow only happens when ieee_compliance = 0.
    assign underflow = (alignment_overflow | (biased_result_exponent[exp_width+1] |
                        ~(|biased_result_exponent[exp_width-1:0]))) & 
                        a_sign & ~denormal_output;

  // Define the output after processing the exp2 function
    assign z_temp2 = (overflow)? PlusInf:
                     (underflow)?0:     
                     (denormal_output)?{1'b0, {exp_width{1'b0}}, final_significand[sig_width-1:0]}:
                     {1'b0, biased_result_exponent[exp_width-1:0], final_significand[sig_width-1:0]};
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
                                      (status2[0] & ~zer_a);
    assign status2[6] = 1'b0;
    assign status2[7] = 1'b0;
    
  // assign the final outputs
  assign z = (status1 != 0 || z_temp1 != 0) ? z_temp1:z_temp2;
  assign status = (status1 != 0 || z_temp1 != 0) ? status1:status2;


endmodule
