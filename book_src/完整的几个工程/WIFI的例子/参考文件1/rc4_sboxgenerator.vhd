
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: rc4_sboxgenerator.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block is part of the RC4 Cryptographic Processor.
-- It generates the S-Box according to the following algorithm:.
-- for i=0 to 255
--   j=(j+Si+Ki) mod 256
--   swap Si and Sj
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/rc4_crc/vhdl/rtl/rc4_sboxgenerator.vhd,v  
--  Log: rc4_sboxgenerator.vhd,v  
-- Revision 1.2  2003/07/16 13:11:48  Dr.A
-- Removed addition signal (useless).
--
-- Revision 1.1  2002/10/15 13:17:47  elama
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Revision 1.2  2002/09/16 14:07:38  elama
-- Inverted the sr_we line.
-- Added the sr_cen line.
--
-- Revision 1.1  2002/07/30 09:50:24  elama
-- Initial revision
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity rc4_sboxgenerator is
  port (
    -- Clocks and resets
    clk        : in  std_logic;         -- AHB clock.
    reset_n    : in  std_logic;         -- AHB reset. Inverted logic.
    -- Selector
    start_sboxgen:in std_logic;         -- Positive edge starts s-box generation
    sboxgen_done:out std_logic;         -- Flag indicating s-box generation done
    -- SRAM
    sr_wdata   : out std_logic_vector( 7 downto 0);-- SRAM Write data.
    sr_address : out std_logic_vector( 8 downto 0);-- SRAM Address bus.
    sr_wen     : out std_logic;                    -- SRAM write enable.
    sr_cen     : out std_logic;                    -- SRAM chip enable.
    sr_rdata   : in  std_logic_vector( 7 downto 0) -- SRAM Read data.
  );
end rc4_sboxgenerator;
