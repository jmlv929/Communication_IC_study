
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: preamble_gen.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Preamble generation. The preamble patterns are read from ROMS.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/preamble_gen/vhdl/rtl/preamble_gen.vhd,v  
--  Log: preamble_gen.vhd,v  
-- Revision 1.3  2004/12/14 10:58:05  Dr.C
-- #BugId:595#
-- Change enable_i to be used like a synchronous reset controlled by Tx state machine for BT coexistence.
--
-- Revision 1.2  2003/04/15 09:59:06  Dr.A
-- Outputs no more registered.
--
-- Revision 1.1  2003/03/13 15:04:55  Dr.A
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
 
--library preamble_gen_rtl;
library work;
--use preamble_gen_rtl.preamble_gen_pkg.all;
use work.preamble_gen_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity preamble_gen is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk             : in  std_logic; -- Module clock
    reset_n         : in  std_logic; -- Asynchronous reset
    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i        : in  std_logic; -- TX path enable.
    data_ready_i    : in  std_logic; -- '1' when next block ready to accept data
    add_short_pre_i : in  std_logic_vector(1 downto 0); -- pre-preamble value.
    --
    end_preamble_o  : out std_logic; -- High at the end of the preamble.
    --------------------------------------
    -- Data
    --------------------------------------
    i_out           : out std_logic_vector(9 downto 0); -- I preamble data.
    q_out           : out std_logic_vector(9 downto 0)  -- Q preamble data.
  );

end preamble_gen;
