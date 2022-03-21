
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
//
// ABSTRACT: Floating-point two-operand Adder/Subtractor - Internal Format
//           Computes the addition/subtraction of two FP numbers. 
//           The format of the FP numbers is defined by the number of bits 
//           in the significand (sig_width) and the number of bits in the 
//           exponent (exp_width), for both the inputs and output.
//           The total number of bits in the FP number is sig_width+exp_width+5
//           since the status information is attached to the representation
//           and it takes 5 bits.
//           Subtraction is forced when op=1.
//           No rounding input is used in this case.
//           Althought rounding is not done, the sign of zeros requires this
//           information.
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_widthi      significand size for input,  2 to 253 bits
//              exp_widthi      exponent size for input,     3 to 31 bits
//              sig_widtho      significand size for output, 2 to 253 bits
//              exp_widtho      exponent size for output,    3 to 31 bits
//              use_denormal    0 or 1  (default 0)
//              use_1scmpl      0 or 1  (default 0)
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_widthi + exp_widthi + 5)-bits
//                              Floating-point Number Input
//              b               (sig_widthi + exp_widthi + 5)-bits
//                              Floating-point Number Input
//              op              1 bit
//                              add/sub control: 0 for add - 1 for sub
//              rnd             3 bits
//                              Rounding mode
//
//              Output ports    Size & Description
//              ===========     ==================
//              z               (sig_widtho + exp_widtho + 5) bits
//                              Floating-point Number result
//
//
// MODIFIED: 
//
//-----------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////// 

module DW_ifp_addsub (

                   a,
                   b,
                   op,
                   rnd,
                   z

    // Embedded dc_shell script
    // _model_constraint_1
    // set_attribute current_design "enable_dp_opt" "TRUE" -type "boolean" -quiet
);

parameter sig_widthi    = 23;  // RANGE 2 to 253 bits
parameter exp_widthi    = 8;   // RANGE 3 to 31 bits
parameter sig_widtho    = 23;  // RANGE sig_widthi to 253 bits
parameter exp_widtho    = 8;   // RANGE exp_widthi to 31 bits
parameter use_denormal  = 0;   // RANGE 0 or 1
parameter use_1scmpl    = 0;   // RANGE 0 or 1

`define  DW_shift_width  (((sig_widtho+1)>256)?(((sig_widtho+1)>4096)?(((sig_widtho+1)>16384)?(((sig_widtho+1)>32768)?16:15):(((sig_widtho+1)>8192)?14:13)):(((sig_widtho+1)>1024)?(((sig_widtho+1)>2048)?12:11):(((sig_widtho+1)>512)?10:9))):(((sig_widtho+1)>16)?(((sig_widtho+1)>64)?(((sig_widtho+1)>128)?8:7):(((sig_widtho+1)>32)?6:5)):(((sig_widtho+1)>4)?(((sig_widtho+1)>8)?4:3):(((sig_widtho+1)>2)?2:1))))

input  [(sig_widthi+exp_widthi+7)-1:0] a,b;
input  op; 
input  [2:0] rnd;
output [(sig_widtho+exp_widtho+7)-1:0] z;


wire sign_c;
wire [exp_widtho-1:0] mag_exp_diff;
wire swap;
wire [sig_widtho-1:0] sig_large;
wire [sig_widtho-1:0] sig_small;
wire [exp_widtho-1:0] exp_large;
wire [exp_widtho-1:0] e_z;
wire [exp_widtho:0] E1;
wire sign_large;
wire sign_small;
wire signed [sig_widtho:0] m_large, m_small, m_small_n;
wire signed [sig_widthi:0] m_a, m_b, m_b_int;
wire [exp_widthi-1:0] exp_a, exp_b;
wire sign_a, sign_b;
wire [sig_widthi:0] ma_int, mb_int;
wire signed [(sig_widtho+1):0] adder_input1;
wire signed [(sig_widtho+1):0] adder_input2;
wire signed [2:0] adder_input3;
wire signed [(sig_widtho+1)-1:0] m_z;
wire signed [(sig_widtho+1):0] adder_output;
wire denormal_large, denormal_small;
wire nan_a, nan_b;
wire inf_a, inf_b;
wire zer_a, zer_b, zer_large, zer_small;
wire stk_a, stk_b;
wire STK;
wire eff_sub;
wire inpa_1scmpl, inpb_1scmpl;
wire sign_zero;
wire LS_large_ext, LS_small_ext;
wire status_lsext_large, status_lsext_small;
wire [7-1:0] status_int;
wire [7-1:0] status_inpa;
wire [7-1:0] status_inpb;
wire [exp_widtho-1:0] SH_limited;
wire [(sig_widtho+1)-1:0] mask;
wire [(sig_widtho+1)-1:0] masked_op;
wire [(sig_widtho+1)-1:0] one_vector;
wire sticky_bit2;
wire signed [(sig_widtho+1):0] m_small_shifted_with_sticky;
wire signed [(sig_widtho+1)-1:0] m_small_shifted;
assign m_a = $signed({a[sig_widthi-1],a[sig_widthi-1:0]});
assign exp_a = a[exp_widthi+sig_widthi-1:sig_widthi] & ~{exp_widthi{zer_a}};
assign sign_a = a[sig_widthi-1];
assign m_b = $signed({b[sig_widthi-1],b[sig_widthi-1:0]});
assign exp_b = b[exp_widthi+sig_widthi-1:sig_widthi] & ~{exp_widthi{zer_b}};
assign sign_b = b[sig_widthi-1];
assign status_inpa = a[sig_widthi+exp_widthi+7-1:sig_widthi+exp_widthi];
assign status_inpb = b[sig_widthi+exp_widthi+7-1:sig_widthi+exp_widthi];
assign zer_a = status_inpa[0] | (~inf_a & ~nan_a & ~|a[sig_widthi-1:0]);
assign zer_b = status_inpb[0] | (~inf_b & ~nan_b & ~|b[sig_widthi-1:0]);
assign inf_a = status_inpa[1];
assign inf_b = status_inpb[1];
assign nan_a = status_inpa[2];
assign nan_b = status_inpb[2];
assign stk_a = status_inpa[3     ];
assign stk_b = status_inpb[3     ];

assign m_b_int = (use_1scmpl)?-m_b-1:-m_b;
assign ma_int = {m_a};
assign mb_int = (op)?{m_b_int}:{m_b};

assign swap = (a[exp_widthi+sig_widthi-1:sig_widthi] < b[exp_widthi+sig_widthi-1:sig_widthi]);
wire [sig_widthi:0] large_n;
assign large_n = ~(swap ? mb_int : ma_int);
wire [sig_widthi:0] small_n;
assign small_n = ~(swap ? ma_int : mb_int);
wire [sig_widthi:0] large_p;
assign large_p = ~large_n;
wire [sig_widthi:0] small_p;
assign small_p = ~small_n;   

wire large_1scmpl;
assign large_1scmpl = (use_1scmpl)?((swap)?status_inpb[4]^op:
                                         status_inpa[4]):0;
wire small_1scmpl;
assign small_1scmpl = (use_1scmpl)?((swap)?status_inpa[4]:
                                         status_inpb[4]^op):0;

assign sign_large = large_p[sig_widthi];
assign sign_small = small_p[sig_widthi];
assign exp_large  = ((swap & ~zer_b) | (~swap & zer_a))?exp_b:exp_a;
assign {status_lsext_large,status_lsext_small} =
               (swap)?{status_inpb[6     ],status_inpa[6     ]}:
                      {status_inpa[6     ],status_inpb[6     ]};
assign LS_large_ext = (status_lsext_large & large_p[0]) |
                      (large_1scmpl & sign_large);
assign LS_small_ext = (status_lsext_small & small_p[0]) |
                      (small_1scmpl & sign_small);

assign m_large  = (sig_widthi < sig_widtho)?
                  $signed({large_p[sig_widthi:0]&~{sig_widthi+1{zer_large}},{sig_widtho-sig_widthi{LS_large_ext}}}):
                  $signed(large_p[sig_widthi:0]);
assign m_small  = (sig_widthi < sig_widtho)?
                  $signed({small_p[sig_widthi:0]&~{sig_widthi+1{zer_small}},{sig_widtho-sig_widthi{LS_small_ext}}}):
                  $signed(small_p[sig_widthi:0]);
assign m_small_n  = (sig_widthi < sig_widtho)?
                    $signed({small_n[sig_widthi:0],{sig_widtho-sig_widthi{~LS_small_ext}}}):
                  $signed(small_n[sig_widthi:0]);

assign zer_large = (swap)?zer_b:zer_a;
assign zer_small = (swap)?zer_a:zer_b;
assign sign_zero = (zer_small && zer_large)?
                     ((status_inpa[5     ] ^ status_inpb[5     ] ^ op)?
                        ((rnd == 3)?1'b1:1'b0):status_inpa[5     ]):
                     (~STK?(rnd == 3):0);

assign eff_sub = sign_large ^ sign_small;

assign mag_exp_diff = (zer_a | zer_b)?0:(swap?$unsigned(-$signed(exp_a - exp_b)):(exp_a - exp_b));


assign SH_limited = mag_exp_diff;
assign m_small_shifted = m_small >>> SH_limited;
assign one_vector = {(sig_widtho+1){1'b1}};
assign mask = ~(one_vector << SH_limited);
assign masked_op = (use_1scmpl)?(mask & ((small_1scmpl?$unsigned(m_small_n):$unsigned(m_small)))) : mask & $unsigned(m_small);
assign sticky_bit2 = |masked_op & ~zer_small;
assign STK = sticky_bit2;
assign m_small_shifted_with_sticky = $signed({m_small_shifted,STK});

assign adder_input1 = $signed({m_large,large_1scmpl});  
assign adder_input2 = m_small_shifted_with_sticky;
assign adder_input3 = $signed({1'b0,small_1scmpl,large_1scmpl});
assign adder_output = adder_input1 + adder_input2 + adder_input3;
assign m_z = $signed(adder_output[sig_widtho+1:1]);
wire  zero_mz;
assign zero_mz = ~|m_z;

wire sign_infinity;
assign sign_infinity = (inf_a)?status_inpa[5     ]:((inf_b)?(status_inpb[5     ] ^ op):1'b0);
assign E1 = exp_large + 1;
assign e_z = E1;
wire exp_overflow;
assign exp_overflow = (~e_z[exp_widtho-1] & exp_large[exp_widtho-1]);

assign z = {status_int,e_z,m_z[sig_widtho:1]};
wire diff_inf_signs;
assign diff_inf_signs = status_inpa[5     ] ^ status_inpb[5     ] ^ op;
assign status_int[2]  = (inf_a & inf_b & diff_inf_signs) | (nan_a | nan_b);
assign status_int[0]     = (zer_large & zer_small);
assign status_int[1] = ((inf_a | inf_b) & ~status_int[2]) | exp_overflow;
assign status_int[3     ]  = (STK | stk_a | stk_b | m_z[0]) & ~(inf_b | inf_a | nan_a | nan_b);
assign status_int[4]  = 1'b0;
assign status_int[5     ] = (zer_large & zer_small)?sign_zero:
                                  (zero_mz & ~(zer_large | zer_small) & 
                                   ~status_int[1] &
                                   ~status_int[2])?(rnd == 3):
                                  ((status_int[1] & 
                                   ~status_int[2])?sign_infinity:
                                                                 1'b0);
assign status_int[6     ] = ((eff_sub | (sign_large & sign_small))& STK) | (zer_b & status_inpa[6     ]) | (zer_a & status_inpb[6     ]);

`undef DW_shift_width

endmodule
