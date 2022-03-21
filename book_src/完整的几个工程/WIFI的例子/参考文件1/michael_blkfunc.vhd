--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: michael_blkfunc.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Block function for TKIP Michael message processing.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/rc4_crc/vhdl/rtl/michael_blkfunc.vhd,v  
--  Log: michael_blkfunc.vhd,v  
-- Revision 1.2  2003/08/28 14:39:00  Dr.A
-- Reworked the state machine to suppress idle_state. MIC block function lasts now only four clock cycles.
--
-- Revision 1.1  2003/07/03 14:13:18  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity michael_blkfunc is
  port (
    -- Clocks and resets
    clk           : in  std_logic; -- AHB clock.
    reset_n       : in  std_logic; -- AHB reset. Inverted logic.
    -- Controls
    start_michael : in  std_logic; -- Pos edge starts Michael block function.
    michael_done  : out std_logic; -- Flag indicating function finished.
    -- Data words
    l_michael_in  : in  std_logic_vector(31 downto 0);
    r_michael_in  : in  std_logic_vector(31 downto 0);
    --
    l_michael_out : out std_logic_vector(31 downto 0);
    r_michael_out : out std_logic_vector(31 downto 0)
  );

end michael_blkfunc;
