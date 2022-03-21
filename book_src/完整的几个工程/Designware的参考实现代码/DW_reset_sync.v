////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from 
//     In the event of publication, the following notice is applicable:
//
//                    
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
//     12/05/05
//
// VERSION:   Verilog Synthesis Model for DWbb_reset_sync
//
// DesignWare_version: 070a5da9
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Reset Synchronizer 
//
//           This synchronizer orchestrates a synchronous reset sequence between the source
//           and destination domains.
//
//              Parameters:     Valid Values
//              ==========      ============
//              f_sync_type     default: 2
//                              Forward Synchronized Type (Source to Destination Domains)
//                                0 = single clock design, no synchronizing stages implemented,
//                                1 = 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing,
//                                2 = 2-stage synchronization w/ both stages pos-edge capturing,
//                                3 = 3-stage synchronization w/ all stages pos-edge capturing
//                                4 = 4-stage synchronization w/ all stages pos-edge capturing
//              r_sync_type     default: 2
//                              Reverse Synchronization Type (Destination to Source Domains)
//                                0 = single clock design, no synchronizing stages implemented,
//                                1 = 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing,
//                                2 = 2-stage synchronization w/ both stages pos-edge capturing,
//                                3 = 3-stage synchronization w/ all stages pos-edge capturing
//                                4 = 4-stage synchronization w/ all stages pos-edge capturing
//              clk_d_faster    default: 1
//                              clk_d faster than clk_s by difference ratio
//                                0        = Either clr_s or clr_d active with the other tied low at input
//                                1 to 15  = ratio of clk_d to clk_s plus 1
//              reg_in_prog     default: 1
//                              Register the 'clr_in_prog_s' and 'clr_in_prog_d' Outputs
//                                0 = unregistered
//                                1 = registered
//              tst_mode        default: 0
//                              Test Mode Setting
//                                0 = no hold latch inserted,
//                                1 = insert hold 'latch' using a neg-edge triggered register
//                                2 = insert hold latch using active low latch
//              verif_en          Synchronization missampling control (Simulation verification)
//                                Default value = 1
//                                0 => no sampling errors modeled,
//                                1 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 1 cycle delay
//                                2 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 1.5 cycle delay
//                                3 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 3 cycle delay
//                                4 => when DW_MODEL_MISSAMPLES defined, randomly insert 0 to 0.5 cycle delay
//                                Note: Use `define DW_MODEL_MISSAMPLES to define the Verilog macro
//                                      that turns on missample modeling in a Verilog HDL file.  Use
//                                      +define+DW_MODEL_MISSAMPLES simulator command line option to turn
//                                      on missample modeleng from the simulator command.
//              
//              Input Ports:    Size     Description
//              ===========     ====     ===========
//              clk_s           1 bit    Source Domain Input Clock
//              rst_s_n         1 bit    Source Domain Active Low Async. Reset
//		init_s_n        1 bit    Source Domain Active Low Sync. Reset
//              clr_s           1 bit    Source Domain Clear Initiated
//              clk_d           1 bit    Destination Domain Input Clock
//              rst_d_n         1 bit    Destination Domain Active Low Async. Reset
//		init_d_n        1 bit    Destination Domain Active Low Sync. Reset
//              clr_d           1 bit    Destination Domain Clear Initiated
//              test            1 bit    Test input
//
//              Output Ports    Size     Description
//              ============    ====     ===========
//              clr_sync_s      1 bit    Source Domain Clear
//              clr_in_prog_s   1 bit    Source Domain Clear in Progress
//              clr_cmplt_s     1 bit    Source Domain Clear Complete (pulse)
//              clr_in_prog_d   1 bit    Destination Domain Clear in Progress
//              clr_sync_d      1 bit    Destination Domain Clear (pulse)
//              clr_cmplt_d     1 bit    Destination Domain Clear Complete (pulse)
//
//
// MODIFIED: 
//
//              DLL  10-04-11  Instrumented to allow the "alt" version of this component for
//                             BCMs to be used for its derivation.
//
//              DLL   7-22-11  Add inherent delay to the feedback path in the destination
//                             domain and clr_in_prog_d.  This effectively extends the 
//                             destination domain acive clearing state.
//                             Also added 'tst_mode = 2' capability.
//
//              DLL   6-20-11  Added pragmas to disable Leda warnings and re-coded some lines
//                             to prevent Leda warnings.
//                             Added 'tst_mode = 2' capability.
//
//              DLL   9-5-08   Accommodate sustained "clr_s" and "clr_d" assertion behavior.
//                             Satisfies STAR#9000261751.
//                             This enhancement Renders 'clk_d_faster' parameter obsolete.
//
//              DLL   8-6-08   Filter long pulses of "clr_s" and "clr_d" to one
//                             clock cycle pulses.
//
//              DLL   1-10-07  Converted looping variable from global to local
//
//              DLL   11-7-06  Modified functionality to support f_sync_type = 4 and
//                             r_sync_type = 4.
//
//              DLL  10-31-06  Added SystemVerilog assertions
//
//              DLL   8-21-06  Added parameters 'r_sync_type', 'clk_d_faster', 'reg_in_prog'.
//                             Added Destination outputs 'clr_in_prog_d' and 'clr_cmplt_d'
//                             and changed Source output 'clr_ack_s' to 'clr_cmplt_s'.
//
//
////////////////////////////////////////////////////////////////////////////////

module DW_reset_sync (
    clk_s,
    rst_s_n,
    init_s_n,
    clr_s,
    clr_sync_s,
    clr_in_prog_s,
    clr_cmplt_s,

    clk_d,
    rst_d_n,
    init_d_n,
    clr_d,
    clr_in_prog_d,
    clr_sync_d,
    clr_cmplt_d,

    test
    // Embedded dc_shell script
    // _model_constraint_1
    );

parameter f_sync_type  = 2;  // RANGE 0 to 4
parameter r_sync_type  = 2;  // RANGE 0 to 4
parameter clk_d_faster = 1;  // RANGE 0 to 15
parameter reg_in_prog  = 1;  // RANGE 0 to 1
parameter tst_mode     = 0;  // RANGE 0 to 2
parameter verif_en     = 1;  // RANGE 0 to 4

input			clk_s;         // clock input from source domain
input			rst_s_n;       // active low asynchronous reset from source domain
input			init_s_n;      // active low synchronous reset from source domain
input			clr_s;         // active high clear from source domain 
output                  clr_sync_s;    // clear to source domain sequential devices
output                  clr_in_prog_s; // clear in progress status to source domain
output                  clr_cmplt_s;   // clear sequence complete (pulse)

input			clk_d;         // clock input from destination domain
input			rst_d_n;       // active low asynchronous reset from destination domain
input			init_d_n;      // active low synchronous reset from destination domain
input			clr_d;         // active high clear from destination domain 
output                  clr_in_prog_d; // clear in progress status to source domain
output                  clr_sync_d;    // clear to destination domain sequential devices (pulse)
output                  clr_cmplt_d;   // clear sequence complete (pulse)

input                   test;          // test input


wire                         drs_clr_s;
wire                         drs_clr_d;

wire                         clr_s_re_cc;
wire                         clr_s_cc;
wire                         clr_s_merge_cc;


reg   [1:0]                  clr_vec_s;     

wire  [1:0]                  next_clr_vec_s;
wire                         clr_in_prog_s_int;

wire                         next_clr_in_prog_d_int;
reg                          clr_in_prog_d_int;
reg                          clr_in_prog_d_int_d1;  


wire                         clr_d_merge;
wire                         clr_d_merge_hist_masked;

wire                         clr_sync_s_int;
reg                          clr_sync_s_int_d1;

wire                         start_ack_d_event;
reg                          start_ack_d;
wire                         next_start_ack_d;

wire                         clr_ack_s;

reg                          clr_cmplt_s_int;
wire                         next_clr_cmplt_s_int;
wire                         clr_cmplt_s;

reg                          clr_cmplt_d_int;
wire                         next_clr_cmplt_d_int;
wire                         clr_cmplt_d;

wire                         next_event_hold;
wire                         rls_event_hold;
reg                          event_hold;

reg                          clr_d_merge_d1;
wire                         set_clr_d_mask;
wire                         unset_clr_d_mask;
wire                         next_clr_d_mask; 
reg                          clr_d_mask; 
wire                         clr_d_merge_masked;

reg                          drs_clr_s_l;
wire                         drs_clr_s_cc;






assign drs_clr_s = clr_s;
assign drs_clr_d = clr_d;


generate
  if (reg_in_prog == 0) begin : GEN_CLR_D_MASK_RIP0
    assign set_clr_d_mask = (clr_d_merge && !clr_d_merge_d1) || ((next_clr_in_prog_d_int && !clr_in_prog_d_int) && clr_d_merge);
  end else begin : GEN_CLR_D_MASK_RIP1
    assign set_clr_d_mask = next_clr_in_prog_d_int && !clr_in_prog_d_int;
  end
endgenerate
assign unset_clr_d_mask = !next_clr_in_prog_d_int && clr_in_prog_d_int;
assign next_clr_d_mask  = (set_clr_d_mask && !unset_clr_d_mask) ? 1'b1 :
                            (unset_clr_d_mask) ? 1'b0 : clr_d_mask;


DW_pulse_sync #(1, (f_sync_type + 8) , tst_mode, verif_en, 1) U_PS_CLR_FROM_SRC (
            .clk_s(clk_s),
            .rst_s_n(rst_s_n),
            .init_s_n(init_s_n),
            .event_s(drs_clr_s),
            .clk_d(clk_d),
            .rst_d_n(rst_d_n),
            .init_d_n(init_d_n),
            .test(test),
            .event_d(clr_s_re_cc)
            ); 

  
  
generate
  if (((f_sync_type&7)>1)&&(tst_mode==2)) begin : GEN_LATCH_frwd_hold_latch_PROC
    always @ (clk_s or drs_clr_s) begin : frwd_hold_latch_PROC
      if (clk_s == 1'b0)

	drs_clr_s_l <= drs_clr_s;

    end // frwd_hold_latch_PROC

    assign drs_clr_s_cc = (test==1'b1)? drs_clr_s_l : drs_clr_s;
  end else begin : GEN_DIRECT_frwd_hold_latch_PROC
    assign drs_clr_s_cc = drs_clr_s;
  end
endgenerate

  DW_sync #(1, f_sync_type+8, tst_mode, verif_en) U_SYNC_CLR_S(
	.clk_d(clk_d),
	.rst_d_n(rst_d_n),
	.init_d_n(init_d_n),
	.data_s(drs_clr_s_cc),
	.test(test),
	.data_d(clr_s_cc) );

assign clr_s_merge_cc = clr_s_re_cc || clr_s_cc;



assign clr_d_merge              = clr_s_merge_cc || drs_clr_d;
assign clr_d_merge_masked       = clr_d_merge && !clr_d_mask;

DW_pulse_sync #(1, (r_sync_type + 8) , tst_mode, verif_en, 0) U_PS_CLR_FROM_DEST (
            .clk_s(clk_d),
            .rst_s_n(rst_d_n),
            .init_s_n(init_d_n),
            .event_s(clr_d_merge_masked),
            .clk_d(clk_s),
            .rst_d_n(rst_s_n),
            .init_d_n(init_s_n),
            .test(test),
            .event_d(clr_sync_s_int)
            ); 

DW_pulse_sync #(0, (f_sync_type + 8) , tst_mode, verif_en, 0) U_PS_FB_TO_DEST (
            .clk_s(clk_s),
            .rst_s_n(rst_s_n),
            .init_s_n(init_s_n),
            .event_s(clr_sync_s_int_d1),
            .clk_d(clk_d),
            .rst_d_n(rst_d_n),
            .init_d_n(init_d_n),
            .test(test),
            .event_d(start_ack_d_event)
            ); 


assign rls_event_hold   = !start_ack_d_event && (!clr_d_merge && event_hold);
assign next_event_hold  = (start_ack_d_event && clr_d_merge) ? 1'b1 :
                            rls_event_hold ? 1'b0 : event_hold;
  
assign next_start_ack_d  = (start_ack_d_event && !clr_d_merge && !event_hold) ||
                           rls_event_hold;


DW_pulse_sync #(0, (r_sync_type + 8) , tst_mode, verif_en, 0) U_PS_ACK_TO_SRC (
            .clk_s(clk_d),
            .rst_s_n(rst_d_n),
            .init_s_n(init_d_n),
            .event_s(start_ack_d),
            .clk_d(clk_s),
            .rst_d_n(rst_s_n),
            .init_d_n(init_s_n),
            .test(test),
            .event_d(clr_ack_s)
            ); 

  assign next_clr_vec_s         = ((clr_sync_s_int == 1'b1) && (clr_ack_s == 1'b0)) ? {clr_vec_s[0], 1'b1} :
                                      ((clr_sync_s_int == 1'b0) && (clr_ack_s == 1'b1)) ?  {1'b0, clr_vec_s[1]} :
                                         clr_vec_s;

  assign next_clr_cmplt_s_int   = ~next_clr_vec_s[0] && clr_vec_s[0];


  always @ (posedge clk_s or negedge rst_s_n) begin : PROC_posedge_src_registers
    if (rst_s_n == 1'b0) begin
      clr_vec_s            <= 2'b00;
      clr_cmplt_s_int      <= 1'b0;
      clr_sync_s_int_d1    <= 1'b0;
    end else if (init_s_n == 1'b0) begin
      clr_vec_s            <= 2'b00;
      clr_cmplt_s_int      <= 1'b0;
      clr_sync_s_int_d1    <= 1'b0;
    end else begin
      clr_vec_s            <= next_clr_vec_s;
      clr_cmplt_s_int      <= next_clr_cmplt_s_int;
      clr_sync_s_int_d1    <= clr_sync_s_int;
    end
  end


  assign next_clr_in_prog_d_int  = ((clr_d_merge_masked == 1'b1) && (start_ack_d == 1'b0)) ? 1'b1 :
                                       ((clr_d_merge_masked == 1'b0) && (start_ack_d == 1'b1)) ? 1'b0 :
                                          clr_in_prog_d_int;

  assign next_clr_cmplt_d_int   = ~clr_in_prog_d_int && clr_in_prog_d_int_d1;


  always @ (posedge clk_d or negedge rst_d_n) begin : PROC_posedge_dest_registers
    if (rst_d_n == 1'b0) begin
      clr_d_merge_d1       <= 1'b0;
      clr_d_mask           <= 1'b0; 
      event_hold           <= 1'b0;
      clr_in_prog_d_int    <= 1'b0;
      clr_in_prog_d_int_d1 <= 1'b0;
      start_ack_d          <= 1'b0;
      clr_cmplt_d_int      <= 1'b0;
    end else if (init_d_n == 1'b0) begin
      clr_d_merge_d1       <= 1'b0;
      clr_d_mask           <= 1'b0; 
      event_hold           <= 1'b0;
      clr_in_prog_d_int    <= 1'b0;
      clr_in_prog_d_int_d1 <= 1'b0;
      start_ack_d          <= 1'b0;
      clr_cmplt_d_int      <= 1'b0;
    end else begin
      clr_d_merge_d1       <= clr_d_merge;
      clr_d_mask           <= next_clr_d_mask; 
      event_hold           <= next_event_hold;
      clr_in_prog_d_int    <= next_clr_in_prog_d_int;
      clr_in_prog_d_int_d1 <= clr_in_prog_d_int;
      start_ack_d          <= next_start_ack_d;
      clr_cmplt_d_int      <= next_clr_cmplt_d_int;
    end
  end


assign clr_in_prog_s_int = clr_vec_s[0];

  assign clr_sync_s      = clr_sync_s_int;
generate
  if (reg_in_prog == 1) begin : GEN_CIPS1
    assign clr_in_prog_s = clr_in_prog_s_int;
  end else begin : GEN_CIPS0
    assign clr_in_prog_s = next_clr_vec_s[0];
  end
endgenerate

  assign clr_cmplt_s     = clr_cmplt_s_int;

generate
  if (reg_in_prog == 1) begin : GEN_CIPD1
    assign clr_in_prog_d = clr_in_prog_d_int_d1;
  end else begin : GEN_CIPD0
     assign clr_in_prog_d = clr_in_prog_d_int;
  end
endgenerate

  assign clr_sync_d      = start_ack_d;
  assign clr_cmplt_d     = clr_cmplt_d_int;

endmodule
