
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: rc4_keystream.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.7   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block is part of the RC4 Cryptographic Processor.
-- In this block the Key Stream is calculated. The key is XORed with the
-- data read from AHB to encrypt them and the encrypted data sent back to
-- the AHB.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/rc4_crc/vhdl/rtl/rc4_keystream.vhd,v  
--  Log: rc4_keystream.vhd,v  
-- Revision 1.7  2003/08/28 14:43:45  Dr.A
-- Added done_early output.
--
-- Revision 1.6  2003/07/16 13:18:09  Dr.A
-- Removed addtion_X registers (useless).
--
-- Revision 1.5  2003/07/03 14:11:05  Dr.A
-- Debugged keystr_done asserted one clock cycle too early.
--
-- Revision 1.4  2002/12/17 17:07:06  elama
-- Reduced the size of sram_counter and kstr_size to 4 bits.
--
-- Revision 1.3  2002/10/16 16:26:45  elama
-- Solved bug in sram_counter.
--
-- Revision 1.2  2002/10/16 16:07:07  elama
-- Changed kstr_size to 5 bits.
--
-- Revision 1.1  2002/10/15 13:18:22  elama
-- Initial revision
--
--
--------------------------------------------------------------------------------

library IEEE; 
  use IEEE.STD_LOGIC_1164.ALL; 
  use IEEE.STD_LOGIC_UNSIGNED.ALL;
  use IEEE.STD_LOGIC_ARITH.ALL;

entity rc4_keystream is
  port (
    -- Clocks and resets
    clk        : in  std_logic;         -- AHB clock.
    reset_n    : in  std_logic;         -- AHB reset. Inverted logic.
    -- Selector
    init_keystr: in  std_logic;         -- Positive edge initialises Key Stream.
    start_keystr:in  std_logic;         -- Positive edge starts key stream.
    keystr_done: out std_logic;         -- Flag indicating key stream finished.
    keystr_done_early: out std_logic;   -- Flag set 2 cycles before keystr_done.
    -- Key Stream Words
    key_stream0: out std_logic_vector(31 downto 0);-- Key stream byte 0.
    key_stream1: out std_logic_vector(31 downto 0);-- Key stream byte 1.
    key_stream2: out std_logic_vector(31 downto 0);-- Key stream byte 2.
    key_stream3: out std_logic_vector(31 downto 0);-- Key stream byte 3.
    -- SRAM
    sr_wdata   : out std_logic_vector( 7 downto 0);-- SRAM Write data.
    sr_address : out std_logic_vector( 8 downto 0);-- SRAM Address bus.
    sr_wen     : out std_logic;         -- SRAM write enable. Inverted logic.
    sr_cen     : out std_logic;         -- SRAM chip enable. Inverted logic.
    sr_rdata   : in  std_logic_vector( 7 downto 0);-- SRAM Read data.
    -- Registers
    kstr_size  : in  std_logic_vector( 3 downto 0) -- Size of the data in bytes
  );
end rc4_keystream;
