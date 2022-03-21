
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//      Parameters:    Valid Values
//      ==========     ============
//      reg_event        0 to 1       default: 1
//                                    0 => event_d will have combination logic
//                                          but latency will be 1 cycle sooner
//                                    1 => event_d will be retimed so there will
//                                          be no logic between register & port
//                                          but event is delayed 1 cycle
//
//      f_sync_type      0 to 4       default: 2
//                                    0 => single clock design, i.e. clk_d == clk_s
//                                    1 => first synchronization in clk_d domain is
//                                          done on the negative edge and the rest
//                                          on positive edge.  This reduces latency
//                                          req. of synchronization slightly but
//                                          quicker metastability resolution for
//                                          the negative edge sensitive FF. It also
//                                          requires the technology library to 
//                                          contain an acceptable negative edge 
//                                          sensitive FF.
//                                    2 =>  all synchronization in clk_d domain is
//                                          done on positive edges - 2 d flops in
//                                          destination domain
//                                    3 =>  all synchronization in clk_d domain is
//                                          done on positive edges - 3 d flops in
//                                          destination domain
//                                    4 =>  all synchronization in clk_d domain is
//                                          done on positive edges - 4 d flops in
//                                          destination domain
//
//      tst_mode         0 to 2       default: 0
//                                    0 =>  no latch insertion
//                                    1 =>  hold latch using neg edge flop
//                                    2 =>  hold latch using active low latch
//
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
//
//      pulse_mode       0 to 3       default: 0
//                                    0 =>  single clock cycle pulse in produces
//                                          single clock cycle pulse out
//                                    1 =>  rising edge transition in produces
//                                          single clock cycle pulse out
//                                    2 =>  falling edge transition in produces
//                                          single clock cycle pulse out
//                                    3 =>  toggle transition in produces
//                                          single clock cycle pulse out
//
// MODIFIED:
//
//
//	DLL	6/20/2011	Modified to disable Leda warning.
//
//	RJK	4/22/2011	Recoded conditionals that were based on constants to
//				use generate-if statements instead (not gnerate-case).
//////////////////////////////////////////////////////////////////////////////// 
module DW_pulse_sync (
             clk_s, 
	     rst_s_n, 
	     init_s_n, 
	     event_s, 

	     clk_d, 
             rst_d_n, 
	     init_d_n, 
	     event_d,

	     test
    // Embedded dc_shell script
    // _model_constraint_1
	     );

 parameter reg_event    = 1;	// RANGE 0 to 1
 parameter f_sync_type  = 2;	// RANGE 0 to 4
 parameter tst_mode     = 0;	// RANGE 0 to 2

 parameter verif_en     = 1;    // RANGE 0 to 4

 parameter pulse_mode   = 0;    // RANGE 0 to 3
 
input  clk_s;			// clock input for source domain
input  rst_s_n;			// active low async. reset in clk_s domain
input  init_s_n;		// active low sync. reset in clk_s domain
input  event_s;			// event pulse input (active high event)

input  clk_d;			// clock input for destination domain
input  rst_d_n;			// active low async. reset in clk_d domain
input  init_d_n;		// active low sync. reset in clk_d domain
input  test;                    // test mode input.

output event_d;			// event pulse output (active high event)

wire   next_tgl_event_s;
wire   tgl_event_cc;
reg    tgl_event_s;
reg    event_s_d;
reg    tgl_event_l;
wire   dw_sync_data_d;
reg    sync_event_out;	  // history for edge detect
wire   next_event_d_q;	  // event seen via edge detect (before registered)
reg    event_d_q;	  // registered version of event seen
wire   event_s_pet;
wire   event_s_net;
wire   event_s_tgl;




generate
    
    if (pulse_mode <= 0) begin : GEN_PLSMD0
      assign next_tgl_event_s = tgl_event_s ^ event_s;
    end
    
    if (pulse_mode == 1) begin : GEN_PLSMD1
      assign next_tgl_event_s = tgl_event_s ^ event_s_pet;
    end
    
    if (pulse_mode == 2) begin : GEN_PLSMD2
      assign next_tgl_event_s = tgl_event_s ^ event_s_net;
    end
    
    if (pulse_mode >= 3) begin : GEN_PLSMD3
      assign next_tgl_event_s = tgl_event_s ^ (event_s_net | event_s_pet);
    end

endgenerate


 assign event_s_pet =  event_s & ! event_s_d;
 assign event_s_net = !event_s &   event_s_d;
 assign event_s_tgl = tgl_event_s ^ event_s_pet;
 
  always @ (posedge clk_s or negedge rst_s_n) begin : event_lauch_reg_PROC
    if (rst_s_n == 1'b0) begin
      tgl_event_s <= 1'b0;
      event_s_d   <= 1'b0;
    end else if (init_s_n == 1'b0) begin
      tgl_event_s <= 1'b0;
      event_s_d   <= 1'b0;
    end else begin
      tgl_event_s <= next_tgl_event_s;
      event_s_d   <= event_s;
    end
  end // always : event_lauch_reg_PROC
  

  
  
  
generate
  if (((f_sync_type&7)>1)&&(tst_mode==2)) begin : GEN_LATCH_frwd_hold_latch_PROC
    always @ (clk_s or tgl_event_s) begin : frwd_hold_latch_PROC
      if (clk_s == 1'b0)

	tgl_event_l <= tgl_event_s;

    end // frwd_hold_latch_PROC

    assign tgl_event_cc = (test==1'b1)? tgl_event_l : tgl_event_s;
  end else begin : GEN_DIRECT_frwd_hold_latch_PROC
    assign tgl_event_cc = tgl_event_s;
  end
endgenerate

  DW_sync #(1, f_sync_type+8, tst_mode, verif_en) U_SYNC(
	.clk_d(clk_d),
	.rst_d_n(rst_d_n),
	.init_d_n(init_d_n),
	.data_s(tgl_event_cc),
	.test(test),
	.data_d(dw_sync_data_d) );
 

  always @ (posedge clk_d or negedge rst_d_n) begin : second_sync_PROC
    if (rst_d_n == 1'b0) begin
      sync_event_out <= 1'b0;
      event_d_q      <= 1'b0;
    end else if (init_d_n == 1'b0) begin
      sync_event_out <= 1'b0;
      event_d_q      <= 1'b0;
    end else begin
      sync_event_out <= dw_sync_data_d;
      event_d_q      <= next_event_d_q;
    end
  end // always



  assign next_event_d_q = sync_event_out ^ dw_sync_data_d;

generate

  if (reg_event == 0) begin : GEN_RGEVT0
    assign event_d = next_event_d_q;
  end

  else begin : GEN_RGEVT1
    assign event_d = event_d_q;
  end

endgenerate

endmodule
