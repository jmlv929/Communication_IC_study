
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: channel_decoder_data.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.1  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Data of the Channel decoder
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/channel_decoder/vhdl/rtl/channel_decoder_data.vhd,v  
--  Log: channel_decoder_data.vhd,v  
-- Revision 1.1  2003/03/24 10:17:46  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all; 
 
--library channel_decoder_rtl;
library work;
--use channel_decoder_rtl.channel_decoder_pkg.all;
use work.channel_decoder_pkg.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity channel_decoder_data is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n            : in  std_logic;
    clk                : in  std_logic;
    sync_reset_n       : in  std_logic;
    
    -----------------------------------------------------------------------
    -- Symbol Strobe
    -----------------------------------------------------------------------
    enable_i           : in  std_logic;  -- Enable signal

    data_valid_i       : in  std_logic;  -- Data_valid input
    data_valid_o       : out std_logic;  -- Data_valid output

    start_data_field_i : in  std_logic;
    start_data_field_o : out std_logic;

    end_data_field_i   : in  std_logic;
    end_data_field_o   : out std_logic;

    -----------------------------------------------------------------------
    -- Data Interface
    -----------------------------------------------------------------------
    data_i             : in  std_logic;
    data_o             : out std_logic
  );

end channel_decoder_data;
