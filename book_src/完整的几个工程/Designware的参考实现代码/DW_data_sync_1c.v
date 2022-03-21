
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Single Clock Data Bus Synchronizer Synthetic Model
//
//           This synchronizes incoming data into the destination domain
//           with a configurable number of sampling stages and consecutive
//           samples of stable data values.
//
//              Parameters:     Valid Values
//              ==========      ============
//              width           [ 1 to 1024 : width of data_s and data_d ports ]
//              f_sync_type     [ 0 = single clock design, no synchronizing stages implemented,
//                                1 = 2-stage synchronization w/ 1st stage neg-edge & 2nd stage pos-edge capturing,
//                                2 = 2-stage synchronization w/ both stages pos-edge capturing,
//                                3 = 3-stage synchronization w/ all stages pos-edge capturing,
//                                4 = 4-stage synchronization w/ all stages pos-edge capturing ]
//              filt_size       [ 1 to 8 : width of filt_d input port ]
//              tst_mode        [ 0 = no hold latch inserted,
//                                1 = insert hold 'latch' using a neg-edge triggered register ]
//              verif_en          Synchronization missampling control (Simulation verification)
//                                Default value = 2
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
//              clk_d           1 bit    Destination Domain Input Clock
//              rst_d_n         1 bit    Destination Domain Active Low Async. Reset
//		init_d_n        1 bit    Destination Domain Active Low Sync. Reset
//              data_s          N bits   Source Domain Data Input
//              filt_d          M bits   Destination Domain filter defining the number of clk_d cycles required to declare stable data
//              test            1 bit    Test input
//
//              Output Ports    Size     Description
//              ============    ====     ===========
//              data_avail_d    1 bit    Destination Domain Data Available Output
//              data_d          N bits   Destination Domain Data Output
//              max_skew_d      M+1 bits Destination Domain maximum skew detected between bits for any data_s bus transition 
//
//                Note: (1) The value of M is equal to the 'filt_size' parameter value
//                      (2) The value of N is equal to the 'width' parameter value
//
//
// MODIFIED: 
//
//              DLL  6/24/11  Minor mods made to clean up Leda warnings.
//
//              DLL  11/15/06 Added 4-stage synchronization capability
//
//
//
////////////////////////////////////////////////////////////////////////////////

module DW_data_sync_1c (
    clk_d,
    rst_d_n,
    init_d_n,
    data_s,
    filt_d,
    test,
    data_avail_d,
    data_d,
    max_skew_d
    // Embedded dc_shell script
    // _model_constraint_1
    );

parameter width        = 8;  // RANGE 1 to 1024
parameter f_sync_type  = 2;  // RANGE 0 to 4
parameter filt_size    = 1;  // RANGE 1 to 8
parameter tst_mode     = 0;  // RANGE 0 to 1

parameter verif_en     = 2;  // RANGE 0 to 4



input			clk_d;         // clock input from destination domain
input			rst_d_n;       // active low asynchronous reset from destination domain
input			init_d_n;      // active low synchronous reset from destination domain
input  [width-1:0]      data_s;        // data to be synchronized from source domain
input  [filt_size-1:0]  filt_d;        // filter determining the number of clk_d cycles required to declare stable data to destination domain
input                   test;          // test input
output                  data_avail_d;  // data available to destination domain
output [width-1:0]      data_d;        // data synchronized to destination domain
output [filt_size:0]    max_skew_d;    // maximum skew detected between bits for any data_s bus transition 

wire   [width-1:0]      drs_data_s;

reg    [width-1:0]      data_d_int;
wire   [width-1:0]      next_data_d_int;
reg                     data_avail_d_int;
wire                    next_data_avail_d_int;
reg    [filt_size:0]    max_skew_d_int;
wire   [filt_size:0]    next_max_skew_d_int;
wire                    greater_skew;

reg    [filt_size-1:0]  counter;
wire   [filt_size:0]    next_counter;

reg                     counting_state;
wire                    next_counting_state;
reg    [filt_size:0]    skew_counter;
wire   [filt_size+1:0]  next_skew_counter;

wire   [width-1:0]      dw_sync_data_d;
reg    [width-1:0]      dw_sync_data_d_q;
wire   [width-1:0]      next_dw_sync_data_d_q;
wire                    diff;

localparam [filt_size-1:0] one_for_cntr     = 1;
localparam [filt_size:0]   one_for_skewcntr = 1;





  assign drs_data_s = data_s;

DW_sync #(width, (f_sync_type + 8) , tst_mode, verif_en) U_SYNC (
            .clk_d(clk_d),
            .rst_d_n(rst_d_n),
            .init_d_n(init_d_n),
            .data_s(drs_data_s),
            .test(test),
            .data_d(dw_sync_data_d)
            ); 

  assign next_dw_sync_data_d_q = dw_sync_data_d;

  assign diff  = (dw_sync_data_d != dw_sync_data_d_q);

  assign next_counting_state = (diff == 1'b1) ? 1'b1 : 
				 ( ((counting_state == 1'b1) && (diff == 1'b0) && (counter == filt_d) || 
				    (filt_d == {filt_size{1'b0}}) || (counter > filt_d)) ? 1'b0 : counting_state ); 

  assign next_counter   = ( (counter > filt_d) || ((counting_state == 1'b1) && (counter == filt_d) && (diff == 1'b0)) ) ? {filt_size{1'b0}} :
			    ( (diff == 1'b1) ? one_for_cntr :
			      ( (counting_state == 1'b1) ? (counter + one_for_cntr) : counter ) );

  assign next_data_d_int       = ((filt_d == {filt_size{1'b0}}) || (next_data_avail_d_int == 1'b1)) ? dw_sync_data_d : data_d;
  assign next_data_avail_d_int = (filt_d == {filt_size{1'b0}}) ? diff : (counting_state == 1'b1) && (counter == filt_d) && (diff == 1'b0);
				

  assign next_skew_counter = ( ((counting_state == 1'b0) && (diff == 1'b0)) ||
				(next_counting_state == 1'b0) || (counter > filt_d) ) ? {(filt_size+1){1'b0}} : (skew_counter + one_for_skewcntr);

  assign greater_skew = (skew_counter > max_skew_d_int);

generate
  if ((f_sync_type & 7) == 0) begin : GEN_NXT_MAX_SKEW_D_FS0
    assign next_max_skew_d_int = {(filt_size+1){1'b0}};
  end else begin : GEN_NXT_MAX_SKEW_D_FS_NE_0
    assign next_max_skew_d_int = ((counting_state == 1'b1) && (diff == 1'b1) && greater_skew) ? skew_counter : max_skew_d_int;
  end
endgenerate


  always @ (posedge clk_d or negedge rst_d_n) begin : PROC_posedge_registers
    if (rst_d_n == 1'b0) begin
      data_avail_d_int     <= 1'b0;
      data_d_int           <= {width{1'b0}};
      max_skew_d_int       <= {(filt_size+1){1'b0}};
      counting_state       <= 1'b0;
      counter              <= {filt_size{1'b0}};
      skew_counter         <= {(filt_size+1){1'b0}};
      dw_sync_data_d_q     <= {width{1'b0}};
    end else if (init_d_n == 1'b0) begin
      data_avail_d_int     <= 1'b0;
      data_d_int           <= {width{1'b0}};
      max_skew_d_int       <= {(filt_size+1){1'b0}};
      counting_state       <= 1'b0;
      counter              <= {filt_size{1'b0}};
      skew_counter         <= {(filt_size+1){1'b0}};
      dw_sync_data_d_q     <= {width{1'b0}};
    end else begin
      data_avail_d_int     <= next_data_avail_d_int;
      data_d_int           <= next_data_d_int;
      max_skew_d_int       <= next_max_skew_d_int;
      counting_state       <= next_counting_state;
      counter              <= next_counter[filt_size-1:0];
      skew_counter         <= next_skew_counter[filt_size:0];
      dw_sync_data_d_q     <= next_dw_sync_data_d_q;
    end
  end

  assign data_avail_d = data_avail_d_int;
  assign data_d       = data_d_int;
  assign max_skew_d   = max_skew_d_int;

endmodule
