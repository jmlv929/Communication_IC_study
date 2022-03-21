
////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------
//
// ABSTRACT: Three-operand Floating-point Adder (SUM3)
//           Computes the addition of three FP numbers. The format of the FP
//           numbers is defined by the number of bits in the significand 
//           (sig_width) and the number of bits in the exponent (exp_width).
//           The outputs are a FP number and status flags with information 
//           about special number representations and exceptions. 
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
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
//        9/15/2006:
//           - corrects the manipulation of STK bits
//           - increases the precision of internal adder
//        5/18/2007:
//           - modified the manipulation of sign of zeros. When ieee_compliance=1
//             the sign of the zero output is manipulated as follows:
//                 a   b   c   rnd    z  rnd      z
//                +0  +0  +0   -inf  +0  others  +0
//                +0  +0  -0   -inf  -0  others  +0
//                +0  -0  +0   -inf  -0  others  +0
//                +0  -0  -0   -inf  -0  others  +0
//                -0  +0  +0   -inf  -0  others  +0
//                -0  +0  -0   -inf  -0  others  +0
//                -0  -0  +0   -inf  -0  others  +0
//                -0  -0  -0   -inf  -0  others  -0
//                +0  -3  +3   -inf  -0  others  +0
//               Notice that the last row shows the case when the inputs are non-
//               zero values, forcing a exact zero output.
//       11/19/2007: fixed detection of denormals and NaN when ieee_compliance=0
//       01/03/2008: 
//            - fixed the output value and status bits when output is NaN
//              and ieee_compliance = 0.
//            - fixed problem related to Star 9000188489 - underflow of 
//              internal variable used to compute exponent value
//
//       03/13/2008: AFT : included a new parameter (arch_type) to control
//                   the use of alternative architecture with IFP blocks
//       01/13/2009: AFT : fixed a length mismatch of a mask that detects
//                   sticky bit values.
//       12/08/2008: expanded the use of IFP components to accept 
//                   ieee_compliance=1
//       02/18/2009: Modified the code to remove lint messages.
//
//-------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_fp_sum3 (

                   a,
                   b,
                   c,
                   rnd,
                   z,
                   status


    // Embedded dc_shell script
    // _model_constraint_2
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

parameter sig_width=23;             // RANGE 2 to 253 bits
parameter exp_width=8;              // RANGE 3 to 31 bits
parameter ieee_compliance=0;        // RANGE 0 or 1           
parameter arch_type=0;              // RANGE 0 or 1           
parameter prec_adj = 0;


input  [(exp_width + sig_width):0] a,b,c;
input  [2:0] rnd;
output [8    -1:0] status;
output [(exp_width + sig_width):0] z;

`define  DW_shift_width  ((((sig_width+1)+3+(sig_width+4+prec_adj))-1>256)?((((sig_width+1)+3+(sig_width+4+prec_adj))-1>4096)?((((sig_width+1)+3+(sig_width+4+prec_adj))-1>16384)?((((sig_width+1)+3+(sig_width+4+prec_adj))-1>32768)?16:15):((((sig_width+1)+3+(sig_width+4+prec_adj))-1>8192)?14:13)):((((sig_width+1)+3+(sig_width+4+prec_adj))-1>1024)?((((sig_width+1)+3+(sig_width+4+prec_adj))-1>2048)?12:11):((((sig_width+1)+3+(sig_width+4+prec_adj))-1>512)?10:9))):((((sig_width+1)+3+(sig_width+4+prec_adj))-1>16)?((((sig_width+1)+3+(sig_width+4+prec_adj))-1>64)?((((sig_width+1)+3+(sig_width+4+prec_adj))-1>128)?8:7):((((sig_width+1)+3+(sig_width+4+prec_adj))-1>32)?6:5)):((((sig_width+1)+3+(sig_width+4+prec_adj))-1>4)?((((sig_width+1)+3+(sig_width+4+prec_adj))-1>8)?4:3):((((sig_width+1)+3+(sig_width+4+prec_adj))-1>2)?2:1))))
reg [8    -1:0] status_int;
reg [8    -1:0] status_int1;
reg [(exp_width + sig_width):0] z_temp;
reg [(exp_width + sig_width):0] z_temp1;
reg output_defined_from_inp;
reg [exp_width-1:0] E_a,E_b,E_c;
reg [sig_width-1:0] F_a,F_b,F_c;
reg [sig_width:0] M_a,M_b;
reg [sig_width+(sig_width+4+prec_adj):0] M_a_sh,M_b_sh;
reg [sig_width:0] M_c;
reg [sig_width+(sig_width+4+prec_adj):0] M_c_sh;
reg S_a,S_b,S_c;
reg [exp_width-1:0] max_exp;
reg [exp_width:0] max_exp_plus1;
reg [exp_width:0] max_exp_plus2;
reg [exp_width-1:0] ediff_a, ediff_b, ediff_c;
wire [(exp_width + sig_width):0] NaNFp;
reg denormal_a, denormal_b, denormal_c;
reg inf_a, inf_b, inf_c;
reg nan_a, nan_b, nan_c;
reg zer_a, zer_b, zer_c;
wire [(exp_width + sig_width + 1)-1:0] z_inf_plus;
wire [(exp_width + sig_width + 1)-1:0] z_inf_minus;
wire [(exp_width + sig_width + 1)-1:0] z_large_plus;
wire [(exp_width + sig_width + 1)-1:0] z_large_minus;
reg [(((sig_width+1)+3+(sig_width+4+prec_adj))-1):0] adder_input1, adder_input2, adder_input3; 
reg [(((sig_width+1)+3+(sig_width+4+prec_adj))-1):0] adder_output; 
reg adder_output_sign;
reg [(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-1:0] adder_output_mag; 
reg [exp_width-1:0] int_exponent;
`define Exp_MSB `DW_shift_width+exp_width-1 
reg [`Exp_MSB:0] corrected_expo1;
reg [`Exp_MSB:0] corrected_expo2;
reg [`Exp_MSB:0] corrected_expo;
reg post_rounding_normalization;
reg [((sig_width+1)+3+(sig_width+4+prec_adj))-1:1] a_mag;
reg [exp_width:0] pos_offset;
reg sticky_bit, T, Rbit, Lbit;
reg inexact;
reg exp_ovf, exp_udf;
reg exp_nz_MSbits; 
wire [`DW_shift_width:0] num_of_zeros;
wire [`DW_shift_width:0] shifting_distance;
reg [((sig_width+1)+3+(sig_width+4+prec_adj))-1:0] a_norm;
reg a_sign;
reg rnd_incr;
reg [sig_width+1:0] a_rounded;
reg no_MS1_detection;
reg [sig_width:0] significand_z;
reg [exp_width-1:0] exponent_z;
reg large_input_exp;
reg [$unsigned((sig_width+1)+(sig_width+4+prec_adj))-1:0] mask;
reg [$unsigned((sig_width+1)+(sig_width+4+prec_adj))-1:0] masked_op;
reg [$unsigned((sig_width+1)+(sig_width+4+prec_adj))-1:0] one_vector;
reg STK_a, STK_b, STK_c;
reg STK_a_add, STK_b_add, STK_c_add;
reg STK_a_raw, STK_b_raw, STK_c_raw;
reg inv_a, inv_b;
wire [sig_width+exp_width : 0] z_temp2;
wire [7 : 0] status_int2;
wire [sig_width+2+exp_width+6:0] ifpa;
wire [sig_width+2+exp_width+6:0] ifpb;
wire [sig_width+2+3+exp_width+1+6:0] ifpc; 
wire [sig_width+2+3+exp_width+1+6:0] ifpd;
wire [sig_width+2+3+sig_width+exp_width+1+1+6:0] ifpe;
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U2 ( .a(a), .z(ifpa) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2, exp_width, ieee_compliance, 0)
          U3 ( .a(b), .z(ifpb) );
    DW_fp_ifp_conv #(sig_width, exp_width, sig_width+2+3, exp_width+1, ieee_compliance, 0)
          U4 ( .a(c), .z(ifpc) );
    DW_ifp_addsub #(sig_width+2, exp_width, sig_width+2+3, exp_width+1, ieee_compliance, 0)
	  U5 ( .a(ifpa), .b(ifpb), .op(1'b0), .rnd(rnd), 
               .z(ifpd) );
    DW_ifp_addsub #(sig_width+2+3, exp_width+1, sig_width+2+3+sig_width, exp_width+1+1, ieee_compliance, 0)
	  U6 ( .a(ifpd), .b(ifpc), .op(1'b0), .rnd(rnd),
               .z(ifpe) );
    DW_ifp_fp_conv #(sig_width+2+3+sig_width, exp_width+1+1, sig_width, exp_width, ieee_compliance)
          U7 ( .a(ifpe), .rnd(rnd), .z(z_temp2), .status(status_int2) );
assign NaNFp = (ieee_compliance == 1)?{1'b0,{exp_width{1'b1}},{sig_width-1{1'b0}},1'b1}:
                                      {1'b0,{exp_width{1'b1}},{sig_width{1'b0}}};
assign z_inf_plus[(exp_width + sig_width)] = 1'b0;
assign z_inf_plus[((exp_width + sig_width) - 1):sig_width] = ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1});
assign z_inf_plus[(sig_width - 1):0] = {sig_width{1'b0}};
assign z_inf_minus[(exp_width + sig_width)] = 1'b1;
assign z_inf_minus[((exp_width + sig_width) - 1):sig_width] = ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1});
assign z_inf_minus[(sig_width - 1):0] = {sig_width{1'b0}};
assign z_large_plus[(exp_width + sig_width)] = 1'b0;
assign z_large_plus[((exp_width + sig_width) - 1):sig_width] = (({exp_width{1'b1}}>>1) << 1);
assign z_large_plus[(sig_width - 1):0] = {sig_width{1'b1}};
assign z_large_minus[(exp_width + sig_width)] = 1'b1;
assign z_large_minus[((exp_width + sig_width) - 1):sig_width] = (({exp_width{1'b1}}>>1) << 1);
assign z_large_minus[(sig_width - 1):0] = {sig_width{1'b1}};
always @(a or b or c or rnd)
begin
  E_a = a[((exp_width + sig_width) - 1):sig_width];
  E_b = b[((exp_width + sig_width) - 1):sig_width];
  E_c = c[((exp_width + sig_width) - 1):sig_width];
  F_a = a[(sig_width - 1):0];
  F_b = b[(sig_width - 1):0];
  F_c = c[(sig_width - 1):0];
  S_a = a[(exp_width + sig_width)];
  S_b = b[(exp_width + sig_width)];
  S_c = c[(exp_width + sig_width)]; 
  if ((E_a == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && ((F_a == 0) || (ieee_compliance == 0)))
     inf_a = 1;
  else
     inf_a = 0;
  if ((E_b == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && ((F_b == 0) || (ieee_compliance == 0)))
     inf_b = 1;
  else
     inf_b = 0;
  if ((E_c == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && ((F_c == 0) || (ieee_compliance == 0)))  
     inf_c = 1;
  else
     inf_c = 0;
  if ((E_a == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && (F_a != 0) && (ieee_compliance == 1))  
     nan_a = 1;
  else
     nan_a = 0;
  if ((E_b == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && (F_b != 0) && (ieee_compliance == 1))  
     nan_b = 1;
  else
     nan_b = 0;
  if ((E_c == ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1})) && (F_c != 0) && (ieee_compliance == 1))  
     nan_c = 1;
  else
     nan_c = 0;
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

end

always @ (nan_a or nan_b or nan_c or inf_a or inf_b or inf_c or S_a or S_b or S_c or 
          NaNFp or zer_a or zer_b or zer_c or a or b or c or denormal_a or denormal_b 
          or denormal_c or rnd or z_inf_plus or z_inf_minus)
begin
  z_temp1 = 0;
  status_int1 = 0;
  output_defined_from_inp = 1;
  if ((nan_a == 1) || (nan_b == 1) || (nan_c == 1)) 
    begin
      z_temp1 = NaNFp;
      status_int1[2] = 1;
    end
  else if  (inf_a == 1) 
    if (((inf_b == 1) && (S_a != S_b)) || ((inf_c == 1) && (S_a != S_c))) 
      begin
        z_temp1 =NaNFp;
        status_int1[2] = 1;
        status_int1[1] = (ieee_compliance == 1)?0:1;
      end
    else 
      begin
        z_temp1 = (S_a)?z_inf_minus:z_inf_plus;
        status_int1[1] = 1;
      end
  else if (inf_b == 1) 
    if (((inf_a == 1) && (S_a != S_b)) || ((inf_c == 1) && (S_b != S_c))) 
      begin
        z_temp1 = NaNFp;
        status_int1[2] = 1;
        status_int1[1] = (ieee_compliance == 1)?0:1;
     end
    else
      begin
        z_temp1 = (S_b)?z_inf_minus:z_inf_plus;
        status_int1[1] = 1;
      end
  else if (inf_c == 1) 
    if (((inf_a == 1) && (S_a != S_c)) || ((inf_b == 1) && (S_b != S_c))) 
      begin
        z_temp1 = NaNFp;
        status_int1[2] = 1;
        status_int1[1] = (ieee_compliance == 1)?0:1;
      end
    else
      begin
        z_temp1 = (S_c)?z_inf_minus:z_inf_plus;
        status_int1[1] = 1;
      end
  
  else if ((zer_a == 1) && (zer_b == 1) && (zer_c == 1)) 
    begin
      z_temp1 =  0;
      status_int1[0] = 1;
      if (ieee_compliance == 0) 
        if (rnd == 3)
          z_temp1[(exp_width + sig_width)] = 1'b1;
        else
          z_temp1[(exp_width + sig_width)] = 1'b0;
      else
        if ((S_a == S_b) && (S_b == S_c)) 
          z_temp1[(exp_width + sig_width)] = S_a;
        else
          if (rnd == 3) 
            z_temp1[(exp_width + sig_width)] = 1'b1;
          else
            z_temp1[(exp_width + sig_width)] = 1'b0;
    end

  else if ((a[((exp_width + sig_width) - 1):0] == b[((exp_width + sig_width) - 1):0]) && (S_a != S_b))
    begin
      z_temp1 = c;
      status_int1[0] = zer_c;
      status_int1[3] = denormal_c;
      if (zer_c)
        if (rnd == 3)
          z_temp1[(exp_width + sig_width)] = 1'b1;
        else
          z_temp1[(exp_width + sig_width)] = 1'b0;
    end
  else if ((b[((exp_width + sig_width) - 1):0]  == c[((exp_width + sig_width) - 1):0]) && (S_b != S_c))
   begin
      z_temp1 = a;
      status_int1[0] = zer_a;
      status_int1[3] = denormal_a;
      if (zer_a)
        if (rnd == 3)
          z_temp1[(exp_width + sig_width)] = 1'b1;
        else
          z_temp1[(exp_width + sig_width)] = 1'b0;
    end
  else if ((a[((exp_width + sig_width) - 1):0] == c[((exp_width + sig_width) - 1):0]) && (S_a != S_c))
    begin
      z_temp1 = b;
      status_int1[0] = zer_b;
      status_int1[3] = denormal_b;
      if (zer_b)
        if (rnd == 3)
          z_temp1[(exp_width + sig_width)] = 1'b1;
        else
          z_temp1[(exp_width + sig_width)] = 1'b0;
    end
  else output_defined_from_inp = 0;
end


always @ (S_a or E_a or F_a or S_b or E_b or F_b or S_c or E_c or F_c or zer_a or zer_b or zer_c or denormal_a or denormal_b or denormal_c)
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
  
    if ((E_a >= E_b) && (E_a >= E_c)) 
      max_exp = E_a;
    else if ((E_b >= E_a) && (E_b >= E_c)) 
      max_exp = E_b;
    else
      max_exp = E_c;
    ediff_a = max_exp - E_a;
    ediff_b = max_exp - E_b;
    ediff_c = max_exp - E_c;
    max_exp_plus2 = max_exp + 2;
    max_exp_plus1 = max_exp + 1;

end

always @ (ediff_a or ediff_b or ediff_c or M_a or M_b or M_c or E_a or 
          E_b or E_c)
begin
  M_a_sh = {M_a,{(sig_width+4+prec_adj){1'b0}}};
  M_a_sh = M_a_sh >> ediff_a;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << ediff_a);
  masked_op = mask & {M_a,{(sig_width+4+prec_adj){1'b0}}};
  STK_a = |masked_op;
  STK_a_raw = STK_a | M_a_sh[0];  

  M_b_sh = {M_b,{(sig_width+4+prec_adj){1'b0}}};
  M_b_sh = M_b_sh >> ediff_b;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << ediff_b);
  masked_op = mask & {M_b,{(sig_width+4+prec_adj){1'b0}}};
  STK_b = |masked_op;
  STK_b_raw = STK_b | M_b_sh[0];  

  M_c_sh = {M_c,{(sig_width+4+prec_adj){1'b0}}};
  M_c_sh = M_c_sh >> ediff_c;
  one_vector = ~$unsigned(0);
  mask = ~(one_vector << ediff_c);
  masked_op = mask & {M_c,{(sig_width+4+prec_adj){1'b0}}};
  STK_c = |masked_op;
  STK_c_raw = STK_c | M_c_sh[0];

  STK_a_add = STK_a_raw;
  STK_b_add = STK_b_raw;
  STK_c_add = STK_c_raw;
  if (STK_a_add & STK_b_add)
    begin
      STK_a_add = ({E_a,M_a}>{E_b,M_b});
      STK_b_add = ~STK_a_add;
    end
  if (STK_a_add & STK_c_add)
    begin
      STK_a_add = ({E_a,M_a}>{E_c,M_c});
      STK_c_add =  ~STK_a_add;
    end
  if (STK_b_add & STK_c_add)
    begin
      STK_b_add = ({E_b,M_b}>{E_c,M_c});
      STK_c_add =  ~STK_b_add;
    end
  M_a_sh[0] = STK_a_add;
  M_b_sh[0] = STK_b_add;
  M_c_sh[0] = STK_c_add;
  

end

always @ (M_a_sh or M_b_sh or M_c_sh or S_a or S_b or S_c)
begin
    inv_a = S_a ^ S_c;
    inv_b = S_b ^ S_c;
    if (inv_a == 1'b1) 
     adder_input1 = ~{3'b000, M_a_sh};
    else 
      adder_input1 = {3'b000, M_a_sh};
    if (inv_b == 1'b1) 
      adder_input2 = ~{3'b000, M_b_sh};
    else 
      adder_input2 = {3'b0, M_b_sh};
    adder_input3 = {3'b0, M_c_sh};

    adder_output = adder_input1 + adder_input2 + adder_input3 + inv_a + inv_b;

    
    adder_output_sign = adder_output[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)] ^ S_c;
    if (adder_output[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)] == 1) 
      adder_output_mag = ~adder_output[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-1:0]+1;
    else
      adder_output_mag = adder_output[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-1:0];
end

  wire [((sig_width+1)+3+(sig_width+4+prec_adj))-2:0] decoded_exp_large;
  wire [((sig_width+1)+3+(sig_width+4+prec_adj))-2:0] masked_adder_output;
  assign decoded_exp_large = ({1'b1,{((sig_width+1)+3+(sig_width+4+prec_adj))-2{1'b0}}} >> (max_exp_plus1)) | 1'b1;
  assign masked_adder_output = (ieee_compliance==1)?adder_output_mag | decoded_exp_large:
                                                 adder_output_mag;
  DW_lzd #(((sig_width+1)+3+(sig_width+4+prec_adj))-1) 
  U1 (.a (masked_adder_output), 
      .enc (num_of_zeros),
      .dec() );

  assign shifting_distance = num_of_zeros;

always @ (adder_output_mag or max_exp_plus2 or adder_output_sign or rnd 
or shifting_distance or STK_a or STK_b or STK_c)
begin
  large_input_exp = max_exp_plus2[exp_width];
  a_mag = adder_output_mag[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-1:0];
  pos_offset = max_exp_plus2;
  sticky_bit = STK_a | STK_b | STK_c;
  a_sign = adder_output_sign;
  a_norm = a_mag << shifting_distance;
  no_MS1_detection = ~a_norm[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-1];
  corrected_expo1 = $unsigned(pos_offset) - $unsigned(shifting_distance);
  corrected_expo2 = $unsigned(pos_offset) - $unsigned(shifting_distance) + 1;
  T = sticky_bit ||  (|a_norm[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-sig_width-3:0]);
  Rbit = a_norm[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-sig_width-2]; 
  Lbit = a_norm[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-sig_width-1];
  rnd_incr =   (rnd == 3'd0) ? Rbit && (Lbit || T) :   
               (rnd == 3'd1) ? 1'b0 :    
               (rnd == 3'd2) ? !a_sign && (Rbit || T) :
               (rnd == 3'd3) ? a_sign && (Rbit || T) :
               (rnd == 3'd4) ? Rbit :
               (rnd == 3'd5) ? Rbit || T : 1'b0;
  a_rounded = {1'b0, a_norm[(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-1:(((sig_width+1)+3+(sig_width+4+prec_adj))-1)-sig_width-1]} + rnd_incr;
  post_rounding_normalization = a_rounded[sig_width+1];
  significand_z = (post_rounding_normalization == 1'b0) ? a_rounded[sig_width:0]:{1'b1, {sig_width{1'b0}}};
  corrected_expo = (post_rounding_normalization == 1'b1) ? corrected_expo2 : corrected_expo1;
  exponent_z = corrected_expo[exp_width-1:0];
  exp_nz_MSbits = |corrected_expo[`Exp_MSB-1:exp_width];
  exp_ovf = exp_nz_MSbits & ~corrected_expo[`Exp_MSB];
  exp_udf = corrected_expo[`Exp_MSB];
  if (large_input_exp == 1 && exp_ovf == 1)
    begin
      exponent_z = ((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1});
    end
  inexact = Rbit | T;
end

always @ (significand_z or exponent_z or no_MS1_detection or rnd or status_int1 or z_temp1 or output_defined_from_inp or adder_output_sign or z_inf_minus or z_inf_plus or z_large_minus or z_large_plus or inexact or S_a or S_b or S_c or exp_ovf or exp_udf)
begin
   status_int = 0;
   if (output_defined_from_inp == 1) 
     begin
       z_temp = z_temp1;
       status_int = status_int1;
     end
   else
    if ((exp_ovf==1 || (exp_udf==0 && exponent_z==((({exp_width{1'b1}}>>1) << 1) + {{exp_width-1{1'b0}},1'b1}))) && ~no_MS1_detection)
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
      if ( no_MS1_detection == 1'b1 && significand_z != 0 && ieee_compliance == 1)
        begin
          int_exponent = {exp_width{1'b0}};
          z_temp = {adder_output_sign, int_exponent, significand_z[(sig_width - 1):0]};
          status_int[5] = inexact;       
          status_int[3] = 1'b1; 
        end
    else 
      if (significand_z != 0 && (exp_udf==1'b1 || exponent_z == 0) && ieee_compliance != 1)
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
`undef  Exp_MSB

endmodule
