
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: signal_control.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.1  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Signal control of the Channel decoder
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/channel_decoder/vhdl/rtl/signal_control.vhd,v  
--  Log: signal_control.vhd,v  
-- Revision 1.1  2003/03/24 10:18:04  Dr.C
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
entity signal_control is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n              : in  std_logic;  -- Async Reset
    clk                  : in  std_logic;  -- Clock
    sync_reset_n         : in  std_logic;  -- Software reset

    -----------------------------------------------------------------------
    -- Symbol Strobe
    -----------------------------------------------------------------------
    enable_i             : in  std_logic;  -- Enable signal
    enable_o             : out std_logic;  -- Enable signal

    data_valid_i         : in  std_logic;  -- Data_valid input
    data_valid_o         : out std_logic;  -- Data_valid output

    -----------------------------------------------------------------------
    -- Data Interface
    -----------------------------------------------------------------------
    start_signal_field_i : in std_logic;
    end_field_i          : in std_logic    
  );

end signal_control;
