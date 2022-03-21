
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: aes_sm.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block contains the state machine of the AES Cryptographic
--              Processor.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/aes_blockcipher/vhdl/rtl/aes_sm.vhd,v  
--  Log: aes_sm.vhd,v  
-- Revision 1.2  2003/11/14 18:08:36  Dr.A
-- Removed unused sram_data port.
--
-- Revision 1.1  2003/09/01 16:35:26  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- Log history:
--
-- Source: Good
-- Log: aes_sm.vhd,v
-- Revision 1.2  2003/09/01 16:14:48  Dr.A
-- Added ciph_done_early.
--
-- Revision 1.1  2003/08/28 15:19:57  Dr.A
-- Initial revision
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
entity aes_sm is
  generic (
    ccm_mode_g      : integer := 0   -- 1 to use the AES cipher in CCM mode.
  );
  port (
    -- Clocks and resets
    clk             : in  std_logic; -- AHB clock.
    reset_n         : in  std_logic; -- AHB reset. Inverted logic.
    -- Control lines
    opmode          : in  std_logic; -- Indicates Rx (0) or Tx (1) mode.
    aes_ksize       : in  std_logic_vector( 5 downto 0);-- Key size in bytes.
    start_expand    : in  std_logic; -- Pulse to start Key Schedule.
    start_cipher    : in  std_logic; -- Pulse to encrypt/decrypt one state.
    expand_done     : in  std_logic; -- Indicates key Schedule done.
    --
    cipher_done     : out std_logic; -- Indicates encryption/decryption done.
    ciph_done_early : out std_logic; -- Flag set 2 cycles before cipher_done.
    number_rounds   : out std_logic_vector(4 downto 0); -- Number of AES rounds.
    round           : out std_logic_vector(4 downto 0); -- Current round number.
    decoded_state   : out std_logic_vector(3 downto 0); -- AES FSM state.
    next_dec_state  : out std_logic_vector(3 downto 0); -- AES next FSM state.
    -- Interrupt
    stopop          : in  std_logic; -- Stops the encryption/decryption.
    -- Encryption state
    state_w0        : in  std_logic_vector(31 downto 0);
    state_w1        : in  std_logic_vector(31 downto 0);
    state_w2        : in  std_logic_vector(31 downto 0);
    state_w3        : in  std_logic_vector(31 downto 0);
    -- Decryption state
    invstate_w0     : in  std_logic_vector(31 downto 0);
    invstate_w1     : in  std_logic_vector(31 downto 0);
    invstate_w2     : in  std_logic_vector(31 downto 0);
    invstate_w3     : in  std_logic_vector(31 downto 0);
    -- Result (Encrypted/decrypted state)
    result_w0       : out std_logic_vector(31 downto 0);
    result_w1       : out std_logic_vector(31 downto 0);
    result_w2       : out std_logic_vector(31 downto 0);
    result_w3       : out std_logic_vector(31 downto 0);
    -- SRAM controls from KeySchedule block
    wr_memo_address : in  std_logic_vector( 3 downto 0); -- Address to save key.
    wr_memo_wen     : in  std_logic; -- Write enable.
    -- AES SRAM interface
    sram_address    : out std_logic_vector(  3 downto 0); -- Address.
    sram_wen        : out std_logic; -- Write Enable. Inverted logic.
    sram_cen        : out std_logic  -- Chip Enable. Inverted logic.
    );
end aes_sm;
