
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-point internal format to IEEE format converter
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_widthi      significand size,  2 to 253 bits
//              exp_widthi      exponent size,     3 to 31 bits
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              use_denormal    0 or 1  (default 0)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_widthi + exp_widthi + 7)-bits
//                              Internal Floating-point Number Input
//              rnd             3 bits
//                              Rounding mode
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_width + exp_width + 1) bits
//                              IEEE Floating-point Number
//              status          8 bits
//                              Status information about FP number
//
//           Important, although the IFP has a bit for 1's complement 
//           representation, this converter does not process this bit. 
//
// MODIFIED: 11/2008 - included the manipulation of denormals and NaNs
//
//------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_ifp_fp_conv (

                   a,
                   rnd,
                   z,
                   status

    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

parameter sig_widthi=25;      // RANGE 2 to 253 bits
parameter exp_widthi=8;       // RANGE 3 to 31 bits  
parameter sig_width=23;       // RANGE 2 to 253 bits
parameter exp_width=8;        // RANGE 3 to 31 bits
parameter use_denormal=0;     // RANGE 0 or 1                 


input  [sig_widthi+exp_widthi+7-1:0] a;
input  [2:0] rnd;
output [sig_width+exp_width:0] z;
output [7:0] status;

  wire sign;
  wire [exp_widthi-1:0] E;
  wire signed [exp_widthi+1:0] E_Comp;
  wire signed [exp_widthi+1:0] E_Comp1;
  wire signed [exp_widthi+1:0] Exp;
  wire signed [sig_widthi:0] M;
  wire signed [sig_widthi:0] M_mag;
  wire [sig_width-1:0] zero_f;
  wire [sig_width-1:0] one_f;
  wire [sig_width-1:0] all_ones_f;
  wire [exp_width-1:0] zero_e;
  wire [exp_width-1:0] InfExp_vec;
  wire [exp_width-1:0] MaxExp_vec;
  wire [7-1:0] status_ifp;
  wire [7:0] status_int;
  wire [7:0] status_ifp_repos;
  wire [7:0] status_tiny;
  wire [7:0] status_huge;
  wire [sig_width+exp_width:0] z_tiny;
  wire [sig_width+exp_width:0] z_huge;
  wire [sig_widthi:0] M_Z_norm;
  wire [sig_widthi:0] M_Z_norm_adj;
  wire [sig_widthi:0] M_Z_out_size;
  wire adj_val;
  wire [exp_width-1:0] min_E;
`define  DW_shift_width  ((sig_widthi+1>256)?((sig_widthi+1>4096)?((sig_widthi+1>16384)?((sig_widthi+1>32768)?16:15):((sig_widthi+1>8192)?14:13)):((sig_widthi+1>1024)?((sig_widthi+1>2048)?12:11):((sig_widthi+1>512)?10:9))):((sig_widthi+1>16)?((sig_widthi+1>64)?((sig_widthi+1>128)?8:7):((sig_widthi+1>32)?6:5)):((sig_widthi+1>4)?((sig_widthi+1>8)?4:3):((sig_widthi+1>2)?2:1))))
  wire [`DW_shift_width:0] num_of_zeros, num_of_zeros_used;
  wire isdenormal;
  wire T, Rbit, Lbit;
  wire ExactZero;
  wire SignofZero;
  wire E_Max, E_inf;
  wire E_zer;
  wire sticky_bit;
  wire allones_reduced_frac0;
  wire allones_frac0;
  wire denorm_norm_trans;

  assign zero_f = {sig_width{1'b0}};
  assign one_f = {{sig_width-1{1'b0}},1'b1};
  assign all_ones_f = {sig_width{1'b1}};
  assign zero_e = {exp_width{1'b0}};
  assign InfExp_vec = {exp_width{1'b1}};
  assign MaxExp_vec = {exp_width{1'b1}}<<1;
  assign min_E = {{exp_width-1{1'b0}},1'b1};

  assign status_ifp = a[sig_widthi+exp_widthi+7-1:sig_widthi+exp_widthi];
  assign status_int[2:0] = status_ifp[2:0];
  assign status_ifp_repos[0] = status_ifp[0] & 
                                          ~status_ifp[2];
  assign status_ifp_repos[1] = (status_ifp[1] & 
                                               ~status_ifp[2]) |
                                              (status_ifp[2] & use_denormal == 0);
  assign status_ifp_repos[2] = status_ifp[2]; 
  assign status_ifp_repos[5] = status_ifp[3] &
                                             ~status_ifp[2];
  assign status_ifp_repos[4] = 1'b0;
  assign status_ifp_repos[3] = 1'b0;
  assign status_ifp_repos[7:6] = 2'b00;
  assign status_int[7:3] = status_ifp_repos[7:3];

  assign E = a[sig_widthi+exp_widthi-1:sig_widthi];

  assign M = $signed({a[sig_widthi-1:0],status_ifp[3]});
  assign M_mag = (((a[sig_widthi-1])?-M:M)>>1)<<1;
  wire Zero_A;
  assign Zero_A = ~|a[sig_widthi-1:0] | status_ifp[0];
  assign sign = (Zero_A)?status_ifp[5     ]:a[sig_widthi-1];
  assign ExactZero = Zero_A & ~sticky_bit;
  assign SignofZero = (Zero_A)?
                         status_ifp[5     ]:
                         (ExactZero)?(rnd == 3):sign;

assign num_of_zeros_used = ((use_denormal == 0) | (E > num_of_zeros))?num_of_zeros : E;

  DW_lzd #(sig_widthi+1) U1 (.a (M_mag[sig_widthi:0]), .enc(num_of_zeros), .dec());
  assign M_Z_norm = M_mag << num_of_zeros_used;
  assign M_Z_norm_adj = M_Z_norm;
  assign adj_val = ~M_Z_norm[sig_widthi];
  assign E_Comp = (M_mag == 0)?{exp_widthi+2{1'b0}}:E - num_of_zeros_used + 
                  {{exp_widthi+2-1{1'b0}},1'b1};
  assign E_Comp1 = E_Comp + {{exp_widthi+2-1{1'b0}},1'b1};
  assign E_Max = E_Comp == (((1 << (exp_width-1)) - 1) * 2);
  assign E_inf = E_Comp > (((1 << (exp_width-1)) - 1) * 2);
  assign E_zer = (E_Comp == 0);

  assign sticky_bit = status_int[5];
  assign M_Z_out_size = M_Z_norm_adj << (sig_widthi-sig_widthi);
  assign T = (sig_widthi-sig_width-1 >= 1)?(sticky_bit | |M_Z_out_size[sig_widthi-sig_width-1-1:0] | 
                        (M_Z_out_size[sig_widthi-sig_width-1] & E_zer)):
                       (sticky_bit | 
                        (M_Z_out_size[0] & E_zer));

  assign Rbit = M_Z_out_size[sig_widthi-sig_width-1] & ~E_zer | 
                M_Z_out_size[sig_widthi-sig_width-1+1] & E_zer;  
  assign Lbit = M_Z_out_size[sig_widthi-sig_width] & ~E_zer |
                M_Z_out_size[sig_widthi-sig_width+1] & E_zer;
  wire [0:0] even;
  assign even = rnd == 0;
  wire [0:0] away;
  assign away = rnd[2] & rnd[0];
  wire [0:0] infMatch;
  assign infMatch = rnd[1] & (sign == rnd[0]);
  wire [0:0] infinity;
  assign infinity = infMatch | away;
  wire [0:0] R0_n;
  assign R0_n = ~( infinity ? T : 1'b0 );
  wire [0:0] R1_n;
  assign R1_n = ~( even ? (Lbit | T) : (rnd[2] | infMatch) );
  wire round;
  assign round = ~( Rbit ? R1_n : R0_n );
  wire [0:0] inexact;
  assign inexact = Rbit | T;
  wire [0:0] HugeInfinity;
  assign HugeInfinity = infinity | (rnd[1:0] == 0);
  wire [0:0] TinyMinNorm;
  assign TinyMinNorm = infinity;
  wire [sig_width-1:0] frac0, frac1, frac;
  assign frac0 = M_Z_out_size[sig_widthi-sig_width+sig_width-1:sig_widthi-sig_width];
  assign frac1 = frac0 + {{sig_width-1{1'b0}},1'b1};
  wire Einc_enable;
  assign allones_reduced_frac0 = &frac0[sig_width-1:1];
  assign allones_frac0 = allones_reduced_frac0 & frac0[0];
  assign Einc_enable = (allones_frac0 | (E_zer & allones_reduced_frac0))
                       & round;
  assign {Exp,frac} = (round)?((Einc_enable & ~denorm_norm_trans)?{E_Comp1,zero_f}:{E_Comp,frac1}):
                      {E_Comp,frac0};
  assign isdenormal = (use_denormal == 1) & ~M_Z_norm[sig_widthi] & ~Einc_enable;
  assign denorm_norm_trans = (use_denormal == 1) & ~isdenormal & ~M_Z_norm[sig_widthi];

  assign {status_tiny,z_tiny} = (TinyMinNorm)?
                                ((use_denormal == 1)?
                                   {{8'b00101000},{sign, zero_e, one_f}}:
                                   {{8'b00100000},{sign, min_E, zero_f}}):
                                {{8'b00101001},{SignofZero, zero_e, zero_f}};
  assign {status_huge,z_huge} = (((E_Max&&Einc_enable)||E_inf) && HugeInfinity)?
                                {{8'b00110010},{sign, InfExp_vec, zero_f}}:
                                {{8'b00110000},{sign, MaxExp_vec, all_ones_f}};
  assign z = ((status_int[0] & ~status_int[2] & ~status_ifp[3])|
              (ExactZero & ~|status_int[2:1]))?{SignofZero, zero_e, zero_f}:
             (status_int[1] & ~status_int[2])?{status_ifp[5     ], InfExp_vec, zero_f}:
             (status_int[2])?{1'b0, InfExp_vec, (use_denormal?one_f:zero_f)}:
             (~ExactZero & (Exp<1) ||
                   (status_int[0]&status_ifp[3]))?z_tiny:
             ((E_Max & Einc_enable) | E_inf)?z_huge:
             (isdenormal & use_denormal == 1)?{sign,zero_e,frac}:
	     {sign,Exp[exp_width-1:0],frac};
  assign status = (status_int[2:1]|(status_int[0]&~status_ifp[3]))?status_ifp_repos:
                  (ExactZero)?8'b00000001:
                  (~ExactZero & (Exp<1) ||
                   (status_int[0] & status_ifp[3]) ||
                   (isdenormal & (use_denormal == 1) & ~|frac))?status_tiny:
                  ((E_Max & Einc_enable) | E_inf)?status_huge:
                  (status_ifp_repos | {2'b00,inexact,1'b0,isdenormal,3'b0});

`undef DW_shift_width

endmodule
