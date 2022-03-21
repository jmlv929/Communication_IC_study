
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : Modem A2
--    ,' GoodLuck ,'      RCSfile: carrier_detect.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Carrier Sense Detection
-- Two detections are performed :
--  * A pulse is generated each time the a16m signal (autoccorelation) is higher
--    than the level estimation. 
--  * Accumulation of the nb of time that the a16m > at1. When this nb reachs a
--    treshold DETTHR, set the carrier_s_o.
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/TIME_DOMAIN/INIT_SYNC/init_sync/vhdl/rtl/carrier_detect.vhd,v  
--  Log: carrier_detect.vhd,v  
-- Revision 1.5  2003/12/18 09:54:31  Dr.B
-- fast_carrier_s_o & fast_99carrier_s_o are now memorized between 2 cycles of a16m_data_valid_i.
--
-- Revision 1.4  2003/11/18 10:32:22  Dr.B
-- Added INPUT cs_accu_en, updated INPUT detthr_reg_i to 6 bits (was 4).
--
-- Revision 1.3  2003/11/03 14:40:08  Dr.B
-- Updated reset conditions on OUTPUT signal fast_99carrier_s_o.
--
-- Revision 1.2  2003/11/03 08:30:43  Dr.B
-- Added OUTPUT fast_99carrier_s_o used in 11g AGC procedure.
--
-- Revision 1.1  2003/06/25 17:13:38  Dr.B
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity carrier_detect is
  generic (
    data_size_g : integer := 13 );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                 : in  std_logic;
    reset_n             : in  std_logic;
    --------------------------------------
    -- Signals
    --------------------------------------
    -- Control Signals
    init_i               : in  std_logic;
    autocorr_enable_i    : in  std_logic;
    a16m_data_valid_i    : in  std_logic; -- a16m valid
    cs_accu_en           : in  std_logic;--NEW rev. 1.4
    -- Level estimation signals
    at0_i                : in  std_logic_vector (data_size_g-1 downto 0);
    at1_i                : in  std_logic_vector (data_size_g-1 downto 0);
    -- Autocorrelation signal
    a16m_i               : in  std_logic_vector (data_size_g-1 downto 0);
    -- treshold of accu (from registers)
    detthr_reg_i         : in  std_logic_vector (5 downto 0);--NEW rev. 1.4 - was (3 downto 0)
    --
    -- Fast Carrier Sense
    fast_carrier_s_o     : out std_logic; -- pulse
    fast_99carrier_s_o   : out std_logic; -- pulse    
    -- Carrier Sense
    carrier_s_o          : out std_logic -- remain high until init_i    
  );

end carrier_detect;
