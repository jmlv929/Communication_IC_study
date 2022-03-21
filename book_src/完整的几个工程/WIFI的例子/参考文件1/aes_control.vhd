
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream_Processing
--    ,' GoodLuck ,'      RCSfile: aes_control.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.11   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : State machine and controls for the AES Cryptographic Processor.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/aes_ccm/vhdl/rtl/aes_control.vhd,v  
--  Log: aes_control.vhd,v  
-- Revision 1.11  2005/05/31 15:45:13  Dr.A
-- #BugId:938#
-- New diags
--
-- Revision 1.10  2003/12/04 09:26:10  Dr.A
-- Register for process_done.
--
-- Revision 1.9  2003/11/26 08:30:06  Dr.A
-- Removed mask on AAD QC field (D7.0).
--
-- Revision 1.8  2003/10/13 16:40:33  Dr.A
-- Register for data size.
--
-- Revision 1.7  2003/10/09 16:39:53  Dr.A
-- Cleaned.
--
-- Revision 1.6  2003/09/29 15:47:50  Dr.A
-- Key size is always 16 bytes: removed unused code.
--
-- Revision 1.5  2003/09/23 14:02:39  Dr.A
-- Cleaned code. Added MIC written to control structure for debug. buffer size length set to 16 bits. state_counter moved in str_proc_control.
--
-- Revision 1.4  2003/09/16 08:04:16  Dr.A
-- Cleaned code.
--
-- Revision 1.3  2003/09/01 16:02:34  Dr.A
-- Optimized state machine to write data while cipher is running.
--
-- Revision 1.2  2003/08/28 15:12:16  Dr.A
-- Removed unused states. Changed bsize length.
--
-- Revision 1.1  2003/07/16 13:38:50  Dr.A
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
use IEEE.STD_LOGIC_ARITH.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity aes_control is
  generic (
    addrmax_g     : integer := 32       -- AHB Address bus width (max. 32 bits).
  );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk           : in  std_logic;      -- AHB clock.
    reset_n       : in  std_logic;      -- AHB reset. Inverted logic.
    --------------------------------------
    -- Interrupts
    --------------------------------------
    process_done  : out std_logic;      -- High when en/decryption finished.
    mic_int       : out std_logic;      -- Indicates error when checking the MIC
    --------------------------------------
    -- Registers
    --------------------------------------
    startop       : in  std_logic;      -- Pulse that starts the encryption.
    stopop        : in  std_logic;      -- Stops the encryption/decryption.
    --------------------------------------
    -- Control structure
    --------------------------------------
    opmode        : in  std_logic;      -- Indicates Rx (0) or Tx (1) mode.
    priority      : in  std_logic_vector( 7 downto 0); -- Priority field.
    aes_packet_num: in  std_logic_vector(47 downto 0); -- Packet number.
    -- Addresses
    aes_csaddr    : in  std_logic_vector(addrmax_g-1 downto 0); --Control struct
    aes_saddr     : in  std_logic_vector(addrmax_g-1 downto 0); --Source.
    aes_daddr     : in  std_logic_vector(addrmax_g-1 downto 0); --Destination.
    aes_maddr     : in  std_logic_vector(addrmax_g-1 downto 0); --MAC header.
    aes_kaddr     : in  std_logic_vector(addrmax_g-1 downto 0); -- Key address.
    enablecrypt   : in  std_logic;      -- Enables(1) or disables the encryption
    -- Sizes (in bytes)
    aes_msize     : in  std_logic_vector( 5 downto 0); -- MAC header size.
    aes_bsize     : in  std_logic_vector(15 downto 0); -- Size of data buffer.
    -- Number of data states (16 bytes) to process.
    state_number  : in  std_logic_vector(12 downto 0);
    --------------------------------------
    -- Read Interface
    --------------------------------------
    start_read    : out std_logic;      -- Start reading data.
    read_size     : out std_logic_vector( 3 downto 0); -- Size of data to read.
    read_addr     : out std_logic_vector(addrmax_g-1 downto 0); -- Read address.
    -- 
    read_done     : in  std_logic;      -- All data read.
    -- Data read.
    read_word0    : in  std_logic_vector(31 downto 0);
    read_word1    : in  std_logic_vector(31 downto 0);
    read_word2    : in  std_logic_vector(31 downto 0);
    read_word3    : in  std_logic_vector(31 downto 0);
    --------------------------------------
    -- Write Interface
    --------------------------------------
    start_write   : out std_logic;      -- Start writing data.
    write_size    : out std_logic_vector( 3 downto 0); -- Size of data to write.
    write_addr    : out std_logic_vector(addrmax_g-1 downto 0); -- Write address
    -- Data to write.
    write_word0   : out std_logic_vector(31 downto 0);
    write_word1   : out std_logic_vector(31 downto 0);
    write_word2   : out std_logic_vector(31 downto 0);
    write_word3   : out std_logic_vector(31 downto 0);
    --
    write_done    : in  std_logic;      -- All data written.
    --------------------------------------
    -- Controls
    --------------------------------------
    key_load4     : out std_logic;      -- Signal to save the first 4 key bytes.
    start_expand  : out std_logic;      -- Positive edge starts Key expansion.
    start_cipher  : out std_logic;      -- Positive edge starts encryption round
    --
    expand_done   : in  std_logic;      -- Key expansion done.
    cipher_done   : in  std_logic;      -- Encryption/decryption round done.
    ciph_done_early:in  std_logic;      -- Flag set 2 cycles before cipher_done.
    --------------------------------------
    -- AES block cipher interface
    --------------------------------------
    -- AES state inputs
    aes_state_w0  : out std_logic_vector(31 downto 0);
    aes_state_w1  : out std_logic_vector(31 downto 0);
    aes_state_w2  : out std_logic_vector(31 downto 0);
    aes_state_w3  : out std_logic_vector(31 downto 0);
    -- AES blockcipher result
    result_w0     : in  std_logic_vector(31 downto 0);
    result_w1     : in  std_logic_vector(31 downto 0);
    result_w2     : in  std_logic_vector(31 downto 0);
    result_w3     : in  std_logic_vector(31 downto 0);
    --------------------------------------
    -- Diagnostic port
    --------------------------------------
    aes_ctrl_diag : out std_logic_vector(7 downto 0)
    
  );

end aes_control;
