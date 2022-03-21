
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: state2byte.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.6   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block serialises the state (4 words) in groups of 8 bits
--               to calculate the CRC.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/rc4_crc/vhdl/rtl/state2byte.vhd,v  
--  Log: state2byte.vhd,v  
-- Revision 1.6  2003/12/04 09:29:12  Dr.A
-- Register for s2bdone_early.
--
-- Revision 1.5  2003/08/28 15:00:52  Dr.A
-- Added done_early output.
--
-- Revision 1.4  2003/07/03 14:09:25  Dr.A
-- Removed internal registers.
--
-- Revision 1.3  2002/11/26 10:54:33  elama
-- Solved bug in Output_byte process.
--
-- Revision 1.2  2002/11/21 16:31:22  elama
-- Removed a negative clock.
--
-- Revision 1.1  2002/10/15 13:19:27  elama
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Revision 1.3  2002/10/14 13:26:21  elama
-- Added the "size" port and modified the structure
-- of the block accordingly.
--
-- Revision 1.2  2002/09/16 14:18:09  elama
-- Added the wait_cycle input line.
--
-- Revision 1.1  2002/07/30 09:51:13  elama
-- Initial revision
--------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 

entity state2byte is
  port (
    -- Clocks and resets:
    clk         : in  std_logic;        -- AHB clock.
    reset_n     : in  std_logic;        -- AHB reset. Inverted logic.
    -- Flags:
    start_s2b   : in  std_logic;        -- Positive edge starts the state2byte.
    s2b_done    : out std_logic;        -- Flag indicating state2byte finished.
    s2b_done_early: out std_logic;      -- Flag set two cycles before s2b_done.
    -- Size:
    size        : in  std_logic_vector(3 downto 0);-- Number of bytes to
                                        -- serialize ("0001" -> 1 byte      )
                                        --           ("0010" -> 2 bytes     ?)
    -- Input state:                     --           ("0000" -> all 16 bytes)
    state_word0 : in  std_logic_vector(31 downto 0);-- First state word.
    state_word1 : in  std_logic_vector(31 downto 0);-- Second state word.
    state_word2 : in  std_logic_vector(31 downto 0);-- Third state word.
    state_word3 : in  std_logic_vector(31 downto 0);-- Fourth state word.
    -- Wait:
    wait_cycle  : in  std_logic;        -- Wait line.
    -- Output byte.
    byte_to_crc : out std_logic_vector( 7 downto 0)-- Output byte.
  );
end state2byte;
