
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: barker_cor.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.6   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Barker Correlator. Correlates the input data with a Barker
--               sequence to find DSSS synchronization. The output data is
--               sent to a peak detector.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/barker_cor/vhdl/rtl/barker_cor.vhd,v  
--  Log: barker_cor.vhd,v  
-- Revision 1.6  2003/09/18 08:35:35  Dr.A
-- Added registers for outputs.
--
-- Revision 1.5  2002/11/28 09:33:34  Dr.A
-- Added data saturation.
--
-- Revision 1.4  2002/11/19 12:48:26  Dr.A
-- Debugged accu reset.
--
-- Revision 1.3  2002/07/31 06:51:21  Dr.A
-- Added correclator reset.
--
-- Revision 1.2  2002/07/11 12:14:23  Dr.A
-- Cleaned code and changed adders size.
-- Removed packet_sync.
--
-- Revision 1.1  2002/03/05 14:47:44  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use ieee.std_logic_signed.all; 
use ieee.std_logic_arith.all;

--library barker_cor_rtl;
library work;
--use barker_cor_rtl.barker_cor_pkg.all;
use work.barker_cor_pkg.all;
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity barker_cor is
  generic (
    dsize_g : integer := 6
  );
  port (
    -- clock and reset.
    reset_n      : in  std_logic; -- Global reset.
    clk          : in  std_logic; -- Clock for Modem 802.11b (44 Mhz).
    correl_rst_n : in  std_logic; -- Correlator reset.
    barker_sync  : in  std_logic; -- Correlator output synchronization.
    -- Input data.
    sampl_i      : in  std_logic_vector(dsize_g-1 downto 0); -- I sample input.
    sampl_q      : in  std_logic_vector(dsize_g-1 downto 0); -- Q sample input.
    -- Saturated correlated outputs.
    peak_data_i  : out std_logic_vector(7 downto 0);  
    peak_data_q  : out std_logic_vector(7 downto 0) 
  );

end barker_cor;
