
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: rx_equ_instage0_hpowman.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.2  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Hpowman of equalizer input stage 0.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/rx_equ/vhdl/rtl/rx_equ_instage0_hpowman.vhd,v  
--  Log: rx_equ_instage0_hpowman.vhd,v  
-- Revision 1.2  2003/03/28 15:53:25  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.1  2003/03/17 10:01:28  Dr.F
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

--library rx_equ_rtl;
library work;
--use rx_equ_rtl.rx_equ_pkg.all;
use work.rx_equ_pkg.all;


--------------------------------------------
-- Entity
--------------------------------------------
entity rx_equ_instage0_hpowman is
  port (
    clk             : in  std_logic; -- Clock input
    reset_n         : in  std_logic; -- Asynchronous negative reset
    module_enable_i : in  std_logic; -- '1': Internal enable
    pipeline_en_i   : in  std_logic;
    cumhist_en_i    : in  std_logic;

    h_re_i          : in  std_logic_vector(CHMEM_WIDTH_CT-1 downto 0);
    h_im_i          : in  std_logic_vector(CHMEM_WIDTH_CT-1 downto 0);

    hpowman_o       : out std_logic_vector(HPOWMAN_PROD_WIDTH_CT-1 downto 0)
  );

end rx_equ_instage0_hpowman;
