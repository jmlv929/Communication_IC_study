
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT: Floating-Point Multiplier - Internal format
//
//              DW_ifp_mult calculates the floating-point multiplication
//              while receiving and generating FP values in internal
//              FP format (no normalization).
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_widthi      significand size of the input,  2 to 253 bits
//              exp_widthi      exponent size of the input,     3 to 31 bits
//              sig_widtho      significand size of the output, 2 to 253 bits
//              exp_widtho      exponent size of the output,    3 to 31 bits
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_widthi + exp_widthi + 7)-bits
//                              Internal Floating-point Number Input
//              b               (sig_widthi + exp_widthi + 7)-bits
//                              Internal Floating-point Number Input
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_widtho + exp_widtho + 7)-bits
//                              Internal Floating-point Number Output
//
//	MODIFIED:
//
//-----------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////


module DW_ifp_mult (
  a,
  b,
  z
  // Embedded dc_shell script
  // _model_constraint_2
);

  parameter sig_widthi = 23;      // RANGE 2 TO 253
  parameter exp_widthi = 8;       // RANGE 3 TO 31
  parameter sig_widtho = 23;      // RANGE 2 TO 253
  parameter exp_widtho = 8;       // RANGE 3 TO 31

  input  [exp_widthi + sig_widthi + 6:0] a;
  input  [exp_widthi + sig_widthi + 6:0] b;
  output [exp_widtho + sig_widtho + 6:0] z;


`define M_left (sig_widtho-1)
`define M_z_full_left (2*sig_widtho-1)
`define E_z_left exp_widtho
`define E_a_left (exp_widtho-1)
  wire [7-1:0] status_int;
  wire [7-1:0] status_inpa;
  wire [7-1:0] status_inpb;
  wire [exp_widtho+sig_widtho+7-1:0] z_temp;
  wire nan_a, inf_a, zer_a, stk_a, nan_b, inf_b, zer_b, stk_b;
  wire STK;
  wire [`E_a_left:0] E_a,E_b;
  wire [`E_z_left:0] E_z;
  wire signed [`M_z_full_left:0] M_z_full;
  wire signed [`M_left:0] M_a;  
  wire signed [`M_left:0] M_b;  
  wire sign_a, sign_b, sign_z;
  wire inputa_1scmpl;
  wire inputb_1scmpl;
  wire [sig_widtho-sig_widthi:0] lsext_a_vector;
  wire [sig_widtho-sig_widthi:0] lsext_b_vector;
  wire LS_a_ext, LS_b_ext;
  wire [exp_widtho:0] Bias;
  wire [exp_widtho:0] Bias_std;
  wire [exp_widtho:0] Bias_std_n;

  assign status_inpa = a[sig_widthi+exp_widthi+7-1:sig_widthi+exp_widthi];
  assign status_inpb = b[sig_widthi+exp_widthi+7-1:sig_widthi+exp_widthi];
  assign nan_a = status_inpa[2];
  assign inf_a = status_inpa[1];
  assign stk_a = status_inpa[3     ];
  assign nan_b = status_inpb[2];
  assign inf_b = status_inpb[1];
  assign stk_b = status_inpb[3     ];
  assign inputa_1scmpl = status_inpa[4];
  assign inputb_1scmpl = status_inpb[4];
  assign LS_a_ext = (status_inpa[6     ] & a[0]) |
                    (inputa_1scmpl & a[sig_widthi-1]);
  assign LS_b_ext = (status_inpb[6     ] & b[0]) |
                    (inputb_1scmpl & b[sig_widthi-1]);
  assign lsext_a_vector = {sig_widtho-sig_widthi+1{LS_a_ext}};
  assign lsext_b_vector = {sig_widtho-sig_widthi+1{LS_b_ext}};

  assign zer_a = status_inpa[0] | (~inf_a & ~|a[sig_widthi-1:0]);
  assign zer_b = status_inpb[0] | (~inf_b & ~|b[sig_widthi-1:0]);
 
  assign E_a = (zer_a | status_int[0])?0:
		(exp_widthi < exp_widtho)?
		  {{exp_widtho-exp_widthi{1'b0}},a[sig_widthi+exp_widthi-1:sig_widthi]}:a[sig_widthi+exp_widthi-1:sig_widthi];
  assign E_b = (zer_b | status_int[0])?0:
		(exp_widthi < exp_widtho)?
		  {{exp_widtho-exp_widthi{1'b0}},b[sig_widthi+exp_widthi-1:sig_widthi]}:b[sig_widthi+exp_widthi-1:sig_widthi];
 
  assign M_a = (zer_a)?0:
		(sig_widthi < sig_widtho)?
		   $signed({a[sig_widthi-1:0],lsext_a_vector[sig_widtho-sig_widthi:1]}):
                   $signed(a[sig_widthi-1:0]);
  assign M_b = (zer_b)?0:
		(sig_widthi < sig_widtho)?
		   $signed({b[sig_widthi-1:0],lsext_b_vector[sig_widtho-sig_widthi:1]}):
                   $signed(b[sig_widthi-1:0]);

  assign sign_a = ((zer_a | inf_a) & status_inpa[5     ]) |
           ((~(zer_a | inf_a)) &  M_a[`M_left]);
  assign sign_b = ((zer_b | inf_b) & status_inpb[5     ]) |
            ((~(zer_b | inf_b)) & M_b[`M_left]);
  assign sign_z = sign_a ^ sign_b;

  assign Bias = (1 << (exp_widthi-1))-1;
  assign Bias_std = Bias;
  assign Bias_std_n = ~Bias_std;

  wire [`E_z_left:0] E_z_int;
  assign E_z_int = ({1'b0,E_a} + {1'b0,E_b}) + Bias_std_n + 3;
  wire exp_overflow, exp_underflow;
  assign exp_overflow = E_z_int[`E_z_left] == 1'b1 && status_int[2:0] == 0 && 
                        E_a[`E_a_left] == 1'b1;
  assign exp_underflow = E_z_int[`E_z_left] == 1'b1 && status_int[2:0] == 0 && 
                         E_a[`E_a_left] == 1'b0;
  assign E_z = exp_overflow?{exp_widtho{1'b1}}:(E_z_int);

  assign M_z_full = exp_underflow?0:(M_a * M_b);     

  assign STK = |M_z_full[`M_z_full_left-sig_widtho:0] | stk_a | stk_b;

  assign status_int[2] = nan_a | nan_b |
                                       ((inf_a | inf_b) & (zer_a | zer_b)) ;
  assign status_int[1] = (inf_a | inf_b) & ~status_int[2];
  assign status_int[5     ] = (status_int[1] | 
                                     status_int[0] | exp_underflow)?sign_z:0;
  assign status_int[0] = ((zer_a | zer_b) & ~status_int[1] &
                                    ~status_int[2]);
  assign status_int[4] = 0;
  assign status_int[6     ] = 0;
  assign status_int[3     ] = STK | (exp_underflow & ~zer_a & ~zer_b);

  assign z_temp = {status_int, E_z[exp_widtho-1:0], 
	           M_z_full[`M_z_full_left:`M_z_full_left-sig_widtho+1]};

  assign z =  z_temp;
  
  `undef M_left 
  `undef M_z_full_left
  `undef E_z_left 
  `undef E_a_left 

endmodule
