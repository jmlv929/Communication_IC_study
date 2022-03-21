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
// AUTHOR:    Rick Kelly         Jul. 19, 1999
//
// VERSION:   Verilog Synthesis Architecture
//
// DesignWare_version: d87abe99
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: 8b/10b Encoder
//
//              Parameters:     Valid Values
//              ==========      ============
//              bytes           [ 1 to 16 ]
//              k28_5_only      [ 0 to 1 ] (0 = all 12 special characters available (as determined by data bus value)
//                                          1 = K28.5 available only (does NOT depend on value of data bus)
//              en_mode         [ 0 to 1 ] (0 = enable input is disconnected (stalls registers)
//                                          1 = enable input is connected (processes inputs based on state of enable input))
//              init_mode       [ 0 to 1 ] (0 = init_rd_val input is registered before being applied to data in
//                                          1 = init_rd_val input is not registered before being applied to data in)
//              rst_mode        [ 0 to 1 ] (0 = using asynchronous reset FFs
//                                          1 = using synchronous reset FFs)
//              op_iso_mode     [ 0 to 4 ] (0 = Follow intent defined by Power Compiler user setting
//                                          1 = no operand isolation
//                                          2 = 'and' gate isolaton
//                                          3 = 'or' gate isolation
//                                          4 = preferred isolation style: 'or' gate)
//
//              Input Ports:    Size    Description
//              ===========     ====    ===========
//              clk             1 bit   Input Clock
//              rst_n           1 bit   Active Low Asynchronous Reset
//              init_rd_n       1 bit   Active Low Running Disparity initialization control
//              init_rd_val     1 bit   Running Disparity initial value applied when init_rd_n active
//              k_char          B bits  Special character control input bus (active high, one control bit per data byte)
//              data_in         E bits  Input data bus (Eight bits per byte)
//              enable          1 bit   Active High Enable to process data_in
//
//              Output Ports    Size    Description
//              ============    ====    ===========
//              rd              1 bit   Current Running Disparity state
//              data_out        T bits  Decoded output data bus (Ten bits per byte)
//
//
// MODIFICATIONS:
//    2/15/08   DLL  Added copyright banner and 'op_iso_mode' parameter to following 'lpwr' architecture.
//
//    5/19/08   RJK  Updated coding to eliminate 'missing signal in sensitivity list` warnings
//
//    10/6/08   RJK Added rst_mode parameter to select reset type (STAR 9000270234)
//
////////////////////////////////////////////////////////////////////////////////



  module DW_8b10b_enc(
	clk,
	rst_n,
	init_rd_n,
	init_rd_val,
	k_char,
	data_in,

	rd,
	data_out,
        enable

	);


    parameter bytes = 2;

    parameter k28_5_only = 0;	// special character control mode

    parameter en_mode = 0;      // enable mode

    parameter init_mode = 0;    // initial RD mode

    parameter rst_mode = 0;     // reset mode

    parameter op_iso_mode = 0;  // operand isolation mode

input  			clk;		// clock input
input  			rst_n;		// active low reset
input  			init_rd_n;	// active low running disp. force control
input  			init_rd_val;	// running disp. value to force
input  [bytes-1:0]	k_char;		// special character control bus (1 bit per byte)
input  [bytes*8-1:0]	data_in;	// data to encode (8 bits per byte)

output			rd;		// current running dispalrity
output [bytes*10-1:0]	data_out;	// encoded data (10 bits per byte)

input			enable;		// register enable


reg			nxt_rd_enc;
wire 			new_rd;
reg    [bytes*10-1:0]	enc_data;

reg    [bytes*10-1:0]	data_out_int_a;
reg			rd_int_a;
reg    [bytes*10-1:0]	data_out_int_s;
reg			rd_int_s;
wire   [bytes*10-1:0]	data_out_int;
wire			rd_int;

wire [bytes-1:0] k_char_masked;

wire rd_effective, enable_int;





generate
  if (init_mode == 0) begin :	GEN_im_eq_0
    assign rd_effective = rd_int;
    assign new_rd = (init_rd_n == 1'b0)? init_rd_val : nxt_rd_enc;
  end else begin :		GEN_im_eq_1
    assign rd_effective = (init_rd_n == 1'b0)? init_rd_val : rd_int;
    assign new_rd = nxt_rd_enc;
  end
endgenerate

generate
  if (en_mode == 0) begin :	GEN_em_eq_0
    assign enable_int = 1'b1;
  end else begin :		GEN_em_eq_1
    assign enable_int = enable;
  end
endgenerate

generate
  if (k28_5_only == 1) begin : GEN_k28p5_only
    assign k_char_masked = {bytes{1'b0}};
  end else begin : GEN_all_k_chars
    assign k_char_masked = k_char;
  end
endgenerate


generate
  if (k28_5_only == 1) begin :	GEN_k28p5only_eq_1
    always @ * begin : PROC_encode
	integer byte_id, inbyte_base, in_k_base, outbyte_base;
	reg [bytes-1:0] pt_0, pt_1, pt_2, pt_3, pt_4, pt_5, pt_6, pt_7, pt_8, pt_9;
	reg [bytes-1:0] pt_10, pt_11, pt_12, pt_13, pt_14, pt_15, pt_16, pt_17, pt_18, pt_19;
	reg [bytes-1:0] pt_20, pt_21, pt_22, pt_23, pt_24, pt_25, pt_26, pt_27, pt_28, pt_29;
	reg [bytes-1:0] pt_30, pt_31, pt_32, pt_33, pt_34, pt_35, pt_36, pt_37, pt_38, pt_39;
	reg [bytes-1:0] pt_40, pt_41, pt_42;
	reg [bytes-1:0] unbal4, unbal6, rdvalbal4, encrd;
	reg [bytes-1:0] a, b, c, d, e, f, g, h, i, j;
	reg [bytes-1:0] unbal4_int, unbal6_int, rdvalbal4_int, encrd_int;
	reg [bytes-1:0] a_int, b_int, c_int, d_int, e_int, f_int, g_int, h_int, i_int, j_int;
	reg [bytes-1:0] rd_b, invrt4, invrt6;
	reg [bytes : 0] rd_a;

	
	
	rd_a[0] = rd_effective;
	for (byte_id=0 ; byte_id < bytes ; byte_id=byte_id+1) begin

	    in_k_base = bytes-byte_id-1;
	    inbyte_base = 8 * (bytes-byte_id-1);
	    outbyte_base = 10 * (bytes-byte_id-1);

	    pt_0[byte_id] = ~k_char_masked[in_k_base] & ~rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    ~data_in[inbyte_base+0];
	    pt_1[byte_id] = ~k_char_masked[in_k_base] & ~rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    ~data_in[inbyte_base+0];
	    pt_2[byte_id] = ~k_char_masked[in_k_base] & rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    ~data_in[inbyte_base+0];
	    pt_3[byte_id] = ~k_char_masked[in_k_base] & ~rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_4[byte_id] = ~k_char_masked[in_k_base] & rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_5[byte_id] = ~k_char_masked[in_k_base] & rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_6[byte_id] = k_char_masked[in_k_base] & data_in[inbyte_base+7] &
			    ~data_in[inbyte_base+6] & ~data_in[inbyte_base+5];
	    pt_7[byte_id] = k_char_masked[in_k_base] & data_in[inbyte_base+6] &
			    ~data_in[inbyte_base+5];
	    pt_8[byte_id] = k_char_masked[in_k_base] & ~data_in[inbyte_base+6] &
			    data_in[inbyte_base+5];
	    pt_9[byte_id] = ~data_in[inbyte_base+7] & data_in[inbyte_base+6] &
			    ~data_in[inbyte_base+5];
	    pt_10[byte_id] = ~data_in[inbyte_base+7] & ~data_in[inbyte_base+6] &
			    data_in[inbyte_base+5];
	    pt_11[byte_id] = ~k_char_masked[in_k_base] & data_in[inbyte_base+7] &
			    ~data_in[inbyte_base+6] & ~data_in[inbyte_base+5];
	    pt_12[byte_id] = ~k_char_masked[in_k_base] & data_in[inbyte_base+7] &
			    data_in[inbyte_base+6] & data_in[inbyte_base+5];
	    pt_13[byte_id] = ~data_in[inbyte_base+7] & ~data_in[inbyte_base+6];
	    pt_14[byte_id] = data_in[inbyte_base+7] & data_in[inbyte_base+6] &
			    ~data_in[inbyte_base+5];
	    pt_15[byte_id] = ~data_in[inbyte_base+7] & data_in[inbyte_base+6] &
			    data_in[inbyte_base+5];
	    pt_16[byte_id] = data_in[inbyte_base+7] & ~data_in[inbyte_base+6] &
			    data_in[inbyte_base+5];
	    pt_17[byte_id] = data_in[inbyte_base+3] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_18[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_19[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_20[byte_id] = ~k_char_masked[in_k_base] & data_in[inbyte_base+4] &
			    data_in[inbyte_base+3] & data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_21[byte_id] = data_in[inbyte_base+3] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_22[byte_id] = data_in[inbyte_base+3] & data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_23[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_24[byte_id] = data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    ~data_in[inbyte_base+0];
	    pt_25[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & ~data_in[inbyte_base+0];
	    pt_26[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_27[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & data_in[inbyte_base+1];
	    pt_28[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_29[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_30[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_31[byte_id] = data_in[inbyte_base+3] & data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_32[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_33[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_34[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_35[byte_id] = data_in[inbyte_base+3] & data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+0];
	    pt_36[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & data_in[inbyte_base+1];
	    pt_37[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+0];
	    pt_38[byte_id] = data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2];
	    pt_39[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_40[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_41[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+0];
	    pt_42[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & data_in[inbyte_base+0];

	
	
	    a_int[byte_id] = ~(pt_24[byte_id] | pt_25[byte_id] | pt_29[byte_id] |
			    pt_34[byte_id] | pt_35[byte_id] | pt_37[byte_id] |
			    pt_17[byte_id] | pt_19[byte_id]);

	    b_int[byte_id] = pt_25[byte_id] | pt_27[byte_id] | pt_29[byte_id] |
			    pt_30[byte_id] | pt_31[byte_id] | pt_32[byte_id] |
			    pt_33[byte_id] | pt_17[byte_id] | pt_18[byte_id] |
			    pt_19[byte_id];

	    c_int[byte_id] = ~(pt_23[byte_id] | pt_29[byte_id] | pt_33[byte_id] |
			    pt_36[byte_id] | pt_39[byte_id] | pt_42[byte_id] |
			    pt_17[byte_id] | pt_18[byte_id]);

	    d_int[byte_id] = pt_22[byte_id] | pt_28[byte_id] | pt_29[byte_id] |
			    pt_35[byte_id] | pt_38[byte_id] | pt_42[byte_id];

	    e_int[byte_id] = ~(pt_24[byte_id] | pt_28[byte_id] | pt_30[byte_id] |
			    pt_32[byte_id] | pt_40[byte_id] | pt_41[byte_id] |
			    pt_42[byte_id] | pt_18[byte_id] | pt_19[byte_id]);

	    f_int[byte_id] = pt_0[byte_id] | pt_1[byte_id] | pt_2[byte_id] |
			    pt_3[byte_id] | pt_4[byte_id] | pt_5[byte_id] |
			    pt_6[byte_id] | pt_13[byte_id] | pt_16[byte_id];

	    g_int[byte_id] = ~(pt_11[byte_id] | pt_12[byte_id] | pt_13[byte_id] |
			    pt_15[byte_id] | pt_16[byte_id]);

	    h_int[byte_id] = ~(pt_6[byte_id] | pt_9[byte_id] | pt_10[byte_id] |
			    pt_12[byte_id]);

	    i_int[byte_id] = ~(pt_20[byte_id] | pt_21[byte_id] | pt_22[byte_id] |
			    pt_23[byte_id] | pt_26[byte_id] | pt_27[byte_id] |
			    pt_31[byte_id] | pt_32[byte_id] | pt_33[byte_id] |
			    pt_34[byte_id] | pt_38[byte_id]);

	    j_int[byte_id] = ~(pt_0[byte_id] | pt_1[byte_id] | pt_2[byte_id] |
			    pt_3[byte_id] | pt_4[byte_id] | pt_5[byte_id] |
			    pt_11[byte_id] | pt_14[byte_id] | pt_16[byte_id]);

	    unbal6_int[byte_id] = ~(pt_20[byte_id] | pt_26[byte_id] | pt_32[byte_id] |
			    pt_36[byte_id] | pt_37[byte_id] | pt_39[byte_id] |
			    pt_40[byte_id] | pt_41[byte_id] | pt_42[byte_id] |
			    pt_17[byte_id] | pt_18[byte_id] | pt_19[byte_id]);

	    encrd_int[byte_id] = ~(pt_20[byte_id] | pt_23[byte_id] | pt_24[byte_id] |
			    pt_26[byte_id] | pt_34[byte_id] | pt_36[byte_id] |
			    pt_37[byte_id] | pt_39[byte_id] | pt_40[byte_id] |
			    pt_41[byte_id] | pt_42[byte_id] | pt_17[byte_id] |
			    pt_18[byte_id] | pt_19[byte_id]);

	    unbal4_int[byte_id] = ~(pt_9[byte_id] | pt_10[byte_id] | pt_14[byte_id] |
			    pt_15[byte_id] | pt_16[byte_id]);

	    rdvalbal4_int[byte_id] = pt_7[byte_id] | pt_8[byte_id] | pt_11[byte_id] |
			    pt_12[byte_id] | pt_15[byte_id];

	    a[byte_id] = a_int[byte_id] & ~k_char[in_k_base];
	    b[byte_id] = b_int[byte_id] & ~k_char[in_k_base];
	    c[byte_id] = c_int[byte_id] | k_char[in_k_base];
	    d[byte_id] = d_int[byte_id] | k_char[in_k_base];
	    e[byte_id] = e_int[byte_id] | k_char[in_k_base];
	    f[byte_id] = f_int[byte_id] | k_char[in_k_base];
	    g[byte_id] = g_int[byte_id] & ~k_char[in_k_base];
	    h[byte_id] = h_int[byte_id] | k_char[in_k_base];
	    i[byte_id] = i_int[byte_id] | k_char[in_k_base];
	    j[byte_id] = j_int[byte_id] & ~k_char[in_k_base];
	    unbal6[byte_id] = unbal6_int[byte_id] | k_char[in_k_base];
	    encrd[byte_id] = encrd_int[byte_id] | k_char[in_k_base];
	    unbal4[byte_id] = unbal4_int[byte_id] & ~k_char[in_k_base];
	    rdvalbal4[byte_id] = rdvalbal4_int[byte_id] | k_char[in_k_base];

	
	
	    rd_b[byte_id] = rd_a[byte_id] ^ unbal6[byte_id];
	    rd_a[byte_id+1] = rd_a[byte_id] ^ unbal4[byte_id] ^ unbal6[byte_id];

	    invrt4[byte_id] = (~rd_b[byte_id] & rdvalbal4[byte_id]) |
			    (rd_b[byte_id] & ~rdvalbal4[byte_id] & unbal4[byte_id]);
	    invrt6[byte_id] = (rd_a[byte_id] & encrd[byte_id]) |
			    (~rd_a[byte_id] & unbal6[byte_id] & ~encrd[byte_id]);

	    enc_data[outbyte_base+0] = j[byte_id] ^ invrt4[byte_id];
	    enc_data[outbyte_base+1] = h[byte_id] ^ invrt4[byte_id];
	    enc_data[outbyte_base+2] = g[byte_id] ^ invrt4[byte_id];
	    enc_data[outbyte_base+3] = f[byte_id] ^ invrt4[byte_id];
	    enc_data[outbyte_base+4] = i[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+5] = e[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+6] = d[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+7] = c[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+8] = b[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+9] = a[byte_id] ^ invrt6[byte_id];
	end

	nxt_rd_enc = rd_a[bytes];
	
    end
  end else begin :		GET_k28p5only_eq_0
    always @ * begin : PROC_encode
	integer byte_id, inbyte_base, in_k_base, outbyte_base;
	reg [bytes-1:0] pt_0, pt_1, pt_2, pt_3, pt_4, pt_5, pt_6, pt_7, pt_8, pt_9;
	reg [bytes-1:0] pt_10, pt_11, pt_12, pt_13, pt_14, pt_15, pt_16, pt_17, pt_18, pt_19;
	reg [bytes-1:0] pt_20, pt_21, pt_22, pt_23, pt_24, pt_25, pt_26, pt_27, pt_28, pt_29;
	reg [bytes-1:0] pt_30, pt_31, pt_32, pt_33, pt_34, pt_35, pt_36, pt_37, pt_38, pt_39;
	reg [bytes-1:0] pt_40, pt_41, pt_42;
	reg [bytes-1:0] unbal4, unbal6, rdvalbal4, encrd;
	reg [bytes-1:0] a, b, c, d, e, f, g, h, i, j;
	reg [bytes-1:0] unbal4_int, unbal6_int, rdvalbal4_int, encrd_int;
	reg [bytes-1:0] a_int, b_int, c_int, d_int, e_int, f_int, g_int, h_int, i_int, j_int;
	reg [bytes-1:0] rd_b, invrt4, invrt6;
	reg [bytes : 0] rd_a;

	
	
	rd_a[0] = rd_effective;
	for (byte_id=0 ; byte_id < bytes ; byte_id=byte_id+1) begin

	    in_k_base = bytes-byte_id-1;
	    inbyte_base = 8 * (bytes-byte_id-1);
	    outbyte_base = 10 * (bytes-byte_id-1);

	    pt_0[byte_id] = ~k_char_masked[in_k_base] & ~rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    ~data_in[inbyte_base+0];
	    pt_1[byte_id] = ~k_char_masked[in_k_base] & ~rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    ~data_in[inbyte_base+0];
	    pt_2[byte_id] = ~k_char_masked[in_k_base] & rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    ~data_in[inbyte_base+0];
	    pt_3[byte_id] = ~k_char_masked[in_k_base] & ~rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_4[byte_id] = ~k_char_masked[in_k_base] & rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_5[byte_id] = ~k_char_masked[in_k_base] & rd_a[byte_id] &
			    data_in[inbyte_base+7] & data_in[inbyte_base+5] &
			    ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_6[byte_id] = k_char_masked[in_k_base] & data_in[inbyte_base+7] &
			    ~data_in[inbyte_base+6] & ~data_in[inbyte_base+5];
	    pt_7[byte_id] = k_char_masked[in_k_base] & data_in[inbyte_base+6] &
			    ~data_in[inbyte_base+5];
	    pt_8[byte_id] = k_char_masked[in_k_base] & ~data_in[inbyte_base+6] &
			    data_in[inbyte_base+5];
	    pt_9[byte_id] = ~data_in[inbyte_base+7] & data_in[inbyte_base+6] &
			    ~data_in[inbyte_base+5];
	    pt_10[byte_id] = ~data_in[inbyte_base+7] & ~data_in[inbyte_base+6] &
			    data_in[inbyte_base+5];
	    pt_11[byte_id] = ~k_char_masked[in_k_base] & data_in[inbyte_base+7] &
			    ~data_in[inbyte_base+6] & ~data_in[inbyte_base+5];
	    pt_12[byte_id] = ~k_char_masked[in_k_base] & data_in[inbyte_base+7] &
			    data_in[inbyte_base+6] & data_in[inbyte_base+5];
	    pt_13[byte_id] = ~data_in[inbyte_base+7] & ~data_in[inbyte_base+6];
	    pt_14[byte_id] = data_in[inbyte_base+7] & data_in[inbyte_base+6] &
			    ~data_in[inbyte_base+5];
	    pt_15[byte_id] = ~data_in[inbyte_base+7] & data_in[inbyte_base+6] &
			    data_in[inbyte_base+5];
	    pt_16[byte_id] = data_in[inbyte_base+7] & ~data_in[inbyte_base+6] &
			    data_in[inbyte_base+5];
	    pt_17[byte_id] = data_in[inbyte_base+3] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_18[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_19[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_20[byte_id] = ~k_char_masked[in_k_base] & data_in[inbyte_base+4] &
			    data_in[inbyte_base+3] & data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_21[byte_id] = data_in[inbyte_base+3] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_22[byte_id] = data_in[inbyte_base+3] & data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_23[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_24[byte_id] = data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    ~data_in[inbyte_base+0];
	    pt_25[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & ~data_in[inbyte_base+0];
	    pt_26[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_27[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & data_in[inbyte_base+1];
	    pt_28[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_29[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_30[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_31[byte_id] = data_in[inbyte_base+3] & data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_32[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & data_in[inbyte_base+1] &
			    data_in[inbyte_base+0];
	    pt_33[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_34[byte_id] = ~data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+1] & ~data_in[inbyte_base+0];
	    pt_35[byte_id] = data_in[inbyte_base+3] & data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+0];
	    pt_36[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & data_in[inbyte_base+1];
	    pt_37[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+0];
	    pt_38[byte_id] = data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2];
	    pt_39[byte_id] = data_in[inbyte_base+4] & ~data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_40[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+2] &
			    ~data_in[inbyte_base+1] & data_in[inbyte_base+0];
	    pt_41[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    data_in[inbyte_base+2] & ~data_in[inbyte_base+0];
	    pt_42[byte_id] = ~data_in[inbyte_base+4] & data_in[inbyte_base+3] &
			    ~data_in[inbyte_base+2] & data_in[inbyte_base+0];

	
	
	    a_int[byte_id] = ~(pt_24[byte_id] | pt_25[byte_id] | pt_29[byte_id] |
			    pt_34[byte_id] | pt_35[byte_id] | pt_37[byte_id] |
			    pt_17[byte_id] | pt_19[byte_id]);

	    b_int[byte_id] = pt_25[byte_id] | pt_27[byte_id] | pt_29[byte_id] |
			    pt_30[byte_id] | pt_31[byte_id] | pt_32[byte_id] |
			    pt_33[byte_id] | pt_17[byte_id] | pt_18[byte_id] |
			    pt_19[byte_id];

	    c_int[byte_id] = ~(pt_23[byte_id] | pt_29[byte_id] | pt_33[byte_id] |
			    pt_36[byte_id] | pt_39[byte_id] | pt_42[byte_id] |
			    pt_17[byte_id] | pt_18[byte_id]);

	    d_int[byte_id] = pt_22[byte_id] | pt_28[byte_id] | pt_29[byte_id] |
			    pt_35[byte_id] | pt_38[byte_id] | pt_42[byte_id];

	    e_int[byte_id] = ~(pt_24[byte_id] | pt_28[byte_id] | pt_30[byte_id] |
			    pt_32[byte_id] | pt_40[byte_id] | pt_41[byte_id] |
			    pt_42[byte_id] | pt_18[byte_id] | pt_19[byte_id]);

	    f_int[byte_id] = pt_0[byte_id] | pt_1[byte_id] | pt_2[byte_id] |
			    pt_3[byte_id] | pt_4[byte_id] | pt_5[byte_id] |
			    pt_6[byte_id] | pt_13[byte_id] | pt_16[byte_id];

	    g_int[byte_id] = ~(pt_11[byte_id] | pt_12[byte_id] | pt_13[byte_id] |
			    pt_15[byte_id] | pt_16[byte_id]);

	    h_int[byte_id] = ~(pt_6[byte_id] | pt_9[byte_id] | pt_10[byte_id] |
			    pt_12[byte_id]);

	    i_int[byte_id] = ~(pt_20[byte_id] | pt_21[byte_id] | pt_22[byte_id] |
			    pt_23[byte_id] | pt_26[byte_id] | pt_27[byte_id] |
			    pt_31[byte_id] | pt_32[byte_id] | pt_33[byte_id] |
			    pt_34[byte_id] | pt_38[byte_id]);

	    j_int[byte_id] = ~(pt_0[byte_id] | pt_1[byte_id] | pt_2[byte_id] |
			    pt_3[byte_id] | pt_4[byte_id] | pt_5[byte_id] |
			    pt_11[byte_id] | pt_14[byte_id] | pt_16[byte_id]);

	    unbal6_int[byte_id] = ~(pt_20[byte_id] | pt_26[byte_id] | pt_32[byte_id] |
			    pt_36[byte_id] | pt_37[byte_id] | pt_39[byte_id] |
			    pt_40[byte_id] | pt_41[byte_id] | pt_42[byte_id] |
			    pt_17[byte_id] | pt_18[byte_id] | pt_19[byte_id]);

	    encrd_int[byte_id] = ~(pt_20[byte_id] | pt_23[byte_id] | pt_24[byte_id] |
			    pt_26[byte_id] | pt_34[byte_id] | pt_36[byte_id] |
			    pt_37[byte_id] | pt_39[byte_id] | pt_40[byte_id] |
			    pt_41[byte_id] | pt_42[byte_id] | pt_17[byte_id] |
			    pt_18[byte_id] | pt_19[byte_id]);

	    unbal4_int[byte_id] = ~(pt_9[byte_id] | pt_10[byte_id] | pt_14[byte_id] |
			    pt_15[byte_id] | pt_16[byte_id]);

	    rdvalbal4_int[byte_id] = pt_7[byte_id] | pt_8[byte_id] | pt_11[byte_id] |
			    pt_12[byte_id] | pt_15[byte_id];

	    a[byte_id] = a_int[byte_id];
	    b[byte_id] = b_int[byte_id];
	    c[byte_id] = c_int[byte_id];
	    d[byte_id] = d_int[byte_id];
	    e[byte_id] = e_int[byte_id];
	    f[byte_id] = f_int[byte_id];
	    g[byte_id] = g_int[byte_id];
	    h[byte_id] = h_int[byte_id];
	    i[byte_id] = i_int[byte_id];
	    j[byte_id] = j_int[byte_id];
	    unbal6[byte_id] = unbal6_int[byte_id];
	    encrd[byte_id] = encrd_int[byte_id];
	    unbal4[byte_id] = unbal4_int[byte_id];
	    rdvalbal4[byte_id] = rdvalbal4_int[byte_id];

	
	
	    rd_b[byte_id] = rd_a[byte_id] ^ unbal6[byte_id];
	    rd_a[byte_id+1] = rd_a[byte_id] ^ unbal4[byte_id] ^ unbal6[byte_id];

	    invrt4[byte_id] = (~rd_b[byte_id] & rdvalbal4[byte_id]) |
			    (rd_b[byte_id] & ~rdvalbal4[byte_id] & unbal4[byte_id]);
	    invrt6[byte_id] = (rd_a[byte_id] & encrd[byte_id]) |
			    (~rd_a[byte_id] & unbal6[byte_id] & ~encrd[byte_id]);

	    enc_data[outbyte_base+0] = j[byte_id] ^ invrt4[byte_id];
	    enc_data[outbyte_base+1] = h[byte_id] ^ invrt4[byte_id];
	    enc_data[outbyte_base+2] = g[byte_id] ^ invrt4[byte_id];
	    enc_data[outbyte_base+3] = f[byte_id] ^ invrt4[byte_id];
	    enc_data[outbyte_base+4] = i[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+5] = e[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+6] = d[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+7] = c[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+8] = b[byte_id] ^ invrt6[byte_id];
	    enc_data[outbyte_base+9] = a[byte_id] ^ invrt6[byte_id];
	end

	nxt_rd_enc = rd_a[bytes];
	
    end
  end
endgenerate



    // async reset
    always @ (posedge clk or negedge rst_n) begin : PROC_async_rst_ffs
	if (rst_n == 1'b0) begin
	    rd_int_a <= 1'b0;
	    data_out_int_a <= {10*bytes{1'b0}};
	end else if (enable_int == 1'b1) begin
	    rd_int_a <= new_rd;
	    data_out_int_a <= enc_data;	
	end
    end
    
    // async reset
    always @ (posedge clk) begin : PROC_sync_rst_ffs
	if (rst_n == 1'b0) begin
	    rd_int_s <= 1'b0;
	    data_out_int_s <= {10*bytes{1'b0}};
	end else if (enable_int == 1'b1) begin
	    rd_int_s <= new_rd;
	    data_out_int_s <= enc_data;	
	end
    end
    

    assign rd_int       = (rst_mode == 0)? rd_int_a       : rd_int_s;
    assign data_out_int = (rst_mode == 0)? data_out_int_a : data_out_int_s;

    assign data_out = data_out_int;
    assign rd = rd_int;

endmodule
