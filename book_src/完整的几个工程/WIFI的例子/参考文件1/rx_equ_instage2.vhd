
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: rx_equ_instage2.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.5  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Equalizer input stage 1.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/rx_equ/vhdl/rtl/rx_equ_instage2.vhd,v  
--  Log: rx_equ_instage2.vhd,v  
-- Revision 1.5  2004/07/20 16:04:07  Dr.C
-- Changed SSHR to SHR for hpowman_shifted_v.
--
-- Revision 1.4  2003/05/13 11:52:45  Dr.F
-- debugged secondexp_v : replaced SXT by EXT !
--
-- Revision 1.3  2003/03/28 15:53:31  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.2  2003/03/17 17:06:55  Dr.F
-- removed debug signals.
--
-- Revision 1.1  2003/03/17 10:01:31  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

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
entity rx_equ_instage2 is
  port (
    clk                : in  std_logic; -- Clock input
    reset_n            : in  std_logic; -- Asynchronous negative reset
    module_enable_i    : in  std_logic; --'1': Internal enable
    sync_reset_n       : in  std_logic; -- Synchronous negative reset

    current_symb_i     : in  std_logic_vector (1 downto 0);
    data_valid_i       : in  std_logic;

    hpowman_i          : in  std_logic_vector(HPOWMAN_PROD_WIDTH_CT-1 downto 0);
    cormanr_i          : in  std_logic_vector(CORMAN_PROD_WIDTH_CT-1 downto 0);
    cormani_i          : in  std_logic_vector(CORMAN_PROD_WIDTH_CT-1 downto 0);

    hpowexp_i          : in  std_logic_vector(HPOWEXP_WIDTH_CT-1 downto 0);
    histexpz_signal_i  : in  std_logic_vector(HISTEXPZ_WIDTH_CT-1 downto 0);
    histexpz_data_i    : in  std_logic_vector(HISTEXPZ_WIDTH_CT-1 downto 0);

    histoffset_54_i    : in  std_logic_vector(HISTOFFSET_WIDTH_CT-1 downto 0); 
    histoffset_48_i    : in  std_logic_vector(HISTOFFSET_WIDTH_CT-1 downto 0);
    histoffset_36_i    : in  std_logic_vector(HISTOFFSET_WIDTH_CT-1 downto 0); 
    histoffset_24_i    : in  std_logic_vector(HISTOFFSET_WIDTH_CT-1 downto 0); 
    histoffset_18_i    : in  std_logic_vector(HISTOFFSET_WIDTH_CT-1 downto 0); 
    histoffset_12_i    : in  std_logic_vector(HISTOFFSET_WIDTH_CT-1 downto 0); 
    histoffset_09_i    : in  std_logic_vector(HISTOFFSET_WIDTH_CT-1 downto 0); 
    histoffset_06_i    : in  std_logic_vector(HISTOFFSET_WIDTH_CT-1 downto 0); 

    burst_rate_i       : in  std_logic_vector(BURST_RATE_WIDTH_CT-1 downto 0);
    start_of_symbol_i  : in  std_logic;
    start_of_burst_i   : in  std_logic;

    hpowman_o          : out std_logic_vector(MANTLEN_CT-1 downto 0);
    cormanr_o          : out std_logic_vector(MANTLEN_CT  downto 0);
    cormani_o          : out std_logic_vector(MANTLEN_CT  downto 0);
    secondexp_o        : out std_logic_vector(SHIFT_SOFT_WIDTH_CT-1 downto 0);
    

    qam_mode_o         : out std_logic_vector(QAM_MODE_WIDTH_CT-1 downto 0);
    data_valid_o       : out std_logic;
    start_of_symbol_o  : out std_logic;
    start_of_burst_o   : out std_logic
  );

end rx_equ_instage2;
