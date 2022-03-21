////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 1999 - 2012 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Rick Kelly         Sep. 14, 1999
//
// VERSION:   Verilog Synthesis Architecture
//
// DesignWare_version: 9ae6d00f
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: 8b/10b Decoder
//
//              Parameters:     Valid Values
//              ==========      ============
//              bytes   	[ 1 to 16 ]
//              k28_5_only      [ 0 to 1 ] (0 = all 12 special characters decoded
//				            1 = K28.5 available only (other special characters are flagged as errors))
//              en_mode       	[ 0 to 1 ] (0 = enable input is disconnected (stalls registers)
//				            1 = enable input is connected (processes inputs based on state of enable input))
//              init_mode  	[ 0 to 1 ] (0 = init_rd_val input is registered before being applied to data in
//				            1 = init_rd_val input is not registered before being applied to data in)
//              rst_mode        [ 0 to 1 ] (0 = asynchronous reset
//                                          1 = synchronous reset)
//              op_iso_mode     [ 0 to 4 ] (0 = Follow intent defined by Power Compiler user setting
//                                          1 = no operand isolation
//                                          2 = 'and' gate isolaton
//                                          3 = 'or' gate isolation
//                                          4 = preferred isolation style: 'and' gate)
//
//              Input Ports:    Size    Description
//              ===========     ====    ===========
//	        clk 	        1 bit   Input Clock
//	        rst_n 	        1 bit   Active Low Asynchronous Reset
//	        init_rd_n       1 bit	Active Low Running Disparity initialization control
//	        init_rd_val     1 bit   Running Disparity initial value applied when init_rd_n active
//	        data_in 	T bits  Input data bus (ten bits per byte)
//	        enable	        1 bit   Active High Enable to process data_in
//
//              Output Ports    Size    Description
//              ============    ====    ===========
//	        error           1 bit 	Active High Error Flag
//	        rd 		1 bit   Current Running Disparity state
//	        k_char 	        B bits  Active High Special character status bus (one status bit per data byte)
//	        data_out 	E bits  Decoded output data bus (eight bits per byte)
//	        rd_err 	        1 bit   Active High Running Disparity Error Flag
//	        code_err 	1 bit   Active High Code violation error Flag
//	        rd_err_bus      B bits  Byte Specific Running Disparity Error Bus
//	        code_err_bus 	B bits  Byte Specific Code violation error Bus
//
//
// MODIFICATIONS:
//	8/23/04	RJK
//	Corrected interpretation of coding versus RD error
//	in separate output flags (code_err vs. rd_err)
//	STAR #9000024623
//
//	8/18/04 Doug Lee
//	Enhancement : Added init_mode paramter
//
//	8/1/05 RJK
//	Enhancement : Added byte-specific RD and code
//      error output ports (rd_err_bus & code_err_bus)
//
//	11/18/05 RJK
//	Corrected improper propagation of disparity errors
//	STAR 9000092772
//
//      2/19/08  DLL
//      Added copyright banner and 'op_iso_mode' parameter
//      to following 'lpwr' architecture.
//
//      5/19/08   RJK
//      Updated coding to eliminate 'missing signal in
//      sensitivity list` warnings
//
//      10/6/08  RJK
//      Added rst_mode parameter to select reset type
//      (STAR 9000270234)
//
//	7/6/11 RJK
//	Updates for Leda message elimination
//
//	9/22/11 DLL
//	Changed position of "k_char" in the port ordering.
//      This addresses STAR#9000493562.
//
////////////////////////////////////////////////////////////////////////////////

  module DW_8b10b_dec(
	    clk,
	    rst_n,
	    init_rd_n,
	    init_rd_val,
	    data_in,

	    error,
	    rd,
	    k_char,
	    data_out,
	    rd_err,
	    code_err,

	    enable,

	    rd_err_bus,
	    code_err_bus
	    );


    parameter bytes = 2;	// number of bytes decode per clock cycle

    parameter k28_5_only = 0;	// special character control mode

    parameter en_mode = 0;	// enable mode

    parameter init_mode = 0;	// initialization mode
    parameter rst_mode = 0;	// reset mode


    parameter op_iso_mode = 0;  // operand isolation mode

input			clk;		// clock input
input			rst_n;		// active low reset
input			init_rd_n;	// active low running disp. force control
input			init_rd_val;	// running disp. value to be forced
input  [bytes*10-1:0]	data_in;	// data to be decoded (10 bits per byte)
output			error;		// "any error" status flag
output			rd;		// current running disparity state
output [bytes-1:0]	k_char;		// special character decode status bus
output [bytes*8-1:0]	data_out;	// decoded output data (8 bits per byte)
output			rd_err;		// running displarity error status flag
output			code_err;	// code violation error status flag
input			enable;		// register enabl input (NC when en_mode = 0)
output [bytes-1:0]	rd_err_bus;	// byte specific running disparity error flag bus
output [bytes-1:0]	code_err_bus;	// byte specific code error flag bus

reg [bytes*8-1:0] data_out_int_a;
reg [bytes-1:0] k_char_int_a;
reg error_int_a, rd_int_a;
reg rd_err_int_a, code_err_int_a;
reg [bytes-1:0] rd_err_bus_int_a, code_err_bus_int_a;
reg [bytes*8-1:0] data_out_int_s;
reg [bytes-1:0] k_char_int_s;
reg error_int_s, rd_int_s;
reg rd_err_int_s, code_err_int_s;
reg [bytes-1:0] rd_err_bus_int_s, code_err_bus_int_s;
wire [bytes*8-1:0] data_out_int;
wire [bytes-1:0] k_char_int;
wire error_int, rd_int;
wire rd_err_int, code_err_int;
wire [bytes-1:0] rd_err_bus_int, code_err_bus_int;

localparam [1:0] k28_5_only_set = k28_5_only;

reg  [bytes*8-1:0] data_out_int_din;
reg  [bytes-1:0] error_code, k_char_int_din, error_rd;
reg  rd_carry;
wire error_int_din, rd_int_din;
wire rd_err_int_din, code_err_int_din;
wire enable_int;
wire rd_int_selected;



generate
  if (en_mode == 0) begin :	GEN_em_eq_0
    assign enable_int = 1'b1;
  end else begin :		GEN_em_ne_0
    assign enable_int = enable;
  end
endgenerate

generate
  if (init_mode == 0) begin :	GEN_im_eq_0
    assign rd_int_selected = rd_int;
    assign rd_int_din = (init_rd_n == 1'b1)? rd_carry : init_rd_val;
  end else begin :		GEN_im_ne_0
    assign rd_int_selected = (init_rd_n == 1'b0)? init_rd_val : rd_int;
    assign rd_int_din = rd_carry;
  end
endgenerate


    assign data_out = data_out_int;
    assign k_char   = k_char_int;
    assign rd       = rd_int;
    assign error    = error_int;
    assign rd_err   = rd_err_int;
    assign code_err = code_err_int;
    assign rd_err_bus   = rd_err_bus_int;
    assign code_err_bus = code_err_bus_int;

    assign data_out_int = (rst_mode==0)? data_out_int_a : data_out_int_s;
    assign k_char_int   = (rst_mode==0)? k_char_int_a : k_char_int_s;
    assign rd_int       = (rst_mode==0)? rd_int_a : rd_int_s;
    assign error_int    = (rst_mode==0)? error_int_a : error_int_s;
    assign rd_err_int   = (rst_mode==0)? rd_err_int_a : rd_err_int_s;
    assign code_err_int = (rst_mode==0)? code_err_int_a : code_err_int_s;
    assign rd_err_bus_int   = (rst_mode==0)? rd_err_bus_int_a : rd_err_bus_int_s;
    assign code_err_bus_int = (rst_mode==0)? code_err_bus_int_a : code_err_bus_int_s;


    always @ (data_in or rd_int_selected) begin : PROC_decode
	integer byte_id, in_bit_base, out_bit_base, pre_bit_base;
	reg  [bytes-1:0] pt_1, pt_2, pt_3, pt_4, pt_5, pt_6, pt_7, pt_8, pt_9;
	reg  [bytes-1:0] pt_10, pt_11, pt_12, pt_13, pt_14, pt_15, pt_16, pt_17, pt_18, pt_19;
	reg  [bytes-1:0] pt_20, pt_21, pt_22, pt_23, pt_24, pt_25, pt_26, pt_27, pt_28, pt_29;
	reg  [bytes-1:0] pt_30, pt_31, pt_32, pt_33, pt_34, pt_35, pt_36, pt_37, pt_38, pt_39;
	reg  [bytes-1:0] pt_40, pt_41, pt_42, pt_43, pt_44, pt_45, pt_46, pt_47, pt_48, pt_49;
	reg  [bytes-1:0] pt_50, pt_51, pt_52, pt_53, pt_54, pt_55, pt_56, pt_57, pt_58, pt_59;
	reg  [bytes-1:0] pt_60, pt_61, pt_62, pt_63, pt_64, pt_65, pt_66, pt_67, pt_68, pt_69;
	reg  [bytes-1:0] pt_70, pt_71, pt_72, pt_73, pt_74, pt_75, pt_76, pt_77, pt_78, pt_79;
	reg  [bytes-1:0] pt_80, pt_81, pt_82, pt_83, pt_84, pt_85, pt_86, pt_87, pt_88, pt_89;
	reg  [bytes-1:0] pt_90, pt_91, pt_92, pt_93, pt_94, pt_95, pt_96, pt_97, pt_98, pt_99;
	reg  [bytes-1:0] pt_100, pt_101, pt_102, pt_103, pt_104, pt_105, pt_106, pt_107, pt_108, pt_109;
	reg  [bytes-1:0] pt_110, pt_111, pt_112, pt_113, pt_114, pt_115, pt_116, pt_117, pt_118, pt_119;
	reg  [bytes-1:0] pt_120, pt_121, pt_122, pt_123, pt_124, pt_125, pt_126, pt_127, pt_128, pt_129;
	reg  [bytes-1:0] pt_130, pt_131, pt_132, pt_133, pt_134, pt_135, pt_136, pt_137, pt_138, pt_139;
	reg  [bytes-1:0] pt_140, pt_141, pt_142, pt_143, pt_144, pt_145, pt_146, pt_147, pt_148, pt_149;
	reg  [bytes-1:0] pt_150, pt_151, pt_152, pt_153, pt_154, pt_155, pt_156, pt_157, pt_158, pt_159;
	reg  [bytes-1:0] pt_160, pt_161, pt_162;
	reg  [bytes*3-1:0] datpreout;
	reg  [bytes-1:0] alw_kx_7, d111314, d171820;
	reg  [bytes-1:0] dx_7, error_hi, error_lo, invert_567, invrt_if_k28;
	reg  [bytes-1:0] k28_x, kx_5, kx_7, lo_f_bal_hi, lo_f_bal_lo;
	reg  [bytes-1:0] unbal_hi_0, unbal_hi_1, unbal_lo_0, unbal_lo_1;
	reg  [bytes:0] rd_thread;

	rd_thread[0] = rd_int_selected;

	for (byte_id=0; byte_id < bytes ; byte_id=byte_id+1) begin
	    in_bit_base = (10*(bytes-1-byte_id));
	    pre_bit_base = (3*(bytes-1-byte_id));
	    out_bit_base = (8*(bytes-1-byte_id));




	
	    pt_1[byte_id] = ( ~data_in[in_bit_base+3] & data_in[in_bit_base+1] & data_in[in_bit_base+0]);
	    pt_2[byte_id] = ( data_in[in_bit_base+3] & ~data_in[in_bit_base+0]);
	    pt_3[byte_id] = ( ~data_in[in_bit_base+2] & ~data_in[in_bit_base+1]);
	    pt_4[byte_id] = ( data_in[in_bit_base+3] & ~data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_5[byte_id] = ( ~data_in[in_bit_base+3] & data_in[in_bit_base+0]);
	    pt_6[byte_id] = ( data_in[in_bit_base+2] & data_in[in_bit_base+1]);
	    pt_7[byte_id] = ( ~data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & ~data_in[in_bit_base+1]);
	    pt_8[byte_id] = ( data_in[in_bit_base+3] & data_in[in_bit_base+2] & data_in[in_bit_base+0]);
	    pt_9[byte_id] = ( ~data_in[in_bit_base+2] & ~data_in[in_bit_base+0]);
	    pt_10[byte_id] = ( ~data_in[in_bit_base+2] & ~data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_11[byte_id] = ( ~data_in[in_bit_base+3] & ~data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_12[byte_id] = ( ~data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & ~data_in[in_bit_base+0]);
	    pt_13[byte_id] = ( data_in[in_bit_base+3] & data_in[in_bit_base+2] & data_in[in_bit_base+1]);
	    pt_14[byte_id] = ( data_in[in_bit_base+3] & data_in[in_bit_base+1] & data_in[in_bit_base+0]);
	    pt_15[byte_id] = ( data_in[in_bit_base+2] & data_in[in_bit_base+1] & data_in[in_bit_base+0]);
	    pt_16[byte_id] = ( data_in[in_bit_base+3] & data_in[in_bit_base+2] & ~data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_17[byte_id] = ( ~data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & data_in[in_bit_base+1] & data_in[in_bit_base+0]);
	    pt_18[byte_id] = ( data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_19[byte_id] = ( ~data_in[in_bit_base+3] & data_in[in_bit_base+2] & ~data_in[in_bit_base+1] & data_in[in_bit_base+0]);
	    pt_20[byte_id] = ( ~data_in[in_bit_base+3] & data_in[in_bit_base+2] & data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_21[byte_id] = ( data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & ~data_in[in_bit_base+1] & data_in[in_bit_base+0]);
	    pt_22[byte_id] = ( data_in[in_bit_base+4] & data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_23[byte_id] = ( ~data_in[in_bit_base+4] & ~data_in[in_bit_base+3] & data_in[in_bit_base+2] & ~data_in[in_bit_base+1] & data_in[in_bit_base+0]);
	    pt_24[byte_id] = ( data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & ~data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_25[byte_id] = ( ~data_in[in_bit_base+3] & data_in[in_bit_base+2] & data_in[in_bit_base+1] & data_in[in_bit_base+0]);
	    pt_26[byte_id] = ( data_in[in_bit_base+3] & data_in[in_bit_base+2] & data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_27[byte_id] = ( ~data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & ~data_in[in_bit_base+1] & data_in[in_bit_base+0]);
	    pt_28[byte_id] = ( ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4] & ~data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & ~data_in[in_bit_base+1]);
	    pt_29[byte_id] = ( data_in[in_bit_base+5] & data_in[in_bit_base+4] & data_in[in_bit_base+3] & data_in[in_bit_base+2] & data_in[in_bit_base+1]);
	    pt_30[byte_id] = ( ~data_in[in_bit_base+3] & ~data_in[in_bit_base+2] & ~data_in[in_bit_base+1] & ~data_in[in_bit_base+0]);
	    pt_31[byte_id] = ( data_in[in_bit_base+3] & data_in[in_bit_base+2] & data_in[in_bit_base+1] & data_in[in_bit_base+0]);


	    datpreout[pre_bit_base+0] = pt_1[byte_id] | pt_2[byte_id] | pt_3[byte_id];

	    datpreout[pre_bit_base+1] = pt_4[byte_id] | pt_5[byte_id] | pt_6[byte_id];

	    datpreout[pre_bit_base+2] = pt_7[byte_id] | pt_8[byte_id] | pt_6[byte_id] | pt_9[byte_id];

	    unbal_lo_0[byte_id] = pt_10[byte_id] | pt_11[byte_id] | pt_12[byte_id] | pt_7[byte_id];

	    unbal_lo_1[byte_id] = pt_13[byte_id] | pt_8[byte_id] | pt_14[byte_id] | pt_15[byte_id];

	    lo_f_bal_lo[byte_id] = pt_16[byte_id] | pt_17[byte_id];

	    invrt_if_k28[byte_id] = pt_18[byte_id] | pt_19[byte_id] | pt_20[byte_id] | pt_21[byte_id];

	    kx_5[byte_id] = pt_22[byte_id] | pt_23[byte_id];

	    kx_7[byte_id] = pt_24[byte_id] | pt_25[byte_id];

	    dx_7[byte_id] = pt_26[byte_id] | pt_27[byte_id];

	    error_lo[byte_id] = pt_28[byte_id] | pt_29[byte_id] | pt_30[byte_id] | pt_31[byte_id];





	    pt_32[byte_id] = ( data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_33[byte_id] = ( ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5]);
	    pt_34[byte_id] = ( data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+6] & data_in[in_bit_base+5]);
	    pt_35[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_36[byte_id] = ( data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+4]);
	    pt_37[byte_id] = ( data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_38[byte_id] = ( ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_39[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_40[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+7] & ~data_in[in_bit_base+4]);
	    pt_41[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_42[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+4]);
	    pt_43[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+7] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_44[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+4]);
	    pt_45[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+7] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_46[byte_id] = ( data_in[in_bit_base+9] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_47[byte_id] = ( ~data_in[in_bit_base+9] & data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_48[byte_id] = ( data_in[in_bit_base+8] & data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_49[byte_id] = ( data_in[in_bit_base+8] & data_in[in_bit_base+6] & ~data_in[in_bit_base+4]);
	    pt_50[byte_id] = ( data_in[in_bit_base+8] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_51[byte_id] = ( ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_52[byte_id] = ( ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+5]);
	    pt_53[byte_id] = ( ~data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_54[byte_id] = ( data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5]);
	    pt_55[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+6] & data_in[in_bit_base+4]);
	    pt_56[byte_id] = ( ~data_in[in_bit_base+9] & data_in[in_bit_base+8] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_57[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & data_in[in_bit_base+6] & data_in[in_bit_base+4]);
	    pt_58[byte_id] = ( data_in[in_bit_base+7] & data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_59[byte_id] = ( data_in[in_bit_base+8] & data_in[in_bit_base+6] & data_in[in_bit_base+5]);
	    pt_60[byte_id] = ( data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5]);
	    pt_61[byte_id] = ( data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+4]);
	    pt_62[byte_id] = ( data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_63[byte_id] = ( ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_64[byte_id] = ( ~data_in[in_bit_base+9] & data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+5]);
	    pt_65[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & ~data_in[in_bit_base+5]);
	    pt_66[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_67[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+4]);
	    pt_68[byte_id] = ( data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_69[byte_id] = ( data_in[in_bit_base+6] & data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_70[byte_id] = ( data_in[in_bit_base+7] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_71[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+4]);
	    pt_72[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+6] & data_in[in_bit_base+4]);
	    pt_73[byte_id] = ( data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+4]);
	    pt_74[byte_id] = ( ~data_in[in_bit_base+9] & data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+4]);
	    pt_75[byte_id] = ( ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & data_in[in_bit_base+4]);
	    pt_76[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & data_in[in_bit_base+4]);
	    pt_77[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+5]);
	    pt_78[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+5]);
	    pt_79[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+7] & data_in[in_bit_base+5]);
	    pt_80[byte_id] = ( data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+5]);
	    pt_81[byte_id] = ( ~data_in[in_bit_base+8] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_82[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_83[byte_id] = ( ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_84[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_85[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_86[byte_id] = ( ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+4]);
	    pt_87[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+4]);
	    pt_88[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+4]);
	    pt_89[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+4]);
	    pt_90[byte_id] = ( ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5]);
	    pt_91[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5]);
	    pt_92[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5]);
	    pt_93[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6]);
	    pt_94[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6]);
	    pt_95[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+5]);
	    pt_96[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+6] & data_in[in_bit_base+5]);
	    pt_97[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5]);
	    pt_98[byte_id] = ( data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5]);
	    pt_99[byte_id] = ( data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_100[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_101[byte_id] = ( data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_102[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_103[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_104[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_105[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_106[byte_id] = ( ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_107[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_108[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_109[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_110[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_111[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_112[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_113[byte_id] = ( data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_114[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_115[byte_id] = ( data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_116[byte_id] = ( ~data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_117[byte_id] = ( data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_118[byte_id] = ( ~data_in[in_bit_base+9] & data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_119[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_120[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_121[byte_id] = ( data_in[in_bit_base+9] & data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_122[byte_id] = ( data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_123[byte_id] = ( ~data_in[in_bit_base+9] & data_in[in_bit_base+8] & data_in[in_bit_base+7] & data_in[in_bit_base+6] & data_in[in_bit_base+5] & ~data_in[in_bit_base+4]);
	    pt_124[byte_id] = ( data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_125[byte_id] = ( ~data_in[in_bit_base+9] & data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_126[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & data_in[in_bit_base+7] & ~data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);
	    pt_127[byte_id] = ( ~data_in[in_bit_base+9] & ~data_in[in_bit_base+8] & ~data_in[in_bit_base+7] & data_in[in_bit_base+6] & ~data_in[in_bit_base+5] & data_in[in_bit_base+4]);


	    data_out_int_din[out_bit_base+0] = pt_32[byte_id] | pt_33[byte_id] | pt_34[byte_id] | pt_35[byte_id] |
			pt_36[byte_id] | pt_37[byte_id] | pt_38[byte_id] | pt_39[byte_id] |
			pt_40[byte_id];

	    data_out_int_din[out_bit_base+1] = pt_41[byte_id] | pt_42[byte_id] | pt_43[byte_id] | pt_44[byte_id] |
			pt_45[byte_id] | pt_46[byte_id] | pt_47[byte_id] | pt_48[byte_id] |
			pt_49[byte_id];

	    data_out_int_din[out_bit_base+2] = pt_50[byte_id] | pt_51[byte_id] | pt_52[byte_id] | pt_53[byte_id] |
			pt_54[byte_id] | pt_55[byte_id] | pt_56[byte_id] | pt_57[byte_id] |
			pt_58[byte_id] | pt_40[byte_id];

	    data_out_int_din[out_bit_base+3] = pt_59[byte_id] | pt_60[byte_id] | pt_61[byte_id] | pt_62[byte_id] |
			pt_63[byte_id] | pt_64[byte_id] | pt_65[byte_id] | pt_66[byte_id] |
			pt_45[byte_id] | pt_67[byte_id] | pt_68[byte_id] | pt_69[byte_id];

	    data_out_int_din[out_bit_base+4] = pt_51[byte_id] | pt_70[byte_id] | pt_71[byte_id] | pt_72[byte_id] |
			pt_73[byte_id] | pt_74[byte_id] | pt_75[byte_id] | pt_76[byte_id] |
			pt_77[byte_id] | pt_78[byte_id] | pt_79[byte_id] | pt_80[byte_id];

	    unbal_hi_0[byte_id] = pt_51[byte_id] | pt_81[byte_id] | pt_82[byte_id] | pt_83[byte_id] |
			pt_84[byte_id] | pt_85[byte_id] | pt_86[byte_id] | pt_87[byte_id] |
			pt_88[byte_id] | pt_89[byte_id] | pt_90[byte_id] | pt_91[byte_id] |
			pt_92[byte_id] | pt_78[byte_id] | pt_93[byte_id];

	    unbal_hi_1[byte_id] = pt_94[byte_id] | pt_95[byte_id] | pt_96[byte_id] | pt_97[byte_id] |
			pt_98[byte_id] | pt_67[byte_id] | pt_55[byte_id] | pt_44[byte_id] |
			pt_36[byte_id] | pt_66[byte_id] | pt_45[byte_id] | pt_99[byte_id] |
			pt_100[byte_id] | pt_50[byte_id] | pt_101[byte_id];

	    lo_f_bal_hi[byte_id] = pt_102[byte_id] | pt_103[byte_id];

	    k28_x[byte_id] = pt_104[byte_id] | pt_105[byte_id];

	    error_hi[byte_id] = pt_93[byte_id] | pt_106[byte_id] | pt_107[byte_id] | pt_108[byte_id] |
			pt_109[byte_id] | pt_94[byte_id] | pt_110[byte_id] | pt_111[byte_id] |
			pt_112[byte_id] | pt_113[byte_id];

	    d111314[byte_id] = pt_114[byte_id] | pt_115[byte_id] | pt_116[byte_id];

	    d171820[byte_id] = pt_117[byte_id] | pt_118[byte_id] | pt_119[byte_id];

	    alw_kx_7[byte_id] = pt_104[byte_id] | pt_120[byte_id] | pt_121[byte_id] | pt_122[byte_id] |
			pt_123[byte_id] | pt_124[byte_id] | pt_125[byte_id] | pt_126[byte_id] |
			pt_127[byte_id] | pt_105[byte_id];





	    
	    pt_128[byte_id] = ( rd_thread[byte_id] & ~unbal_hi_0[byte_id] & ~lo_f_bal_hi[byte_id] & invrt_if_k28[byte_id]);
	    pt_129[byte_id] = ( ~data_in[in_bit_base+9] & lo_f_bal_hi[byte_id] & invrt_if_k28[byte_id]);
	    pt_130[byte_id] = ( ~data_in[in_bit_base+3] & lo_f_bal_lo[byte_id]);
	    pt_131[byte_id] = ( unbal_hi_1[byte_id] & invrt_if_k28[byte_id]);
	    pt_132[byte_id] = ( unbal_lo_1[byte_id]);


	    pt_135[byte_id] = ( alw_kx_7[byte_id] & kx_7[byte_id] & ~k28_5_only_set[0]);
	    pt_136[byte_id] = ( k28_x[byte_id] & kx_5[byte_id]);
	    pt_137[byte_id] = ( k28_x[byte_id] & ~k28_5_only_set[0]);
	    pt_138[byte_id] = ( data_in[in_bit_base+9] & lo_f_bal_hi[byte_id] & ~data_in[in_bit_base+3] & lo_f_bal_lo[byte_id]);
	    pt_139[byte_id] = ( ~data_in[in_bit_base+9] & lo_f_bal_hi[byte_id] & data_in[in_bit_base+3] & lo_f_bal_lo[byte_id]);
	    pt_140[byte_id] = ( ~d111314[byte_id] & ~d171820[byte_id] & ~alw_kx_7[byte_id] & kx_7[byte_id]);
	    pt_141[byte_id] = ( alw_kx_7[byte_id] & kx_7[byte_id] & k28_5_only_set[0]);
	    pt_142[byte_id] = ( ~data_in[in_bit_base+9] & lo_f_bal_hi[byte_id] & unbal_lo_1[byte_id]);
	    pt_143[byte_id] = ( data_in[in_bit_base+9] & lo_f_bal_hi[byte_id] & unbal_lo_0[byte_id]);
	    pt_144[byte_id] = ( k28_x[byte_id] & ~kx_5[byte_id] & k28_5_only_set[0]);
	    pt_145[byte_id] = ( d111314[byte_id] & ~data_in[in_bit_base+3] & kx_7[byte_id]);
	    pt_146[byte_id] = ( d171820[byte_id] & data_in[in_bit_base+3] & kx_7[byte_id]);
	    pt_147[byte_id] = ( unbal_hi_0[byte_id] & ~data_in[in_bit_base+3] & lo_f_bal_lo[byte_id]);
	    pt_148[byte_id] = ( unbal_hi_1[byte_id] & data_in[in_bit_base+3] & lo_f_bal_lo[byte_id]);
	    pt_149[byte_id] = ( k28_x[byte_id] & dx_7[byte_id]);
	    pt_150[byte_id] = ( unbal_hi_1[byte_id] & unbal_lo_1[byte_id]);
	    pt_151[byte_id] = ( unbal_hi_0[byte_id] & unbal_lo_0[byte_id]);
	    pt_152[byte_id] = ( error_lo[byte_id]);
	    pt_153[byte_id] = ( error_hi[byte_id]);
	    pt_154[byte_id] = ( ~rd_thread[byte_id] & ~unbal_hi_1[byte_id] & ~lo_f_bal_hi[byte_id] & ~data_in[in_bit_base+3] & lo_f_bal_lo[byte_id]);
	    pt_155[byte_id] = ( rd_thread[byte_id] & ~unbal_hi_0[byte_id] & ~lo_f_bal_hi[byte_id] & data_in[in_bit_base+3] & lo_f_bal_lo[byte_id]);
	    pt_156[byte_id] = ( rd_thread[byte_id] & ~unbal_hi_0[byte_id] & ~lo_f_bal_hi[byte_id] & unbal_lo_1[byte_id]);
	    pt_157[byte_id] = ( ~rd_thread[byte_id] & ~unbal_hi_1[byte_id] & ~lo_f_bal_hi[byte_id] & unbal_lo_0[byte_id]);
	    pt_158[byte_id] = ( ~rd_thread[byte_id] & ~data_in[in_bit_base+9] & lo_f_bal_hi[byte_id]);
	    pt_159[byte_id] = ( rd_thread[byte_id] & data_in[in_bit_base+9] & lo_f_bal_hi[byte_id]);
	    pt_160[byte_id] = ( rd_thread[byte_id] & unbal_hi_1[byte_id]);
	    pt_161[byte_id] = ( ~rd_thread[byte_id] & unbal_hi_0[byte_id]);
	    pt_162[byte_id] = ( data_in[in_bit_base+9] & k28_x[byte_id] & invrt_if_k28[byte_id]);
	


	    rd_thread[byte_id+1] = pt_128[byte_id] | pt_129[byte_id] | pt_130[byte_id] | pt_131[byte_id] | pt_132[byte_id];
	    

	    error_code[bytes-1-byte_id] = pt_138[byte_id] | pt_139[byte_id] | pt_140[byte_id] | pt_141[byte_id] |
				pt_142[byte_id] | pt_143[byte_id] | pt_144[byte_id] | pt_145[byte_id] |
				pt_146[byte_id] | pt_147[byte_id] | pt_148[byte_id] | pt_149[byte_id] |
				pt_150[byte_id] | pt_151[byte_id] | pt_152[byte_id] | pt_153[byte_id];

	    error_rd[bytes-1-byte_id] = pt_154[byte_id] | pt_155[byte_id] | pt_156[byte_id] | pt_157[byte_id] |
				pt_158[byte_id] | pt_159[byte_id] | pt_160[byte_id] | pt_161[byte_id];

	    k_char_int_din[bytes-1-byte_id] = (pt_135[byte_id] | pt_136[byte_id] | pt_137[byte_id]) & ~(
	    			pt_138[byte_id] | pt_139[byte_id] | pt_140[byte_id] | pt_141[byte_id] |
				pt_142[byte_id] | pt_143[byte_id] | pt_144[byte_id] | pt_145[byte_id] |
				pt_146[byte_id] | pt_147[byte_id] | pt_148[byte_id] | pt_149[byte_id] |
				pt_150[byte_id] | pt_151[byte_id] | pt_152[byte_id] | pt_153[byte_id]);

	    invert_567[byte_id] = pt_162[byte_id];



	
	    data_out_int_din[out_bit_base+5] = datpreout[pre_bit_base+0] ^ invert_567[byte_id];

	    data_out_int_din[out_bit_base+6] = datpreout[pre_bit_base+1] ^ invert_567[byte_id];

	    data_out_int_din[out_bit_base+7] = datpreout[pre_bit_base+2] ^ invert_567[byte_id];
	

	    end

	    rd_carry = rd_thread[bytes];

	end



    assign error_int_din = (|error_code) | (|error_rd);

    assign rd_err_int_din = |error_rd;

    assign code_err_int_din = |error_code;


// Async reset
    always @ (posedge clk or negedge rst_n) begin : PROC_mk_registers_a
        if (rst_n == 1'b0) begin
	    data_out_int_a <= 0;
	    error_int_a    <= 0;
	    rd_err_int_a   <= 0;
	    code_err_int_a <= 0;
	    k_char_int_a   <= 0;
	    rd_int_a       <= 0;
	    rd_err_bus_int_a   <= 0;
	    code_err_bus_int_a <= 0;
	end else if (enable_int == 1'b1) begin
	    data_out_int_a <= data_out_int_din;
	    error_int_a    <= error_int_din;
	    rd_err_int_a   <= rd_err_int_din;
	    code_err_int_a <= code_err_int_din;
	    k_char_int_a   <= k_char_int_din;
	    rd_int_a       <= rd_int_din;
	    rd_err_bus_int_a   <= error_rd;
	    code_err_bus_int_a <= error_code;
	end
    end

// Sync reset
    always @ (posedge clk) begin : PROC_mk_registers_s
        if (rst_n == 1'b0) begin
	    data_out_int_s <= 0;
	    error_int_s    <= 0;
	    rd_err_int_s   <= 0;
	    code_err_int_s <= 0;
	    k_char_int_s   <= 0;
	    rd_int_s       <= 0;
	    rd_err_bus_int_s   <= 0;
	    code_err_bus_int_s <= 0;
	end else if (enable_int == 1'b1) begin
	    data_out_int_s <= data_out_int_din;
	    error_int_s    <= error_int_din;
	    rd_err_int_s   <= rd_err_int_din;
	    code_err_int_s <= code_err_int_din;
	    k_char_int_s   <= k_char_int_din;
	    rd_int_s       <= rd_int_din;
	    rd_err_bus_int_s   <= error_rd;
	    code_err_bus_int_s <= error_code;
	end
    end


endmodule
