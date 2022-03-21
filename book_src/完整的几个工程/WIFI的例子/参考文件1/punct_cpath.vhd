
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: punct_cpath.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : 
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/puncturer/vhdl/rtl/punct_cpath.vhd,v  
--  Log: punct_cpath.vhd,v  
-- Revision 1.2  2004/12/14 10:59:30  Dr.C
-- #BugId:595#
-- Change enable_i to be used like a synchronous reset controlled by Tx state machine for BT coexistence.
--
-- Revision 1.1  2003/03/13 15:06:50  Dr.A
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
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity punct_cpath is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk            : in  std_logic;
    reset_n        : in  std_logic;
    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i       : in  std_logic; -- TX global enable.
    data_valid_i   : in  std_logic; -- From previous module.
    data_ready_i   : in  std_logic; -- From following module.
    marker_i       : in  std_logic; -- Marks start of burst & signal field
    coding_rate_i  : in  std_logic_vector(1 downto 0); -- 1/2, 2/3 or 3/4.
    -- 
    data_valid_o   : out std_logic; -- To following module.
    data_ready_o   : out std_logic; -- To previous module.
    marker_o       : out std_logic; -- Marks start of burst.
    dpath_enable_o : out std_logic; -- Enable data registers.
    mux_sel_o      : out std_logic_vector(1 downto 0) -- Command for data muxes.
    
  );

end punct_cpath;
