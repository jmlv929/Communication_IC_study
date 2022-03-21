--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: aes_decrypt.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.1  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block contains the decryption processing for the AES
--               Cryptographic Processor. It receives the Key and the State as
--               inputs and performs all the decrytion protocol on one state,
--               under control of the AES cipher state machine.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/aes_blockcipher/vhdl/rtl/aes_decrypt.vhd,v  
--  Log: aes_decrypt.vhd,v  
-- Revision 1.1  2003/09/01 16:35:04  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- Log history:
--
-- Source: Good
-- Log: aes_decrypt.vhd,v
-- Revision 1.1  2003/08/28 15:19:46  Dr.A
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
entity aes_decrypt is
  port (
    -- Clocks and resets
    clk            : in  std_logic; -- AHB clock.
    reset_n        : in  std_logic; -- AHB reset. Inverted logic.
    -- Data to decrypt
    init_state_w0  : in  std_logic_vector(31 downto 0);
    init_state_w1  : in  std_logic_vector(31 downto 0);
    init_state_w2  : in  std_logic_vector(31 downto 0);
    init_state_w3  : in  std_logic_vector(31 downto 0);
    -- Result state
    invstate_w0    : out std_logic_vector(31 downto 0);
    invstate_w1    : out std_logic_vector(31 downto 0);
    invstate_w2    : out std_logic_vector(31 downto 0);
    invstate_w3    : out std_logic_vector(31 downto 0);
    -- Controls
    enable         : in  std_logic; -- Enable the decryption block.
    number_rounds  : in  std_logic_vector(4 downto 0); -- Nb of rounds in AES.
    round          : in  std_logic_vector(4 downto 0); -- Current round number.
    decoded_state  : in  std_logic_vector(3 downto 0); -- Current AES state.
    next_dec_state : in  std_logic_vector(3 downto 0); -- Next AES state.
    -- AES SRAM
    sram_rdata     : in  std_logic_vector(127 downto 0) -- Data read.
  );
end aes_decrypt;
