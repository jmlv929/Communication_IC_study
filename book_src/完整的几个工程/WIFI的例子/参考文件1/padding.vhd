
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: padding.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This unit builds the complete WLAN frame, starting with the
--              tx_start_end_req_i signal. The SIGNAL and SERVICE field are built
--              from the input parameters rate, length, and service. Parity and
--              tail bits are added. Then the incoming data octets from data_i
--              are taken, when validated with data_valid_i. After the data
--              bits, the tail and (if necessary) the pad bits are appended.
-- 
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/padding/vhdl/rtl/padding.vhd,v  
--  Log: padding.vhd,v  
-- Revision 1.4  2004/12/14 10:54:53  Dr.C
-- #BugId:595#
-- Change enable_i to be used like a synchronous reset controlled by Tx state machine for BT coexistence.
--
-- Revision 1.3  2003/05/26 15:40:04  Dr.A
-- Wait for enable to generate marker_o and start_of_burst_o.
--
-- Revision 1.2  2003/04/02 16:56:05  Dr.A
-- Debugged symbol_cnt wrap around in data_tail state.
--
-- Revision 1.1  2003/03/13 15:00:20  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity padding is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                : in std_logic;
    reset_n            : in std_logic;

    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i           : in  std_logic;
    data_ready_o       : out std_logic;
    data_ready_i       : in  std_logic;
    data_valid_i       : in  std_ulogic;
    tx_start_end_req_i : in  std_logic;
    prbs_sel_i         : in  std_logic_vector(1 downto 0);
    prbs_inv_i         : in  std_logic;
    prbs_init_i        : in  std_logic_vector(22 downto 0);
    --
    data_valid_o       : out std_logic;
    marker_o           : out std_logic;
    coding_rate_o          : out std_logic_vector(1 downto 0);  -- data coding rate
    qam_mode_o         : out std_logic_vector(1 downto 0);  -- qam mode
    start_burst_o      : out std_logic;
    --------------------------------------
    -- Data
    --------------------------------------
    txv_length_i       : in  std_logic_vector(11 downto 0);  -- Length of frame 1
    txv_rate_i         : in  std_logic_vector(3 downto 0);  -- Rate for frame 1
    txv_service_i      : in  std_logic_vector(15 downto 0);  -- Service field
    data_i             : in  std_logic_vector(7 downto 0);  -- Input data octet
    --
    data_o             : out std_logic


    );

end padding;
