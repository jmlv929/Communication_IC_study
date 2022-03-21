
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: pilot_scr.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block scrambles '1' for pilot carriers.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/pilot_scr/vhdl/rtl/pilot_scr.vhd,v  
--  Log: pilot_scr.vhd,v  
-- Revision 1.2  2004/12/14 10:56:29  Dr.C
-- #BugId:595#
-- Change enable_i to be used like a synchronous reset controlled by Tx state machine for BT coexistence.
--
-- Revision 1.1  2003/03/13 15:02:26  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity pilot_scr is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n           : in std_logic; -- asynchronous reset.
    clk               : in std_logic; -- Module clock.
    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i          : in  std_logic; -- TX path enable.
    pilot_ready_i     : in  std_logic;
    init_pilot_scr_i  : in  std_logic;
    --------------------------------------
    -- Data
    --------------------------------------
    pilot_scr_o       : out std_logic  -- Data for the 4 pilot carriers.
    
  );

end pilot_scr;
