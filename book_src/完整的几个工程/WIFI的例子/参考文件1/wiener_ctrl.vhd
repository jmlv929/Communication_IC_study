
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: wiener_ctrl.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Wiener filter controller.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/wiener_filter/vhdl/rtl/wiener_ctrl.vhd,v  
--  Log: wiener_ctrl.vhd,v  
-- Revision 1.4  2003/12/10 17:25:21  arisse
-- Changed cyclical incerementation of chanwien_a.
--
-- Revision 1.3  2003/03/28 15:48:31  Dr.F
-- changed modem802_11a2 package name.
--
-- Revision 1.2  2003/03/27 16:48:27  arisse
-- Modified data_valid_d into process gen_ctrl_p for
-- calc_count = 0 and count_data = 18, 32, 45 and 59.
-- These data correspond to the pilots.
--
-- Revision 1.1  2003/03/14 07:42:47  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

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
entity wiener_ctrl is

  port (
    clk               : in  std_logic;
    reset_n           : in  std_logic;
    sync_reset_n      : in  std_logic;
    wf_window_i       : in  std_logic_vector(1 downto 0);
    i_i               : in  std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    q_i               : in  std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    data_valid_i      : in  std_logic;
    start_of_burst_i  : in  std_logic;
    start_of_symbol_i : in  std_logic;
    data_ready_i      : in  std_logic;
    data_ready_o      : out std_logic;
    i_o               : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    q_o               : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    data_valid_o      : out std_logic;
    start_of_symbol_o : out std_logic;
    start_of_burst_o  : out std_logic;
    -- ROM access
    chanwien_do_i     : in  std_logic_vector((4*WIENER_COEFF_WIDTH_CT)-1 downto 0);
    chanwien_a_o      : out std_logic_vector(WIENER_ADDR_WIDTH_CT-1 downto 0);
    chanwien_cs_no    : out std_logic;
    module_enable_o   : out std_logic;
    -- to multadd module
    i_add1_i          : in  std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-1 downto 0);
    q_add1_i          : in  std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-1 downto 0);
    i_add2_i          : in  std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-1 downto 0);
    q_add2_i          : in  std_logic_vector(WIENER_FIRSTADD_WIDTH_CT-1 downto 0);
    i_data1_o         : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    q_data1_o         : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    i_data2_o         : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    q_data2_o         : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    i_data3_o         : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    q_data3_o         : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    i_data4_o         : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    q_data4_o         : out std_logic_vector(FFT_WIDTH_CT-1 downto 0);
    chanwien_c0_o     : out std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
    chanwien_c1_o     : out std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
    chanwien_c2_o     : out std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
    chanwien_c3_o     : out std_logic_vector(WIENER_COEFF_WIDTH_CT-1 downto 0);
    en_add_reg_o      : out std_logic
  );

end wiener_ctrl;
