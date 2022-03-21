
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: rx_mac_if.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : RX MAC interface. Provides the rx data and the data indication
--               signal to the MAC.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/rx_mac_if/vhdl/rtl/rx_mac_if.vhd,v  
--  Log: rx_mac_if.vhd,v  
-- Revision 1.5  2005/03/09 12:03:50  Dr.C
-- #BugId:1123#
-- Added packet_end_i input to avoid data taken into account 2 times by the bup at the end of the reception.
--
-- Revision 1.4  2003/11/18 18:00:47  Dr.F
-- resynchronized rx_data and rx_data_ind due to timing problems.
--
-- Revision 1.3  2003/06/27 15:54:35  Dr.F
-- fixed sensitivity list.
--
-- Revision 1.2  2003/06/27 15:49:23  Dr.F
-- rx_data_ind is now generated as a transitional signal instead of a pulse.
--
-- Revision 1.1  2003/03/14 14:17:16  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity rx_mac_if is
  port(
    -- asynchronous reset
    reset_n               : in  std_logic; 
    -- synchronous reset
    sync_reset_n          : in  std_logic; 
    -- clock
    clk                   : in  std_logic; 

    -- data coming from the rx path
    data_i                : in  std_logic;
    -- data valid indication. When 1, data_i is valid.
    data_valid_i          : in  std_logic;
    -- start of burst (packet) when 1.
    start_of_burst_i      : in  std_logic;
    
    data_ready_o          : out std_logic;
    -- end of packet
    packet_end_i          : in  std_logic;
    -- BuP interface
    rx_data_o             : out std_logic_vector(7 downto 0);
    rx_data_ind_o         : out std_logic
  );
end rx_mac_if;
