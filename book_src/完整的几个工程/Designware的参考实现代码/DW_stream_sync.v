////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
//     12/01/05
//
// VERSION:   Verilog Synthesis Model for DWbb_stream_sync
//
// DesignWare_version: 5db29355
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Data Stream Synchronizer Synthetic Model
//
//    This synchronizes an incoming data stream from a source domain 
//    to a destination domain with a minimum amount of latency.
//
//       Parameters:     Valid Values    Description
//       ==========      ============    ===========
//       width            1 to 1024      default: 8 
//                                       Width of data_s and data_d ports
//
//       depth            2 to 256       default: 4
//                                       Depth of FIFO
//
//       prefill_lvl     0 to depth-1    default: 0
//                                       number of FIFO locations filled before
//                                       transferring to destination domain ]
//
//       f_sync_type       0 to 4        default: 2
//                                       Forward Synchronization Type (Source to Destination Domains)
//                                         0 => no synchronization, single clock design
//                                         1 => 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing
//                                         2 => 2-stage synchronization w/ both stages pos-edge capturing
//                                         3 => 3-stage synchronization w/ all stages pos-edge capturing
//                                         4 => 4-stage synchronization w/ all stages pos-edge capturing
//
//       reg_stat          0 or 1        default: 1
//                                       Register internally calculated status
//                                         0 => don't register internally calculated status
//                                         1 => register internally calculated status
//
//       tst_mode          0 or 2        default: 0
//                                       Insert neg-edge hold latch at front-end of synchronizers during "test"
//                                         0 => no hold latch inserted,
//                                         1 => insert hold latch using a neg-edge triggered register
//                                         2 => insert hold latch using an active low latch
//
//        verif_en       0 to 4       Synchronization missampling control (Simulation verification)
//                                    Default value = 1
//                                    0 => no sampling errors modeled,
//                                    1 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 1 cycle delay
//                                    2 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 1.5 cycle delay
//                                    3 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 3 cycle delay
//                                    4 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 0.5 cycle delay
//                                    Note: Use `define DW_MODEL_MISSAMPLES to define the Verilog macro
//                                          that turns on missample modeling in a Verilog HDL file.  Use
//                                          +define+DW_MODEL_MISSAMPLES simulator command line option to turn
//                                          on missample modeleng from the simulator command.
//
//       r_sync_type       0 to 4        default: 2
//                                       Reverse Synchronization Type (Destination to Source Domains)
//                                         0 => no synchronization, single clock design
//                                         1 => 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing
//                                         2 => 2-stage synchronization w/ both stages pos-edge capturing
//                                         3 => 3-stage synchronization w/ all stages pos-edge capturing
//                                         4 => 4-stage synchronization w/ all stages pos-edge capturing
//
//       clk_d_faster      0 to 15       default: 1
//                                       clk_d faster than clk_s by difference ratio
//                                         0        => Either clr_s or clr_d active with the other tied low at input
//                                         1 to 15  => ratio of clk_d to clk_s frequencies plus 1
//
//       reg_in_prog       0 or 1        default: 1
//                                       Register the 'clr_in_prog_s' and 'clr_in_prog_d' Outputs
//                                         0 => unregistered
//                                         1 => registered
//       
//       Input Ports:    Size     Description
//       ===========     ====     ===========
//       clk_s           1 bit    Source Domain Input Clock
//       rst_s_n         1 bit    Source Domain Active Low Async. Reset
//       init_s_n        1 bit    Source Domain Active Low Sync. Reset
//       clr_s           1 bit    Source Domain Internal Logic Clear (reset)
//       send_s          1 bit    Source Domain Active High Send Request
//       data_s          N bits   Source Domain Data
//
//       clk_d           1 bit    Destination Domain Input Clock
//       rst_d_n         1 bit    Destination Domain Active Low Async. Reset
//	 init_d_n        1 bit    Destination Domain Active Low Sync. Reset
//       clr_d           1 bit    Destination Domain Internal Logic Clear (reset)
//       prefill_d       1 bit    Destination Domain Prefill Control
//
//       test            1 bit    Test input
//
//       Output Ports    Size     Description
//       ============    ====     ===========
//       clr_sync_d      1 bit    Source Domain Clear
//       clr_in_prog_s   1 bit    Source Domain Clear in Progress
//       clr_cmplt_s     1 bit    Soruce Domain Clear Complete (pulse)
//
//       clr_in_prog_d   1 bit    Destination Domain Clear in Progress
//       clr_sync_d      1 bit    Destination Domain Clear (pulse)
//       clr_cmplt_d     1 bit    Destination Domain Clear Complete (pulse)
//       data_avail_d    1 bit    Destination Domain Data Available
//       data_d          N bits   Destination Domain Data
//       prefilling_d    1 bit    Destination Domain Prefillng Status
//
//           Note: The value of N is equal to the 'width' parameter value
//
//
// MODIFIED: 
//
//  10/04/11 DLL  Instrumented to allow the "alt" version of this component for
//                             BCMs to be used for its derivation.
//
//  07/19/11 DLL  Removed or-ing of 'clr_in_prog_d' with 'init_d_n' that
//                wires to DW_sync 'init_d_n' input port.
//                Extended clr_in_prog_d and applied to destination domain
//                registers.
//
//  06/28/11 DLL  Code cleanup to eliminate or disable Leda warnings/errors.
//
//  09/09/08 DLL  Changed "rcv_d_cntr" initialization to include
//                all bits...{depth{1'b0}}.  Fixes STAR#900259765
//                And fixed always block warning for next_count_d.
//
//  01/10/07 DLL  Converted looping variables from global to local
//
//  11/15/06 DLL  Added 4-stage synchronization capability
//
//  10/20/06 DLL  Updated with new version of DW_reset_sync
//           
//
////////////////////////////////////////////////////////////////////////////////

module DW_stream_sync (
    clk_s,
    rst_s_n,
    init_s_n,
    clr_s,
    send_s,
    data_s,
    clr_sync_s,
    clr_in_prog_s,
    clr_cmplt_s,

    clk_d,
    rst_d_n,
    init_d_n,
    clr_d,
    prefill_d,
    clr_in_prog_d,
    clr_sync_d,
    clr_cmplt_d,
    data_avail_d,
    data_d,
    prefilling_d,

    test
    // Embedded dc_shell script
    // _model_constraint_1
    );

parameter width        = 8;  // RANGE 1 to 1024
parameter depth        = 4;  // RANGE 2 to 256
parameter prefill_lvl  = 0;  // RANGE 0 to 255
parameter f_sync_type  = 2;  // RANGE 0 to 4
parameter reg_stat     = 1;  // RANGE 0 to 1
parameter tst_mode     = 0;  // RANGE 0 to 2

parameter verif_en     = 1;  // RANGE 0 to 4

parameter r_sync_type  = 2;  // RANGE 0 to 4
parameter clk_d_faster = 1;  // RANGE 0 to 15
parameter reg_in_prog  = 1;  // RANGE 0 to 1

localparam bit_width   = ((depth>16)?((depth>64)?((depth>128)?8:7):((depth>32)?6:5)):((depth>4)?((depth>8)?4:3):((depth>2)?2:1)));
localparam sync_verif_en = (verif_en == 2) ? 4 : (verif_en == 3) ? 1 : verif_en;

input                   clk_s;         // clock input from source domain
input                   rst_s_n;       // active low asynchronous reset from source domain
input                   init_s_n;      // active low synchronous reset from source domain
input                   clr_s;         // active high clear from source domain
input                   send_s;        // active high send request from source domain
input  [width-1:0]      data_s;        // data to be synchronized from source domain
output                  clr_sync_s;    // clear to source domain sequential devices (pulse)
output                  clr_in_prog_s; // clear in progress status to source domain
output                  clr_cmplt_s;   // clear sequence complete (pulse)

input                   clk_d;         // clock input from destination domain
input                   rst_d_n;       // active low asynchronous reset from destination domain
input                   init_d_n;      // active low synchronous reset from destination domain
input                   clr_d;         // active high clear from destination domain
input                   prefill_d;     // active high prefill control from destination domain
output                  clr_in_prog_d; // clear in progress status to source domain
output                  clr_sync_d;    // clear to destination domain sequential devices (pulse)
output                  clr_cmplt_d;   // clear sequence complete (pulse)
output                  data_avail_d;  // data available to destination domain
output [width-1:0]      data_d;        // data synchronized to destination domain
output                  prefilling_d;  // prefilling status to destination domain

input                   test;          // test input


reg    [(width*depth)-1:0] data_s_vec;
reg    [(width*depth)-1:0] next_data_s_vec;

reg    [(width*depth)-1:0] masked_data_s_vec;

reg    [depth-1:0]      send_s_cntr;
wire   [depth-1:0]      next_send_s_cntr;
wire   [depth-1:0]      send_s_cntr_new;

reg    [depth-1:0]      next_event_vec_s;
reg    [depth-1:0]      event_vec_s;
reg    [depth-1:0]      event_vec_l;
wire   [depth-1:0]      event_vec_cc;
wire   [depth-1:0]      dw_sync_event_vec_cc;

reg                     det_event_level_n;
wire                    next_det_event_level_n;

reg    [depth-1:0]      rcv_d_cntr;
wire   [depth-1:0]      next_rcv_d_cntr;
wire   [depth-1:0]      rcv_d_cntr_new;

wire   [depth-1:0]      rcv_d_cntr_filled_ones;

wire   [depth-1:0]      count_vec;

reg    [bit_width-1:0]   count_d;
reg    [bit_width-1:0]   next_count_d;

reg    [width-1:0]      data_mux_out;
reg                     prefilling_d_int;
wire                    next_prefilling_d_int;

reg                     data_avail_d_int;
wire                    next_data_avail_d_int;
reg    [width-1:0]      data_d_int;
wire   [width-1:0]      next_data_d_int;





DW_reset_sync #((f_sync_type + 8) , (r_sync_type + 8) , clk_d_faster, reg_in_prog, tst_mode, verif_en) U1 (
            .clk_s(clk_s),
            .rst_s_n(rst_s_n),
            .init_s_n(init_s_n),
            .clr_s(clr_s),
            .clk_d(clk_d),
            .rst_d_n(rst_d_n),
            .init_d_n(init_d_n),
            .clr_d(clr_d),
            .test(test),
            .clr_sync_s(clr_sync_s),
            .clr_in_prog_s(clr_in_prog_s),
            .clr_cmplt_s(clr_cmplt_s),
            .clr_in_prog_d(clr_in_prog_d),
            .clr_sync_d(clr_sync_d),
            .clr_cmplt_d(clr_cmplt_d)
            );


  assign next_send_s_cntr  = (send_s == 1'b1) ? 
			       ((send_s_cntr_new << 1) | {{depth-1{1'b0}}, ~send_s_cntr_new[depth-1]}) :
                               send_s_cntr;
  assign send_s_cntr_new   = {send_s_cntr[depth-1:1], ~send_s_cntr[0]};

  always @(send_s or send_s_cntr_new or data_s or data_s_vec or event_vec_s) begin : PROC_EVENT_VEC
    integer s_a, s_b;

    for (s_a = 0; s_a < depth; s_a = s_a + 1) begin : PROC_LD_FIFO
      if ((send_s == 1'b1) && (send_s_cntr_new[s_a] == 1'b1)) begin
	next_event_vec_s[s_a] = ~event_vec_s[s_a];
        for (s_b = 0; s_b < width; s_b = s_b + 1) begin
          next_data_s_vec[s_a*width+s_b] = data_s[s_b];
        end // for (s_b = 0;
      end  // if (send_s == 1'b1
      else begin
	next_event_vec_s[s_a] = event_vec_s[s_a];
        for (s_b = 0; s_b < width; s_b = s_b + 1) begin
	  next_data_s_vec[s_a*width+s_b] = data_s_vec[s_a*width+s_b];
        end // for (s_b = 0;
      end // else
    end // for (s_a = 0; 
  end // always @(



  
generate
  if (((f_sync_type&7)>1)&&(tst_mode==2)) begin : GEN_LATCH_hold_latch_PROC
    always @ (clk_s or event_vec_s) begin : hold_latch_PROC
      if (clk_s == 1'b0)

	event_vec_l <= event_vec_s;

    end // hold_latch_PROC

    assign event_vec_cc = (test==1'b1)? event_vec_l : event_vec_s;
  end else begin : GEN_DIRECT_hold_latch_PROC
    assign event_vec_cc = event_vec_s;
  end
endgenerate

  DW_sync #(depth, f_sync_type+8, tst_mode, sync_verif_en) U_SYNC(
	.clk_d(clk_d),
	.rst_d_n(rst_d_n),
	.init_d_n(init_d_n),
	.data_s(event_vec_cc),
	.test(test),
	.data_d(dw_sync_event_vec_cc) );


  assign next_det_event_level_n  = ((next_data_avail_d_int == 1'b1) && (rcv_d_cntr_new[depth-1] == 1'b1)) ?
				     det_event_level_n : ~det_event_level_n;

  assign next_rcv_d_cntr  = (next_data_avail_d_int == 1'b1) ? 
		              ((rcv_d_cntr_new << 1) | {{depth-1{1'b0}}, ~rcv_d_cntr_new[depth-1]}) :
                              rcv_d_cntr;
  assign rcv_d_cntr_new   = {rcv_d_cntr[depth-1:1], ~rcv_d_cntr[0]};


  
  function [depth-1:0] fill_ones_to_msb;
    input [depth-1:0]            g;      // input
    reg   [depth-1:0]            b;
    integer	                i;
    begin
      b = g;
      for (i=1 ; i<(depth) ; i=i+1) begin
        b [i] = g [i] | b [i-1];
      end // for (i
      fill_ones_to_msb = b;
    end
  endfunction

  assign rcv_d_cntr_filled_ones = fill_ones_to_msb( rcv_d_cntr_new );

  assign count_vec  = (dw_sync_event_vec_cc ^ rcv_d_cntr_filled_ones) ^ {depth{~det_event_level_n}};
  always @(count_vec) begin : PROC_NEXT_COUNT_D
    integer i, temp_count;

    temp_count = 0;
    for (i = 0; i < depth; i = i + 1) begin
      temp_count = temp_count + ((count_vec[i] == 1'b1) ? 1 : 0);
    end  // for (i = 0;

    for (i=0;i<bit_width;i=i+1) next_count_d[ i ] = (((temp_count>>i)&1)!=0)?1'b1:1'b0;
  end  // always @(count_vec)
  

generate
  if (prefill_lvl == 0) begin : GEN_NXT_PF_D_PRLVL_EQ_0
    assign next_prefilling_d_int = 1'b0;
  end else begin : GEN_NXT_PF_D_PRLVL_NE_0
    if (reg_stat == 1) begin : GEN_NXT_PF_D_RS_EQ_1
      assign next_prefilling_d_int = ((prefill_d == 1'b1) && (count_d < prefill_lvl)) ? 1'b1 :
                                      (count_d >= prefill_lvl) ? 1'b0 : prefilling_d_int;
    end else begin : GEN_NXT_PF_D__RS_EQ_0
      assign next_prefilling_d_int = ((prefill_d == 1'b1) && (next_count_d < prefill_lvl)) ? 1'b1 :
                                      (next_count_d >= prefill_lvl) ? 1'b0 : prefilling_d_int;
    end
  end

endgenerate

generate
  if (prefill_lvl == 0) begin : GEN_NXT_DAD_PF_EQ_0
    assign next_data_avail_d_int = |(({depth{det_event_level_n}} ^ dw_sync_event_vec_cc) & rcv_d_cntr_new);
  end else begin : GEN_NXT_DAD_PF_NE_0
    assign next_data_avail_d_int = |(({depth{det_event_level_n}} ^ dw_sync_event_vec_cc) & rcv_d_cntr_new) && ~next_prefilling_d_int;
  end
endgenerate

  always @(data_s_vec or rcv_d_cntr_new) begin : PROC_MASK_DATA_S
    integer m_a, m_b;

    for (m_a = 0; m_a < depth; m_a = m_a + 1) begin
      for (m_b = 0; m_b < width; m_b = m_b + 1) begin
	masked_data_s_vec[m_a*width+m_b] =
	   data_s_vec[m_a*width+m_b] & rcv_d_cntr_new[m_a];
      end  // for (m_b = 0
    end  // for (m_a = 0
  end  // always @(data_s_vec

  always @(masked_data_s_vec) begin : PROC_MASK_DATA_MUX_OUT
    integer d_a, d_b;

    data_mux_out = {width{1'b0}};
    for (d_b = 0; d_b < width; d_b = d_b + 1) begin
      for (d_a = 0; d_a < depth; d_a = d_a + 1) begin
        data_mux_out[d_b] = data_mux_out[d_b] |
        	            masked_data_s_vec[d_a*width+d_b];
      end  // for (d_a = 0;
    end  // for (d_b = 0;
  end  // always @(data_s_vec

  assign next_data_d_int = (next_data_avail_d_int == 1'b1) ? data_mux_out : data_d_int;
				

  always @ (posedge clk_s or negedge rst_s_n) begin : PROC_posedge_s_registers
    if (rst_s_n == 1'b0) begin
      data_s_vec           <= {(width*depth){1'b0}};
      send_s_cntr          <= {depth{1'b0}};
      event_vec_s          <= {depth{1'b0}};
    end else if ((init_s_n == 1'b0) || (clr_in_prog_s == 1'b1)) begin
      data_s_vec           <= {(width*depth){1'b0}};
      send_s_cntr          <= {depth{1'b0}};
      event_vec_s          <= {depth{1'b0}};
    end else begin
      data_s_vec           <= next_data_s_vec;
      send_s_cntr          <= next_send_s_cntr;
      event_vec_s          <= next_event_vec_s;
    end
  end


  always @ (posedge clk_d or negedge rst_d_n) begin : PROC_posedge_d_registers
    if (rst_d_n == 1'b0) begin
      rcv_d_cntr           <= {depth{1'b0}};
      count_d              <= {bit_width{1'b0}};
      det_event_level_n    <= 1'b0;
      data_avail_d_int     <= 1'b0;
      data_d_int           <= {width{1'b0}};
      prefilling_d_int     <= 1'b0;
    end else if ((init_d_n == 1'b0) || (clr_in_prog_d == 1'b1))  begin
      rcv_d_cntr           <= {depth{1'b0}};
      count_d              <= {bit_width{1'b0}};
      det_event_level_n    <= 1'b0;
      data_avail_d_int     <= 1'b0;
      data_d_int           <= {width{1'b0}};
      prefilling_d_int     <= 1'b0;
    end else begin
      rcv_d_cntr           <= next_rcv_d_cntr;
      count_d              <= next_count_d;
      det_event_level_n    <= ~next_det_event_level_n;
      data_avail_d_int     <= next_data_avail_d_int;
      data_d_int           <= next_data_d_int;
      prefilling_d_int     <= next_prefilling_d_int;
    end
  end


  assign data_avail_d = data_avail_d_int;
  assign data_d       = data_d_int;
  assign prefilling_d = prefilling_d_int;

endmodule
