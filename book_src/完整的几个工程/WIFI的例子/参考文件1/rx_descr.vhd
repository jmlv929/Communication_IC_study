
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: rx_descr.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : RX descrambling.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/rx_descr/vhdl/rtl/rx_descr.vhd,v  
--  Log: rx_descr.vhd,v  
-- Revision 1.4  2004/05/27 07:27:35  Dr.C
-- Add register on rxv_service_o for BuP/Modem interface.
--
-- Revision 1.3  2004/05/18 11:37:23  Dr.A
-- rxv_service_ind is now two clock-cycles
--
-- Revision 1.2  2003/03/28 16:02:55  Dr.F
-- changed some port names.
--
-- Revision 1.1  2003/03/17 15:30:56  Dr.C
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
entity rx_descr is
  port (
    clk                   : in  std_logic;
    reset_n               : in  std_logic;
    sync_reset_n          : in  std_logic;
    data_i                : in  std_logic;
    data_valid_i          : in  std_logic;
    data_ready_i          : in  std_logic;
    start_of_burst_i      : in  std_logic;
    
    data_ready_o          : out std_logic;
    data_o                : out std_logic;
    data_valid_o          : out std_logic;
    rxv_service_o         : out std_logic_vector(15 downto 0);
    rxv_service_ind_o     : out std_logic;
    start_of_burst_o      : out std_logic
  );

end rx_descr;
