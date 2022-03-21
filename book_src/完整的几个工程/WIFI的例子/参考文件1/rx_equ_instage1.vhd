
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: rx_equ_instage1.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.4  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Equalizer input stage 1.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/rx_equ/vhdl/rtl/rx_equ_instage1.vhd,v  
--  Log: rx_equ_instage1.vhd,v  
-- Revision 1.4  2003/05/19 07:16:08  Dr.F
-- removed start_of_symbol and start_of_burst.
--
-- Revision 1.3  2003/03/28 15:53:29  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.2  2003/03/17 17:06:49  Dr.F
-- removed debug signals.
--
-- Revision 1.1  2003/03/17 10:01:30  Dr.F
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
entity rx_equ_instage1 is
  port (
    clk                 : in  std_logic; -- Clock input
    reset_n             : in  std_logic; -- Asynchronous negative reset
    module_enable_i     : in  std_logic; -- '1': Internal enable for clock gating
    sync_reset_n        : in  std_logic; -- synchronous negative reset

    current_symb_i      : in  std_logic_vector(1 downto 0);
    data_valid_i        : in  std_logic;
    cumhist_valid_i     : in  std_logic;
    clean_hist_i        : in  std_logic;

    hpowman_i           : in  std_logic_vector(HPOWMAN_PROD_WIDTH_CT-1 downto 0);
    cormanr_i           : in  std_logic_vector(CORMAN_PROD_WIDTH_CT-1 downto 0);
    cormani_i           : in  std_logic_vector(CORMAN_PROD_WIDTH_CT-1 downto 0);

    satmaxncarr_54_i    : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_48_i    : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_36_i    : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_24_i    : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_18_i    : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_12_i    : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_09_i    : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
    satmaxncarr_06_i    : in  std_logic_vector(SATMAXNCARR_WIDTH_CT-1 downto 0); 
   
    burst_rate_i        : in  std_logic_vector(BURST_RATE_WIDTH_CT-1 downto 0);
    burst_rate_4_hist_i : in  std_logic_vector(BURST_RATE_WIDTH_CT-1 downto 0);

    hpowman_o           : out std_logic_vector(HPOWMAN_PROD_WIDTH_CT-1 downto 0);
    cormanr_o           : out std_logic_vector(CORMAN_PROD_WIDTH_CT-1 downto 0);
    cormani_o           : out std_logic_vector(CORMAN_PROD_WIDTH_CT-1 downto 0);
    
    hpowexp_o           : out std_logic_vector(HPOWEXP_WIDTH_CT-1 downto 0);
    histexpz_signal_o   : out std_logic_vector(HISTEXPZ_WIDTH_CT-1 downto 0);
    histexpz_data_o     : out std_logic_vector(HISTEXPZ_WIDTH_CT-1 downto 0);


    burst_rate_o        : out std_logic_vector(BURST_RATE_WIDTH_CT-1 downto 0);
    current_symb_o      : out std_logic_vector(1 downto 0);
    data_valid_o        : out std_logic
  );

end rx_equ_instage1;
