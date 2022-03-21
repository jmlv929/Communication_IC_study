
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: control_filter.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.7  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Tx & RX Filter control for WILD Modem A2
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/tx_rx_filter/vhdl/rtl/control_filter.vhd,v  
--  Log: control_filter.vhd,v  
-- Revision 1.7  2005/01/25 10:35:36  Dr.C
-- #BugId:960#
-- Adjusted constant value according to AGC verification.
--
-- Revision 1.6  2005/01/18 13:13:18  Dr.C
-- #BugId:960#
-- Added dc_pre_estim_4_agc outputs and reduce dc_pre_estim to 11-bit.
--
-- Revision 1.5  2004/12/08 16:05:53  Dr.C
-- #BugId:888#
-- Change counter constant value for DC offset pre-estimation.
--
-- Revision 1.4  2004/10/27 14:15:31  Dr.C
-- #BugId:799#
-- Added dc pre-estimation calculation.
--
-- Revision 1.3  2004/06/17 16:57:09  Dr.C
-- Change name of resynchronisation register according to design rules.
--
-- Revision 1.2  2004/05/13 14:48:05  Dr.C
-- Added use_sync_reset_g generic.
--
-- Revision 1.1  2004/04/07 13:44:58  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity control_filter is
   generic (
    size_in_tx_g     : integer := 10; -- I & Q size for Tx input
    size_out_tx_g    : integer := 8;  -- I & Q size for Tx output
    size_in_rx_g     : integer := 10; -- I & Q size for Tx input
    size_out_rx_g    : integer := 11; -- I & Q size for Rx output
    size_core_in_g   : integer := 10; -- size for Core front-end input
    size_core_out_g  : integer := 15; -- size for Core front-end output
    --
--    use_sync_reset_g : integer := 1   -- when 1 sync_reset_n input is used
    use_sync_reset_g : integer := 1   -- when 1 sync_reset_n input is used
    );                                -- else the reset_n input must be separately
  port (                              -- controlled by the reset controller
    ----------------------------
    -- Clock and reset
    ----------------------------
    clk                : in  std_logic;       -- 60 MHz
    reset_n            : in  std_logic;
    sync_reset_n       : in  std_logic;       -- synchronous reset from AGC/CCA
    ----------------------------
    -- Tx/Rx selection
    ----------------------------
    tx_rx_select       : in  std_logic;       -- 1 -> Tx 
    ----------------------------                 0 -> Rx
    -- Filter bypass
    ----------------------------
    filtbyp_tx_i       : in  std_logic;       -- 1 -> bypass the filter for Tx
    ----------------------------
    -- I & Q for Rx (decimation)
    ----------------------------    
    -- From dc_offset (60 MS/s)
    rx_filter_in_i     : in  std_logic_vector(size_in_rx_g-1 downto 0);
    rx_filter_in_q     : in  std_logic_vector(size_in_rx_g-1 downto 0);
    -- To Rx path (20 MS/s)
    rx_filter_out_i    : out std_logic_vector(size_out_rx_g-1 downto 0);
    rx_filter_out_q    : out std_logic_vector(size_out_rx_g-1 downto 0);
    ----------------------------
    -- I & Q for Tx (interpolation)
    ----------------------------
    -- From Tx path (20 MS/s)
    tx_filter_in_i     : in  std_logic_vector(size_in_tx_g-1 downto 0);
    tx_filter_in_q     : in  std_logic_vector(size_in_tx_g-1 downto 0);
    -- To iq_compensation (60 MS/s)
    tx_filter_out_i    : out std_logic_vector(size_out_tx_g-1 downto 0);
    tx_filter_out_q    : out std_logic_vector(size_out_tx_g-1 downto 0);
    ----------------------------
    -- Sampling ready command
    ----------------------------
    start_of_burst_i   : in  std_logic;  -- start of burst
    sample_ready_tx_i  : in  std_logic;  -- toggle from Tx path
    --
    sample_ready_rx_o  : out std_logic;  -- pulse for rx
    sample_toggle_rx_o : out std_logic;  -- toggle for rx
    ----------------------------
    -- Normalization factor
    ----------------------------
    txnorm_i           : in  std_logic_vector(7 downto 0);
    ----------------------------
    -- Core interface
    ----------------------------
    data_filtered_i    : in  std_logic_vector(size_core_out_g-1 downto 0);
    data_filtered_q    : in  std_logic_vector(size_core_out_g-1 downto 0);
    --
    data2core_i        : out std_logic_vector(size_core_in_g-1 downto 0);
    data2core_q        : out std_logic_vector(size_core_in_g-1 downto 0);
    --
    clear_core         : out std_logic;
    tx_active          : out std_logic;
    ----------------------------
    -- DC Offset pre-estimation control
    ----------------------------
    dc_pre_estim_valid : out std_logic
    );

end control_filter;
