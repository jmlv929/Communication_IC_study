
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Gray Coded Synchronizer Synthetic Model
//
//           This converts binary counter values to gray-coded values in the source domain
//           which then gets synchronized in the destination domain.  Once in the destination
//           domain, the gray-coded values are decoded back to binary values and presented
//           to the output port 'count_d'.  In the source domain, two versions of binary
//           counter values, count_s and offset_count_s, are output to give reference to
//           current state of the counters in, relative and absolute terms, respectively.
//
//              Parameters:         Valid Values
//              ==========          ============
//              width               [ 1 to 1024: width of count_s, offset_count_s and count_d ports
//                                    default: 8 ]
//              offset              [ 0 to (2**(width-1) - 1): offset for non integer power of 2
//                                    default: 0 ]
//              reg_count_d         [ 0 or 1: registering of count_d output
//                                    default: 1
//                                    0 = count_d output is unregistered
//                                    1 = count_d output is registered ]
//              f_sync_type         [ 0 to 4: mode of synchronization
//                                    default: 2
//                                    0 = single clock design, no synchronizing stages implemented,
//                                    1 = 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing,
//                                    2 = 2-stage synchronization w/ both stages pos-edge capturing,
//                                    3 = 3-stage synchronization w/ all stages pos-edge capturing
//                                    4 = 4-stage synchronization w/ all stages pos-edge capturing ]
//              tst_mode            [ 0 or 2: latch insertion for testing purposes
//                                    default: 0
//                                    0 = no hold latch inserted,
//                                    1 = insert hold 'latch' using a neg-edge triggered register 
//                                    2 = insert hold 'latch' using active low latch ]
//
//              verif_en          Synchronization missampling control (Simulation verification)
//                                Default value = 1
//                                0 => no sampling errors modeled,
//                                1 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 1 cycle delay
//                                4 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 0.5 cycle delay
//                                Note: Use `define DW_MODEL_MISSAMPLES to define the Verilog macro
//                                      that turns on missample modeling in a Verilog HDL file.  Use
//                                      +define+DW_MODEL_MISSAMPLES simulator command line option to turn
//                                      on missample modeleng from the simulator command.
//              pipe_delay          [ 0 to 2: pipeline bin2gray result
//                                    default: 0
//                                    0 = only re-timing register of bin2gray result to destination domain
//                                    1 = one additional pipeline stage of bin2gray result to destination domain
//                                    2 = two additional pipeline stages of bin2gray result to destination domain ]
//              reg_count_s         [ 0 or 1: registering of count_s output
//                                    default: 1
//                                    0 = count_s output is unregistered
//                                    1 = count_s output is registered ]
//              reg_offset_count_s  [ 0 or 1: registering of offset_count_s output
//                                    default: 1
//                                    0 = offset_count_s output is unregistered
//                                    1 = offset_count_s output is registered ]
//              
//              Input Ports:    Size     Description
//              ===========     ====     ===========
//              clk_s           1 bit    Source Domain Input Clock
//              rst_s_n         1 bit    Source Domain Active Low Async. Reset
//		init_s_n        1 bit    Source Domain Active Low Sync. Reset
//              en_s            1 bit    Source Domain enable that advances binary counter
//              clk_d           1 bit    Destination Domain Input Clock
//              rst_d_n         1 bit    Destination Domain Active Low Async. Reset
//		init_d_n        1 bit    Destination Domain Active Low Sync. Reset
//              test            1 bit    Test input
//
//              Output Ports    Size     Description
//              ============    ====     ===========
//              count_s         M bit    Source Domain binary counter value 
//              offset_count_s  M bits   Source Domain binary counter offset value
//              count_d         M bits   Destination Domain binary counter value
//
//                Note: (1) The value of M is equal to the 'width' parameter value
//
//
// MODIFIED: 
//
//            7/29/11 DLL    Tied 'init_d_n' input to instance DWbb_sync to 1'b1 to
//                           disable any type of synchronous reset to it.  Also added
//                           tst_mode=2 capability.
//
//             6/8/11 DLL    Made edit to prevent carry/borrow warning from Leda.
//
//            2/28/11 DLL    Changed behavior of next_count_s_int and next_offset_count_s_int
//                           during init_s_n assertion.  
//                           Addresses STAR#9000450996.
//
//            10/30/08 DLL   To accommodate certain lint checkers, modified to 'size' some
//                           signals to match accompanying logic.
//
//            11/7/06  DLL   Modified functionality to support f_sync_type = 4
//
//            8/1/06   DLL   Added parameter 'reg_offset_count_s' which allows for registered
//                           or unregistered 'offset_count_s'.
//
//            7/21/06  DLL   Added parameter 'reg_count_s' which allows for registered
//                           or unregistered 'count_s'.
//
//            7/10/06  DLL   Added parameter 'pipe_delay' that allows up to 2 additional
//                           register delays of the binary to gray code result from
//                           the source to destination domain.
//
//
////////////////////////////////////////////////////////////////////////////////

module DW_gray_sync (
    clk_s,
    rst_s_n,
    init_s_n,
    en_s,
    count_s,
    offset_count_s,

    clk_d,
    rst_d_n,
    init_d_n,
    count_d,

    test
// Embedded dc_shell script
// set_local_link_library { "dw01.sldb" "dw03.sldb" } ;
// _model_constraint_1
    );

parameter width               = 8;  // RANGE 1 to 1024
parameter offset              = 0;  // RANGE 0 to (2**(width-1) - 1)
parameter reg_count_d         = 1;  // RANGE 0 to 1
parameter f_sync_type         = 2;  // RANGE 0 to 4
parameter tst_mode            = 0;  // RANGE 0 to 2

parameter verif_en            = 1;  // RANGE 0 to 4

parameter pipe_delay          = 0;  // RANGE 0 to 2
parameter reg_count_s         = 1;  // RANGE 0 to 1
parameter reg_offset_count_s  = 1;  // RANGE 0 to 1


input			clk_s;           // clock input from source domain
input			rst_s_n;         // active low asynchronous reset from source domain
input			init_s_n;        // active low synchronous reset from source domain
input                   en_s;            // enable source domain
output [width-1:0]      count_s;         // binary counter value to source domain
output [width-1:0]      offset_count_s;  // binary counter offset value to source domain

input			clk_d;           // clock input from destination domain
input			rst_d_n;         // active low asynchronous reset from destination domain
input			init_d_n;        // active low synchronous reset from destination domain
output [width-1:0]      count_d;         // binary counter value to destination domain

input                   test;            // test input

wire                    drs_en_s;
wire   [width-1:0]      count_s_int_xor;  

wire   [width-1:0]      next_count_s_int;
wire   [width:0]        next_count_s_adv;
wire   [width-1:0]      next_offset_count_s_int;
wire   [width:0]        next_offset_count_s;
reg    [width-1:0]      count_s_int;
reg    [width-1:0]      offset_count_s_int;

wire   [width-1:0]      bin2gray_s_func_out;
wire   [width-1:0]      next_bin2gray_s;
reg    [width-1:0]      bin2gray_s;
reg    [width-1:0]      bin2gray_s_d1;
reg    [width-1:0]      bin2gray_s_d2;
wire   [width-1:0]      bin2gray_s_pipe;
reg    [width-1:0]      bin2gray_l;
wire   [width-1:0]      bin2gray_cc;

wire   [width-1:0]      dw_sync_bin2gray_d;
wire   [width-1:0]      gray2bin_d_func_out;
wire   [width-1:0]      forced_value_bin2gray;

reg    [width-1:0]      count_d_int;
wire   [width-1:0]      count_d_int_xor;

wire   [width-1:0]      ONE;


localparam [width-1:0] end_value = ((32'b1 << width) - 32'b1) - offset;





generate
  if (width == 1) begin : GEN_ONE_W_EQ_1
    assign ONE = 1'b1;
  end else begin : GEN_ONE_W_GT_1
    assign ONE = {{width-1{1'b0}},1'b1};
  end
endgenerate


localparam [width-1:0] forced_value   = offset;

  assign drs_en_s = en_s;


  // Disable Leda warning 'Possible loss of carry/borrow in addition/subtraction'
  assign next_count_s_adv      = ((offset != 0) && (count_s_int_xor == end_value)) ?
			          forced_value : (count_s_int_xor + ONE);

  assign next_count_s_int = (init_s_n == 1'b0) ? forced_value :
                              ((drs_en_s == 1'b1) ?  next_count_s_adv[width-1:0] : count_s_int_xor);

  assign next_offset_count_s     = (count_s_int_xor == end_value) ?
	  			       {width{1'b0}} : (offset_count_s_int + ONE);

  assign next_offset_count_s_int = (init_s_n == 1'b0) ? {width{1'b0}} :
                                     ((drs_en_s == 1'b1) ?  next_offset_count_s[width-1:0] : offset_count_s_int);

  generate
    if (width > 1) begin : GEN_B2G_FUNCOUT_W_GT_1
      
  function [width-1:0] func_bin2gray ;
    input [width-1:0]		B;	// input
    begin 
      func_bin2gray  = B ^ { 1'b0, B[width-1 : 1] }; 
    end
  endfunction

  assign bin2gray_s_func_out = func_bin2gray ( next_count_s_int );
      assign forced_value_bin2gray = func_bin2gray(forced_value);
    end else begin : GEN_B2G_FUNCOUT_W_EQ_1
      assign bin2gray_s_func_out = next_count_s_int;
      assign forced_value_bin2gray =  (forced_value);
    end
  endgenerate

  assign next_bin2gray_s = (drs_en_s == 1'b1) ? (bin2gray_s_func_out ^ forced_value_bin2gray) : bin2gray_s;

  generate
    if (pipe_delay == 0) begin : GEN_B2G_SPIPE_PD_GT_2
      assign bin2gray_s_pipe = bin2gray_s;
    end
    if (pipe_delay == 1) begin : GEN_B2G_SPIPE_PD_EQ_1
      assign bin2gray_s_pipe = bin2gray_s_d1;
    end
    if (pipe_delay >= 2) begin : GEN_B2G_SPIPE_PD_EQ_2
      assign bin2gray_s_pipe = bin2gray_s_d2;
    end
  endgenerate

  
  
generate
  if (((f_sync_type&7)>1)&&(tst_mode==2)) begin : GEN_LATCH_frwd_hold_latch_PROC
    always @ (clk_s or bin2gray_s_pipe) begin : frwd_hold_latch_PROC
      if (clk_s == 1'b0)

	bin2gray_l <= bin2gray_s_pipe;

    end // frwd_hold_latch_PROC

    assign bin2gray_cc = (test==1'b1)? bin2gray_l : bin2gray_s_pipe;
  end else begin : GEN_DIRECT_frwd_hold_latch_PROC
    assign bin2gray_cc = bin2gray_s_pipe;
  end
endgenerate

  DW_sync #(width, f_sync_type+8, tst_mode, verif_en) U_SYNC(
	.clk_d(clk_d),
	.rst_d_n(rst_d_n),
	.init_d_n(1'b1),
	.data_s(bin2gray_cc),
	.test(test),
	.data_d(dw_sync_bin2gray_d) );

  
  function [width-1:0] func_gray2bin ;
    input [width-1:0]		G;	// input
    reg   [width-1:0]		b;
    integer			i;
    begin 
      b = {width{1'b0}};
      for (i=width-1 ; i >= 0 ; i=i-1) begin
        if (i < width-1)


	  b[i] = G[i] ^ b[i+1];


	else
	  b[i] = G[i];
      end // for (i
      func_gray2bin  = b; 
    end
  endfunction

  assign gray2bin_d_func_out = func_gray2bin ( dw_sync_bin2gray_d );


  always @ (posedge clk_s or negedge rst_s_n) begin : PROC_source_registers
    if (rst_s_n == 1'b0) begin
      count_s_int          <= {width{1'b0}};
      offset_count_s_int   <= {width{1'b0}};
      bin2gray_s           <= {width{1'b0}};
      bin2gray_s_d1        <= {width{1'b0}};
      bin2gray_s_d2        <= {width{1'b0}};
    end else if (init_s_n == 1'b0) begin
      count_s_int          <= {width{1'b0}};
      offset_count_s_int   <= {width{1'b0}};
      bin2gray_s           <= {width{1'b0}};
      bin2gray_s_d1        <= {width{1'b0}};
      bin2gray_s_d2        <= {width{1'b0}};
    end else begin
      count_s_int          <= (next_count_s_int ^ forced_value);
      offset_count_s_int   <= next_offset_count_s_int;
      bin2gray_s           <= next_bin2gray_s;
      bin2gray_s_d1        <= bin2gray_s;
      bin2gray_s_d2        <= bin2gray_s_d1;
    end
  end


  always @ (posedge clk_d or negedge rst_d_n) begin : PROC_dest_registers
    if (rst_d_n == 1'b0) begin
      count_d_int          <= {width{1'b0}};
    end else if (init_d_n == 1'b0) begin
      count_d_int          <= {width{1'b0}};
    end else begin
      count_d_int          <= gray2bin_d_func_out;
    end
  end


  assign count_s_int_xor = count_s_int ^ forced_value;

generate
  if (reg_count_d == 1) begin : GEN_CNT_D_INT_XOR_RCD_EQ_1
    assign count_d_int_xor = count_d_int ^ forced_value;
  end else begin : GEN_CNT_D_INT_XOR_RCD_NE_1
    assign count_d_int_xor = gray2bin_d_func_out ^ forced_value;
  end
endgenerate

// #ifdef 
generate
  if (reg_count_s == 1) begin : GEN_COUNT_S_RCS_EQ_1
    assign count_s = count_s_int_xor;
  end else begin : GEN_COUNT_S_RCS_NE_1
    assign count_s = next_count_s_int;
  end
endgenerate

generate
  if (reg_offset_count_s == 1) begin : GEN_OFF_CNT_S_ROCS_EQ_1
    assign offset_count_s = offset_count_s_int;
  end else begin : GEN_OFF_CNT_S_ROCS_NE_1
    assign offset_count_s = next_offset_count_s_int;
  end
endgenerate

  assign count_d         = count_d_int_xor;

endmodule
