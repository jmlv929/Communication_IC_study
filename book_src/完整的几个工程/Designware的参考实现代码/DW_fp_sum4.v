////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------
//
// ABSTRACT: Four-operand Floating-point Adder (SUM4)
//           Computes the addition of four FP numbers. The format of the FP
//           numbers is defined by the number of bits in the significand 
//           (sig_width) and the number of bits in the exponent (exp_width).
//           The total number of bits in each FP number is sig_width+exp_width+1.
//           The sign bit takes the place of the MS bit in the significand,
//           which is always 1 (unless the number is a denormal; a condition 
//           that can be detected testing the exponent value).
//           The outputs are a FP number and status flags with information about
//           special number representations and exceptions. 
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand f,  2 to 253 bits
//              exp_width       exponent e,     3 to 31 bits
//              ieee_compliance 0 or 1 (default 0)
//              arch_type       0 or 1 (default 0)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              b               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              c               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              d               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              rounding mode
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_width + exp_width + 1) bits
//                              Floating-point Number -> a+b+c
//              status          byte
//                              info about FP result
//
// MODIFIED:
//        8/11/2006: 
//           - fixes case of normal numbers becomming denormal in ieee_compliance=0
//             The result should be zero.
//           - included correction for the inexact bit in the status flag
//        8/29/2006:
//           - calculations extended to full precision
//           - improves detection of largest exponent
//        9/01/06:
//           - fix manipulation of STK bit
//           - big change in the architecture: sort inputs before applying to adder,
//             has specialized STK bit determination, has smaller adder, one less
//             alignment unit.
//        5/15/2007:
//           - modified the manipulation of sign of zeros. When ieee_compliance=1
//             the sign of the zero output is manipulated as follows:
//                 a   b   c   d   rnd    z  rnd      z
//                +0  +0  +0  +0   -inf  +0  others  +0
//                +0  +0  +0  -0   -inf  -0  others  +0
//                +0  +0  -0  +0   -inf  -0  others  +0
//                +0  +0  -0  -0   -inf  -0  others  +0
//                +0  -0  +0  +0   -inf  -0  others  +0
//                +0  -0  +0  -0   -inf  -0  others  +0
//                +0  -0  -0  +0   -inf  -0  others  +0
//                +0  -0  -0  -0   -inf  -0  others  +0
//                -0  +0  +0  +0   -inf  -0  others  +0
//                -0  +0  +0  -0   -inf  -0  others  +0
//                -0  +0  -0  +0   -inf  -0  others  +0
//                -0  +0  -0  -0   -inf  -0  others  +0
//                -0  -0  +0  +0   -inf  -0  others  +0
//                -0  -0  +0  -0   -inf  -0  others  +0
//                -0  -0  -0  +0   -inf  -0  others  +0
//                -0  -0  -0  -0   -inf  -0  others  -0
//                +0  -3  +2  +1   -inf  -0  others  +0
//               Notice that the last row shows the case when the inputs are non-
//               zero values, forcing a exact zero output.
//       11/19/2007: fixed detection of denormals and NaN when ieee_compliance=0
//       01/04/2008: AFT 
//           - fixed the output value and status bits when output is NaN
//             and ieee_compliance = 0.
//           - fixed problem related to Star 9000188489 - underflow of 
//             internal variable used to compute exponent value
//
//       03/13/2008: AFT : included a new parameter (arch_type) to control
//                   the use of alternative architecture with IFP blocks
//       12/11/2008: expanded the use of IFP components to accept 
//                   ieee_compliance=1
//       02/18/2009: modified code to remove lint warning messages
//
//-------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_fp_sum4 (

                   a,
                   b,
                   c,
                   d,
                   rnd,
                   z,
                   status


    // Embedded dc_shell script
    // _model_constraint_2
);

parameter sig_width=23;             // RANGE 2 to 253 bits
parameter exp_width=8;              // RANGE 3 to 31 bits
parameter ieee_compliance=0;        // RANGE 0 or 1           
parameter arch_type=0;              // RANGE 0 or 1           


input  [(exp_width + sig_width):0] a,b,c,d;
input  [2:0] rnd;
output [8    -1:0] status;
output [(exp_width + sig_width):0] z;

`define extra_length (1)
`define  DW_shift_width  (((2*(sig_width+1)+3+2+`extra_length)-1>256)?(((2*(sig_width+1)+3+2+`extra_length)-1>4096)?(((2*(sig_width+1)+3+2+`extra_length)-1>16384)?(((2*(sig_width+1)+3+2+`extra_length)-1>32768)?16:15):(((2*(sig_width+1)+3+2+`extra_length)-1>8192)?14:13)):(((2*(sig_width+1)+3+2+`extra_length)-1>1024)?(((2*(sig_width+1)+3+2+`extra_length)-1>2048)?12:11):(((2*(sig_width+1)+3+2+`extra_length)-1>512)?10:9))):(((2*(sig_width+1)+3+2+`extra_length)-1>16)?(((2*(sig_width+1)+3+2+`extra_length)-1>64)?(((2*(sig_width+1)+3+2+`extra_length)-1>128)?8:7):(((2*(sig_width+1)+3+2+`extra_length)-1>32)?6:5)):(((2*(sig_width+1)+3+2+`extra_length)-1>4)?(((2*(sig_width+1)+3+2+`extra_length)-1>8)?4:3):(((2*(sig_width+1)+3+2+`extra_length)-1>2)?2:1))))
`define  large_norm_test_range ((((2*(sig_width+1)+3+2+`extra_length)-1)-1)  -(sig_width+2+`extra_length)+3)
`define  enc_output_size  (((`large_norm_test_range>256)?((`large_norm_test_range>4096)?((`large_norm_test_range>16384)?((`large_norm_test_range>32768)?16:15):((`large_norm_test_range>8192)?14:13)):((`large_norm_test_range>1024)?((`large_norm_test_range>2048)?12:11):((`large_norm_test_range>512)?10:9))):((`large_norm_test_range>16)?((`large_norm_test_range>64)?((`large_norm_test_range>128)?8:7):((`large_norm_test_range>32)?6:5)):((`large_norm_test_range>4)?((`large_norm_test_range>8)?4:3):((`large_norm_test_range>2)?2:1))))+1)
reg [8    -1:0] status_int;
reg [8    -1:0] status_int1;
reg [(exp_width + sig_width):0] z_temp;
reg [(exp_width + sig_width):0] z_temp1;
reg output_defined_from_inp;
reg [exp_width-1:0] E_a,E_b,E_c,E_d;
reg [sig_width-1:0] F_a,F_b,F_c,F_d;
reg [sig_width:0] M_a,M_b,M_c,M_d;
reg [(2*(sig_width+1)+3+2+`extra_length)-1-3:0] M_1_sh,M_2_sh,M_3_sh,M_4_sh; 
reg S_a,S_b,S_c,S_d;
reg [exp_width-1:0] max_exp;
reg [exp_width:0] max_exp_plus1;
reg [exp_width:0] max_exp_plus2;
reg [exp_width-1:0] ediff_12, ediff_13, ediff_14;
wire [sig_width+2+`extra_length:0] zero_vec;
reg completely_shifted_out_2, completely_shifted_out_3;
reg C0, C1, C2, C3, C4;
reg [exp_width+sig_width+1:0] Max1L1,Max2L1,MaxL2,Min1L1,Min2L1,MinL2; 
reg EQAB, EQCD, EQ12, EQ23, EQ34, EQX, EQY;
reg [sig_width:0] M_1,M_2,M_3,M_4;
reg S_1,S_2,S_3,S_4;
reg [exp_width-1:0] E_1,E_2,E_3,E_4;
wire [(exp_width + sig_width):0] NaNFp;
reg denormal_a, denormal_b, denormal_c, denormal_d;
reg inf_a, inf_b, inf_c, inf_d;
reg nan_a, nan_b, nan_c, nan_d;
reg zer_a, zer_b, zer_c, zer_d;
wire [(exp_width + sig_width + 1)-1:0] z_inf_plus;
wire [(exp_width + sig_width + 1)-1:0] z_inf_minus;
wire [(exp_width + sig_width + 1)-1:0] z_large_plus;
wire [(exp_width + sig_width + 1)-1:0] z_large_minus;
reg [((2*(sig_width+1)+3+2+`extra_length)-1):0] adder_input1, adder_input2, adder_input3, adder_input4; 
reg [((2*(sig_width+1)+3+2+`extra_length)-1):0] adder_output; 
reg adder_output_sign;
reg [((2*(sig_width+1)+3+2+`extra_length)-1)-1:0] adder_output_mag; 
reg [exp_width-1:0] int_exponent;
`define DW_Exp_MSB `DW_shift_width+exp_width-1 
reg [`DW_Exp_MSB:0] corrected_expo1;
reg [`DW_Exp_MSB:0] corrected_expo2;
reg [`DW_Exp_MSB:0] corrected_expo;
reg post_rounding_normalization;
reg [((2*(sig_width+1)+3+2+`extra_length)-1)-1:0] a_mag;
reg [exp_width:0] pos_offset;
reg sticky_bit, T, R_bit, L_bit;
reg inexact;
reg exp_ovf, exp_udf;
reg exp_nz_MSbits; 
wire [`DW_shift_width:0] num_of_zeros;
wire [`DW_shift_width:0] shifting_distance;
reg [((2*(sig_width+1)+3+2+`extra_length)-1)-1:0] a_norm;
reg a_sign;
reg rnd_incr;
reg [sig_width+1:0] a_rounded;
reg no_MS1_detection;
reg [sig_width:0] significand_z;
reg [exp_width-1:0] exponent_z;
reg large_input_exp;
wire [`enc_output_size-1:0] num_of_zeros2;
wire large_normalization;
reg [(2*(sig_width+1)+3+2+`extra_length)-1-2  -1:0] mask1,mask2,mask3,mask4;
reg [(2*(sig_width+1)+3+2+`extra_length)-1-2  -1:0] masked_op1,masked_op2,masked_op3,masked_op4;
reg [(2*(sig_width+1)+3+2+`extra_length)-1-2  -1:0] one_vector;
reg STK_1, STK_2, STK_3, STK_4;
reg cancel_STK_3,cancel_STK_4;
reg STK;
reg inv_2, inv_3, inv_4;
wire [sig_width+exp_width : 0] z_temp2;
wire [7 : 0] status_int2;
wire [sig_width+2+exp_width+6:0] ifpa;
wire [sig_width+2+exp_width+6:0] ifpb;
wire [sig_width+2+exp_width+6:0] ifpc; 
wire [sig_width+2+exp_width+6:0] ifpd;
wire [sig_width+2+3+exp_width+1+6:0] ifpe;
wire [sig_width+2+3+exp_width+1+6:0] ifpf;
wire [sig_width+2+3+sig_width+exp_width+1+1+6:0] ifpg;

    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U3 ( .a(a), .z(ifpa) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U4 ( .a(b), .z(ifpb) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U5 ( .a(c), .z(ifpc) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U6 ( .a(d), .z(ifpd) );
    DW_ifp_addsub #(sig_width+2, exp_width, sig_width+2+3, exp_width+1, ieee_compliance)
          U7 ( .a(ifpa), .b(ifpb), .op(1'b0), .rnd(rnd), 
               .z(ifpe) );
    DW_ifp_addsub #(sig_width+2, exp_width, sig_width+2+3, exp_width+1, ieee_compliance)
          U8 ( .a(ifpc), .b(ifpd), .op(1'b0), .rnd(rnd), 
               .z(ifpf) );
    DW_ifp_addsub #(sig_width+2+3, exp_width+1, sig_width+2+3+sig_width, exp_width+1+1, ieee_compliance)
          U9 ( .a(ifpe), .b(ifpf), .op(1'b0), .rnd(rnd), 
               .z(ifpg) );
    DW_ifp_fp_conv #(sig_width+2+3+sig_width, exp_width+1+1, sig_width, exp_width, ieee_compliance)
          U10 ( .a(ifpg), .rnd(rnd), .z(z_temp2), .status(status_int2) );

assign NaNFp = (ieee_compliance == 1)?{1'b0,{exp_width{1'b1}},{sig_width-1{1'b0}},1'b1}:
                                      {1'b0,{exp_width{1'b1}},{sig_width{1'b0}}};
assign zero_vec = {sig_width+2+`extra_length{1'b0}};
assign z_inf_plus[(exp_width + sig_width)] = 1'b0;
assign z_inf_plus[$unsigned((exp_width + sig_width) - 1):sig_width] = $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1});
assign z_inf_plus[$unsigned(sig_width - 1):0] = {sig_width{1'b0}};
assign z_inf_minus[(exp_width + sig_width)] = 1'b1;
assign z_inf_minus[$unsigned((exp_width + sig_width) - 1):sig_width] = $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1});
assign z_inf_minus[$unsigned(sig_width - 1):0] = {sig_width{1'b0}};
assign z_large_plus[(exp_width + sig_width)] = 1'b0;
assign z_large_plus[$unsigned((exp_width + sig_width) - 1):sig_width] = $unsigned($unsigned({exp_width{1'b1}}>>1) << 1);
assign z_large_plus[$unsigned(sig_width - 1):0] = $unsigned({sig_width{1'b1}});
assign z_large_minus[(exp_width + sig_width)] = 1'b1;
assign z_large_minus[$unsigned((exp_width + sig_width) - 1):sig_width] = $unsigned($unsigned({exp_width{1'b1}}>>1) << 1);
assign z_large_minus[$unsigned(sig_width - 1):0] = $unsigned({sig_width{1'b1}});


always @(a or b or c or d)
begin
  E_a = a[$unsigned((exp_width + sig_width) - 1):sig_width];
  E_b = b[$unsigned((exp_width + sig_width) - 1):sig_width];
  E_c = c[$unsigned((exp_width + sig_width) - 1):sig_width];
  E_d = d[$unsigned((exp_width + sig_width) - 1):sig_width];
  F_a = a[$unsigned(sig_width - 1):0];
  F_b = b[$unsigned(sig_width - 1):0];
  F_c = c[$unsigned(sig_width - 1):0];
  F_d = d[$unsigned(sig_width - 1):0];
  S_a = a[(exp_width + sig_width)];
  S_b = b[(exp_width + sig_width)];
  S_c = c[(exp_width + sig_width)]; 
  S_d = d[(exp_width + sig_width)]; 

  // infinities
  if ((E_a == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && ((F_a == 0) || (ieee_compliance == 0)))
     inf_a = 1;
  else
     inf_a = 0;
  if ((E_b == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && ((F_b == 0) || (ieee_compliance == 0)))
     inf_b = 1;
  else
     inf_b = 0;
  if ((E_c == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && ((F_c == 0) || (ieee_compliance == 0)))  
     inf_c = 1;
  else
     inf_c = 0;
  if ((E_d == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && ((F_d == 0) || (ieee_compliance == 0)))  
     inf_d = 1;
  else
     inf_d = 0;
  if ((E_a == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && (F_a != 0) && (ieee_compliance == 1))  
     nan_a = 1;
  else
     nan_a = 0;
  if ((E_b == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && (F_b != 0) && (ieee_compliance == 1))  
     nan_b = 1;
  else 
     nan_b = 0;
  if ((E_c == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && (F_c != 0) && (ieee_compliance == 1))  
     nan_c = 1;
  else
     nan_c = 0;
  if ((E_d == $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && (F_d != 0) && (ieee_compliance == 1))  
     nan_d = 1;
  else
     nan_d = 0;
  if ((E_a == {exp_width{1'b0}}) && ((F_a == 0) || (ieee_compliance == 0))) 
    begin
      zer_a = 1;
      F_a = 0;
    end
  else
     zer_a = 0;
  if ((E_b == {exp_width{1'b0}}) && ((F_b == 0) || (ieee_compliance == 0)))  
    begin
      zer_b = 1;
      F_b = 0;
    end
  else
     zer_b = 0;
  if ((E_c == {exp_width{1'b0}}) && ((F_c == 0) || (ieee_compliance == 0)))  
    begin
      zer_c = 1;
      F_c = 0;
    end
  else
     zer_c = 0;
  if ((E_d == {exp_width{1'b0}}) && ((F_d == 0) || (ieee_compliance == 0))) 
    begin
      zer_d = 1;
      F_d = 0;
    end
  else
     zer_d = 0;
   if ((E_a == {exp_width{1'b0}}) && (F_a != 0) && (ieee_compliance == 1)) 
    begin
      denormal_a = 1;
      E_a = {{exp_width-1{1'b0}},1'b1};
    end
  else
    denormal_a = 0;
  if ((E_b == {exp_width{1'b0}}) && (F_b != 0) && (ieee_compliance == 1)) 
    begin
      denormal_b = 1;
      E_b = {{exp_width-1{1'b0}},1'b1};
    end
  else
    denormal_b = 0;
  if ((E_c == {exp_width{1'b0}}) && (F_c != 0) && (ieee_compliance == 1)) 
    begin
      denormal_c = 1;
      E_c = {{exp_width-1{1'b0}},1'b1};
    end
  else
    denormal_c = 0;
  if ((E_d == {exp_width{1'b0}}) && (F_d != 0) && (ieee_compliance == 1)) 
    begin
      denormal_d = 1;
      E_d = {{exp_width-1{1'b0}},1'b1};
    end
  else
    denormal_d = 0;
end

always @ (nan_a or nan_b or nan_c or nan_d or inf_a or inf_b or inf_c or inf_d 
          or S_a or S_b or S_c or S_d or NaNFp or zer_a or zer_b or zer_c or 
          zer_d  or a or b or c or d or E_a or E_b or F_a or F_b or 
          denormal_c or rnd or z_inf_plus or z_inf_minus)
begin
  z_temp1 = 0;
  status_int1 = 0;
  output_defined_from_inp = 1;
  if ((nan_a == 1) || (nan_b == 1) || (nan_c == 1) || (nan_d == 1)) 
    begin
      z_temp1 = NaNFp;
      status_int1[2] = 1;
    end

  else if ((zer_a == 1) && (zer_b == 1) && (zer_c == 1) && (zer_d == 1)) 
    begin
      z_temp1 =  0;
      status_int1[0] = 1;
      if (ieee_compliance == 0)
        begin
          if (rnd == 3) 
            z_temp1[(exp_width + sig_width)] = 1'b1;
          else
            z_temp1[(exp_width + sig_width)] = 1'b0;
	end
      else
        if (S_a == S_b && S_b == S_c && S_c == S_d) 
          z_temp1[(exp_width + sig_width)] = S_a;
        else
          begin
            if (rnd == 3) 
              z_temp1[(exp_width + sig_width)] = 1'b1;
            else
              z_temp1[(exp_width + sig_width)] = 1'b0;
          end
    end

  else if (((inf_a == 1) && (inf_b == 1) && (S_a != S_b)) ||
           ((inf_a == 1) && (inf_c == 1) && (S_a != S_c)) ||
           ((inf_a == 1) && (inf_d == 1) && (S_a != S_d)) ||
           ((inf_b == 1) && (inf_c == 1) && (S_b != S_c)) ||
           ((inf_b == 1) && (inf_d == 1) && (S_b != S_d)) ||
           ((inf_c == 1) && (inf_d == 1) && (S_c != S_d)))
      begin
        z_temp1 =NaNFp;
        status_int1[2] = 1;
        status_int1[1] = (ieee_compliance == 1)?0:1;
      end
  else if (inf_a == 1 || inf_b == 1 || inf_c == 1 || inf_d == 1) 
      begin
        status_int1[1] = 1;
        z_temp1 = ((inf_a & S_a)||(inf_b & S_b)||(inf_c & S_c)||(inf_d & S_d))?z_inf_minus:z_inf_plus;
      end
  else output_defined_from_inp = 0;

end


always @ (S_a or E_a or F_a or S_b or E_b or F_b or F_c or F_d or 
          zer_a or zer_b or zer_c or zer_d or denormal_a or denormal_b or 
          denormal_c or denormal_d or a or b)
begin 
   if (denormal_a == 1 || zer_a == 1) 
    M_a = (ieee_compliance == 1)?{1'b0,F_a}:0;
   else
    M_a = {1'b1,F_a};
   if (denormal_b == 1 || zer_b == 1) 
    M_b = (ieee_compliance == 1)?{1'b0,F_b}:0;
   else
    M_b = {1'b1,F_b};
   if (denormal_c == 1 || zer_c == 1) 
    M_c = (ieee_compliance == 1)?{1'b0,F_c}:0;
   else
    M_c = {1'b1,F_c};
  if (denormal_d == 1 || zer_d == 1) 
    M_d = (ieee_compliance == 1)?{1'b0,F_d}:0;
  else
    M_d = {1'b1,F_d};
end   

always @ (S_a or E_a or M_a or S_b or E_b or M_b or 
          S_c or E_c or M_c or S_d or E_d or M_d)
begin
  {Max1L1,Min1L1,C0} = ({E_a,M_a} >= {E_b,M_b}) ? 
                    {{S_a,E_a,M_a},{S_b,E_b,M_b},1'b0}:
                    {{S_b,E_b,M_b},{S_a,E_a,M_a},1'b1};
  {Max2L1,Min2L1,C1} = ({E_c,M_c} >= {E_d,M_d}) ? 
                    {{S_c,E_c,M_c},{S_d,E_d,M_d},1'b0}:
                    {{S_d,E_d,M_d},{S_c,E_c,M_c},1'b1};
  {{S_1,E_1,M_1},MinL2,C2} = (Max1L1[exp_width+sig_width:0] >= Max2L1[exp_width+sig_width:0]) ?
                          {Max1L1,Max2L1,1'b0} : {Max2L1,Max1L1,1'b1};
  {MaxL2,{S_4,E_4,M_4},C3} = (Min1L1[exp_width+sig_width:0] >= Min2L1[exp_width+sig_width:0]) ?
                             {Min1L1,Min2L1,1'b0} : {Min2L1,Min1L1,1'b1};
  {{S_2,E_2,M_2},{S_3,E_3,M_3},C4} = (MinL2[exp_width+sig_width:0] >= MaxL2[exp_width+sig_width:0]) ? 
                                  {MinL2,MaxL2,1'b0}:{MaxL2,MinL2,1'b1};
  EQAB = ({E_a,M_a} == {E_b,M_b});
  EQCD = ({E_c,M_c} == {E_d,M_d});
  EQX = Max1L1[exp_width+sig_width:0] == Max2L1[exp_width+sig_width:0];
  EQY = Min1L1[exp_width+sig_width:0] == Min2L1[exp_width+sig_width:0];
  EQ23 = MaxL2[exp_width+sig_width:0] == MinL2[exp_width+sig_width:0];
  EQ34 = EQY | EQCD&~C3 | EQAB&C2&C3&C4;
  EQ12 = EQAB&~C2 | EQX | EQCD&C2&C3&C4; 
end

wire cancel12, cancel23, cancel34;
assign cancel12 = EQ12 & (S_1 != S_2);
assign cancel23 = EQ23 & (S_2 != S_3) & ~cancel12;
assign cancel34 = EQ34 & (S_3 != S_4) & ~(cancel12 | cancel23);
 
always @ (E_1 or E_2 or E_3 or E_4 or cancel12)
begin
    max_exp = cancel12?E_3:E_1;
    ediff_12 = cancel12?0:max_exp - E_2;
    ediff_13 = max_exp - E_3;
    ediff_14 = max_exp - E_4;
    max_exp_plus2 = max_exp + 2;
    max_exp_plus1 = max_exp + 1;
end

always @ (ediff_12 or ediff_13 or ediff_14 or zero_vec or M_1 or M_2 or M_3 or M_4 or
          S_2 or S_3 or S_4 or EQ23 or EQ34 or C1 or C2 or C3 or C4 or cancel12 or
          cancel23 or cancel34)
begin
  M_1_sh = cancel12?0:{M_1,zero_vec};
  STK_1 = 0;

  M_2_sh = (cancel12 | cancel23)?0:{M_2,zero_vec};
  M_2_sh = M_2_sh >> ediff_12;
  one_vector = ~$unsigned(0);
  mask2 = ~(one_vector << ediff_12);
  completely_shifted_out_2 = ~|M_2_sh[(2*(sig_width+1)+3+2+`extra_length)-1-3:1];
  masked_op2 = mask2 & {M_2,zero_vec};
  STK_2 = (|masked_op2) & ~(cancel12 | cancel23);
  M_2_sh[0] = M_2_sh[0] | STK_2;
  STK_2 = M_2_sh[0];

  M_3_sh = (cancel23 | cancel34)?0:{M_3,zero_vec};
  M_3_sh = M_3_sh >> ediff_13;
  mask3 = ~(one_vector << ediff_13);
  completely_shifted_out_3 =  ~|M_3_sh[(2*(sig_width+1)+3+2+`extra_length)-1-3:1];
  masked_op3 = mask3 & {M_3,zero_vec};
  STK_3 = (|masked_op3) & ~(cancel23 | cancel34);
  cancel_STK_3 = STK_2 & completely_shifted_out_2 & ~EQ23;
  M_3_sh[0] = (M_3_sh[0] | STK_3) & ~cancel_STK_3;
  STK_3 = M_3_sh[0];  

  M_4_sh = cancel34?0:{M_4,zero_vec};
  M_4_sh = M_4_sh >> ediff_14;
  mask4 = ~(one_vector << ediff_14);
  masked_op4 = mask4 & {M_4,zero_vec};
  STK_4 = (|masked_op4) & ~cancel34;
  cancel_STK_4 = cancel_STK_3 | (STK_3 & completely_shifted_out_3 & ~EQ34 & ~EQ23);
  M_4_sh[0] = (M_4_sh[0] | STK_4) & ~cancel_STK_4;
  STK_4 = M_4_sh[0];  

end

always @ (M_1_sh or M_2_sh or M_3_sh or M_4_sh or S_1 or S_2 or S_3 or S_4)
begin
    inv_2 = S_2 ^ S_1;
    inv_3 = S_3 ^ S_1;
    inv_4 = S_4 ^ S_1;
    adder_input1 = {3'b0, M_1_sh};
    if (inv_2 == 1'b1) 
      adder_input2 = ~{3'b0, M_2_sh};
    else
      adder_input2 = M_2_sh;
    if (inv_3 == 1'b1) 
      adder_input3 = ~{3'b0, M_3_sh};
    else
      adder_input3 = M_3_sh;
    if (inv_4 == 1'b1) 
      adder_input4 = ~{3'b0, M_4_sh};
    else
      adder_input4 = M_4_sh;

    adder_output = adder_input1 + adder_input2 + inv_2 + 
                   adder_input3 + inv_3 + adder_input4 + inv_4;

    
    adder_output_sign = adder_output[((2*(sig_width+1)+3+2+`extra_length)-1)] ^ S_1;
    if (adder_output[((2*(sig_width+1)+3+2+`extra_length)-1)] == 1) 
      adder_output_mag = ~adder_output[((2*(sig_width+1)+3+2+`extra_length)-1)-1:0]+1;
    else
      adder_output_mag = adder_output[((2*(sig_width+1)+3+2+`extra_length)-1)-1:0];
end

  wire [(2*(sig_width+1)+3+2+`extra_length)-2:0] decoded_exp_large;
  wire [(2*(sig_width+1)+3+2+`extra_length)-2:0] masked_adder_output;
  assign decoded_exp_large = ({1'b1,{(2*(sig_width+1)+3+2+`extra_length)-2{1'b0}}} >> (max_exp_plus1)) | 1'b1;
  assign masked_adder_output = (ieee_compliance)?adder_output_mag | decoded_exp_large:
                                                 adder_output_mag;
  DW_lzd #((2*(sig_width+1)+3+2+`extra_length)-1) 
  U1 (.a (masked_adder_output), 
      .enc (num_of_zeros) );

  assign shifting_distance = num_of_zeros;

always @ (adder_output_mag or max_exp_plus2 or max_exp or adder_output_sign or rnd 
or shifting_distance or STK_1 or STK_2 or STK_3 or STK_4)
begin
  large_input_exp = max_exp_plus2[exp_width];
  a_mag = adder_output_mag[((2*(sig_width+1)+3+2+`extra_length)-1)-1:0];
  pos_offset = max_exp_plus2;
  sticky_bit = STK_1 | STK_2 | STK_3 | STK_4;
  a_sign = adder_output_sign;
  a_norm = a_mag << shifting_distance;
  no_MS1_detection = ~a_norm[((2*(sig_width+1)+3+2+`extra_length)-1)-1];
  corrected_expo1 = $unsigned(pos_offset) - $unsigned(shifting_distance);
  corrected_expo2 = $unsigned(pos_offset) - $unsigned(shifting_distance) + 1;
  T = sticky_bit ||  (|a_norm[((2*(sig_width+1)+3+2+`extra_length)-1)-sig_width-3:0]);
  R_bit = a_norm[((2*(sig_width+1)+3+2+`extra_length)-1)-sig_width-2]; 
  L_bit = a_norm[((2*(sig_width+1)+3+2+`extra_length)-1)-sig_width-1];
  rnd_incr =   (rnd == 3'd0) ? R_bit && (L_bit || T) :   
               (rnd == 3'd1) ? 1'b0 :    
               (rnd == 3'd2) ? !a_sign && (R_bit || T) :
               (rnd == 3'd3) ? a_sign && (R_bit || T) :
               (rnd == 3'd4) ? R_bit :
               (rnd == 3'd5) ? R_bit || T : 1'b0;
  a_rounded = {1'b0, a_norm[((2*(sig_width+1)+3+2+`extra_length)-1)-1:((2*(sig_width+1)+3+2+`extra_length)-1)-sig_width-1]} + rnd_incr;
  post_rounding_normalization = a_rounded[sig_width+1];
  significand_z = (post_rounding_normalization == 1'b0) ? a_rounded[sig_width:0]:{1'b1, {sig_width{1'b0}}};
  corrected_expo = (post_rounding_normalization == 1'b1) ? corrected_expo2 : corrected_expo1;
  exponent_z = corrected_expo[exp_width-1:0];
  exp_nz_MSbits = |corrected_expo[`DW_Exp_MSB-1:exp_width];
  exp_ovf = exp_nz_MSbits & ~corrected_expo[`DW_Exp_MSB];
  exp_udf = corrected_expo[`DW_Exp_MSB];
  if (large_input_exp == 1 && exp_ovf == 1)
    begin
      exponent_z = $unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1});
    end
  inexact = R_bit | T;
end

  DW_lzd #(`large_norm_test_range) 
  U2 (.a (adder_output_mag[(((2*(sig_width+1)+3+2+`extra_length)-1)-1)  :(sig_width+2+`extra_length)-2]), 
      .enc (num_of_zeros2) );
  assign large_normalization = &num_of_zeros2;

always @ (significand_z or exponent_z or no_MS1_detection or rnd or 
          status_int1 or z_temp1 or output_defined_from_inp or 
          adder_output_sign or z_inf_minus or z_inf_plus or 
          z_large_minus or z_large_plus or inexact or large_normalization or 
          a or zer_a or inf_a or nan_a or b or zer_b or inf_b or nan_b or
          c or zer_c or inf_c or nan_c or d or zer_d or inf_d or nan_d or 
          C0 or C1 or C3 or STK or S_a or S_b or S_c 
          or S_d or STK_1 or STK_2 or STK_3 or STK_4 or exp_ovf or exp_udf)
begin
   status_int = 0;
   if (output_defined_from_inp == 1) 
     begin
       z_temp = z_temp1;
       status_int = status_int1;
     end
   else
     if (large_normalization == 1 && (STK_1 | STK_2 | STK_3 | STK_4))
       begin
         z_temp = (C0&C3)?a:((~C0&C3)?b:((C1&~C3)?c:d));
         status_int[0] = (C0&C3)?zer_a:((~C0&C3)?zer_b:((C1&~C3)?zer_c:zer_d));
         status_int[1] = (C0&C3)?inf_a:((~C0&C3)?inf_b:((C1&~C3)?inf_c:inf_d));
         status_int[2] = (C0&C3)?nan_a:((~C0&C3)?nan_b:((C1&~C3)?nan_c:nan_d));
       end
    else
    if ((exp_ovf==1 || (exp_udf==0 && exponent_z==$unsigned($unsigned($unsigned({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))) && ~no_MS1_detection)
      begin
        case (rnd)
          0,4,5:
            begin 
              if (adder_output_sign==1'b1) z_temp = z_inf_minus;
              else              z_temp = z_inf_plus;
              status_int[1] = 1'b1;       
              status_int[4] = 1'b1;       
            end
          1:
            if (adder_output_sign==1'b1) z_temp = z_large_minus;
            else                         z_temp = z_large_plus;
          2:
            if (adder_output_sign==1'b1) z_temp = z_large_minus;
            else 
              begin
                z_temp = z_inf_plus;
                status_int[1] = 1'b1;  
                status_int[4] = 1'b1;       
              end
          3:
            if (adder_output_sign==1'b1) 
              begin
                z_temp = z_inf_minus;
                status_int[1] = 1'b1;  
                status_int[4] = 1'b1;       
             end
            else              z_temp = z_large_plus;
          default: z_temp = 0;
        endcase
        status_int[5] = 1'b1;
      end
    else
      if ( no_MS1_detection == 1'b1 && significand_z != 0 )
        begin
          int_exponent = {exp_width{1'b0}};
          if ( ieee_compliance == 1)
            begin
              z_temp = {adder_output_sign, int_exponent, significand_z[$unsigned(sig_width - 1):0]};
              status_int[5] = inexact;       
            end
          else
           if ((rnd == 3 && adder_output_sign == 1) ||
               (rnd == 2 && adder_output_sign == 0) ||
               rnd == 5)
             begin
               z_temp = {adder_output_sign, {exp_width-1{1'b0}}, 1'b1,{sig_width{1'b0}}};
               status_int[0] = 0;
               status_int[5] = 1'b1;       
             end
           else
             begin
               z_temp = {adder_output_sign, {exp_width+sig_width{1'b0}}};
               status_int[0] = 1;
               status_int[5] = 1'b1;       
             end
          status_int[3] = 1'b1; 
        end
    else 
      if (no_MS1_detection == 1'b0 && (exp_udf==1'b1 || exponent_z == 0) && ieee_compliance != 1)
        begin
           if ((rnd == 3 && adder_output_sign == 1) ||
               (rnd == 2 && adder_output_sign == 0) ||
               rnd == 5)
             begin
               z_temp = {adder_output_sign, {exp_width-1{1'b0}}, 1'b1,{sig_width{1'b0}}};
               status_int[0] = 0;
             end
           else
             begin
               z_temp = {adder_output_sign, {exp_width+sig_width{1'b0}}};
               status_int[0] = 1;
             end
          status_int[3] = 1'b1; 
          status_int[5] = 1'b1;       
      end
    else
     if (no_MS1_detection == 1'b1)
       begin    
        status_int[0] = 1;
        if (rnd == 3) 
          z_temp = {1'b1, {exp_width+sig_width{1'b0}}};
        else
          z_temp = {1'b0, {exp_width+sig_width{1'b0}}};
       end
    else     
      begin
          status_int[5] = inexact;       
          z_temp = {adder_output_sign, exponent_z[exp_width-1:0], significand_z[sig_width-1:0]};
       end 

end

assign status = (arch_type == 1)?status_int2:status_int;
assign z = (arch_type == 1)?z_temp2:z_temp;
  
`undef  DW_shift_width
`undef  enc_output_size
`undef  extra_length 
`undef  large_norm_test_range
`undef  DW_Exp_MSB

endmodule
