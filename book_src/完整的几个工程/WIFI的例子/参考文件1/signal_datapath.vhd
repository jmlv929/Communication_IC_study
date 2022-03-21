
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: signal_datapath.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Signal datapath of the Channel decoder
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/channel_decoder/vhdl/rtl/signal_datapath.vhd,v  
--  Log: signal_datapath.vhd,v  
-- Revision 1.2  2003/03/28 15:37:14  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.1  2003/03/24 10:18:07  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity signal_datapath is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n        : in  std_logic;  -- Async Reset
    clk            : in  std_logic;  -- 200 MHz Clock
    sync_reset_n   : in  std_logic;  -- Software reset
    --------------------------------------
    -- Symbol Strobe
    --------------------------------------
    enable_i       : in std_logic;  -- Enable signal
                                     -- bit
    --------------------------------------
    -- Data Interface
    --------------------------------------
    data_i         : in  std_logic;
    signal_field_o : out std_logic_vector(SIGNAL_FIELD_LENGTH_CT-1 downto 0)
    
  );

end signal_datapath;
