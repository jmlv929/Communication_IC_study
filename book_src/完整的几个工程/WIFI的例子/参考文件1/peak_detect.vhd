
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: peak_detect.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.19   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : This block detects the maximum of the correlated data square
--               module (abs_2_corr input) over a correlation period (1 Mhz for
--               DSSS modulation). A synchronization pulse is sent when the 
--               maximum is detected. When the synchronization is disabled
--               (synchro_en=0), the pulse is sent at a 1 MHz frequency (DSSS)
--               or at a 1.375 MHz frequency (CCK).
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/peak_detect/vhdl/rtl/peak_detect.vhd,v  
--  Log: peak_detect.vhd,v  
-- Revision 1.19  2005/03/10 13:38:38  arisse
-- #BugId:983#
-- Added globals.
--
-- Revision 1.18  2005/03/07 11:11:34  arisse
-- #BugId:983#
-- Added abs_2_corr_trunc_tglobal.
--
-- Revision 1.17  2005/02/21 09:41:43  arisse
-- #BugId:983#
-- Remove max_value2 and max_value3 which are unused anymore.
--
-- Revision 1.16  2005/02/02 14:31:22  arisse
-- #BugId:983#
-- Re-implement max_value signals because they update max_index signal.
--
-- Revision 1.15  2005/01/24 14:36:04  arisse
-- #BugId:983#
-- Cleaned of unused signals.
--
-- Revision 1.14  2004/02/20 13:31:29  Dr.A
-- Added global signals.
--
-- Revision 1.13  2003/12/04 14:01:40  Dr.A
-- Test two accu_add MSB to detect overflow.
--
-- Revision 1.12  2003/11/28 10:08:11  arisse
-- Added reset to max_index every Symbol period.
--
-- Revision 1.11  2003/09/18 08:36:23  Dr.A
-- Added synchronization output for Barker Correlator.
--
-- Revision 1.10  2002/11/28 09:36:00  Dr.A
-- data truncated inside the block.
--
-- Revision 1.9  2002/11/13 13:14:53  Dr.A
-- Removed variable init values.
--
-- Revision 1.8  2002/11/06 17:12:39  Dr.A
-- Changed signal_quality size.
--
-- Revision 1.7  2002/10/24 17:02:44  Dr.A
-- Added accumulator reset.
--
-- Revision 1.6  2002/10/17 08:20:13  Dr.A
-- Synchronisation on squared module instead of absolute values sum.
-- Signal quality based on three max values.
--
-- Revision 1.5  2002/09/19 12:26:26  Dr.A
-- Reset count_end to DSSS for new packet.
--
-- Revision 1.4  2002/08/28 13:47:03  Dr.A
-- Debugged DSSS/CCK change.
--
-- Revision 1.3  2002/07/31 06:48:30  Dr.A
-- Added signal quality, synchro_en and mod_type ports.
-- Debugged and cleaned code.
--
-- Revision 1.2  2002/07/11 12:12:38  Dr.A
-- Cleaned and debugged code.
-- Removed packet_sync.
--
-- Revision 1.1  2002/03/05 15:09:30  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all; 
 
--library peak_detect_rtl;
library work;
--use peak_detect_rtl.peak_detect_pkg.all;
use work.peak_detect_pkg.all;
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off
--use peak_detect_rtl.peak_detect_tb_global_pkg.all;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity peak_detect is
  generic (
    accu_size_g : integer := 20
  );
  port (
    -- clock and reset.
    reset_n        : in  std_logic; -- Global reset.
    clk            : in  std_logic; -- Clock for Modem 802.11b (44 Mhz).
    --
    accu_resetn    : in  std_logic; -- Reset the accumulator.
    synchro_en     : in  std_logic; -- '1' to enable timing synchronization.
    mod_type       : in  std_logic; -- Modulation type (0 for DSSS , 1 for CCK).
    -- Square module of the correlator output data.
    abs_2_corr     : in  std_logic_vector(15 downto 0);
    --
    barker_sync    : out std_logic; -- Synchronization signal to Correlator.
    symbol_sync    : out std_logic -- Indicates the correlator peak value.
  );

end peak_detect;
