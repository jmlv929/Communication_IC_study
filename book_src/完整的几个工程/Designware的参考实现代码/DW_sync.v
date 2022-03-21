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
//     2/20/05
//
// VERSION:   Verilog Synthesis Model for DWbb_sync
//
// DesignWare_version: ef7f39a1
// DesignWare_release: G-2012.06-DWBB_201206.1
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Fundamental Synchronizer 
//
//           This synchronizes incoming data into the destination domain
//           with a configurable number of sampling stages.
//
//
//              Parameters:     Valid Values
//              ==========      ============
//              width           [ 1 to 1024 ]
//              f_sync_type     [ 0 = single clock design, no synchronizing stages implemented,
//                                1 = 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing,
//                                2 = 2-stage synchronization w/ both stages pos-edge capturing,
//                                3 = 3-stage synchronization w/ all stages pos-edge capturing,
//                                4 = 4-stage synchronization w/ all stages pos-edge capturing ]
//              tst_mode        [ 0 = no hold latch inserted,
//                                1 = insert hold 'latch' using a neg-edge triggered register
//                                2 = reserved (functions same as tst_mode=0 ]
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
//              Input Ports:    Size    Description
//              ===========     ====    ===========
//              clk_d           1 bit   Destination Domain Input Clock
//              rst_d_n         1 bit   Destination Domain Active Low Async. Reset
//		init_d_n        1 bit   Destination Domain Active Low Sync. Reset
//              data_s          N bits  Source Domain Data Input
//              test            1 bit   Test input
//
//              Output Ports    Size    Description
//              ============    ====    ===========
//              data_d          N bits  Destination Domain Data Output
//
//                Note: the value of N is equal to the 'width' parameter value
//
//
// MODIFIED: 
//     10/26/06  DLL  Added capability to be 4-stages (all positive edge)
//
//     11/15/06  DLL  Revised approach to routing missampling and X processing of data_s
//
//      2/03/09  RJK  Added static seed if $random function
//
//      6/17/10  DLL  Removed directive to '-dont_show' references under licensing.
//                    Fixes an error of a returned empty list when f_sync_type=0.
//                    Addresses STAR#9000401601.
//
//      7/21/10  DLL  Incorporated generate blocks wherever possible especially to replace
//                    'constant expression conditionals'.
//
//       4/1/11  DLL  Default to 'generate-if' structures instead of 'generate-case' to
//                    accommodate Leda capabilities.  Also, coded #ifdef clauses to allow
//                    derivation of DW_sync_lite (no 'test' and no synchronous reset
//                    capability).
//
//       6/20/11 DLL  Added pragma to disable Leda warning regarding verif_en and general
//                    cleanup.
//
//
//
////////////////////////////////////////////////////////////////////////////////


module DW_sync (
    clk_d,
    rst_d_n,
    init_d_n,
    data_s,
    test,
    data_d
    // Embedded dc_shell script
    // if ( find( "cell", "*sample_nsyncf*" ) ) {
    //   set_attribute find("cell", "*sample_nsyncf*") "syncff_first_n" "true" -type "boolean" -quiet
    //   set_dont_retime find("cell", "*sample_nsyncf*") "true"
    // }
    // if ( find( "cell", "*sample_syncf*" ) ) {
    //   set_attribute find("cell", "*sample_syncf*") "syncff_first" "true" -type "boolean" -quiet
    //   set_dont_retime find("cell", "*sample_syncf*") "true"
    // }
    // if ( find( "cell", "*sample_syncm*" ) ) {
    //   set_attribute find("cell", "*sample_syncm*") "syncff_middle" "true" -type "boolean" -quiet
    //   set_dont_retime find("cell", "*sample_syncm*") "true"
    // }
    // if ( find( "cell", "*sample_syncl*" ) ) {
    //   set_attribute find("cell", "*sample_syncl*") "syncff_last" "true" -type "boolean" -quiet
    //   set_dont_retime find("cell", "*sample_syncl*") "true"
    // }
    // _model_constraint_1
    );

parameter width        = 1;  // RANGE 1 to 1024
parameter f_sync_type  = 2;  // RANGE 0 to 4
parameter tst_mode     = 0;  // RANGE 0 to 2

parameter verif_en     = 1;  // RANGE 0 to 5



input			clk_d;      // clock input from destination domain
input			rst_d_n;    // active low asynchronous reset from destination domain
input			init_d_n;   // active low synchronous reset from destination domain
input  [width-1:0]      data_s;     // data to be synchronized from source domain
input                   test;       // test input
output [width-1:0]      data_d;     // data synchronized to destination domain


reg    [width-1:0]      sample_nsyncf;
reg    [width-1:0]      sample_syncf;
reg    [width-1:0]      sample_syncm1;
reg    [width-1:0]      sample_syncm2;
reg    [width-1:0]      sample_syncl;
reg    [width-1:0]      test_hold;

wire   [width-1:0]      next_sample_syncf;
wire   [width-1:0]      next_sample_syncm1;
wire   [width-1:0]      next_sample_syncm2;
wire   [width-1:0]      next_sample_syncl;





`define DW_data_s_int data_s
  generate
    if ((f_sync_type & 7) == 1) begin : GEN_NXT_SYNCM1_FST1
      assign next_sample_syncm1 = sample_nsyncf;
    end
    if ((f_sync_type & 7) > 1) begin : GEN_NXT_SYNCM1_FST_GT_1
      assign next_sample_syncm1 = sample_syncf;
    end
  endgenerate



generate
  if (tst_mode == 1) begin : GEN_TST_MODE1
    assign next_sample_syncf      = (test == 1'b0) ? `DW_data_s_int : test_hold;

    always @ (negedge clk_d or negedge rst_d_n) begin : PROC_test_hold_registers
      if (rst_d_n == 1'b0) begin
        test_hold        <= {width{1'b0}};
      end else if (init_d_n == 1'b0) begin
        test_hold        <= {width{1'b0}};
      end else begin
        test_hold        <= data_s;
      end
    end
  end else begin : GEN_TST_MODE0
    assign next_sample_syncf      = (test == 1'b0) ? `DW_data_s_int : data_s;
  end
endgenerate


generate
    if ((f_sync_type & 7) == 0) begin : GEN_FST0
      if (tst_mode == 1) begin : GEN_DATAD_FST0_TM1
        assign data_d  = (test == 1'b1) ? test_hold : data_s;
      end else begin : GEN_DATAD_FST0_TM_NE_1
        assign data_d  =  data_s;
      end
    end
    if ((f_sync_type & 7) == 1) begin : GEN_FST1
         always @ (negedge clk_d or negedge rst_d_n) begin : PROC_negedge_registers
           if (rst_d_n == 1'b0) begin
             sample_nsyncf    <= {width{1'b0}};
           end else if (init_d_n == 1'b0) begin
             sample_nsyncf    <= {width{1'b0}};
           end else begin
             sample_nsyncf    <= `DW_data_s_int;
           end
         end

         assign next_sample_syncl = next_sample_syncm1;

         always @ (posedge clk_d or negedge rst_d_n) begin : PROC_posedge_registers
           if (rst_d_n == 1'b0) begin
             sample_syncl     <= {width{1'b0}};
           end else if (init_d_n == 1'b0) begin
             sample_syncl     <= {width{1'b0}};
           end else begin
             sample_syncl     <= next_sample_syncl;
           end
         end

         assign data_d = sample_syncl;
    end
    if ((f_sync_type & 7) == 2) begin : GEN_FST2
         assign next_sample_syncl = next_sample_syncm1;
         always @ (posedge clk_d or negedge rst_d_n) begin : PROC_posedge_registers
           if (rst_d_n == 1'b0) begin
             sample_syncf     <= {width{1'b0}};
             sample_syncl     <= {width{1'b0}};
           end else if (init_d_n == 1'b0) begin
             sample_syncf     <= {width{1'b0}};
             sample_syncl     <= {width{1'b0}};
           end else begin
             sample_syncf     <= next_sample_syncf;
             sample_syncl     <= next_sample_syncl;
           end
         end

         assign data_d = sample_syncl;
    end
    if ((f_sync_type & 7) == 3) begin : GEN_FST3
         assign next_sample_syncl = sample_syncm1;
         always @ (posedge clk_d or negedge rst_d_n) begin : PROC_posedge_registers
           if (rst_d_n == 1'b0) begin
             sample_syncf     <= {width{1'b0}};
             sample_syncm1    <= {width{1'b0}};
             sample_syncl     <= {width{1'b0}};
           end else if (init_d_n == 1'b0) begin
             sample_syncf     <= {width{1'b0}};
             sample_syncm1    <= {width{1'b0}};
             sample_syncl     <= {width{1'b0}};
           end else begin
             sample_syncf     <= next_sample_syncf;
             sample_syncm1    <= next_sample_syncm1;
             sample_syncl     <= next_sample_syncl;
           end
         end

         assign data_d = sample_syncl;
    end
    if ((f_sync_type & 7) == 4) begin : GEN_FST4
         assign next_sample_syncm2 = sample_syncm1;
         assign next_sample_syncl  = sample_syncm2;
         always @ (posedge clk_d or negedge rst_d_n) begin : PROC_posedge_registers
           if (rst_d_n == 1'b0) begin
             sample_syncf     <= {width{1'b0}};
             sample_syncm1    <= {width{1'b0}};
             sample_syncm2    <= {width{1'b0}};
             sample_syncl     <= {width{1'b0}};
           end else if (init_d_n == 1'b0) begin
             sample_syncf     <= {width{1'b0}};
             sample_syncm1    <= {width{1'b0}};
             sample_syncm2    <= {width{1'b0}};
             sample_syncl     <= {width{1'b0}};
           end else begin
             sample_syncf     <= next_sample_syncf;
             sample_syncm1    <= next_sample_syncm1;
             sample_syncm2    <= next_sample_syncm2;
             sample_syncl     <= next_sample_syncl;
           end
         end

         assign data_d = sample_syncl;
    end
endgenerate

`undef DW_data_s_int
endmodule
