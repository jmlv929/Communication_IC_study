
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: channel_decoder_signal.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Signal of the Channel decoder
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/channel_decoder/vhdl/rtl/channel_decoder_signal.vhd,v  
--  Log: channel_decoder_signal.vhd,v  
-- Revision 1.2  2003/03/28 15:37:10  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.1  2003/03/24 10:17:52  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library channel_decoder_rtl;
library work;
--use channel_decoder_rtl.channel_decoder_pkg.all;
use work.channel_decoder_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity channel_decoder_signal is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n        : in  std_logic;  -- Async Reset
    clk            : in  std_logic;  -- Clock
    sync_reset_n   : in  std_logic;  -- Software reset
    
    --------------------------------------
    -- Symbol Strobe
    --------------------------------------
    enable_i       : in  std_logic;  -- Enable signal
    data_valid_i   : in  std_logic;  -- Data_valid input
    start_field_i  : in std_logic;
    end_field_i    : in std_logic;
    --
    data_valid_o   : out std_logic;  -- Data_valid output
 
    --------------------------------------
    -- Data Interface
    --------------------------------------
    data_i         : in  std_logic;
    --
    signal_field_o : out std_logic_vector(SIGNAL_FIELD_LENGTH_CT-1 downto 0)
    
  );

end channel_decoder_signal;
