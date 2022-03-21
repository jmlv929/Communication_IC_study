
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: wiener_multadd2.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Multiplier and adder.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/wiener_filter/vhdl/rtl/wiener_multadd2.vhd,v  
--  Log: wiener_multadd2.vhd,v  
-- Revision 1.2  2003/03/28 15:48:46  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.1  2003/03/14 07:42:53  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library wiener_filter_rtl;
library work;
--use wiener_filter_rtl.wiener_filter_pkg.all;
use work.wiener_filter_pkg.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity wiener_multadd2 is
  port (
    clk               : in  std_logic;
    reset_n           : in  std_logic;
    module_enable_i   : in  std_logic;
    data1_i           : in  std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    data2_i           : in  std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    chanwien_c0_i     : in  std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
    chanwien_c1_i     : in  std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
    en_add_reg_i      : in  std_logic;
    add_o             : out std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-1 downto 0)  
  );

end wiener_multadd2;
