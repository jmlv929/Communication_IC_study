
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Stream_Processing
--    ,' GoodLuck ,'      RCSfile: tkip_key_mixing.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Top of the TKIP key mixing block.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/STREAM_PROCESSOR/tkip_key_mixing/vhdl/rtl/tkip_key_mixing.vhd,v  
--  Log: tkip_key_mixing.vhd,v  
-- Revision 1.2  2003/08/13 16:23:26  Dr.A
-- Updated phase1 port map.
--
-- Revision 1.1  2003/07/16 13:23:29  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 

--library tkip_key_mixing_rtl;
library work;
--use tkip_key_mixing_rtl.tkip_key_mixing_pkg.all;
use work.tkip_key_mixing_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity tkip_key_mixing is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n      : in  std_logic;
    clk          : in  std_logic;
    --------------------------------------
    -- Controls
    --------------------------------------
    key1_key2n   : in  std_logic; -- Indicates the key mixing phase.
    start_keymix : in  std_logic; -- Pulse to start the key mixing phase.
    --
    keymix1_done : out std_logic; -- High when key mixing phase 1 is done.
    keymix2_done : out std_logic; -- High when key mixing phase 2 is done.
    --------------------------------------
    -- Data
    --------------------------------------
    tsc          : in  std_logic_vector(47 downto 0); -- Sequence counter.
    address2     : in  std_logic_vector(47 downto 0); -- A2 MAC header field.
    -- Temporal key (128 bits)
    temp_key_w3  : in  std_logic_vector(31 downto 0);
    temp_key_w2  : in  std_logic_vector(31 downto 0);
    temp_key_w1  : in  std_logic_vector(31 downto 0);
    temp_key_w0  : in  std_logic_vector(31 downto 0);
    -- TKIP key (128 bits)
    tkip_key_w3  : out std_logic_vector(31 downto 0);
    tkip_key_w2  : out std_logic_vector(31 downto 0);
    tkip_key_w1  : out std_logic_vector(31 downto 0);
    tkip_key_w0  : out std_logic_vector(31 downto 0)
  );

end tkip_key_mixing;
