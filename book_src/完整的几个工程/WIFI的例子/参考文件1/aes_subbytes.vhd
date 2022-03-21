
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processing
--    ,' GoodLuck ,'      RCSfile: aes_subbytes.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.1  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block performs the SubBytes transformation in the
--               AES encryption algorithm.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/aes_blockcipher/vhdl/rtl/aes_subbytes.vhd,v  
--  Log: aes_subbytes.vhd,v  
-- Revision 1.1  2003/09/01 16:35:28  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- Log history:
--
-- Source: Good
-- Log: aes_subbytes.vhd,v
-- Revision 1.1  2003/07/03 14:01:33  Dr.A
-- Initial revision
--
--------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity aes_subbytes is
  port (
    word_in      : in  std_logic_vector (31 downto 0); -- Input word.
    word_out     : out std_logic_vector (31 downto 0)  -- Transformed word.
  );
end aes_subbytes;
