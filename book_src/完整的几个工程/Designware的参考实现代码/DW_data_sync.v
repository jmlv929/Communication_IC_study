
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------
// ABSTRACT: data bus synchronizer with ack 
//
//
//----------------------------------------------------------------------------
//
//      Parameters:     Valid Values
//      ==========      ============
//        width          1 to 1024    default: 8
//                                    width of transfer data bus
//
//        pend_mode       0 to 1      default: 1 (buffer pending data)
//                                    optional data pending register
//
//        ack_delay       0 to 1      default: 1 (ack sent when dest data captured)
//				      0 => acknowledge will be returned form dest
//                                         before actual data capture has taken
//				           place - but latency will be 1 cycle less
//                                         NOTE that this is NOT RECOMMENDED
//                                         when clk_s can be > 2X freq. of clk_d
//				      1 => ack_s will be retimed so there will
//				           be no logic between register & port
//				           but event is delayed 1 cycle
//                                         NOTE that this mode safely captures
//                                         data regardless of clk_s & clk_d
//                                         frequencies
//
//        f_sync_type     0 to 4      default: 2
//				      0 => single clock design, i.e. clk_s == clk_d
//				      1 => first synchronization in clk_d domain is
//				           done on the negative edge and the rest
//				           on positive edge.  This reduces latency
//				           req. of synchronization slightly but
//				           quicker metastability resolution for
//				           the negative edge sensitive FF. It also
//				           requires the technology library to 
//				           contain an acceptable negative edge 
//                                         sensitive FF.
//				     2 =>  all synchronization in clk_d domain is
//				           done on positive edges - 2 d flops in
//				           source domain
//				     3 =>  all synchronization in clk_d domain is
//				           done on positive edges - 3 d flops in
//				           source domain
//				     4 =>  all synchronization in clk_d domain is
//				           done on positive edges - 4 d flops in
//				           source domain
//
//        r_sync_type     0 to 4     default: 2
//				     0 => single clock design, i.e. clk_s == clk_d
//				     1 => first synchronization in clk_s domain is
//				           done on the negative edge and the rest
//				           on positive edge.  This reduces latency
//				           req. of synchronization slightly but
//				           quicker metastability resolution for
//				           the negative edge sensitive FF. It also
//				           requires the technology library to 
//				           contain an acceptable negative edge 
//                                         sensitive FF.
//				     2 =>  all synchronization in clk_s domain is
//				           done on positive edges - 2 d flops in
//				           source domain
//				     3 =>  all synchronization in clk_s domain is
//				           done on positive edges - 3 d flops in
//				           source domain
//				     4 =>  all synchronization in clk_d domain is
//				           done on positive edges - 4 d flops in
//				           source domain
//
//        tst_mode        0 to 2     default: 0
//                                   0 =>  no latch insertion
//				     1 =>  hold latch using neg edge flop
//				     2 =>  hold latch using active low latch
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
//        send_mode       0 to 3     default: 0 (buffer pending data)
//                                   0 =>  single clock cycle pulse invokes
//                                         a data transfer to dest domain
//                                   1 =>  rising edge transition invokes
//                                         a data transfer to dest domain
//                                   2 =>  falling edge transition invokes
//                                         a data transfer to dest domain
//                                   3 =>  toggle transition invokes
//                                         a data transfer to dest domain
//
//
// MODIFIED:
//
//              DLL   9-22-11  Changed port order of data_avail_d and data_d.
//                             Addresses STAR#9000493519.
//
//              DLL   6-22-11  Added pragmas to disable Leda warnings and other
//                             cleanup to prevent Leda warnings.
//
//              DLL   1-8-10   Fixed STAR#9000366699 regarding improper behavior
//                             of 'error_s' for both 'pend_mode' values (0, 1).
//
//
//----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
module DW_data_sync (
             clk_s,
             rst_s_n,
             init_s_n,
             send_s,
             data_s,
             empty_s,
             full_s,
             done_s,

             clk_d,
             rst_d_n,
             init_d_n,
             data_avail_d,
             data_d,

             test
    // Embedded dc_shell script
    // _model_constraint_1
           );

 parameter width       = 8;  // RANGE 1 to 1024
 parameter pend_mode   = 1;  // RANGE 0 to 1
 parameter ack_delay   = 1;  // RANGE 0 to 1
 parameter f_sync_type = 2;  // RANGE 0 to 4
 parameter r_sync_type = 2;  // RANGE 0 to 4
 parameter tst_mode    = 0;  // RANGE 0 to 2

 parameter verif_en    = 1;  // RANGE 0 to 4

 parameter send_mode   = 0;  // RANGE 0 to 1

 input             clk_s;    //Source clock 
 input             rst_s_n;  //Source domain asynch.reset (active low)
 input             init_s_n; //Source domain synch. reset (active low)
 input             send_s;   //Source domain send request input 
 input [width-1:0] data_s;   //Source domain send data input 
 output             empty_s;  //Source domain transaction regs empty 
 output             full_s;   //Source domain transaction regs full 
 output             done_s;   //Source domain transaction done output 

 input             clk_d;    //Destination clock 
 input             rst_d_n;  //Destination domain asynch. reset (active low)
 input             init_d_n; //Destination domain synch. reset (active low)
 output             data_avail_d; //Destination domain data update output 
 output [width-1:0] data_d;   // width Destination domain data output 

 input             test;     //Scan test mode select input 
  reg  [width-1:0] data_s_reg;
  reg  [width-1:0] data_d_reg;
  wire [width-1:0] data_s_mux;
  reg  [width-1:0] data_s_pnd;
 
  reg  send_d;
  reg  send_q;
  reg  send_reg;
  wire send_nxt;

  reg  busy_pnr;
  wire busy_s_pnd;

  wire busy_s_pas;
  reg  busy_int;
  reg  pbusy_int;
  wire ack_s_pas;
  wire event_d_pas;
  reg  xmit_d_en;
  reg  pend_d_en;
  wire data_s_ren;
  wire data_s_pen;

  wire send_in;
  wire send_en;
  reg  send_tgl;
  reg  dr_bsy;
  wire dr_bsy_nxt;

  reg  pr_bsy;
  wire pr_bsy_nxt;

  wire done_s_nxt;
  wire busy_s_nxt;

  reg  data_avail_reg;
  wire data_d_nxt;


 
  DW_pulseack_sync #(0, 0, ack_delay, f_sync_type, r_sync_type, tst_mode, verif_en, 0)
    U1 ( 
        .clk_s(clk_s), 
        .rst_s_n(rst_s_n), 
        .init_s_n(init_s_n), 
        .event_s(send_en), 
        .clk_d(clk_d), 
        .rst_d_n(rst_d_n), 
        .init_d_n(init_d_n), 
        .test(test), 
        .busy_s(busy_s_pas), 
        .ack_s(ack_s_pas), 
        .event_d(event_d_pas) 
        );

  
  always @ (posedge clk_s or negedge rst_s_n) begin : PROC_src_pos_reg
    if  (rst_s_n == 1'b0)  begin
      data_s_reg <= {width{1'b0}};
      data_s_pnd <= {width{1'b0}};
      send_reg   <= 1'b0;
      send_tgl   <= 1'b0;
      busy_int   <= 1'b0;
      busy_pnr   <= 1'b0;
      dr_bsy     <= 1'b0;
      pr_bsy     <= 1'b0;
    end else begin
      if ( init_s_n == 1'b0)  begin
        data_s_reg <= {width{ 1'b0}};
        data_s_pnd <= {width{ 1'b0}};
        send_reg   <= 1'b0;
        send_tgl   <= 1'b0;
        busy_int   <= 1'b0;
        busy_pnr   <= 1'b0;
        dr_bsy     <= 1'b0;
        pr_bsy     <= 1'b0;
      end else begin
        if(data_s_ren == 1'b1) 
          data_s_reg <= data_s_mux;
        if(data_s_pen == 1'b1) 
          data_s_pnd <= data_s;
	send_reg   <= send_s;
        send_tgl   <= send_in;
        busy_int   <= busy_s_nxt;
        busy_pnr   <= busy_s_pnd;
        dr_bsy     <= dr_bsy_nxt;
        pr_bsy     <= pr_bsy_nxt;
      end 
    end 
  end 


  always @ (posedge clk_d or negedge rst_d_n) begin : PROC_dest_pos_reg
    if (rst_d_n == 1'b0 ) begin
       data_d_reg     <= {width{1'b0}};
       data_avail_reg <= 1'b0;
    end else  begin
      if (init_d_n == 1'b0 ) begin
        data_d_reg     <= {width{1'b0}};
        data_avail_reg <= 1'b0;
      end else begin
        if(data_d_nxt == 1'b1) 
          data_d_reg   <= data_s_reg;
        data_avail_reg <= data_d_nxt;
      end
    end 
  end


generate
  if (pend_mode == 0) begin : GEN_DR_BSY_NXT_PM0
    assign dr_bsy_nxt = (send_en & ~ busy_s_pas) | (dr_bsy & ~ ack_s_pas);
  end else begin : GEN_DR_BSY_NXT_PM1
    assign dr_bsy_nxt = (send_en & ~ busy_s_pas) | (dr_bsy & ~ ack_s_pas) | (ack_s_pas & pr_bsy) | (pr_bsy & ~ dr_bsy);
  end
endgenerate

  assign pr_bsy_nxt   = (send_in & ~ pr_bsy & dr_bsy) 
                        | (pr_bsy & ~ ack_s_pas & dr_bsy)
                        | (send_in & ack_s_pas & dr_bsy); 
  assign data_s_pen   = busy_s_nxt & send_in;

generate
  if (pend_mode == 1) begin : GEN_PM1
    assign busy_s_pnd   = (dr_bsy & pr_bsy_nxt) & ~ack_s_pas;
    assign busy_s_nxt   = (send_in | send_en) | (~ack_s_pas & busy_int) | (ack_s_pas & pr_bsy);
    assign data_s_ren   = (send_in & ~ dr_bsy & ~busy_int) | (ack_s_pas & pr_bsy) | (~ dr_bsy & pr_bsy & ~ ack_s_pas);
    assign send_en      = (send_in & ~ dr_bsy) | (dr_bsy & ~ busy_s_pas);
    assign data_s_mux   = (pr_bsy == 1'b1) ? data_s_pnd : data_s;
  end else begin : GEN_PM0
    assign busy_s_pnd   = send_in | dr_bsy_nxt;
    assign busy_s_nxt   = send_in | dr_bsy_nxt;
    assign data_s_ren   = send_in & ~ busy_s_pas;
    assign send_en      = send_in;
    assign data_s_mux   = data_s;
  end
endgenerate

generate
  if (send_mode == 0) begin : GEN_SEND_IN_SM0
    assign send_in = send_s;
  end
  if (send_mode == 1) begin : GEN_SEND_IN_SM1
    assign send_in = send_s && !send_reg;
  end
  if (send_mode == 2) begin : GEN_SEND_IN_SM2
    assign send_in = !send_s && send_reg;
  end
  if (send_mode > 2) begin : GEN_SEND_IN_SM_GT_2
    assign send_in = send_s ^ send_reg;
  end
endgenerate

  assign done_s_nxt = ack_s_pas;
  assign send_nxt   = send_in;
  assign data_d_nxt = event_d_pas;

  assign data_avail_d = data_avail_reg;
  assign data_d       = data_d_reg;
  assign done_s       = done_s_nxt;
  assign empty_s      = busy_int;
  assign full_s       = busy_pnr;
  
endmodule
