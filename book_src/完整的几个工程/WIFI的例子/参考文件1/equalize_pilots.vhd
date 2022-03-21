
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: equalize_pilots.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.6   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Equalize pilots.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/pilot_tracking/vhdl/rtl/equalize_pilots.vhd,v  
--  Log: equalize_pilots.vhd,v  
-- Revision 1.6  2005/03/11 10:06:39  Dr.C
-- #BugId:1130#
-- Added second_start_of_symbol_v to delay pilot scrambling sequence of one symbol.
--
-- Revision 1.5  2004/05/18 14:57:39  Dr.C
-- Added a saturation after the multiplier in process round_p.
--
-- Revision 1.4  2003/10/30 08:29:34  ahemani
-- Shifted rounding of the shared multiplier
-- Modification done by Christoph Klausman
--
-- Revision 1.3  2003/04/24 06:16:36  Dr.F
-- does not generate scrambling for the first start_of_symbol.
-- internaly generate a pulse of start_of_symbol.
--
-- Revision 1.2  2003/04/01 16:31:02  Dr.F
-- optimizations.
--
-- Revision 1.1  2003/03/27 07:48:44  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library pilot_tracking_rtl;
library work;
--use pilot_tracking_rtl.pilot_tracking_pkg.all;
use work.pilot_tracking_pkg.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity equalize_pilots is

  port (clk               : in  std_logic;
        reset_n           : in  std_logic;
        sync_reset_n      : in  std_logic;
        start_of_symbol_i : in  std_logic;
        start_of_burst_i  : in  std_logic;
        -- pilots from fft
        pilot_p21_i_i     : in  std_logic_vector(11 downto 0);
        pilot_p21_q_i     : in  std_logic_vector(11 downto 0);
        pilot_p7_i_i      : in  std_logic_vector(11 downto 0);
        pilot_p7_q_i      : in  std_logic_vector(11 downto 0);
        pilot_m21_i_i     : in  std_logic_vector(11 downto 0);
        pilot_m21_q_i     : in  std_logic_vector(11 downto 0);
        pilot_m7_i_i      : in  std_logic_vector(11 downto 0);
        pilot_m7_q_i      : in  std_logic_vector(11 downto 0);
        -- channel coefficients
        ch_m21_coef_i_i   : in  std_logic_vector(11 downto 0);
        ch_m21_coef_q_i   : in  std_logic_vector(11 downto 0);
        ch_m7_coef_i_i    : in  std_logic_vector(11 downto 0);
        ch_m7_coef_q_i    : in  std_logic_vector(11 downto 0);
        ch_p7_coef_i_i    : in  std_logic_vector(11 downto 0);
        ch_p7_coef_q_i    : in  std_logic_vector(11 downto 0);
        ch_p21_coef_i_i   : in  std_logic_vector(11 downto 0);
        ch_p21_coef_q_i   : in  std_logic_vector(11 downto 0);
        -- equalized pilots
        pilot_p21_i_o     : out std_logic_vector(11 downto 0);
        pilot_p21_q_o     : out std_logic_vector(11 downto 0);
        pilot_p7_i_o      : out std_logic_vector(11 downto 0);
        pilot_p7_q_o      : out std_logic_vector(11 downto 0);
        pilot_m21_i_o     : out std_logic_vector(11 downto 0);
        pilot_m21_q_o     : out std_logic_vector(11 downto 0);
        pilot_m7_i_o      : out std_logic_vector(11 downto 0);
        pilot_m7_q_o      : out std_logic_vector(11 downto 0);
        
        eq_done_o : out std_logic
        );


end equalize_pilots;
