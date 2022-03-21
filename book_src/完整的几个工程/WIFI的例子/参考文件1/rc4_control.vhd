--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream_Processing
--    ,' GoodLuck ,'      RCSfile: rc4_control.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.16   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : State machine and control lines for the RC4 block.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/rc4_crc/vhdl/rtl/rc4_control.vhd,v  
--  Log: rc4_control.vhd,v  
-- Revision 1.16  2005/05/31 15:43:53  Dr.A
-- #BugId:938#
-- New diags
--
-- Revision 1.15  2004/05/04 16:05:14  Dr.A
-- Cleaned comments.
--
-- Revision 1.14  2004/05/04 09:44:39  Dr.A
-- First release of changes to correct MIC on fragmented MSDUs.
--
-- Revision 1.13  2003/12/04 09:31:53  Dr.A
-- Added registers to ease synthesis.
--
-- Revision 1.12  2003/11/26 08:39:18  Dr.A
-- Added D6.0 compliant Michael IV, enabled by register bit.
--
-- Revision 1.11  2003/09/29 16:02:52  Dr.A
-- Added crc_debug.
--
-- Revision 1.10  2003/09/23 14:06:00  Dr.A
-- State_number and read_done_dly moved to str_proc_control. bsize set to 16 bits.
--
-- Revision 1.9  2003/09/15 08:40:44  Dr.A
-- Diagnostic port.
--
-- Revision 1.8  2003/09/10 07:11:17  Dr.A
-- Corrected MIC init value oading. Small FSM changes.
--
-- Revision 1.7  2003/09/03 12:20:09  Dr.A
-- Debugged write address.
--
-- Revision 1.6  2003/09/02 09:24:16  Dr.A
-- Debugged state machine (wait for CRC done before leaving wr_kstr).
-- Changed crc_int generation.
--
-- Revision 1.5  2003/08/28 15:03:51  Dr.A
-- Reworked state machine to pipeline key stream and AHB accesses.
--
-- Revision 1.4  2003/08/21 16:16:34  Dr.A
-- Corrected length of control pulses.
--
-- Revision 1.3  2003/08/13 16:21:56  Dr.A
-- Removed unused port.
--
-- Revision 1.2  2003/08/06 13:48:03  Dr.A
-- Corrected bug in state machine to begin key mixing.
-- Removed useless test when setting saddr and daddr.
--
-- Revision 1.1  2003/07/16 13:20:27  Dr.A
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
entity rc4_control is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk            : in  std_logic;     -- AHB clock.
    reset_n        : in  std_logic;     -- AHB reset. Inverted logic.
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
    -- Controls for sizes.
    rc4_bsize_lsb  : in  std_logic_vector( 3 downto 0);-- Data buffer size LSB.
    -- Number of data states (16 bytes) to process.
    state_number   : in  std_logic_vector(12 downto 0);
    -- Addresses
    rc4_csaddr     : in  std_logic_vector(31 downto 0);-- Control structure.
    rc4_saddr      : in  std_logic_vector(31 downto 0);-- Source buffer.
    rc4_daddr      : in  std_logic_vector(31 downto 0);-- Destination buffer.
    rc4_maddr      : in  std_logic_vector(31 downto 0);-- Control structure.
    rc4_kaddr      : in  std_logic_vector(31 downto 0);-- Key in control struct.
    -- Interrupts
    process_done   : out std_logic;     -- Pulse indicating encryption finished.
    crc_int        : out std_logic;     -- Indicates error in CRC.
    mic_int        : out std_logic;     -- Indicates error in MIC.
    --------------------------------------
    -- Commands
    --------------------------------------
    start_sbinit   : out std_logic;     -- Start S-Box initialisation.
    start_keymix   : out std_logic;     -- Start TKIP key mixing.
    key1_key2n     : out std_logic;     -- Indicates the TKIP key mixing phase.
    start_keyload  : out std_logic;     -- Start key loading in RAM.
    start_sboxgen  : out std_logic;     -- Start S-Box generation.
    init_keystr    : out std_logic;     -- Start key stream initialisation.
    start_keystr   : out std_logic;     -- Start key stream generation.
    start_michael  : out std_logic;     -- Start Michael processing.
    start_s2b      : out std_logic;     -- Start CRC serializer (state to bytes)
    crc_ld_init    : out std_logic;     -- Initialises CRC calculation.
    crc_calc       : out std_logic;     -- Pulse to compute CRC byte.
    --
    sbinit_done    : in  std_logic;     -- S-Box initialisation done.
    keymix1_done   : in  std_logic;     -- TKIP key mixing phase 1 done.
    keymix2_done   : in  std_logic;     -- TKIP key mixing phase 2 done.
    keyload_done   : in  std_logic;     -- High when Key is stored in SRAM.
    sboxgen_done   : in  std_logic;     -- S-Box generation done.
    kstr_done      : in  std_logic;     -- Indicates Key Stream calculated.
    michael_done   : in  std_logic;     -- Michael block function done.
    s2b_done       : in  std_logic;     -- Flag indicating CRC calculated.
    -- 'done' signals asserted two cycles earlier to pipeline next AHB access.
    kstr_done_early: in  std_logic;     -- Key Stream calculated.
    s2b_done_early : in  std_logic;     -- CRC calculated.
    --------------------------------------
    -- Signals from control structure / MAC header
    --------------------------------------
    firstpack      : in  std_logic;     -- High if MPDU is the first of an MSDU.
    lastpack       : in  std_logic;     -- High if MPDU is the last of an MSDU.
    priority       : in  std_logic_vector( 7 downto 0); -- Priority field.
    --
    address2       : out std_logic_vector(47 downto 0); -- Address 2 field.
    --------------------------------------
    -- Signals for Michael processing
    --------------------------------------
    -- Hardware compliancy with IEEE 802.11i drafts, D4.0 against D6.0 and after
    comply_d6_d4n  : in  std_logic;     -- Low for MIC IV compliancy with D4.0.
    -- Michael initial values.
    l_michael_init : in  std_logic_vector(31 downto 0);
    r_michael_init : in  std_logic_vector(31 downto 0);
    -- Michael block function interface.
    l_michael_out  : in  std_logic_vector(31 downto 0); -- L Michael result.
    r_michael_out  : in  std_logic_vector(31 downto 0); -- R Michael result.
    --
    l_michael_in   : out std_logic_vector(31 downto 0); -- L Michael input.
    r_michael_in   : out std_logic_vector(31 downto 0); -- R Michael input.    
    --------------------------------------
    -- Read Interface
    --------------------------------------
    -- Controls from Keyload block.
    keyload_start_read : in  std_logic; -- Start read process
    keyload_rd_size    : in  std_logic_vector( 3 downto 0);-- Size of read data.
    keyload_rd_addr    : in  std_logic_vector(31 downto 0);-- Add to read data.
    -- Controls from/to AHB interface
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
    -- Write Interface
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
    -- Key Stream
    --------------------------------------
    kstr_word0     : in  std_logic_vector(31 downto 0);
    kstr_word1     : in  std_logic_vector(31 downto 0);
    kstr_word2     : in  std_logic_vector(31 downto 0);
    kstr_word3     : in  std_logic_vector(31 downto 0);
    --
    kstr_size      : out std_logic_vector( 3 downto 0);-- Size of data.
    --------------------------------------
    -- CRC
    --------------------------------------
    -- Data fed to the state to byte serializer.
    data2crc_w0    : out std_logic_vector(31 downto 0);
    data2crc_w1    : out std_logic_vector(31 downto 0);
    data2crc_w2    : out std_logic_vector(31 downto 0);
    data2crc_w3    : out std_logic_vector(31 downto 0);
    -- CRC results.
    crc_out_1st    : in  std_logic_vector( 7 downto 0);
    crc_out_2nd    : in  std_logic_vector( 7 downto 0);
    crc_out_3rd    : in  std_logic_vector( 7 downto 0);
    crc_out_4th    : in  std_logic_vector( 7 downto 0);
    -- Number of bytes to serialize
    state2byte_size: out std_logic_vector( 3 downto 0);
    --------------------------------------
    -- SRAM interface
    --------------------------------------
    -- Address, write data, write enable and chip enable from S_Box init.
    sboxinit_address: in  std_logic_vector( 7 downto 0);
    sboxinit_wdata : in  std_logic_vector( 7 downto 0);
    sboxinit_wen   : in  std_logic;
    sboxinit_cen   : in  std_logic;
    -- Address, write data, write enable and chip enable from Key loading.
    key_sr_address : in  std_logic_vector( 8 downto 0);
    key_sr_wdata   : in  std_logic_vector( 7 downto 0);
    key_sr_wen     : in  std_logic;
    key_sr_cen     : in  std_logic;
    -- Address, write data, write enable and chip enable from S-Box Generation.
    sboxgen_address: in  std_logic_vector( 8 downto 0);
    sboxgen_wdata  : in  std_logic_vector( 7 downto 0);
    sboxgen_wen    : in  std_logic;
    sboxgen_cen    : in  std_logic;
    -- Address, write data, write enable and chip enable from Key Stream block.
    kstr_sr_address: in  std_logic_vector( 8 downto 0);
    kstr_sr_wdata  : in  std_logic_vector( 7 downto 0);
    kstr_sr_wen    : in  std_logic;
    kstr_sr_cen    : in  std_logic;
    -- SRAM lines.
    sram_wdata     : out std_logic_vector(7 downto 0);-- Data to be written.
    sram_address   : out std_logic_vector(8 downto 0);-- Address.
    sram_wen       : out std_logic;     -- Write Enable. Inverted logic.
    sram_cen       : out std_logic;     -- Chip Enable. Inverted logic.
    --------------------------------------
    -- Diagnostic port
    --------------------------------------
    rc4_diag       : out std_logic_vector(7 downto 0)
    
  );

end rc4_control;
