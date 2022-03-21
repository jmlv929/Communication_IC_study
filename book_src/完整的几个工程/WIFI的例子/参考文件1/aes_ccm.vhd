
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: aes_ccm.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.9  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block is the top of the AES Cryptographic Processor.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/aes_ccm/vhdl/rtl/aes_ccm.vhd,v  
--  Log: aes_ccm.vhd,v  
-- Revision 1.9  2005/05/31 15:45:06  Dr.A
-- #BugId:938#
-- New diags
--
-- Revision 1.8  2003/11/26 08:30:42  Dr.A
-- Updated diag.
--
-- Revision 1.7  2003/09/29 15:46:33  Dr.A
-- Removed unused key size port.
--
-- Revision 1.6  2003/09/23 14:03:47  Dr.A
-- updated for new aes_control.
--
-- Revision 1.5  2003/09/01 16:38:11  Dr.A
-- Moved cipher files to another block.
--
-- Revision 1.4  2003/09/01 16:03:06  Dr.A
-- Added early signal.
--
-- Revision 1.3  2003/08/28 15:18:45  Dr.A
-- Changed bsize length. Added generic.
--
-- Revision 1.2  2003/07/16 13:39:20  Dr.A
-- Updated for version 0.09. Moved state machine and controls to a separated entity.
--
-- Revision 1.1  2003/07/03 14:04:59  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 

--library aes_ccm_rtl; 
library work;
--use aes_ccm_rtl.aes_ccm_pkg.ALL; 
use work.aes_ccm_pkg.ALL; 

--library aes_blockcipher_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity aes_ccm is
  generic (
    addrmax_g  : integer := 32          -- AHB Address bus width (max. 32 bits).
  );
  port (
    --------------------------------------
    -- Clocks and resets
    --------------------------------------
    clk        : in  std_logic;         -- AHB clock.
    reset_n    : in  std_logic;         -- AHB reset. Inverted logic.

    --------------------------------------
    -- Interrupts
    --------------------------------------
    process_done : out std_logic;       -- High when en/decryption finished.
    mic_int      : out std_logic;       -- Indicates an error in the CCMP MIC.

    --------------------------------------
    -- Registers
    --------------------------------------
    startop    : in  std_logic;         -- Pulse that starts the encryption.
    stopop     : in  std_logic;         -- Stops the encryption/decryption.

    --------------------------------------
    -- Control structure fields
    --------------------------------------
    opmode     : in  std_logic;         -- Indicates Rx (0) or Tx (1) mode.
    priority   : in  std_logic_vector( 7 downto 0);      -- Priority field.
    aes_packet_num  : in  std_logic_vector(47 downto 0); -- Packet number.
    -- Addresses
    aes_csaddr : in  std_logic_vector(addrmax_g-1 downto 0); -- Control struct.
    aes_saddr  : in  std_logic_vector(addrmax_g-1 downto 0); -- Source data.
    aes_daddr  : in  std_logic_vector(addrmax_g-1 downto 0); -- Destination data
    aes_maddr  : in  std_logic_vector(addrmax_g-1 downto 0); -- MAC header.
    aes_kaddr  : in  std_logic_vector(addrmax_g-1 downto 0); -- Key address.
    enablecrypt: in  std_logic;         -- Enables(1) or disables the encryption
    -- Sizes (in bytes)
    aes_msize  : in  std_logic_vector( 5 downto 0); -- Size of the MAC header.
    aes_bsize  : in  std_logic_vector(15 downto 0); -- Size of the data buffer.
    -- Number of data states (16 bytes) to process.
    state_number : in  std_logic_vector(12 downto 0);

    --------------------------------------
    -- Read Interface
    --------------------------------------
    start_read : out std_logic;         -- Pulse to start read access.
    read_size  : out std_logic_vector( 3 downto 0); -- Size of data to read.
    read_addr  : out std_logic_vector(addrmax_g-1 downto 0); -- Read address.
    --
    read_done  : in  std_logic;         -- Indicates read access is over.
    -- Read data words.
    read_word0 : in  std_logic_vector(31 downto 0);
    read_word1 : in  std_logic_vector(31 downto 0);
    read_word2 : in  std_logic_vector(31 downto 0);
    read_word3 : in  std_logic_vector(31 downto 0);

    --------------------------------------
    -- Write Interface
    --------------------------------------
    start_write: out std_logic;         -- Pulse to start write access.
    write_size : out std_logic_vector( 3 downto 0); -- Size of data to write.
    write_addr : out std_logic_vector(addrmax_g-1 downto 0); -- Write address.
    -- Words of data to write.
    write_word0: out std_logic_vector(31 downto 0);
    write_word1: out std_logic_vector(31 downto 0);
    write_word2: out std_logic_vector(31 downto 0);
    write_word3: out std_logic_vector(31 downto 0);
    --
    write_done : in  std_logic;         -- Indicates write access is over.

    --------------------------------------
    -- AES SRAM interface
    --------------------------------------
    sram_wdata : out std_logic_vector(127 downto 0); -- Data to be written.
    sram_addr  : out std_logic_vector(  3 downto 0); -- Address.
    sram_wen   : out std_logic;         -- Write Enable. Inverted logic.
    sram_cen   : out std_logic;         -- Chip Enable. Inverted logic.
    --
    sram_rdata : in  std_logic_vector(127 downto 0); -- Data read.

    --------------------------------------
    -- Diagnostic port
    --------------------------------------
    aes_diag   : out std_logic_vector(7 downto 0)
  );
end aes_ccm;
