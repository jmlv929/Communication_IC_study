
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--       ------------      Project : Wild 
--    ,' GoodLuck ,'      RCSfile: master_hiss_sm.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.19   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Interface HiSS of the Radio Controller
-- Get info from Radio Controller. Send info to Radio Controller
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/master_hiss/vhdl/rtl/master_hiss_sm.vhd,v  
--  Log: master_hiss_sm.vhd,v  
-- Revision 1.19  2005/10/04 12:21:07  Dr.A
-- #BugId:1397#
-- Added txv_immstop_i to tx_sm sensitivity list
--
-- Revision 1.18  2005/01/06 15:11:15  sbizet
-- #BugId:713#
-- Added txv_immstop enhancement
--
-- Revision 1.17  2004/01/14 12:33:36  Dr.B
-- update sensitivity list.
--
-- Revision 1.16  2004/01/08 18:06:34  Dr.B
-- add condition on return_read_marker.
--
-- Revision 1.15  2003/12/19 11:33:36  Dr.B
-- commented code removed.
--
-- Revision 1.14  2003/12/03 08:00:36  Dr.B
-- remove marker type to improve timings.
--
-- Revision 1.13  2003/12/01 09:58:03  Dr.B
-- add read_access_stop + delay en_drivers.
--
-- Revision 1.12  2003/11/28 10:39:59  Dr.B
-- sync found has the priority.
--
-- Revision 1.11  2003/11/26 13:59:55  Dr.B
-- back from deep_sleep added.
--
-- Revision 1.10  2003/11/21 17:55:16  Dr.B
-- lighten combinational logic.
--
-- Revision 1.9  2003/11/20 11:19:20  Dr.B
-- remove sync on rf_rxi_i.
--
-- Revision 1.8  2003/11/17 14:33:05  Dr.B
-- add state links for conflict accesses + keep_rf_low state.
--
-- Revision 1.7  2003/10/30 14:38:23  Dr.B
-- add cca_info , change input reclocking.
--
-- Revision 1.6  2003/10/09 08:24:30  Dr.B
-- constrain and protect marker detection.
--
-- Revision 1.5  2003/09/25 14:39:57  Dr.B
-- remove combinational loop.
--
-- Revision 1.4  2003/09/25 12:29:47  Dr.B
-- some debug.
--
-- Revision 1.3  2003/09/23 13:05:13  Dr.B
-- sync_found added.
--
-- Revision 1.2  2003/09/22 09:33:32  Dr.B
-- add switch_ant marker.
--
-- Revision 1.1  2003/07/21 11:48:41  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity master_hiss_sm is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    hiss_clk                : in  std_logic;
    rfh_fastclk             : in  std_logic; -- 240 MHz clock inverted without clktree
    reset_n                 : in  std_logic;
    --------------------------------------
    -- Interface with Wild_RF
    --------------------------------------
    rf_rxi_i                : in  std_logic;  -- Real Part received
    rf_rxq_i                : in  std_logic;  -- Imaginary Part received 
    -- 
    rf_txi_o                : out std_logic;  -- Real Part to send 
    rf_txq_o                : out std_logic;  -- Imaginary Part to send
    rf_tx_enable_o          : out std_logic;  -- Enable the rf_txi/rf_txq output when high
    rf_rx_rec_o             : out std_logic;  -- Enable the rf_rx input when high
    rf_en_o                 : out std_logic;  -- Control Signal - enable transfers
    --------------------------------------
    -- Interface with serializer-deserializer
    --------------------------------------
    seria_valid_i           : in  std_logic;  -- high = there is a data to transfert
    start_seria_i           : in  std_logic;  -- 1st data to transfer
    get_reg_cca_conf_i      : in  std_logic;  -- high = accept received data
    parity_err_tog_i        : in  std_logic;  -- toggle = a prity error occured
    parity_err_cca_tog_i    : in  std_logic;  -- toggle = a prity error occured
    i_i                     : in  std_logic;  -- serialized d0-d7 val
    q_i                     : in  std_logic;  -- serialized d8-d15 val
    --
    start_rx_data_o         : out std_logic;  -- high when there are rx data to deserialize
    get_reg_pulse_o         : out std_logic;  -- pulse when data reg to get(right after the pulse)
    cca_info_pulse_o        : out std_logic;  -- pulse when cca info to get(right after the pulse)
    wr_reg_pulse_o          : out std_logic;  -- pulse when add/data to send
    rd_reg_pulse_o          : out std_logic;  -- pulse when data to send(right after the pulse)
    transmit_possible_o     : out std_logic;  -- enable the transmission (after the marker is set)
    rf_rxi_reg_o            : out std_logic;  -- registered input rf_rxi
    rf_rxq_reg_o            : out std_logic;  -- registered input rf_rxq    
    --------------------------------------------
    -- Interface for BuP
    --------------------------------------------
    txv_immstop_i           : in  std_logic;  -- BuP asks for immediate transmission stop
    --------------------------------------
    -- Interface with Radio Controller sm 
    --------------------------------------
    rf_en_force_i           : in  std_logic;  -- clock reset force rf_en in order to wake up hiss clock.
    hiss_enable_n_i         : in  std_logic;  -- enable block 
    force_hiss_pad_i        : in  std_logic;  -- when high the receivers/drivers are always activated
    clk_switch_req_i        : in  std_logic;  -- ask of clock switching (decoded from write_reg)
    back_from_deep_sleep_i  : in  std_logic;  -- pulse when wake up.
    preamble_detect_req_i   : in  std_logic;  -- ask of pre detection (from AGC)
    apb_access_i            : in  std_logic;  -- ask of apb access (wr or rd)
    wr_nrd_i                : in  std_logic;  -- wr_nrd = '1' => write access
    rd_time_out_i           : in  std_logic;  -- time out : no reg val from RF
    clkswitch_time_out_i    : in  std_logic;  -- time out : no clock switch happens
    reception_enable_i      : in  std_logic;  -- high = BB accepts incoming data (after CCA detect)
    transmission_enable_i   : in  std_logic;  -- high = there are data to transmit
    sync_found_i            : in  std_logic;  -- high and remain high when sync is found
    --
    rd_access_stop_o        : out std_logic;  -- indicate the sync to cancel 
    switch_ant_tog_o        : out std_logic;  -- toggle = antenna switch
    acc_end_tog_o           : out std_logic;  -- toggle when acc finished
    glitch_found_o          : out std_logic;  -- pulse = glitch found or rf_rxi/rf_rxq  
    prot_err_o              : out std_logic;  -- error on the protocol (high during G pers)
    clk_switched_o          : out std_logic;  -- pulse when the clock will switch
    clk_switched_tog_o      : out std_logic   -- toggle when the clock will switch
    
    
  );

end master_hiss_sm;
