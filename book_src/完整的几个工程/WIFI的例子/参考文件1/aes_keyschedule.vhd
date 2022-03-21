--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processor
--    ,' GoodLuck ,'      RCSfile: aes_keyschedule.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.1  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block performs the Key Expansion in the
--               AES encryption algorithm.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/aes_blockcipher/vhdl/rtl/aes_keyschedule.vhd,v  
--  Log: aes_keyschedule.vhd,v  
-- Revision 1.1  2003/09/01 16:35:18  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- Log history:
--
-- Source: Good
-- Log: aes_keyschedule.vhd,v
-- Revision 1.2  2003/07/16 13:37:42  Dr.A
-- Updated key size.
--
-- Revision 1.1  2003/07/03 14:01:25  Dr.A
-- Initial revision
--
--------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity aes_keyschedule is
  port (
    -- Clocks and resets
    clk          : in  std_logic;       -- System clock.
    reset_n      : in  std_logic;       -- System reset. Inverted logic.
    -- Flags:
    key_load4    : in  std_logic;       -- Signal to save the first 4 key bytes.
    key_load8    : in  std_logic;       -- Signal to save the last 4 key bytes.
    start_expand : in  std_logic;       -- Signal that starts the key expansion.
    expand_done  : out std_logic;       -- Flag indicating expansion done.
    -- Registers:
    aes_ksize    : in  std_logic_vector(5 downto 0);-- Size of key in bytes (Nk)
    -- Interruption:
    stopop       : in  std_logic;       -- Stops the keyschedule.
    -- Initial Key values:
    init_key_w0  : in  std_logic_vector(31 downto 0);-- Initial key word no.0.
    init_key_w1  : in  std_logic_vector(31 downto 0);-- Initial key word no.1.
    init_key_w2  : in  std_logic_vector(31 downto 0);-- Initial key word no.2.
    init_key_w3  : in  std_logic_vector(31 downto 0);-- Initial key word no.3.
    init_key_w4  : in  std_logic_vector(31 downto 0);-- Initial key word no.4.
    init_key_w5  : in  std_logic_vector(31 downto 0);-- Initial key word no.5.
    init_key_w6  : in  std_logic_vector(31 downto 0);-- Initial key word no.6.
    init_key_w7  : in  std_logic_vector(31 downto 0);-- Initial key word no.7.
    -- Key Storage Memory:
    memo_wrdata  : out std_logic_vector(127 downto 0);-- KeyWord to save in memo
    memo_address : out std_logic_vector( 3 downto 0);-- Address to save KeyWord.
    memo_wen     : out std_logic;       -- Memo Write Enable line. Inverted log.
    -- AES_SubByte block:
    subword      : in  std_logic_vector(31 downto 0);-- Result word.
    keyword      : out std_logic_vector(31 downto 0) -- Input word to SubBlock.
  );
end aes_keyschedule;
