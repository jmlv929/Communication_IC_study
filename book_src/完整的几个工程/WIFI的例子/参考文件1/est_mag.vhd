
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: est_mag.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Magnitude estimation.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/pilot_tracking/vhdl/rtl/est_mag.vhd,v  
--  Log: est_mag.vhd,v  
-- Revision 1.3  2003/10/30 08:30:26  ahemani
-- Changed clipping of the output weights.
-- Modification done by CHristoph Klausman
--
-- Revision 1.2  2003/04/01 16:31:08  Dr.F
-- optimizations.
--
-- Revision 1.1  2003/03/27 07:48:46  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned."+";
use ieee.std_logic_unsigned."-";

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity est_mag is

  port (clk             : in  std_logic;
        reset_n         : in  std_logic;
        sync_reset_n    : in  std_logic;
        data_valid_i    : in  std_logic;
        ch_m21_coef_i_i : in  std_logic_vector(11 downto 0);
        ch_m21_coef_q_i : in  std_logic_vector(11 downto 0);
        ch_m7_coef_i_i  : in  std_logic_vector(11 downto 0);
        ch_m7_coef_q_i  : in  std_logic_vector(11 downto 0);
        ch_p7_coef_i_i  : in  std_logic_vector(11 downto 0);
        ch_p7_coef_q_i  : in  std_logic_vector(11 downto 0);
        ch_p21_coef_i_i : in  std_logic_vector(11 downto 0);
        ch_p21_coef_q_i : in  std_logic_vector(11 downto 0);
        data_valid_o    : out std_logic;
        weight_ch_m21_o : out std_logic_vector(5 downto 0);
        weight_ch_m7_o  : out std_logic_vector(5 downto 0);
        weight_ch_p7_o  : out std_logic_vector(5 downto 0);
        weight_ch_p21_o : out std_logic_vector(5 downto 0)
        );

end est_mag;
