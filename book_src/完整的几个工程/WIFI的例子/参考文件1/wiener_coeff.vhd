
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: wiener_coeff.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Wiener filter coefficients.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/wiener_filter/vhdl/rtl/wiener_coeff.vhd,v  
--  Log: wiener_coeff.vhd,v  
-- Revision 1.2  2003/12/10 17:29:22  arisse
-- Changed coeffs.
--
-- Revision 1.1  2003/03/14 07:42:46  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--library wiener_filter_rtl;
library work;
--use wiener_filter_rtl.wiener_filter_pkg.all;
use work.wiener_filter_pkg.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity wiener_coeff is

  port (
    clk               : in  std_logic;
    reset_n           : in  std_logic;
    chanwien_cs_ni    : in  std_logic;
    module_enable_i   : in  std_logic;
    chanwien_a_i      : in  std_logic_vector(WIENER_ADDR_WIDTH_CT-1 downto 0);
    chanwien_do_o     : out std_logic_vector((4*WIENER_COEFF_WIDTH_CT)-1 downto 0)
  );

end wiener_coeff;
