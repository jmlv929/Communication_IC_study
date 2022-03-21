
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//      Parameters:    Valid Values
//      ==========     ============
//       reg_event       0 to 1      default: 1
//                                   0 => event_d will have combination logic
//                                         but latency will be 1 cycle sooner
//                                   1 => event_d will be retimed so there will
//                                         be no logic between register & port
//                                         but event is delayed 1 cycle
//
//       reg_ack         0 to 1      default: 1
//                                   0 => ack_s will have combination logic
//                                         but latency will be 1 cycle sooner
//                                   1 => ack_s will be retimed so there will
//                                         be no logic between register & port
//                                         but event is delayed 1 cycle
//
//       ack_delay       0 to 1      default: 1
//                                   0 =>  acknowledge from dest to src will
//                                         be sent before the dest domain has
//                                         had time to detect the event,
//                                         but ack_s latency will be 1 cycle less
//                                   1 =>  acknowledge from dest to src will be
//                                         retimed so that the dest domain has
//                                         had time to detect the event
//
//       f_sync_type     0 to 4      default: 2
//                                   0 => single clock design, i.e. clk_d == clk_s
//                                   1 => first synchronization in clk_d domain is
//                                         done on the negative edge and the rest
//                                         on positive edge.  This reduces latency
//                                         req. of synchronization slightly but
//                                         quicker metastability resolution for
//                                         the negative edge sensitive FF. It also
//                                         requires the technology library to 
//                                         contain an acceptable negative edge 
//                                         sensitive FF.
//                                   2 =>  all synchronization in clk_d domain is
//                                         done on positive edges - 2 d flops in
//                                         destination domain
//                                   3 =>  all synchronization in clk_d domain is
//                                         done on positive edges - 3 d flops in
//                                         destination domain
//                                   4 =>  all synchronization in clk_d domain is
//                                         done on positive edges - 4 d flops in
//                                         destination domain
//
//       r_sync_type     0 to 4      default: 2
//                                   0 => single clock design, i.e. clk_s == clk_s
//                                   1 => first synchronization in clk_s domain is
//                                         done on the negative edge and the rest
//                                         on positive edge.  This reduces latency
//                                         req. of synchronization slightly but
//                                         quicker metastability resolution for
//                                         the negative edge sensitive FF. It also
//                                         requires the technology library to 
//                                         contain an acceptable negative edge 
//                                         sensitive FF.
//                                   2 =>  all synchronization in clk_s domain is
//                                         done on positive edges - 2 d flops in
//                                         source domain
//                                   3 =>  all synchronization in clk_s domain is
//                                         done on positive edges - 3 d flops in
//                                         source domain
//                                   4 =>  all synchronization in clk_s domain is
//                                         done on positive edges - 4 d flops in
//                                         source domain
//
//       tst_mode        0 to 2      default: 0
//                                   0 =>  no latch insertion
//                                   1 =>  hold latch using neg edge flop
//                                   2 =>  hold latch using active low latch
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
//       pulse_mode      0 to 3      default: 0
//                                   0 =>  single clock cycle pulse in produces
//                                         single clock cycle pulse out
//                                   1 =>  rising edge transition in produces
//                                         single clock cycle pulse out
//                                   2 =>  falling edge transition in produces
//                                         single clock cycle pulse out
//                                   3 =>  toggle transition in produces
//                                         single clock cycle pulse out
//
// MODIFIED :
//                  RJK 12/13/07  Fixed typo that caused srcdom_ack not to have reset
//		    RJK  3/24/10  Removed unused register, sync_event_out (LEDA complaints)
//
//	RJK	4/22/2011	Recoded conditionals that were based on constants to
//				use generate-if statements instead (not generate-case).
//
//	DLL	6/20/2011	Add pragma to disable Leda warning regarding unused parameter.
//
////////////////////////////////////////////////////////////////////////////////
module DW_pulseack_sync (
             clk_s, 
	     rst_s_n, 
	     init_s_n, 
	     event_s, 
	     ack_s,
	     busy_s,

	     clk_d, 
             rst_d_n, 
	     init_d_n,
	     event_d,

	     test 
    // Embedded dc_shell script
    // _model_constraint_1
	     );

 parameter reg_event    = 1;	// RANGE 0 to 1
 parameter reg_ack      = 1;	// RANGE 0 to 1
 parameter ack_delay    = 1;	// RANGE 0 to 1
 parameter f_sync_type  = 2;	// RANGE 0 to 4
 parameter r_sync_type  = 2;	// RANGE 0 to 4
 parameter tst_mode     = 0;	// RANGE 0 to 2

 parameter verif_en     = 1;    // RANGE 0 to 4

 parameter pulse_mode   = 0;    // RANGE 0 to 3

 
input  clk_s;			// clock input for source domain
input  rst_s_n;			// active low async. reset in clk_s domain
input  init_s_n;		// active low sync. reset in clk_s domain
input  event_s;			// event pulseack input (active high event)
output ack_s;			// event pulseack output (active high event)
output busy_s;			// event pulseack output (active high event)

input  clk_d;			// clock input for destination domain
input  rst_d_n;			// active low async. reset in clk_d domain
input  init_d_n;		// active low sync. reset in clk_d domain
output event_d;			// event pulseack output (active high event)

input  test;                    // test mode input.

wire   tgl_s_event_cc;
wire   tgl_d_event_cc;
reg    tgl_s_event_l;
reg    tgl_d_event_l;
reg    tgl_s_event_q;
wire   tgl_s_ack_x;
reg    event_s_cap;

wire   tgl_s_event_x;
wire   tgl_d_event_d;
wire   tgl_d_event_a;

wire   tgl_s_ack_d;
reg    srcdom_ack;
reg    tgl_s_ack_q;
wire   nxt_busy_state;
reg    busy_state;
wire   tgl_d_event_dx;	  // event seen via edge detect (before registered)
reg    tgl_d_event_q;	  // registered version of event seen
reg    tgl_d_event_qx;	  // xor of dest dom data and registered version


  
  always @ (posedge clk_s or negedge rst_s_n) begin : event_lauch_reg_PROC
    if (rst_s_n == 1'b0) begin
      tgl_s_event_q    <= 1'b0;
      busy_state       <= 1'b0;
      srcdom_ack       <= 1'b0;
      tgl_s_ack_q      <= 1'b0;
      event_s_cap      <= 1'b0;
    end else if (init_s_n == 1'b0) begin
      tgl_s_event_q    <= 1'b0;
      busy_state       <= 1'b0;
      srcdom_ack       <= 1'b0;
      tgl_s_ack_q      <= 1'b0;
      event_s_cap      <= 1'b0;
    end else begin
      tgl_s_event_q    <= tgl_s_event_x;
      busy_state       <= nxt_busy_state;
      srcdom_ack       <= tgl_s_ack_x;
      tgl_s_ack_q      <= tgl_s_ack_d;
      event_s_cap      <= event_s;
    end 
  end // always : event_lauch_reg_PROC



  
generate
  if (((f_sync_type&7)>1)&&(tst_mode==2)) begin : GEN_LATCH_frwd_hold_latch_PROC
    always @ (clk_s or tgl_s_event_q) begin : frwd_hold_latch_PROC
      if (clk_s == 1'b0)

	tgl_s_event_l <= tgl_s_event_q;

    end // frwd_hold_latch_PROC

    assign tgl_s_event_cc = (test==1'b1)? tgl_s_event_l : tgl_s_event_q;
  end else begin : GEN_DIRECT_frwd_hold_latch_PROC
    assign tgl_s_event_cc = tgl_s_event_q;
  end
endgenerate

  DW_sync #(1, f_sync_type+8, tst_mode, verif_en) U_DW_SYNC_F(
	.clk_d(clk_d),
	.rst_d_n(rst_d_n),
	.init_d_n(init_d_n),
	.data_s(tgl_s_event_cc),
	.test(test),
	.data_d(tgl_d_event_d) );


  
generate
  if (((r_sync_type&7)>1)&&(tst_mode==2)) begin : GEN_LATCH_rvs_hold_latch_PROC
    always @ (clk_d or tgl_d_event_a) begin : rvs_hold_latch_PROC
      if (clk_d == 1'b0)

	tgl_d_event_l <= tgl_d_event_a;

    end // rvs_hold_latch_PROC

    assign tgl_d_event_cc = (test==1'b1)? tgl_d_event_l : tgl_d_event_a;
  end else begin : GEN_DIRECT_rvs_hold_latch_PROC
    assign tgl_d_event_cc = tgl_d_event_a;
  end
endgenerate

  DW_sync #(1, r_sync_type+8, tst_mode, verif_en) U_DW_SYNC_R(
	.clk_d(clk_s),
	.rst_d_n(rst_s_n),
	.init_d_n(init_s_n),
	.data_s(tgl_d_event_cc),
	.test(test),
	.data_d(tgl_s_ack_d) );


  always @ (posedge clk_d or negedge rst_d_n) begin : second_sync_PROC
    if (rst_d_n == 1'b0) begin
      tgl_d_event_q      <= 1'b0;
      tgl_d_event_qx     <= 1'b0;
    end else if (init_d_n == 1'b0) begin
      tgl_d_event_q      <= 1'b0;
      tgl_d_event_qx     <= 1'b0;
    end else begin
      tgl_d_event_q      <= tgl_d_event_d;
      tgl_d_event_qx     <= tgl_d_event_dx;
    end
  end // always


generate
    
    if (pulse_mode <= 0) begin : GEN_PLSMD0
      assign tgl_s_event_x = tgl_s_event_q   ^ (event_s && ! busy_state);
    end
    
    if (pulse_mode == 1) begin : GEN_PLSMD1
      assign tgl_s_event_x = tgl_s_event_q   ^ (! busy_state &(event_s & ! event_s_cap));
    end
    
    if (pulse_mode == 2) begin : GEN_PLSMD2
      assign tgl_s_event_x = tgl_s_event_q  ^ (! busy_state &(event_s_cap & !event_s));
    end
    
    if (pulse_mode >= 3) begin : GEN_PLSMD3
      assign tgl_s_event_x = tgl_s_event_q ^ (! busy_state & (event_s ^ event_s_cap));
    end

endgenerate
  assign tgl_d_event_dx = tgl_d_event_d ^ tgl_d_event_q;
  //assign tgl_s_event_x  = tgl_s_event_q ^ (event_s & ! busy_s);
  assign tgl_s_ack_x    = tgl_s_ack_d   ^ tgl_s_ack_q;
  assign nxt_busy_state = tgl_s_event_x ^ tgl_s_ack_d;

  generate
    if (reg_event == 0) begin : GEN_RGEVT0
      assign event_d       = tgl_d_event_dx;
    end

    else begin : GEN_RGRVT1
      assign event_d       = tgl_d_event_qx;
    end
  endgenerate

  generate
    if (reg_ack == 0) begin : GEN_RGACK0
      assign ack_s         = tgl_s_ack_x;
    end

    else begin : GEN_RGACK1
      assign ack_s         = srcdom_ack;
    end
  endgenerate

  generate
    if (ack_delay == 0) begin : GEN_AKDLY0
      assign tgl_d_event_a = tgl_d_event_d;
    end

    else begin : GEN_AKDLY1
      assign tgl_d_event_a = tgl_d_event_q;
    end
  endgenerate


  assign busy_s = busy_state;

endmodule
