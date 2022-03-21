
////////////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-point format to internal format converter
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_widthi      significand size,  2 to 253 bits
//              exp_widthi      exponent size,     3 to 31 bits
//              sig_widtho      significand size,  sig_widthi to 253 bits
//              exp_widtho      exponent size,     exp_widthi to 31 bits
//              use_denormal    0 or 1  (default 0)
//              use_1scmpl      0 or 1  (default 0)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_widthi + exp_widthi + 1)-bits
//                              Floating-point Number Input
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_widtho + exp_widtho + 7) bits
//                              Internal Floating-point Number
//
// MODIFIED: 
//          11/2008 - included the manipulation of denormals and NaN when 
//                    use_denormal = 1
//
//------------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_fp_ifp_conv (

                   a,
                   z

    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

parameter sig_widthi    = 23;  // RANGE 2 to 253 bits
parameter exp_widthi    = 8;   // RANGE 3 to 31 bits
parameter sig_widtho    = 25;  // RANGE sig_widthi+2 to 253 bits
parameter exp_widtho    = 8;   // RANGE exp_widthi to 31 bits
parameter use_denormal  = 0;    // RANGE 0 or 1
parameter use_1scmpl    = 0;      // RANGE 0 or 1



input  [(sig_widthi+exp_widthi+1)-1:0] a;
output [(sig_widtho+exp_widtho+7)-1:0] z;

wire sign;
wire [exp_widthi-1:0] E;
wire [sig_widthi+1:0] M;
wire [sig_widthi-1:0] F;
wire [sig_widthi-1:0] zero_f;
wire [exp_widthi-1:0] zero_e;
wire [exp_widthi-1:0] InfExp_vec;
wire [7-1:0] status_int;
wire [sig_widthi+1:0] M_compl;
wire [sig_widthi+1:0] M_1scompl;
wire [sig_widthi+1:0] M_2scompl;
wire [sig_widtho+exp_widtho+7-1:0] z_temp;
wire [exp_widtho-1:0] E_adj;
wire [sig_widthi+1:0] M_z;
wire [sig_widtho-1:0] M_ext;
wire denormal_value;
wire [sig_widthi-1:0] F_post;
wire iszero, isinf, isnan;
`define extra_sig_lsbs ((sig_widtho > (sig_widthi+2))?(sig_widtho-sig_widthi-2):1)
`define extra_exp_lsbs ((exp_widtho > exp_widthi)?(exp_widtho-exp_widthi):1)

assign InfExp_vec = ~0;
assign zero_f = 0;
assign zero_e = 0;
assign E = a[sig_widthi+exp_widthi-1:sig_widthi];
assign F = a[sig_widthi-1:0];
assign sign = a[sig_widthi+exp_widthi];
assign iszero = (use_denormal == 0)?~|E:(~|E & ~|F);
assign isinf = (use_denormal == 0)?&E:(&E & ~|F);
assign isnan = (use_denormal == 0)?0:(&E & |F);
assign status_int[0] = iszero;
assign status_int[1] = isinf;
assign status_int[3     ] = 0;
assign status_int[2] = isnan;
assign status_int[5     ] = sign;
assign status_int[6     ] = 1'b0;
assign denormal_value = ~iszero & ~|E;
assign F_post = (iszero | isnan | isinf)?0:F;
assign M = (use_denormal == 0)?{1'b0,1'b1, F}:{1'b0, ~denormal_value, F_post};

assign M_1scompl = ~M;
assign M_2scompl = -$signed(M);
assign M_compl = (sign)?(use_1scmpl?M_1scompl:M_2scompl):M;
assign status_int[4     ] = (use_1scmpl)?(sign & ~(status_int[0]|status_int[1])):0;

assign M_z = (M_compl);

assign E_adj = (use_denormal == 1 && denormal_value)?
                {{exp_widtho-1{1'b0}},1'b1}:
                ((exp_widtho == exp_widthi)?E:{{`extra_exp_lsbs{1'b0}},E});

assign M_ext = (sig_widtho == sig_widthi+2)?M_z:
               (use_1scmpl)?{M_z,{`extra_sig_lsbs{sign}}}:
                            {M_z,{`extra_sig_lsbs{1'b0}}};

assign z_temp = (status_int[0] | status_int[1] | status_int[2])?{status_int,{sig_widtho+exp_widtho{1'b0}}}:{status_int,E_adj,M_ext};
assign z = z_temp;

endmodule
