
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: master_hiss.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.18   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Master HiSS top level - Instantiate subblocks
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/master_hiss/vhdl/rtl/master_hiss.vhd,v  
--  Log: master_hiss.vhd,v  
-- Revision 1.18  2005/03/16 13:09:20  sbizet
-- #BugId:1135#
-- added txv_immstop port to master_seria
--
-- Revision 1.17  2005/01/06 15:08:44  sbizet
-- #BugId:713#
-- Added txv_immstop enhancement
--
-- Revision 1.16  2004/07/16 07:36:02  Dr.B
-- add cca_add_info feature
--
-- Revision 1.15  2004/03/29 13:01:31  Dr.B
-- add clk44possible_g generic.
--
-- Revision 1.14  2004/02/19 17:26:59  Dr.B
-- add hiss_reset_n reset.
--
-- Revision 1.13  2003/12/01 09:57:23  Dr.B
-- add rd_access_stop.
--
-- Revision 1.12  2003/11/28 10:39:23  Dr.B
-- change update of apb_accesses.
--
-- Revision 1.11  2003/11/26 13:58:53  Dr.B
-- decode_add is now running at 240 MHz.
--
-- Revision 1.10  2003/11/21 17:52:43  Dr.B
-- add stream_enable_i.
--
-- Revision 1.9  2003/11/20 11:18:08  Dr.B
-- add cs protection + sync 240to80.
--
-- Revision 1.8  2003/11/17 14:33:37  Dr.B
-- add clk_switch_80 output.
--
-- Revision 1.7  2003/10/30 14:37:24  Dr.B
-- remove sampling_clk + add CCA info.
--
-- Revision 1.6  2003/10/09 08:23:58  Dr.B
-- add carrier sense info.
--
-- Revision 1.5  2003/09/25 12:32:08  Dr.B
-- start_seria replace one_data_in_buf, ant_selection, cca_search ...
--
-- Revision 1.4  2003/09/23 13:03:35  Dr.B
-- mux rx a b
--
-- Revision 1.3  2003/09/22 09:31:42  Dr.B
-- new subblocks.
--
-- Revision 1.2  2003/07/21 12:24:35  Dr.B
-- remove clk_gen_rtl.
--
-- Revision 1.1  2003/07/21 11:52:29  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;

--library master_hiss_rtl;
library work;
--use master_hiss_rtl.master_hiss_pkg.all;
use work.master_hiss_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity master_hiss is
  generic (
    rx_a_size_g      : integer := 11;   -- size of data of rx_filter A
    rx_b_size_g      : integer := 8;    -- size of data of rx_filter B
    tx_a_size_g      : integer := 10;   -- size of data input of tx_filter A
    tx_b_size_g      : integer := 1;    -- size of data input of tx_filter B
    clk44_possible_g : integer := 0);  -- when 1 - the radioctrl can work with a
  -- 44 MHz clock instead of the normal 80 MHz.
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    hiss_clk              : in  std_logic; -- 240 MHz clock
    rfh_fastclk           : in  std_logic; -- 240 MHz clock without clktree directly from pad)
    pclk                  : in  std_logic; -- 80  MHz clock
    reset_n               : in  std_logic;
    hiss_reset_n          : in  std_logic;
    --------------------------------------
    -- Interface with Wild_RF
    --------------------------------------
    rf_rxi_i              : in  std_logic;  -- Real Part received
    rf_rxq_i              : in  std_logic;  -- Imaginary Part received 
    -- 
    rf_txi_o              : out std_logic;  -- Real Part to send 
    rf_txq_o              : out std_logic;  -- Imaginary Part to send
    rf_txen_o             : out std_logic;  -- Enable the rf_txi/rf_txq output when high
    rf_rxen_o             : out std_logic;  -- Enable the inputs rf_rx when high
    rf_en_o               : out std_logic;  -- Control Signal - enable transfers
    --------------------------------------
    -- Interface with muxed tx path
    --------------------------------------
    -- Data from Tx Filter A and B
    tx_ai_i               : in  std_logic_vector(tx_a_size_g-1 downto 0);
    tx_aq_i               : in  std_logic_vector(tx_a_size_g-1 downto 0);
    tx_val_tog_a_i        : in  std_logic;   -- toggle = data is valid
    --
    tx_b_i                : in  std_logic_vector(2*tx_b_size_g-1 downto 0);
    tx_val_tog_b_i        : in  std_logic;   -- toggle = data is valid
    --------------------------------------
    -- Interface with Rx Paths 
    --------------------------------------
    hiss_enable_n_i      : in  std_logic;  -- enable block 60 MHz
    -- Data from Rx Filter A or B
    rx_i_o               : out std_logic_vector(rx_a_size_g-1 downto 0); -- B data are on LSB
    rx_q_o               : out std_logic_vector(rx_a_size_g-1 downto 0); -- B data are on LSB
    rx_val_tog_o         : out std_logic;  -- toggle = data is valid
    clk_2skip_tog_o      : out std_logic;  -- tog when 2 clock-skip is needed | gated 44 MHz clk
    --------------------------------------
    -- Interface with Radio Controller sm 
    --------------------------------------
    -- 80 MHz signals Inputs (from Radio Controller)
    rf_en_force_i         : in  std_logic;  -- clock reset force rf_en in order to wake up hiss clock.
    tx_abmode_i           : in  std_logic;  -- transmission mode : 0 = A , 1 = B
    rx_abmode_i           : in  std_logic;  -- reception mode : 0 = A , 1 = B
    force_hiss_pad_i      : in  std_logic;  -- when high the receivers/drivers are always activated
    apb_access_i          : in  std_logic;  -- ask of apb access (wr or rd)
    wr_nrd_i              : in  std_logic;  -- wr_nrd = '1' => write access
    rd_time_out_i         : in  std_logic;  -- time out : no reg val from RF
    clkswitch_time_out_i  : in  std_logic;  -- time out : no clock switch happens
    wrdata_i              : in  std_logic_vector(15 downto 0); -- data to write in reg
    add_i                 : in  std_logic_vector( 5 downto 0); -- add of the reg access
    sync_found_i          : in  std_logic;  -- high and remain high when sync is found
    -- BuP control
    txv_immstop_i         : in std_logic;   -- BuP asks for immediate transmission stop
    -- Control signals Inputs (from Radio Controller)   
    recep_enable_i        : in  std_logic;  -- high = BB accepts incoming data (after CCA detect)
    trans_enable_i        : in  std_logic;  -- high = there are data to transmit
    --
    -- Data (from read-access)
    parity_err_tog_o      : out std_logic;  -- toggle when parity check error (no data will be sent)
    rddata_o              : out std_logic_vector(15 downto 0);
    -- Control Signals    
    cca_search_i          : in  std_logic;  -- wait for CCA (wait for pr_detected_o)
    --
    cca_info_o            : out std_logic_vector(5 downto 0);  -- CCA information
    cca_add_info_o        : out std_logic_vector(15 downto 0); -- CCA additional information
    cca_o                 : out std_logic;  -- high during a 80 MHz period
    parity_err_cca_tog_o  : out std_logic;  -- toggle when parity err during CCA info
    cs_error_o            : out std_logic;  -- when high : error on CS
    switch_ant_tog_o      : out std_logic;  -- toggle = antenna switch
    cs_o                  : out std_logic_vector(1 downto 0);  -- CS info for AGC/CCA
    cs_valid_o            : out std_logic;  -- high when the CS is valid
    acc_end_o             : out std_logic;  -- toggle => acc finished
    prot_err_o            : out std_logic;  -- "long signal" : error on the protocol
    clk_switch_req_o      : out std_logic;  -- pulse: clk swich req for time out
    clk_div_o             : out std_logic_vector(2 downto 0); -- val of rf_fastclk speed
    clk_switched_tog_o    : out std_logic;   -- toggle, the clock will switch
    clk_switched_80_o     : out std_logic;   -- pulse, the clock will switch (80 MHz)
    --
    hiss_diagport_o       : out std_logic_vector(15 downto 0)
  );

end master_hiss;
