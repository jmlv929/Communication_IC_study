
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: mac_interface.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Interface between the 802.11a MAC and the Modema2 blocks.
--               This module interfaces directly with the tx_data_req and
--               tx_data_conf signals from the mac/phy interface and 
--               generate the data_valid signals for the padding module.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/mac_interface/vhdl/rtl/mac_interface.vhd,v  
--  Log: mac_interface.vhd,v  
-- Revision 1.4  2004/12/14 10:49:49  Dr.C
-- #BugId:595#
-- Change enable_i to be used like a synchronous reset controlled by Tx state machine for BT coexistence.
--
-- Revision 1.3  2004/06/24 09:17:10  Dr.A
-- Corrected when others clause.
--
-- Revision 1.2  2004/04/09 12:08:18  Dr.A
-- Modified state machine to gain one clock cycle when waiting for ready signal.
--
-- Revision 1.1  2003/03/13 14:54:08  Dr.A
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
entity mac_interface is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n             : in  std_logic;
    clk                 : in  std_logic;

    --------------------------------------
    -- Controls
    --------------------------------------
    enable_i            : in  std_logic;
    tx_start_end_req_i  : in  std_logic;
    tx_start_end_conf_i : in  std_logic;
    data_ready_i        : in  std_logic;
    data_valid_o        : out std_logic;
    tx_data_req_i       : in  std_logic;
    tx_data_conf_o      : out std_logic;
    --------------------------------------
    -- Data
    --------------------------------------
    tx_data_i           : in  std_logic_vector(7 downto 0);
    data_o              : out std_logic_vector(7 downto 0)

    
  );

end mac_interface;
