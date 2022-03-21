
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: rc4_keyloading.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.8   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block is part of the RC4 Cryptographic Processor.
-- It loads the key from the memory to the SRAM. The address and size of the key
-- is given by the registers RC4_KSIZE and RC4_KADDR.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/rc4_crc/vhdl/rtl/rc4_keyloading.vhd,v  
--  Log: rc4_keyloading.vhd,v  
-- Revision 1.8  2003/09/15 12:20:05  Dr.A
-- Debugged key loading for key > 16 bytes. Added 256 bytes load for key size = 0.
--
-- Revision 1.7  2003/07/16 13:17:12  Dr.A
-- Modified to accept a key from the tkip_key_mixing block in tkip_mode.
--
-- Revision 1.6  2003/07/03 14:12:40  Dr.A
-- Removed generic.
--
-- Revision 1.5  2002/12/17 17:07:36  elama
-- Reduced the size of rd_size, bytes_written, init_size and init_size_dly
-- to 4 bits.
--
-- Revision 1.4  2002/11/26 13:00:59  elama
-- Solved bug in the addrmax_g generic.
--
-- Revision 1.3  2002/11/19 15:22:32  elama
-- Finished the implementation of the addrmax_g generic.
--
-- Revision 1.2  2002/10/16 16:31:09  elama
-- Changed rd_size to 5 bits.
--
-- Revision 1.1  2002/10/15 13:17:13  elama
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Revision 1.4  2002/10/15 13:40:00  elama
-- Added the stopop port.
--
-- Revision 1.3  2002/10/14 13:22:36  elama
-- Solved bugs in the address generation.
--
-- Revision 1.2  2002/09/16 13:59:20  elama
-- Re-designed the block to make it bus independant.
--
-- Revision 1.1  2002/07/30 09:50:05  elama
-- Initial revision
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity rc4_keyloading is
  port (
    -- Clocks and resets
    clk        : in  std_logic;         -- AHB clock.
    reset_n    : in  std_logic;         -- AHB reset. Inverted logic.
    -- Selector
    tkip_mode  : in  std_logic;         -- High when TKIP key mixing used.
    start_keyload:in std_logic;         -- Positive edge starts key loading.
    keyload_done:out std_logic;         -- Flag indicating Key stored in SRAM.
    -- Interrupt
    stopop     : in  std_logic;         -- Stop operation. Stop key loading.
    -- Read Data interface
    rd_size    : out std_logic_vector( 3 downto 0);-- Size of data to read.
    rd_addr    : out std_logic_vector(31 downto 0);-- Addr to read data
    rd_start_read:out std_logic;        -- Positive edge starts read process.
    rd_read_done:in  std_logic;         -- Flag indicating read process done.
    rd_word0   : in  std_logic_vector(31 downto 0);-- Word read.
    rd_word1   : in  std_logic_vector(31 downto 0);-- Word read.
    rd_word2   : in  std_logic_vector(31 downto 0);-- Word read.
    rd_word3   : in  std_logic_vector(31 downto 0);-- Word read.
    tkip_key_w0: in  std_logic_vector(31 downto 0);-- Mixed TKIP key.
    tkip_key_w1: in  std_logic_vector(31 downto 0);-- Mixed TKIP key.
    tkip_key_w2: in  std_logic_vector(31 downto 0);-- Mixed TKIP key.
    tkip_key_w3: in  std_logic_vector(31 downto 0);-- Mixed TKIP key.
    -- SRAM
    sr_wdata   : out std_logic_vector( 7 downto 0);-- SRAM Write data.
    sr_address : out std_logic_vector( 8 downto 0);-- SRAM Address bus.
    sr_wen     : out std_logic;                    -- SRAM write enable.
    sr_cen     : out std_logic;                    -- SRAM chip enable.
    sr_rdata   : in  std_logic_vector( 7 downto 0);-- SRAM Read data.
    -- Registers
    rc4_ksize  : in  std_logic_vector( 7 downto 0);-- Size of the key in bytes
    rc4_kaddr  : in  std_logic_vector(31 downto 0) -- Address of the key.
  );
end rc4_keyloading;
