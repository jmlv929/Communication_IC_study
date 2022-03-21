

--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: rx_equ_outstage2.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.4  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Equalizer output stage 2.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/rx_equ/vhdl/rtl/rx_equ_outstage2.vhd,v  
--  Log: rx_equ_outstage2.vhd,v  
-- Revision 1.4  2003/10/06 09:27:57  Dr.C
-- Debugged SXT operation for hpowman_ext to EXT operation. This signal is unsigned.
--
-- Revision 1.3  2003/03/28 15:53:37  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.2  2003/03/17 17:07:19  Dr.F
-- removed debug signals.
--
-- Revision 1.1  2003/03/17 10:01:37  Dr.F
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
entity rx_equ_outstage2 is
  port (
    clk                : in  std_logic; --Clock input
    reset_n            : in  std_logic; --Asynchronous negative reset
    module_enable_i    : in  std_logic; --'1': Internal enable for clock gating
    sync_reset_n       : in  std_logic; --'0': The control state of the module will be reset

    data_valid_i       : in  std_logic; 

    hpowman_i          : in  std_logic_vector(MANTLEN_CT-1 downto 0);
    cormanr_i          : in  std_logic_vector(MANTLEN_CT downto 0);
    cormani_i          : in  std_logic_vector(MANTLEN_CT downto 0);
    secondexp_i        : in  std_logic_vector(SHIFT_SOFT_WIDTH_CT-1 downto 0);
   
    soft_x0_i          : in  std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0); 
    soft_y0_i          : in  std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);

    soft_x1_i          : in  std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0); 
    soft_y1_i          : in  std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);

    qam_mode_i         : in  std_logic_vector(QAM_MODE_WIDTH_CT-1 downto 0);
    start_of_symbol_i  : in  std_logic;
    start_of_burst_i   : in  std_logic;

    soft_x0_o          : out std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y0_o          : out std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);

    soft_x1_o          : out std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y1_o          : out std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);

    soft_x2_o          : out std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);
    soft_y2_o          : out std_logic_vector(SOFTBIT_WIDTH_CT-1 downto 0);

    data_valid_o       : out std_logic;
    start_of_symbol_o  : out std_logic;
    start_of_burst_o   : out std_logic;
    reducerasures_i    : in  std_logic_vector(1 downto 0)
  );

end rx_equ_outstage2;
