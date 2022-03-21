--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: aes_blockcipher.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block is the core of the AES Cryptographic Processor. It
--              receives the Key and the State as input and performs all the
--              encrytion protocol on one state.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/aes_blockcipher/vhdl/rtl/aes_blockcipher.vhd,v  
--  Log: aes_blockcipher.vhd,v  
-- Revision 1.2  2003/11/14 18:08:18  Dr.A
-- aes_sm port map update.
--
-- Revision 1.1  2003/09/01 16:34:59  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--
-- Log history:
--
-- Source: Good
-- Log: aes_blockcipher.vhd,v
-- Revision 1.4  2003/09/01 16:14:13  Dr.A
-- Added ciph_done_early.
--
-- Revision 1.3  2003/08/28 15:17:33  Dr.A
-- Separated into 3 files: encrypt, decrypt and state machines.
--
-- Revision 1.2  2003/07/16 13:36:18  Dr.A
-- Updated key size.
--
-- Revision 1.1  2003/07/03 14:01:06  Dr.A
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

--library aes_blockcipher_rtl; 
library work;
--use aes_blockcipher_rtl.aes_blockcipher_pkg.ALL; 
use work.aes_blockcipher_pkg.ALL; 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity aes_blockcipher is
  generic (
    ccm_mode_g  : integer := 0          -- 1 to use the AES cipher in CCM mode.
  );
  port (
    -- Clocks and resets
    clk           : in  std_logic; -- AHB clock.
    reset_n       : in  std_logic; -- AHB reset. Inverted logic.
    -- Control lines
    opmode        : in  std_logic; -- Indicates Rx (0) or Tx (1) mode.
    aes_ksize     : in  std_logic_vector( 5 downto 0); -- Key size in bytes.
    key_load4     : in  std_logic; -- Signal to save the first 4 key bytes.
    key_load8     : in  std_logic; -- Signal to save the last 4 key bytes.
    start_expand  : in  std_logic; -- Signal to start Key Schedule.
    start_cipher  : in  std_logic; -- Signal to encrypt/decrypt one state.
    --
    expand_done   : out std_logic; -- Key Schedule done.
    cipher_done   : out std_logic; -- Indicates encryption/decryption done.
    ciph_done_early: out std_logic;-- Flag set 2 cycles before cipher_done.
    -- Interrupt
    stopop        : in  std_logic; -- Stops the encryption/decryption.
    -- Initial key words
    init_key_w0   : in  std_logic_vector(31 downto 0);
    init_key_w1   : in  std_logic_vector(31 downto 0);
    init_key_w2   : in  std_logic_vector(31 downto 0);
    init_key_w3   : in  std_logic_vector(31 downto 0);
    init_key_w4   : in  std_logic_vector(31 downto 0);
    init_key_w5   : in  std_logic_vector(31 downto 0);
    init_key_w6   : in  std_logic_vector(31 downto 0);
    init_key_w7   : in  std_logic_vector(31 downto 0);
    -- State to encrypt/decrypt
    init_state_w0 : in  std_logic_vector(31 downto 0);
    init_state_w1 : in  std_logic_vector(31 downto 0);
    init_state_w2 : in  std_logic_vector(31 downto 0);
    init_state_w3 : in  std_logic_vector(31 downto 0);
    -- Result (Encrypted/decrypted State)
    result_w0     : out std_logic_vector(31 downto 0);
    result_w1     : out std_logic_vector(31 downto 0);
    result_w2     : out std_logic_vector(31 downto 0);
    result_w3     : out std_logic_vector(31 downto 0);
    -- AES SRAM Interface
    sram_wdata    : out std_logic_vector(127 downto 0); -- Data to be written.
    sram_address  : out std_logic_vector(  3 downto 0); -- Address.
    sram_wen      : out std_logic; -- Write Enable. Inverted logic.
    sram_cen      : out std_logic; -- Chip Enable. Inverted logic.
    --
    sram_rdata    : in  std_logic_vector(127 downto 0) -- Data read.
  );
end aes_blockcipher;
