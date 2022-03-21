
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Data Bus Synchronizer without acknowledge Synthetic Model
//
//           This synchronizer passes data values from the source domain to the destination domain. 
//           Full feedback hand-shake is NOT used. So there is no busy or done status on in the source domain. 
//
//              Parameters:     Valid Values
//              ==========      ============
//              width           [ default : 8
//                                1 to 1024 : width of data_s and data_d ports ]
//              f_sync_type     [ default : 2
//                                0 = single clock design, no synchronizing stages implemented,
//                                1 = 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing,
//                                2 = 2-stage synchronization w/ both stages pos-edge capturing,
//                                3 = 3-stage synchronization w/ all stages pos-edge capturing,
//                                4 = 4-stage synchronization w/ all stages pos-edge capturing ]
//              tst_mode        [ default : 0
//                                0 = no hold latch inserted,
//                                1 = insert hold 'latch' using a neg-edge triggered register
//                                2 = insert hold latch using active low latch ]
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
//              send_mode       [ default : 0 (send_s detection control)
//                                0 = every clock cycle of send_s asserted invokes
//                                    a data transfer to destination domain
//                                1 = rising edge transition of send_s invokes
//                                    a data transfer to destination domain
//                                2 = falling edge transition of send_s invokes
//                                    a data transfer to destination domain
//                                3 = every toggle transition of send_s invokes
//                                    a data transfer to destination domain ]
//
//              
//              Input Ports:    Size     Description
//              ===========     ====     ===========
//              clk_s           1 bit    Source Domain Input Clock
//              rst_s_n         1 bit    Source Domain Active Low Async. Reset
//		init_s_n        1 bit    Source Domain Active Low Sync. Reset
//              send_s          1 bit    Source Domain Active High Send Request
//              data_s          N bits   Source Domain Data Input
//              clk_d           1 bit    Destination Domain Input Clock
//              rst_d_n         1 bit    Destination Domain Active Low Async. Reset
//		init_d_n        1 bit    Destination Domain Active Low Sync. Reset
//              test            1 bit    Test input
//
//              Output Ports    Size     Description
//              ============    ====     ===========
//              data_avail_d    1 bit    Destination Domain Data Available Output
//              data_d          N bits   Destination Domain Data Output
//
//                Note: (1) The value of N is equal to the 'width' parameter value
//
//
// MODIFIED: 
//
//              DLL  6/23/11  Added pragmas to disable some Leda warnings along
//                            with converted to using 'generate' blocks.
//
//              DLL  11/15/06 Added 4-stage synchronization capability
//
//              DLL  6/8/06   Added send_mode parameter and functionality
//
////////////////////////////////////////////////////////////////////////////////

module DW_data_sync_na (
    clk_s,
    rst_s_n,
    init_s_n,
    send_s,
    data_s,
    clk_d,
    rst_d_n,
    init_d_n,
    test,
    data_avail_d,
    data_d
    // Embedded dc_shell script
    // _model_constraint_1
    );

parameter width        = 8;  // RANGE 1 to 1024
parameter f_sync_type  = 2;  // RANGE 0 to 4
parameter tst_mode     = 0;  // RANGE 0 to 2

parameter verif_en     = 1;  // RANGE 0 to 4

parameter send_mode    = 0;  // RANGE 0 to 3


input			clk_s;         // clock input from source domain
input			rst_s_n;       // active low asynchronous reset from source domain
input			init_s_n;      // active low synchronous reset from source domain
input			send_s;        // active high send request from source domain 
input  [width-1:0]      data_s;        // data to be synchronized from source domain
input			clk_d;         // clock input from destination domain
input			rst_d_n;       // active low asynchronous reset from destination domain
input			init_d_n;      // active low synchronous reset from destination domain
input                   test;          // test input
output                  data_avail_d;  // data available to destination domain
output [width-1:0]      data_d;        // data synchronized to destination domain

wire                    drs_send_s;
wire   [width-1:0]      drs_data_s;

reg                     send_s_reg;    // send_s history register
wire                    send_s_int;    // conditioned 'send_s' based on 'send_mode'

reg    [width-1:0]      data_s_hold;
wire   [width-1:0]      next_data_s_hold;

reg    [width-1:0]      data_d_int;
wire   [width-1:0]      next_data_d_int;
reg                     data_avail_d_int;
wire                    next_data_avail_d_int;

wire                    dw_pulse_sync_event_d;







  assign drs_send_s = send_s;
  assign drs_data_s = data_s;


DW_pulse_sync #(0, (f_sync_type + 8) , tst_mode, verif_en, send_mode) U_PULSE_SYNC (
            .clk_s(clk_s),
            .rst_s_n(rst_s_n),
            .init_s_n(init_s_n),
            .event_s(drs_send_s),
            .clk_d(clk_d),
            .rst_d_n(rst_d_n),
            .init_d_n(init_d_n),
            .test(test),
            .event_d(dw_pulse_sync_event_d)
            ); 

generate
  if (send_mode == 0) begin : GEN_SEND_S_INT_SM0
    assign send_s_int = send_s;
  end
  if (send_mode == 1) begin : GEN_SEND_S_INT_SM1
    assign send_s_int = send_s && !send_s_reg;
  end
  if (send_mode == 2) begin : GEN_SEND_S_INT_SM2
    assign send_s_int = !send_s && send_s_reg;
  end
  if (send_mode > 2) begin : GEN_SEND_S_INT_SM_GT_2
    assign send_s_int = send_s ^ send_s_reg;
  end
endgenerate

  assign next_data_s_hold = (send_s_int == 1'b1) ? drs_data_s : data_s_hold;

  assign next_data_avail_d_int = dw_pulse_sync_event_d;
  assign next_data_d_int       = (next_data_avail_d_int == 1'b1) ? data_s_hold : data_d_int;
				

  always @ (posedge clk_s or negedge rst_s_n) begin : PROC_posedge_source_registers
    if (rst_s_n == 1'b0) begin
      send_s_reg           <= 1'b0;
      data_s_hold          <= {width{1'b0}};
    end else if (init_s_n == 1'b0) begin
      send_s_reg           <= 1'b0;
      data_s_hold          <= {width{1'b0}};
    end else begin
      send_s_reg           <= drs_send_s;
      data_s_hold          <= next_data_s_hold;
    end
  end


  always @ (posedge clk_d or negedge rst_d_n) begin : PROC_posedge_destination_registers
    if (rst_d_n == 1'b0) begin
      data_avail_d_int     <= 1'b0;
      data_d_int           <= {width{1'b0}};
    end else if (init_d_n == 1'b0) begin
      data_avail_d_int     <= 1'b0;
      data_d_int           <= {width{1'b0}};
    end else begin
      data_avail_d_int     <= next_data_avail_d_int;
      data_d_int           <= next_data_d_int;
    end
  end


  assign data_avail_d = data_avail_d_int;
  assign data_d       = data_d_int;


endmodule
