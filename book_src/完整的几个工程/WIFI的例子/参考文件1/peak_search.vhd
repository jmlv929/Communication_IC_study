
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: peak_search.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.6   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Peak Detection : detect the position of the maximum of the xb
-- in a range of 16.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/postprocessing/vhdl/rtl/peak_search.vhd,v  
--  Log: peak_search.vhd,v  
-- Revision 1.6  2004/04/05 17:19:26  Dr.C
-- Change yb_counter_i value in peak_storage_p.
--
-- Revision 1.5  2003/12/23 10:18:48  Dr.B
-- yb_max_g added.
--
-- Revision 1.4  2003/08/01 14:52:44  Dr.B
-- update signals for new metrics calc.
--
-- Revision 1.3  2003/06/25 17:09:18  Dr.B
-- add a position_valid to not generate any signal during the first time.
--
-- Revision 1.2  2003/04/04 16:23:27  Dr.B
-- bug on max_peax_mem corrected.
--
-- Revision 1.1  2003/03/27 16:48:45  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity peak_search is
  generic (
    yb_size_g : integer := 9;
    yb_max_g  : integer := 4);
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                  : in  std_logic;
    reset_n              : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    init_i               : in  std_logic;  -- initialize registers
    enable_peak_search_i : in  std_logic;  -- enable block (no search when dis)
    yb_data_valid_i      : in  std_logic;  -- yb available
    yb_i                 : in  std_logic_vector (yb_size_g-1 downto 0);  -- magnitude xb
    yb_counter_i         : in  std_logic_vector(6 downto 0);-- 16 counter 
    --
    peak_position_o      : out std_logic_vector (3 downto 0);  -- position of peak mod 16
    f_position_o         : out std_logic;   -- high when counter = F (reg)
    expected_peak_o      : out std_logic;   -- high when a next peak should occur (according to memorize peak)
    current_peak_o       : out std_logic    -- high when a peak occurs (according to present peak)
  );

end peak_search;
