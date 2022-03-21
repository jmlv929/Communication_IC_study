
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: bup2modem_sync.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Synchronization block between the BuP and the 802.11 A or B
--               modem clock domains.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2modem_sync/vhdl/rtl/bup2modem_sync.vhd,v  
--  Log: bup2modem_sync.vhd,v  
-- Revision 1.2  2004/12/14 09:27:45  Dr.A
-- #BugId:821,606#
-- Added rxv_macaddr_match and txv_immstop to the BuP/Modem resync interface.
--
-- Revision 1.1  2004/05/18 12:57:50  Dr.A
-- initial release
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
entity bup2modem_sync is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n                         : in std_logic; -- Global reset.
    modem_clk                       : in std_logic; -- Modem clock.

    --------------------------------------
    -- Signals from BuP clock domain
    --------------------------------------
    phy_txstartend_req              : in  std_logic;
    phy_data_req                    : in  std_logic;
    phy_ccarst_req                  : in  std_logic; 
    rxv_macaddr_match               : in  std_logic; 
    txv_immstop                     : in  std_logic; 

    --------------------------------------
    -- Signals synchronized with modem_clk
    --------------------------------------
    phy_txstartend_req_ff2_resync   : out std_logic;
    phy_data_req_ff2_resync         : out std_logic;
    phy_ccarst_req_ff2_resync       : out std_logic;
    rxv_macaddr_match_ff2_resync    : out std_logic;
    txv_immstop_ff2_resync          : out std_logic 

  );

end bup2modem_sync;
