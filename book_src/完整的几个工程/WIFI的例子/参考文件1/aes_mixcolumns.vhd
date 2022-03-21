
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Stream Processor
--    ,' GoodLuck ,'      RCSfile: aes_mixcolumns.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.1  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block performs the MixColumns transformation in the
--               AES encryption algorithm.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/aes_blockcipher/vhdl/rtl/aes_mixcolumns.vhd,v  
--  Log: aes_mixcolumns.vhd,v  
-- Revision 1.1  2003/09/01 16:35:21  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- Log history:
--
-- Source: Good
-- Log: aes_mixcolumns.vhd,v
-- Revision 1.1  2003/07/03 14:01:28  Dr.A
-- Initial revision
--
--------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 

entity aes_mixcolumns is
  port (
    -- State in:
    state_in_w0 : in  std_logic_vector (31 downto 0); -- Input State word 0.
    state_in_w1 : in  std_logic_vector (31 downto 0); -- Input State word 1.
    state_in_w2 : in  std_logic_vector (31 downto 0); -- Input State word 2.
    state_in_w3 : in  std_logic_vector (31 downto 0); -- Input State word 3.
    -- State in:
    state_out_w0: out std_logic_vector (31 downto 0); -- Output State word 0.
    state_out_w1: out std_logic_vector (31 downto 0); -- Output State word 1.
    state_out_w2: out std_logic_vector (31 downto 0); -- Output State word 2.
    state_out_w3: out std_logic_vector (31 downto 0)  -- Output State word 3.
  );
end aes_mixcolumns;
