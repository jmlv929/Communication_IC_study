
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: modemg2bup_if.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.7   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Interface between the 802.11g modem and the BuP. It contains
--               synchronization blocks between the BuP and the Modems, along
--               with logic redirecting the BuP signals towards the selected
--               modem (A or B), and selecting which modem (A or B) outputs
--               are sent to the BuP.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11g/modemg2bup_if/vhdl/rtl/modemg2bup_if.vhd,v  
--  Log: modemg2bup_if.vhd,v  
-- Revision 1.7  2005/01/11 15:56:49  Dr.A
-- #BugId:952#
-- A modem selected when select_rx_ab = 0
--
-- Revision 1.6  2005/01/11 10:33:41  Dr.A
-- #BugId:952#
-- New A/B select in RX mode
--
-- Revision 1.5  2005/01/05 10:10:32  Dr.A
-- #BugId:798#
-- BuP signals towards A and B modems are gated with txv_datarate(3) before resynchronization.
--
-- Revision 1.4  2004/12/14 09:30:17  Dr.A
-- #BugId:822,606#
-- Added rxv_macaddr_match and txv_immstop to the BuP/Modem resync interface.
--
-- Revision 1.3  2004/08/03 09:01:19  sbizet
-- phy_cca_ind FF and process name changed
--
-- Revision 1.2  2004/07/12 13:20:14  sbizet
-- Delayed a_phy_cca_ind to avoid bup2_timers SM stucking when BuP gating not activated (CLKCNTL(5)=0)
--
-- Revision 1.1  2004/05/18 13:06:57  Dr.A
-- initial release
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library modem2bup_sync_rtl;
library work;
--library bup2modem_sync_rtl;
library work;

--library modemg2bup_if_rtl;
library work;
--use modemg2bup_if_rtl.modemg2bup_if_pkg.all;
use work.modemg2bup_if_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity modemg2bup_if is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n                  : in  std_logic; -- Global reset.
    bup_clk                  : in  std_logic; -- BuP clock.
    modemb_clk               : in  std_logic; -- Modem B clock.
    modema_clk               : in  std_logic; -- Modem A clock.

    --------------------------------------
    -- Modem selection
    --------------------------------------
    -- BuP -> Modem selection: high when Modem A is transmitting.
    bup_txv_datarate3        : in  std_logic; -- From BuP clock domain
    -- Modem -> BuP selection: low when Modem A is receiving.
    select_rx_ab              : in  std_logic; -- From AGC clock domain.
    
    --====================================
    -- Modems to BuP interface
    --====================================
    --------------------------------------
    -- Signals from Modem A
    --------------------------------------
    a_phy_txstartend_conf    : in  std_logic;
    a_phy_rxstartend_ind     : in  std_logic;
    a_phy_data_conf          : in  std_logic;
    a_phy_data_ind           : in  std_logic;
    a_phy_cca_ind            : in  std_logic;
    a_rxv_service_ind        : in  std_logic;
    a_phy_ccarst_conf        : in  std_logic;
    -- Busses
    a_rxv_datarate           : in  std_logic_vector( 3 downto 0);
    a_rxv_length             : in  std_logic_vector(11 downto 0);
    a_rxv_rssi               : in  std_logic_vector( 7 downto 0);
    a_rxv_service            : in  std_logic_vector(15 downto 0);
    a_rxe_errorstat          : in  std_logic_vector( 1 downto 0);
    a_rxdata                 : in  std_logic_vector( 7 downto 0);

    --------------------------------------
    -- Signals from Modem B
    --------------------------------------
    b_phy_txstartend_conf    : in  std_logic;
    b_phy_rxstartend_ind     : in  std_logic;
    b_phy_data_conf          : in  std_logic;
    b_phy_data_ind           : in  std_logic;
    b_phy_cca_ind            : in  std_logic;
    -- Busses
    b_rxv_datarate           : in  std_logic_vector( 3 downto 0);
    b_rxv_length             : in  std_logic_vector(11 downto 0);
    b_rxv_rssi               : in  std_logic_vector( 7 downto 0);
    b_rxv_service            : in  std_logic_vector( 7 downto 0);
    b_rxe_errorstat          : in  std_logic_vector( 1 downto 0);
    b_rxdata                 : in  std_logic_vector( 7 downto 0);

    --------------------------------------
    -- Signals to BuP
    --------------------------------------
    bup_phy_txstartend_conf  : out std_logic;
    bup_phy_rxstartend_ind   : out std_logic;
    bup_phy_data_conf        : out std_logic;
    bup_phy_data_ind         : out std_logic;
    bup_phy_cca_ind          : out std_logic;
    bup_rxv_service_ind      : out std_logic;
    bup_a_phy_ccarst_conf    : out std_logic;
    -- Busses
    bup_rxv_datarate         : out std_logic_vector( 3 downto 0);
    bup_rxv_length           : out std_logic_vector(11 downto 0);
    bup_rxv_rssi             : out std_logic_vector( 7 downto 0);
    bup_rxv_service          : out std_logic_vector(15 downto 0);
    bup_rxe_errorstat        : out std_logic_vector( 1 downto 0);
    bup_rxdata               : out std_logic_vector( 7 downto 0);
    
    --====================================
    -- BuP to Modems interface
    --====================================
    --------------------------------------
    -- Signals from BuP
    --------------------------------------
    bup_phy_txstartend_req   : in  std_logic;
    bup_phy_data_req         : in  std_logic;
    bup_phy_ccarst_req       : in  std_logic;
    bup_rxv_macaddr_match    : in  std_logic; 
    bup_txv_immstop          : in  std_logic; 

    --------------------------------------
    -- Signals to Modem A
    --------------------------------------
    a_phy_txstartend_req     : out std_logic;
    a_phy_data_req           : out std_logic;
    a_phy_ccarst_req         : out std_logic;
    a_rxv_macaddr_match      : out std_logic; 
    a_txv_immstop            : out std_logic; 

    --------------------------------------
    -- Signals to Modem B
    --------------------------------------
    b_phy_txstartend_req     : out std_logic;
    b_phy_data_req           : out std_logic;
    b_phy_ccarst_req         : out std_logic;
    b_rxv_macaddr_match      : out std_logic; 
    b_txv_immstop            : out std_logic 
    
  );

end modemg2bup_if;
