
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  ABSTRACT:  quasai synchronous data transfer.
//
//             Parameters:     Valid Values   Default Values
//             ==========      ============   ==============
//             width           1 to 1024      8
//             clk_ratio       2 to 1024      2
//             reg_data_s      0 to 1         1
//             reg_data_d      0 to 1         1
//             tst_mode        0 to 2         0
//
//             Input Ports:    Size    Description
//             ===========     ====    ===========
//             clk_s            1        Source clock
//             rst_s_n          1        Source domain asynch. reset (active low)
//             init_s_n         1        Source domain synch. reset (active low)
//             send_s           1        Source domain send request input
//             data_s           width    Source domain send data input
//             clk_d            1        Destination clock
//             rst_d_n          1        Destination domain asynch. reset (active low)
//             init_d_n         1        Destination domain synch. reset (active low)
//             test             1        Scan test mode select input
//
//
//             Output Ports    Size    Description
//             ============    =====    ===========
//             data_d          width    Destination domain data output
//             data_avail_d    1        Destination domain data update output
//
//
//  MODIFIED:
//
//     DLL     6-24-11   Edits for Leda cleanup (which includes disabling some
//                       warnings)  and added simulation messages for
//                       when negative-edge clocking is configured in.
//
////////////////////////////////////////////////////////////////////////////////
module DW_data_qsync_lh(
// Embedded dc_shell script
// _model_constraint_1
        clk_s,
        rst_s_n,
        init_s_n,
        send_s,
        data_s,
        clk_d,
        rst_d_n,
        init_d_n,
        data_d,
        data_avail_d,
        test
      );

parameter width      = 8; // RANGE 1 to 1024
parameter clk_ratio  = 2; // RANGE 2 to 1024
parameter reg_data_s = 1; // RANGE 0 to 1
parameter reg_data_d = 1; // RANGE 0 to 1
parameter tst_mode   = 0; // RANGE 0 to 2

  input  clk_s;             // clk_s 1 Source clock
  input  rst_s_n;           // rst_s_n 1 Source domain asynch. reset (active low)
  input  init_s_n;          // init_s_n 1 Source domain synch. reset (active low)
  input  send_s;            // send_s 1 Source domain send request input
  input  [width-1:0] data_s;// data_s width Source domain send data input
  
  input  clk_d;             // clk_d 1 Destination clock
  input  rst_d_n;           // rst_d_n 1 Destination domain asynch. reset (active low)
  input  init_d_n;          // init_d_n 1 Destination domain synch. reset (active low)

  output [width-1:0] data_d;// data_d width Destination domain data output
  output data_avail_d;      // data_avail_d 1 Destination domain data update output

  input  test;              // test 1 Scan test mode select input
  
  wire             send_s_x;     // toggle signal
  wire             data_d_xvail; // toggle data available signal
  wire [width-1:0] data_s_snd;   // source data sel mux
  reg  [width-1:0] data_s_l;     // data scan hold latch/flop
  wire [width-1:0] data_s_cc;    // data scan hold mux
  
  reg  [width-1:0] data_s_reg;   // source data storage
  reg              send_reg;     // send signal storage
  reg              send_reg_l;   // send control signal hold latch/flop
  wire             send_reg_cc;  // send signal crossing domains
  reg              data_avail_reg; // dest signal storage (1st stage)
  reg  [width-1:0] data_d_reg;      // dest data storage
  reg              data_avail_xreg; // dest avail toggle
  reg              data_avail_d;    // dest semaph signal


 
  assign send_s_x = send_s ^ send_reg;

  
generate
  if ( tst_mode == 2 ) begin : GEN_LATCH_data
      always @ (clk_s or send_reg) begin : PROC_LATCH_data
	if (clk_s == 1'b0) 
	  data_s_l <= send_reg;
      end // PROC_LATCH_data

      assign  data_s_cc = (test == 1'b1)? data_s_l : data_s_snd;
  end else if ( tst_mode == 1 ) begin : GEN_NEGEDGE_REG_data
      always @ (negedge clk_d or negedge rst_d_n) begin
	if (rst_d_n == 1'b0)
	  data_s_l <= 1'b0;
	else
	  data_s_l <= data_s_snd;
      end

      assign  data_s_cc = (test == 1'b1)? data_s_l : data_s_snd;
  end else begin : GEN_DIRECTdata
    assign  data_s_cc = data_s_snd;
  end
endgenerate

  
generate
  if ((clk_ratio >= 3) && ( tst_mode == 2 )) begin : GEN_LATCH_ctl
      always @ (clk_s or send_reg) begin : PROC_LATCH_ctl
	if (clk_s == 1'b0) 
	  send_reg_l <= send_reg;
      end // PROC_LATCH_ctl

      assign  send_reg_cc = (test == 1'b1)? send_reg_l : send_reg;
  end else if ((clk_ratio >= 3) && ( tst_mode == 1 )) begin : GEN_NEGEDGE_REG_ctl
      always @ (negedge clk_d or negedge rst_d_n) begin
	if (rst_d_n == 1'b0)
	  send_reg_l <= 1'b0;
	else
	  send_reg_l <= send_reg;
      end

      assign  send_reg_cc = (test == 1'b1)? send_reg_l : send_reg;
  end else begin : GEN_DIRECTctl
    assign  send_reg_cc = send_reg;
  end
endgenerate

  always @ (posedge clk_s or negedge rst_s_n) begin : SRC_DM_SEQ_PROC
    if  (rst_s_n == 1'b0)  begin
      data_s_reg <= {width{1'b0}};
      send_reg   <= 1'b0;
    end else begin
      if ( init_s_n == 1'b0)  begin
        data_s_reg <= {width{ 1'b0}};
        send_reg   <= 1'b0;
      end else begin
        data_s_reg <= data_s;
	send_reg   <= send_s_x;
      end 
    end 
  end 


  always @ (posedge clk_d or negedge rst_d_n) begin : DST_DM_POS_SEQ_PROC
    if (rst_d_n == 1'b0 ) begin
       data_d_reg      <= {width{1'b0}};
       data_avail_xreg <= 1'b0;
       data_avail_d    <= 1'b0;
    end else  begin
      if (init_d_n == 1'b0 ) begin
        data_d_reg      <= {width{1'b0}};
        data_avail_xreg <= 1'b0;
        data_avail_d    <= 1'b0;
      end else begin
        data_d_reg      <= data_s_cc;
        data_avail_xreg <= data_avail_reg;
        data_avail_d    <= data_d_xvail;
      end
    end 
  end


generate
  if (clk_ratio >= 3) begin : GEN_DATA_D_MUX_CR_GT_2

    always @ (posedge clk_d or negedge rst_d_n) begin : DST_DA_POS_SEQ_PROC
      if (rst_d_n == 1'b0 ) begin
        data_avail_reg <= 1'b0;
      end else  begin
        if (init_d_n == 1'b0 ) begin
          data_avail_reg <= 1'b0;
        end else begin
          data_avail_reg <= send_reg_cc;
        end
      end 
    end


  end else begin : GEN_DATA_D_MUX_CR_EQ_2


    always @ (negedge clk_d or negedge rst_d_n) begin : DST_DA_NEG_SEQ_PROC
      if (rst_d_n == 1'b0 ) begin
         data_avail_reg  <= 1'b0;
      end else  begin
        if (init_d_n == 1'b0 ) begin
          data_avail_reg <= 1'b0;
        end else begin
          data_avail_reg <= send_reg;
        end
      end 
    end



  end
endgenerate

generate
  if (reg_data_s == 1) begin : GEN_DATA_D_RDS1
    assign data_d = data_d_reg;
  end else begin : GEN_DATA_D_RDS0
    assign data_d = data_s_cc;
  end
endgenerate

generate
  if (reg_data_d == 1) begin : GEN_DATA_S_SND_RDD1
    assign data_s_snd = data_s_reg;
  end else begin : GEN_DATA_S_SND_RDD0
    assign data_s_snd = data_s;
  end
endgenerate

assign data_d_xvail = data_avail_reg ^ data_avail_xreg;
endmodule
