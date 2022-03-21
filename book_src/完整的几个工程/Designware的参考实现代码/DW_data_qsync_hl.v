
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  ABSTRACT:  
//
//             Parameters:     Valid Values
//             =======      ========
//             width           1 to 1024      8
//             clk_ratio       2 to 1024      2
//             tst_mode        0 to 2         0
//
//
//             Input Ports:    Size    Description
//             ========     ===    ========
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
//             ========    ===    ========
//             data_d          width    Destination domain data output
//             data_avail_d    1        Destination domain data update output
//
//
//
//
//
//  MODIFIED:
//
//     DLL     6-27-11   Edits for Leda cleanup (which includes disabling some
//                       warnings)  and added simulation messages for
//                       when negative-edge clocking is configured in.
//
////////////////////////////////////////////////////////////////////////////////
module DW_data_qsync_hl(
       clk_s,
       rst_s_n,
       init_s_n,
       send_s,
       data_s,
       
       clk_d,
       rst_d_n,
       init_d_n,
       data_avail_d,
       data_d,
       
       test
    // Embedded dc_shell script
    // _model_constraint_1
      );
parameter width     = 8;
parameter clk_ratio = 2;
parameter tst_mode  = 0;

parameter idle        = 0;
parameter update_a    = 1;
parameter update_hold = 2;
parameter update_b    = 3;
input              clk_s;
input              rst_s_n;
input              init_s_n;
input              send_s;
input  [width-1:0] data_s;
input              clk_d;
input              rst_d_n;
input              init_d_n;
output             data_avail_d ;
output [width-1:0] data_d;
input              test;
reg    [clk_ratio - 1:0] fb_hold; 
reg    [clk_ratio - 1:0] fb_state; 

reg                fb_en;
wire               fb_hd;
reg    [width-1:0] data_s_hld; 
wire   [width-1:0] data_s_mux; 
reg    [3:0]       send_state; 
reg    [3:0]       next_state; 

reg                send_r;
reg                tmg_ref_data;
wire               tmg_ref_cc;
wire               tmg_ref_ccm;
reg                tmg_ref_l;
reg                tmg_ref_reg;
wire               tmg_ref_mux;
reg                tmg_ref_neg;
reg                tmg_ref_pos;
reg                tmg_ref_xi;
wire               tmg_ref_xo;
wire               tmg_ref_fb;
reg                data_avl_out;
reg                data_avail_r;
reg                data_avail_s;
reg                data_s_reg_en;
reg                data_s_hld_en;
reg    [width-1:0] data_s_reg;
reg                send_s_en;
reg                data_m_sel;
wire               tmg_ref_fben;
reg                data_a_reg;


 
  always @ ( posedge clk_s or negedge rst_s_n) begin : SRC_DM_POS_SEQ_PROC
    if  (rst_s_n == 1'b0) begin  
      data_s_hld   <= {width{1'b0}};
      data_s_reg   <= {width{1'b0}};
      fb_state     <= {clk_ratio{1'b0}};
      send_state   <= 4'b0000;
      data_avail_r <= 1'b0;
      tmg_ref_xi   <= 1'b0;
      tmg_ref_reg  <= 1'b0;
      tmg_ref_pos  <= 1'b0;
      data_a_reg   <= 1'b0;
      send_r       <= 1'b0;
      fb_en        <= 1'b0;
    end else if ( init_s_n == 0) begin  
        data_s_hld   <= {width{1'b0}};
        data_s_reg   <= {width{1'b0}};
        fb_state     <= {clk_ratio{1'b0}};
        send_state   <= 4'b0000;
        data_avail_r <= 1'b0;
        tmg_ref_xi   <= 1'b0;
        tmg_ref_reg  <= 1'b0;
        tmg_ref_pos  <= 1'b0;
        data_a_reg   <= 1'b0;
        send_r       <= 1'b0;
        fb_en        <= 1'b0;
    end else begin 
      if(data_s_hld_en == 1'b1)  
        data_s_hld   <= data_s;
      if(data_s_reg_en == 1'b1) 
        data_s_reg   <= data_s_mux;
      fb_state       <= fb_hold;
      fb_en          <= fb_hd;
      send_state     <= next_state;
      data_avail_r   <= data_avl_out;
      tmg_ref_xi     <= tmg_ref_xo;
      tmg_ref_reg    <= tmg_ref_mux;
      tmg_ref_pos    <= tmg_ref_ccm;
      data_a_reg     <= data_avl_out;
      send_r         <= send_s;
    end 
  end  

generate
  if ((clk_ratio == 2) || (tst_mode == 1)) begin : GEN_TMG_REF_NEG_CR_EQ_2

    always @ ( negedge clk_s or negedge rst_s_n) begin : SRC_DM_NEG_SEQ_PROC
      if  (rst_s_n == 1'b0)   
	tmg_ref_neg  <= 1'b0;
      else if ( init_s_n == 1'b0)   
	tmg_ref_neg  <= 1'b0;
      else  
	tmg_ref_neg  <= tmg_ref_ccm;
    end  

  end
endgenerate


  always @ ( posedge clk_d or negedge rst_d_n) begin : DST_DM_POS_SEQ_PROC
    if (rst_d_n == 1'b0 ) 
      tmg_ref_data <= 1'b0;
    else if (init_d_n == 1'b0 ) 
      tmg_ref_data <= 1'b0;
    else   
      tmg_ref_data <= !  tmg_ref_data ;
  end

      

  always @ (send_state or fb_state or send_s or tmg_ref_fb) begin : SRC_DM_COMB_PROC
    next_state    = 4'b0000;
    data_m_sel    = 1'b0;
    data_s_hld_en = 1'b0;
    data_s_reg_en = 1'b0;
    data_avl_out  = 1'b0;
    fb_hold       = {clk_ratio{1'b0}};
      if (send_state[idle]) begin //  bit 0
        if (send_s == 1'b1)  begin
  	  next_state[update_a] = 1'b1 ;
          data_s_reg_en        = 1'b1;
          data_avl_out         = 1'b1;
          fb_hold = {fb_state[clk_ratio-2:0],  1'b1};
        end else begin
  	  next_state[idle] =  1'b1;
          fb_hold = {clk_ratio{1'b0}};
	end
      end else if (send_state[update_a]) begin // bit 1 
        data_avl_out         = 1'b1;
        fb_hold = {fb_state[clk_ratio-2:0],  1'b1};
        if(send_s == 1'b1)  begin
  	  next_state[update_b] = 1'b1;
          data_s_hld_en        = 1'b1;
        end else
  	  next_state[update_hold] =  1'b1;
      end else if (send_state[update_hold] ) begin // bit 2
        if(send_s == 1'b1 & tmg_ref_fb == 1'b0) begin
  	  next_state[update_b] =  1'b1;
          data_s_hld_en        =  1'b1;
          data_avl_out         = 1'b1;
          fb_hold = {fb_state[clk_ratio-2:0],  1'b1};
        end else if(send_s == 1'b1 & tmg_ref_fb == 1'b1) begin 
  	  next_state[update_hold] =  1'b1;
          data_s_reg_en      =  1'b1;
          data_avl_out       = 1'b1;
          fb_hold = {fb_state[clk_ratio-2:0],  1'b1};
        end else if(send_s == 1'b0 & tmg_ref_fb == 1'b1) begin 
  	  next_state[idle]  =  1'b1;
          fb_hold = {clk_ratio{1'b0}};
        end else begin
  	  next_state[update_hold] = 1'b1 ;
          data_avl_out            = 1'b1;
          fb_hold = {fb_state[clk_ratio-2:0],  1'b1};
        end
      end else if (send_state[update_b] ) begin // bit 3
        data_avl_out         = 1'b1;
        fb_hold = {fb_state[clk_ratio-2:0],  1'b1};
        if(send_s == 1'b0 & tmg_ref_fb == 1'b1 ) begin 
  	  next_state[update_hold]  = 1'b1 ;
          data_m_sel               = 1'b1;
          data_s_reg_en            = 1'b1;
        end else if(send_s == 1'b1 & tmg_ref_fb == 1'b1 ) begin 
  	  next_state[update_b]    = 1'b1 ;
          data_m_sel               = 1'b1;
          data_s_reg_en            = 1'b1;
          data_s_hld_en            = 1'b1;
        end else if(send_s == 1'b1 & tmg_ref_fb == 1'b0 ) begin 
  	  next_state[update_b]    = 1'b1 ;
          data_s_hld_en            = 1'b1;
        end else begin
  	  next_state[update_b]    = 1'b1;
        end
      end else
      next_state[idle] = 1'b1;
  end 
  assign tmg_ref_xo     = tmg_ref_reg ^  tmg_ref_mux;
  assign tmg_ref_fb     = tmg_ref_xo & tmg_ref_fben;//not (tmg_ref_xi | tmg_ref_xo) when clk_ratio = 3 else tmg_ref_xo;
  assign tmg_ref_fben   = tmg_ref_xo & fb_en;
  assign data_s_mux     = (data_m_sel == 1'b0) ? data_s : data_s_hld;
  assign tmg_ref_cc     = tmg_ref_data;

generate
  if (clk_ratio > 3) begin : GEN_FB_HD_CR_GT_3
    assign fb_hd = fb_hold[clk_ratio-2];
  end else begin : GEN_FB_HD_CR_LE_3
    assign fb_hd = fb_hold[clk_ratio-1];
  end
endgenerate

generate
  if ((clk_ratio > 2) && (tst_mode == 1)) begin : GEN_CR_GT_2_AND_TM1
    assign tmg_ref_ccm = (test == 1'b1)? tmg_ref_neg : tmg_ref_cc;
  end else begin : GEN_NOT_CR_GT_2_AND_TM1
    if ((clk_ratio > 2) && (tst_mode == 2)) begin : GEN_CR_GT_2_AND_TM2
      `ifdef DWC_DISALLOW_LATCHES
      assign  tmg_ref_ccm = tmg_ref_cc;
      `else
      always @ (clk_s or tmg_ref_cc) begin : frwd_hold_latch_PROC
        if (clk_s == 1'b0) 
          tmg_ref_l <= tmg_ref_cc;
      end // frwd_hold_latch_PROC;
        assign tmg_ref_ccm = (test == 1'b1)? tmg_ref_l : tmg_ref_cc;
      `endif
    end else begin : GEN_ELSE_CR_AND_TM
      assign tmg_ref_ccm = tmg_ref_cc;
    end
  end
endgenerate

generate
  if (clk_ratio == 2) begin : GEN_TMG_REF_MUX_CR_EQ_2
    assign tmg_ref_mux = tmg_ref_neg;
  end else begin : GEN_TMG_REF_MUX_CR_NE_2
    assign tmg_ref_mux = tmg_ref_pos;
  end
endgenerate

  assign data_d         = data_s_reg;
  assign data_avail_d   = data_a_reg;

endmodule
