
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: data_control.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.1  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Data control of the Channel decoder
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/channel_decoder/vhdl/rtl/data_control.vhd,v  
--  Log: data_control.vhd,v  
-- Revision 1.1  2003/03/24 10:17:59  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity data_control is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n            : in  std_logic;  -- Async Reset
    clk                : in  std_logic;  -- Clock
    sync_reset_n       : in  std_logic;  -- Software reset

    --------------------------------------
    -- Symbol Strobe
    --------------------------------------
    enable_i           : in  std_logic;  -- Enable signal
    enable_o           : out std_logic;  -- Enable signal

    data_valid_i       : in  std_logic;  -- Data_valid input
    data_valid_o       : out std_logic;  -- Data_valid output

    start_data_field_i : in  std_logic;
    start_data_field_o : out std_logic;

    end_data_field_i   : in  std_logic;
    end_data_field_o   : out std_logic
  );

end data_control;
