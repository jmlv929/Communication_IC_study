
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: modem2bup_sync.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.1   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Synchronization block between the 802.11 A or B modem and the
--               BuP clock domains.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/modem2bup_sync/vhdl/rtl/modem2bup_sync.vhd,v  
--  Log: modem2bup_sync.vhd,v  
-- Revision 1.1  2004/05/18 13:27:18  Dr.A
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
entity modem2bup_sync is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n                        : in std_logic; -- Global reset.
    bup_clk                        : in std_logic; -- BuP clock.

    --------------------------------------
    -- Signals from Modem clock domain
    --------------------------------------
    phy_txstartend_conf            : in  std_logic;
    phy_rxstartend_ind             : in  std_logic;
    phy_data_conf                  : in  std_logic;
    phy_data_ind                   : in  std_logic;
    phy_cca_ind                    : in  std_logic;
    rxv_service_ind                : in  std_logic;
    phy_ccarst_conf                : in  std_logic;

    --------------------------------------
    -- Signals synchronized with bup_clk
    --------------------------------------
    phy_txstartend_conf_ff2_resync : out std_logic;
    phy_rxstartend_ind_ff2_resync  : out std_logic;
    phy_data_conf_ff2_resync       : out std_logic;
    phy_data_ind_ff2_resync        : out std_logic;
    phy_cca_ind_ff2_resync         : out std_logic;
    rxv_service_ind_ff2_resync     : out std_logic;
    phy_ccarst_conf_ff2_resync     : out std_logic
    
  );

end modem2bup_sync;
