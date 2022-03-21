
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: max_decision.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Timing Decision Metrics
--
-- The Timing Decision Metrics are calculated and then compared. When cp2
-- metric is the largest, CP2 is considered as detected
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/postprocessing/vhdl/rtl/max_decision.vhd,v  
--  Log: max_decision.vhd,v  
-- Revision 1.5  2003/08/01 14:52:17  Dr.B
-- improve calc metrics.
--
-- Revision 1.4  2003/06/27 16:14:17  Dr.B
-- memorize yb/yc1/yc2 old the 1st time.
--
-- Revision 1.3  2003/06/25 17:08:36  Dr.B
-- add memo_yb_first.
--
-- Revision 1.2  2003/04/02 13:09:49  Dr.B
-- mb_lpeak => mc1_lpeak.
--
-- Revision 1.1  2003/03/27 16:48:35  Dr.B
-- Initial revision
--
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity max_decision is
  generic (
    yb_size_g : integer := 10);
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                  : in  std_logic;  -- ofdm clock (80 MHz)   
    reset_n              : in  std_logic;  -- asynchronous negative reset
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i               : in  std_logic;  -- synchronous negative reset
    f_position_i         : in  std_logic;  -- when high yb_memo => yb_old
    current_peak_i       : in  std_logic;  -- used for y_old calculation
    expected_peak_i      : in  std_logic;  -- begin decision metrics and maximum search
    -- current (n) yb, yci, yt
    yb_data_valid_i      : in  std_logic;  -- xb available   
    yb_i                 : in  std_logic_vector (yb_size_g-1 downto 0);
    yc1_i                : in  std_logic_vector (yb_size_g-1 downto 0);
    yc2_i                : in  std_logic_vector (yb_size_g-1 downto 0);
    -- Timing decision metrics and maximum search outputs (flags + their valid)
    cp2_detected_o       : out std_logic;
    cp2_detected_pulse_o : out std_logic);

end max_decision;
