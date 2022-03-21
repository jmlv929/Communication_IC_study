
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: aes_encrypt.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.1  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block contains the encryption processing for the AES
--               Cryptographic Processor. It receives the Key and the State as
--               inputs and performs all the encrytion protocol on one state,
--               under control of the AES cipher state machine.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/aes_blockcipher/vhdl/rtl/aes_encrypt.vhd,v  
--  Log: aes_encrypt.vhd,v  
-- Revision 1.1  2003/09/01 16:35:06  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- Log history:
--
-- Source: Good
-- Log: aes_encrypt.vhd,v
-- Revision 1.1  2003/08/28 15:19:49  Dr.A
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
entity aes_encrypt is
  port (
    -- Clocks and resets
    clk            : in  std_logic; -- AHB clock.
    reset_n        : in  std_logic; -- AHB reset. Inverted logic.
    -- Interface to share SubByte block with the KeySchedule block
    keyword        : in  std_logic_vector(31 downto 0); -- Word to SubByte block
    key_subbyte_rs : out std_logic_vector(31 downto 0); -- SubByte result word.
    -- Data to encrypt
    init_state_w0  : in  std_logic_vector(31 downto 0);
    init_state_w1  : in  std_logic_vector(31 downto 0);
    init_state_w2  : in  std_logic_vector(31 downto 0);
    init_state_w3  : in  std_logic_vector(31 downto 0);
    -- Result state
    state_w0       : out std_logic_vector(31 downto 0);
    state_w1       : out std_logic_vector(31 downto 0);
    state_w2       : out std_logic_vector(31 downto 0);
    state_w3       : out std_logic_vector(31 downto 0);
    -- Controls
    enable         : in  std_logic; -- Enable the encryption block.
    number_rounds  : in  std_logic_vector(4 downto 0); -- Nb of rounds in AES.
    round          : in  std_logic_vector(4 downto 0); -- Current round number.
    decoded_state  : in  std_logic_vector(3 downto 0); -- Current AES state.
    next_dec_state : in  std_logic_vector(3 downto 0); -- Next AES state.
    -- AES SRAM
    sram_rdata     : in  std_logic_vector(127 downto 0) -- Data read.
  );
end aes_encrypt;
