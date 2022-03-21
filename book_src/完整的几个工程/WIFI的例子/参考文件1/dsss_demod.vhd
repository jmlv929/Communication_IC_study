
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: dsss_demod.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Direct Sequence Spread Spectrum Demodulation.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/dsss_demod/vhdl/rtl/dsss_demod.vhd,v  
--  Log: dsss_demod.vhd,v  
-- Revision 1.3  2004/02/20 17:10:54  Dr.A
-- Added global signals.
--
-- Revision 1.2  2002/07/16 15:32:49  Dr.A
-- Cleaned code.
--
-- Revision 1.1  2002/03/11 12:55:15  Dr.A
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

--library dsss_demod_rtl;
library work;
--use dsss_demod_rtl.dsss_demod_pkg.all;
use work.dsss_demod_pkg.all;
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off
--use dsss_demod_rtl.dsss_demod_tb_global_pkg.all;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity dsss_demod is
  generic (
    dsize_g : integer := 6
  );
  port (
    -- clock and reset.
    reset_n      : in  std_logic; -- Global reset.
    clk          : in  std_logic; -- Clock for Modem 802.11b (44 Mhz).
    --
    symbol_sync  : in  std_logic; -- Symbol synchronization at 1 Mhz.
    x_i          : in  std_logic_vector(dsize_g-1 downto 0); -- dsss input.
    x_q          : in  std_logic_vector(dsize_g-1 downto 0); -- dsss input.
    -- 
    demod_i      : out std_logic_vector(dsize_g+3 downto 0); -- dsss output.
    demod_q      : out std_logic_vector(dsize_g+3 downto 0)  -- dsss output.
    
  );

end dsss_demod;
