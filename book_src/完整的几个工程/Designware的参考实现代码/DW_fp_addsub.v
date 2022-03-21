
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT: Floating-point two-operand Adder/Subtractor
//           Computes the addition/subtraction of two FP numbers. 
//           The format of the FP numbers is defined by the number of bits 
//           in the significand (sig_width) and the number of bits in the 
//           exponent (exp_width).
//           The total number of bits in the FP number is sig_width+exp_width+1
//           since the sign bit takes the place of the MS bits in the significand
//           which is always 1 (unless the number is a denormal; a condition 
//           that can be detected testing the exponent value).
//           The output is a FP number and status flags with information about
//           special number representations and exceptions. 
//           Subtraction is forced when op=1.
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance 0 or 1  (default 0)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              b               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              rounding mode
//              op              1 bit
//                              add/sub control: 0 for add - 1 for sub
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_width + exp_width + 1) bits
//                              Floating-point Number result
//              status          byte
//                              info about FP results
//
//
// MODIFIED: 
//          8/9/06: code cleanup
//
//-----------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_fp_addsub (

                   a,
                   b,
                   rnd,
                   op,
                   z,
                   status

    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

parameter sig_width    = 23;  // RANGE 2 to 253 bits
parameter exp_width    = 8;   // RANGE 3 to 31 bits
parameter ieee_compliance = 0;   // RANGE 0 or 1


`define  DW_shift_width  (($unsigned(sig_width + 3 + 3        )-2>256)?(($unsigned(sig_width + 3 + 3        )-2>4096)?(($unsigned(sig_width + 3 + 3        )-2>16384)?(($unsigned(sig_width + 3 + 3        )-2>32768)?16:15):(($unsigned(sig_width + 3 + 3        )-2>8192)?14:13)):(($unsigned(sig_width + 3 + 3        )-2>1024)?(($unsigned(sig_width + 3 + 3        )-2>2048)?12:11):(($unsigned(sig_width + 3 + 3        )-2>512)?10:9))):(($unsigned(sig_width + 3 + 3        )-2>16)?(($unsigned(sig_width + 3 + 3        )-2>64)?(($unsigned(sig_width + 3 + 3        )-2>128)?8:7):(($unsigned(sig_width + 3 + 3        )-2>32)?6:5)):(($unsigned(sig_width + 3 + 3        )-2>4)?(($unsigned(sig_width + 3 + 3        )-2>8)?4:3):(($unsigned(sig_width + 3 + 3        )-2>2)?2:1))))
`define  Elz_MSB         `DW_shift_width+exp_width-1

input  [(exp_width + sig_width):0] a,b;
input  [2:0] rnd;
input  op; 
output [8    -1:0] status;
output [(exp_width + sig_width):0] z;


wire sign_c;

wire [exp_width-1:0] mag_exp_diff;

wire swap;
wire [sig_width:0] sig_large;
wire [sig_width:0] sig_small;
wire [exp_width-1:0] exp_large;
wire [exp_width:0] E1;
wire [exp_width-1:0] exp_large_int;
wire [exp_width-1:0] exp_small;
wire sign_large;
wire sign_small;
wire [exp_width-1:0] exp_small_int;
wire [sig_width-1:0] f_large;
wire [sig_width-1:0] f_small;

wire [$unsigned(sig_width + 3 + 3        )-2:0] sig_aligned1;
wire [$unsigned(sig_width + 3 + 3        )-2:0] sig_aligned2;
wire [$unsigned(sig_width + 3 + 3        )-2:0] adder_output;
wire adder_output_sign;
wire [$unsigned(sig_width + 3 + 3        )-2:0] adder_output_mag;
 
wire denormal_large, denormal_small;
wire nan_large, nan_small;
wire inf_large, inf_small;
wire zer_large, zer_small;
wire Ezd_large, Ezd_small;
wire Fzd_large, Fzd_small;
wire Emax_large, Emax_small;
wire E_MSB_large, E_MSB_small;

wire eff_sub;

wire [$unsigned(sig_width + 3 + 3        )-2:1] a_mag;
wire sticky_bit, T, Rbit, Lbit;

wire [`DW_shift_width:0] num_of_zeros;
wire [`DW_shift_width:0] zeros;
wire [`DW_shift_width-1:0] num_of_zeros_used;
wire [$unsigned(sig_width + 3 + 3        )-2:1] a_norm;
wire round;

wire [8    -1:0] status_int;


wire [exp_width-1:0] SH_limited;
wire [$unsigned(sig_width+3        +1)-1:0] mask;
wire [$unsigned(sig_width+3        +1)-1:0] masked_op;
wire [$unsigned(sig_width+3        +1)-1:0] one_vector;
wire sticky_bit2;
wire [$unsigned(sig_width+3        +1)-1:0] sig_small_shifted_with_sticky;
wire [$unsigned(sig_width+3        +1)-1:0] sig_small_shifted;


assign zeros = 0;

assign swap = a[exp_width+sig_width-1:0] < b[exp_width+sig_width-1:0];
wire [exp_width+sig_width:0] large_n;
wire [exp_width+sig_width:0] small_n;
assign large_n = ~(swap ? b : a);
assign small_n = ~(swap ? a : b);
wire [exp_width+sig_width:0] large_p;
assign large_p = ~large_n;
wire [exp_width+sig_width:0] small_p;
assign small_p = ~small_n;      

assign sign_large = large_p[(exp_width + sig_width)] ^ (swap & op);
assign sign_small = small_p[(exp_width + sig_width)] ^ (~swap & op) ;
assign exp_large  = large_p[$unsigned((exp_width + sig_width) - 1):sig_width];
assign exp_small  = small_p[$unsigned((exp_width + sig_width) - 1):sig_width];
assign f_large  = large_p[$unsigned(sig_width - 1):0];
assign f_small  = small_p[$unsigned(sig_width - 1):0];
assign Ezd_large = !(|exp_large);
assign Ezd_small = !(|exp_small);
assign Fzd_large = (f_large == 0);
assign Fzd_small = (f_small == 0);
assign E_MSB_large = &exp_large[exp_width-1:1];
assign Emax_large = E_MSB_large & ~exp_large[0];
assign E_MSB_small = &exp_small[exp_width-1:1];
assign Emax_small = E_MSB_small & ~exp_small[0];
assign zer_large = (ieee_compliance ? Ezd_large & Fzd_large : Ezd_large);
assign zer_small = (ieee_compliance ? Ezd_small && Fzd_small : Ezd_small);
assign inf_large = (ieee_compliance?E_MSB_large & exp_large[0] & Fzd_large:E_MSB_large & exp_large[0]);
assign inf_small = (ieee_compliance?E_MSB_small & exp_small[0] & Fzd_small:E_MSB_small & exp_small[0]);
assign denormal_large = Ezd_large & ~Fzd_large;
assign denormal_small = Ezd_small & ~Fzd_small;
assign nan_large = (ieee_compliance?E_MSB_large & exp_large[0] & ~Fzd_large:0);
assign nan_small = (ieee_compliance?E_MSB_small & exp_small[0] & ~Fzd_small:0);
assign sig_large  = (ieee_compliance?{~denormal_large, f_large}:{1'b1, f_large});
assign sig_small  = (ieee_compliance?{~denormal_small, f_small}:{1'b1, f_small});
assign exp_large_int = (ieee_compliance?((denormal_large|zer_large)?1:exp_large):exp_large);
assign exp_small_int = (ieee_compliance?((denormal_small|zer_small)?1:exp_small):exp_small);

assign eff_sub = sign_large ^ sign_small;

wire zeroSmall;
assign zeroSmall = |({zer_small, inf_large});

assign mag_exp_diff = exp_large_int - exp_small_int;


assign SH_limited = mag_exp_diff;
assign sig_small_shifted = {sig_small, {3{1'b0}}} >> SH_limited;
assign one_vector = ~$unsigned(0);
assign mask = ~(one_vector << SH_limited);
assign masked_op = mask & {1'b0,sig_small,{2{1'b0}}};
assign sticky_bit2 = |masked_op & ~zeroSmall;
assign sig_small_shifted_with_sticky = {sig_small_shifted[$unsigned(sig_width+3        +1)-1:1]&{$unsigned(sig_width+3        +1)-1{~zeroSmall}},sticky_bit2};

assign sig_aligned1 = {{1{1'b0}},sig_large,{3{1'b0}}};  
assign sig_aligned2 = (eff_sub == 1'b1)? 
                 ~{{1{1'b0}}, sig_small_shifted_with_sticky}:
                 {{1{1'b0}}, sig_small_shifted_with_sticky};
assign adder_output = sig_aligned1 + sig_aligned2 + eff_sub;
assign adder_output_mag = adder_output[$unsigned(sig_width + 3 + 3        )-2:0];
assign adder_output_sign = 1'b0;
assign sign_c = sign_large;

assign num_of_zeros_used = ((ieee_compliance == 0) | (exp_large_int > num_of_zeros))?num_of_zeros : exp_large_int;

assign a_mag = adder_output_mag[$unsigned(sig_width + 3 + 3        )-2:1];
DW_lzd #($unsigned(sig_width + 3 + 3        )-2) U1 (.a(a_mag), .enc(num_of_zeros), .dec());
wire ExactZero;
assign ExactZero = &num_of_zeros;
assign a_norm = a_mag << num_of_zeros_used;
assign sticky_bit = adder_output_mag[0];
assign T = sticky_bit ||  a_norm[1] || a_norm[2];
assign Rbit = a_norm[3]; 
assign Lbit = a_norm[4];
wire [0:0] even;
assign even = rnd == 0;
wire [0:0] away;
assign away = rnd[2] & rnd[0];
wire [0:0] infMatch;
assign infMatch = rnd[1] & (sign_c == rnd[0]);
wire [0:0] infinity;
assign infinity = infMatch | away;
wire [0:0] R0_n;
assign R0_n = ~( infinity ? T : 0 );
wire [0:0] R1_n;
assign R1_n = ~( even ? (Lbit | T) : (rnd[2] | infMatch) );
assign round = ~( Rbit ? R1_n : R0_n );
wire [0:0] inexact;
assign inexact = Rbit | T;
wire [0:0] HugeInfinity;
assign HugeInfinity = infinity | (rnd[1:0] == 0);
wire [0:0] TinyMinNorm;
assign TinyMinNorm = infinity;

wire [sig_width-1:0] frac0,frac1,fraction;
assign frac0 = a_norm[$unsigned(sig_width + 3 + 3        )-2-1:4];
assign frac1 = frac0 + 1;

wire signed [`Elz_MSB:0] Elz;
assign E1 = exp_large + 1;
assign Elz = E1 - num_of_zeros_used;
wire Einc_possible;
assign Einc_possible = &({ round, adder_output_mag[$unsigned(sig_width + 3 + 3        )-2-2:3] } );
wire [0:0] ADD_Einc;
assign ADD_Einc = ( a_mag[$unsigned(sig_width + 3 + 3        )-2-1]&Einc_possible )|a_mag[$unsigned(sig_width + 3 + 3        )-2];
wire largeE_MSBs;
assign largeE_MSBs = &(exp_large[exp_width-1:1]);
wire largeEi_MSBs;
assign largeEi_MSBs = largeE_MSBs;
assign status_int[4] = largeEi_MSBs & ADD_Einc & (ieee_compliance==0 | (~nan_large & ~nan_small));
wire [0:0] Elz_Tiny;
assign Elz_Tiny = (Elz[`Elz_MSB] | ~|(Elz[`Elz_MSB-1:0]));
wire [0:0] Tiny_partial;
assign Tiny_partial = Elz_Tiny & ~zer_large;
assign status_int[3] = Tiny_partial & ~ExactZero & (ieee_compliance == 0);
wire [0:0] EincEnable;
assign EincEnable = ((~largeEi_MSBs) | HugeInfinity) & (ieee_compliance==0 | (~nan_large & ~nan_small));
wire [0:0] E1select;
assign E1select = (ADD_Einc & EincEnable) | (ieee_compliance==1 & denormal_large & a_norm[$unsigned(sig_width + 3 + 3        )-2]);
wire [exp_width-1:0] exp0_n;
assign exp0_n = ~( E1select ? E1[exp_width-1:0] : exp_large);
wire [exp_width-1:0] expSUB;
assign expSUB = (~ExactZero) & (TinyMinNorm & ieee_compliance == 0);
wire [0:0] expSUBsel;
assign expSUBsel = ExactZero | Tiny_partial | (ieee_compliance==1 & ~a_norm[$unsigned(sig_width + 3 + 3        )-2]);
wire [exp_width-1:0] exp1_n;
assign exp1_n = ~( expSUBsel ? expSUB : Elz[exp_width-1:0] );
wire [0:0] exp1select;
assign exp1select = eff_sub & ~(Einc_possible &  adder_output_mag[2]) & (ieee_compliance==0 | (~denormal_large & ~nan_large & ~nan_small));
wire [exp_width-1:0] exponent;
assign exponent = ~( exp1select ? exp1_n : exp0_n );
wire [0:0] sign;
assign sign = ((zer_large | (status_int[0] &
                   ~status_int[3])) & eff_sub & (rnd==3))?1'b1:
                  ((inf_small & eff_sub)|ExactZero|(zer_large & eff_sub)|((ieee_compliance==1)&status_int[2])) ? 1'b0 : sign_large;

wire signed [sig_width-1:0] SpecialFrac;
assign SpecialFrac = (status_int[4] & ~HugeInfinity)?~0:(ieee_compliance?status_int[2]:0);
wire [0:0] SpecialSel;
assign SpecialSel = zer_large | ExactZero | (Elz_Tiny & (ieee_compliance==0 | ~denormal_large)) | status_int[4] | inf_large | status_int[2];
wire [sig_width-1:0] frac0Spec_n;
assign frac0Spec_n = ~( SpecialSel ? SpecialFrac : frac0 );
wire [0:0] frac1Sel;
assign frac1Sel = round & (~status_int[4] & ~(ieee_compliance==1 & status_int[2]));
assign fraction = ~( frac1Sel ? (~frac1) : frac0Spec_n );
assign z = {sign,exponent,fraction};
assign status_int[2]  = (inf_small & eff_sub) | (ieee_compliance==1 &(nan_large | nan_small));
assign status_int[0]     = zer_large | (ExactZero & (ieee_compliance==0 | (~nan_large & ~nan_small))) | ((Elz_Tiny & (ieee_compliance==0 | (~denormal_large & ~nan_large & ~nan_small))) & (~TinyMinNorm));
assign status_int[1] = inf_large&(ieee_compliance==0 | ~status_int[2]) | (status_int[4] & HugeInfinity);
assign status_int[5]  = status_int[3] | (inexact & (ieee_compliance==0 | (ieee_compliance==1 & ~nan_large & ~nan_small))) | status_int[4];
assign status_int[6] = 0;
assign status_int[7] = 0;
assign status = status_int;

`undef DW_shift_width
`undef Elz_MSB

endmodule
