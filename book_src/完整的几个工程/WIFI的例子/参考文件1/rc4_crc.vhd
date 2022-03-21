
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: rc4_crc.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.20   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Top of the RC4 Cryptographic Processor.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/rc4_crc/vhdl/rtl/rc4_crc.vhd,v  
--  Log: rc4_crc.vhd,v  
-- Revision 1.20  2005/05/31 15:44:00  Dr.A
-- #BugId:938#
-- New diags
--
-- Revision 1.19  2004/05/04 09:44:40  Dr.A
-- First release of changes to correct MIC on fragmented MSDUs.
--
-- Revision 1.18  2003/11/26 08:39:56  Dr.A
-- Added D4/D6 compliancy.
--
-- Revision 1.17  2003/10/09 16:40:41  Dr.A
-- Cleaned.
--
-- Revision 1.16  2003/09/29 16:03:09  Dr.A
-- Added crc-debug.
--
-- Revision 1.15  2003/09/23 14:06:46  Dr.A
-- Added ports from str_proc_control.
--
-- Revision 1.14  2003/09/15 08:40:52  Dr.A
-- Diagnostic port.
--
-- Revision 1.13  2003/08/28 15:05:23  Dr.A
-- Added done_early signals. Changed bsize length.
--
-- Revision 1.12  2003/08/13 16:22:07  Dr.A
-- rc4_control port map updated.
--
-- Revision 1.11  2003/07/16 13:19:10  Dr.A
-- Updated for spec 0.09. Added tkip_key_mixing block. State machine and controls moved to a separated entity.
--
-- Revision 1.10  2003/07/03 14:14:05  Dr.A
-- Re-written for TKIP.
--
-- Revision 1.9  2002/12/17 17:08:12  elama
-- Reduced the size of int_read_size, kstr_size, keyload_rd_size,
-- data_size and int_write_size to 4 bits.
--
-- Revision 1.8  2002/12/04 12:30:57  elama
-- Increased the size of key_states to 21 bits.
--
-- Revision 1.7  2002/11/20 15:29:54  elama
-- Solved bug in the addrmax_g generic.
--
-- Revision 1.6  2002/11/19 15:23:14  elama
-- Finished the implementation of the addrmax_g generic.
--
-- Revision 1.5  2002/11/19 14:51:52  elama
-- Changed the process_done flag generation.
--
-- Revision 1.4  2002/11/12 17:41:54  elama
-- Added opmode and enablecrc to the sensitivity list in the
-- main state machine.
--
-- Revision 1.3  2002/10/25 09:06:32  elama
-- Changed bsize to 25 bits.
--
-- Revision 1.2  2002/10/16 16:46:11  elama
-- Added the CRC.
-- Changed the read_size and write_size to 4 bits.
-- Implemented the stop_operation (stopop) functionality.
-- Removed the io_error generation.
--
-- Revision 1.1  2002/10/15 13:14:50  elama
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Revision 1.5  2002/10/15 13:15:00  elama
-- Taken the SRAM out of the block.

-- Revision 1.4  2002/10/14 13:23:05  elama
-- Implemented the interrupt line.
-- Solved several bugs.
--
-- Revision 1.3  2002/09/23 13:09:34  elama
-- Added the generic for the RC4_SBoxInit subblock.
--
-- Revision 1.2  2002/09/16 14:09:17  elama
-- Re-designed the block to make it bus independant.
--
-- Revision 1.1  2002/07/30 09:50:26  elama
-- Initial revision
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

--library rc4_crc_rtl; 
library work;
--use rc4_crc_rtl.rc4_crc_pkg.ALL; 
use work.rc4_crc_pkg.ALL; 

--library crc32_rtl; 
library work;
--library tkip_key_mixing_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity rc4_crc is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk            : in  std_logic;     -- AHB clock.
    reset_n        : in  std_logic;     -- AHB reset. Inverted logic.
    --------------------------------------
    -- Interrupts
    --------------------------------------
    process_done   : out std_logic;     -- Pulse indicating encryption finished.
    crc_int        : out std_logic;     -- Indicates error in CRC.
    mic_int        : out std_logic;     -- Indicates error in MIC.
    --------------------------------------
    -- Global controls
    --------------------------------------
    crc_debug      : in  std_logic;     -- Enable CRC stored for debug.
    opmode         : in  std_logic;     -- Indicates Rx (0) or Tx (1) mode.
    startop        : in  std_logic;     -- Pulse that starts the encryption.
    stopop         : in  std_logic;     -- Stops the encryption.
    enablecrypt    : in  std_logic;     -- Enables(1) or disables the encryption
    enablecrc      : in  std_logic;     -- Enables (1) or disables CRC operation
    enablemic      : in  std_logic;     -- Enables (1) or disables MIC operation
    -- Sizes in bytes
    rc4_ksize      : in  std_logic_vector( 7 downto 0);-- Key size.
    rc4_bsize_lsb  : in  std_logic_vector( 3 downto 0);-- Data buffer size LSB.
    -- Number of data states (16 bytes) to process.
    state_number   : in  std_logic_vector(12 downto 0);
    -- Addresses
    rc4_csaddr     : in  std_logic_vector(31 downto 0);-- Control structure.
    rc4_kaddr      : in  std_logic_vector(31 downto 0);-- Key.
    rc4_saddr      : in  std_logic_vector(31 downto 0);-- Source buffer.
    rc4_daddr      : in  std_logic_vector(31 downto 0);-- Destination buffer.
    rc4_maddr      : in  std_logic_vector(31 downto 0);-- Control structure.
    --------------------------------------
    -- Control structure
    --------------------------------------
    packet_num     : in  std_logic_vector(47 downto 0);
    --------------------------------------
    -- Signals for Michael processing
    --------------------------------------
    -- Hardware compliancy with IEEE 802.11i drafts, D4.0 against D6.0 and after
    comply_d6_d4n  : in  std_logic;     -- Low for MIC IV compliancy with D4.0.
    -- Michael Control signals
    firstpack      : in  std_logic;     -- High if MPDU is the first of an MSDU.
    lastpack       : in  std_logic;     -- High if MPDU is the last of an MSDU.
    -- Michael initial values (from the control structure).
    l_michael_init : in  std_logic_vector(31 downto 0);
    r_michael_init : in  std_logic_vector(31 downto 0);
    -- Michael IV data.
    priority       : in  std_logic_vector( 7 downto 0); -- Priority field.
    --------------------------------------
    -- Read Interface
    --------------------------------------
    -- Controls
    start_read     : out std_logic;     -- Start reading data.
    read_size      : out std_logic_vector( 3 downto 0);-- Size of data to read.
    read_addr      : out std_logic_vector(31 downto 0);-- Address to read data.
    --
    read_done      : in  std_logic;     -- All data read.
    read_done_dly  : in  std_logic;     -- read_done delayed by one clock cycle.
    -- Data
    read_word0     : in  std_logic_vector(31 downto 0);-- Read word 0.
    read_word1     : in  std_logic_vector(31 downto 0);-- Read word 1.
    read_word2     : in  std_logic_vector(31 downto 0);-- Read word 2.
    read_word3     : in  std_logic_vector(31 downto 0);-- Read word 3.
    --------------------------------------
    -- Write Interface:
    --------------------------------------
    -- Controls
    start_write    : out std_logic;     -- Start writing data.
    write_size     : out std_logic_vector( 3 downto 0);-- Size of data to write.
    write_addr     : out std_logic_vector(31 downto 0);-- Address to write data.
    --
    write_done     : in  std_logic;     -- All data written.
    -- Data
    write_word0    : out std_logic_vector(31 downto 0);-- Word 0 to be written.
    write_word1    : out std_logic_vector(31 downto 0);-- Word 1 to be written.
    write_word2    : out std_logic_vector(31 downto 0);-- Word 2 to be written.
    write_word3    : out std_logic_vector(31 downto 0);-- Word 3 to be written.
    --------------------------------------
    -- RC4 SRAM
    --------------------------------------
    sram_wdata     : out std_logic_vector(7 downto 0);-- Data to be written.
    sram_address   : out std_logic_vector(8 downto 0);-- Address.
    sram_wen       : out std_logic;     -- Write Enable. Inverted logic.
    sram_cen       : out std_logic;     -- Chip Enable. Inverted logic.
    --
    sram_rdata     : in  std_logic_vector(7 downto 0);-- Data read.
    --------------------------------------
    -- Diagnostic port
    --------------------------------------
    rc4_diag       : out std_logic_vector(7 downto 0)

  );
end rc4_crc;
