
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: comp_angle.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.6   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Compute angle.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/pilot_tracking/vhdl/rtl/comp_angle.vhd,v  
--  Log: comp_angle.vhd,v  
-- Revision 1.6  2004/05/27 07:54:21  Dr.C
-- Debugged unwrap phase calculation.
--
-- Revision 1.5  2003/07/17 13:55:03  Dr.F
-- added saturation on computed and estimated phases.
--
-- Revision 1.4  2003/06/25 16:10:45  Dr.F
-- code cleaning.
--
-- Revision 1.3  2003/04/02 11:42:52  Dr.F
-- changed unwrap process.
--
-- Revision 1.2  2003/04/01 16:30:48  Dr.F
-- optimizations.
--
-- Revision 1.1  2003/03/27 07:48:41  Dr.F
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

--library pilot_tracking_rtl;
library work;
--use pilot_tracking_rtl.pilot_tracking_pkg.all;
use work.pilot_tracking_pkg.all;

--library cordic_vectoring_rtl;
library work;

--------------------------------------------
-- Entity
--------------------------------------------
entity comp_angle is
  generic (Nbit_ph_g     : integer := 13;
           Nbit_pilots_g : integer := 12;
           Nbit_pred_g   : integer := 17
           );

  port (clk           : in std_logic;
        reset_n       : in std_logic;
        sync_reset_n  : in std_logic;
        data_valid_i  : in std_logic;
        pilot_p21_i_i : in std_logic_vector(Nbit_pilots_g-1 downto 0);
        pilot_p21_q_i : in std_logic_vector(Nbit_pilots_g-1 downto 0);
        pilot_p7_i_i  : in std_logic_vector(Nbit_pilots_g-1 downto 0);
        pilot_p7_q_i  : in std_logic_vector(Nbit_pilots_g-1 downto 0);
        pilot_m21_i_i : in std_logic_vector(Nbit_pilots_g-1 downto 0);
        pilot_m21_q_i : in std_logic_vector(Nbit_pilots_g-1 downto 0);
        pilot_m7_i_i  : in std_logic_vector(Nbit_pilots_g-1 downto 0);
        pilot_m7_q_i  : in std_logic_vector(Nbit_pilots_g-1 downto 0);
        cpe_pred_i    : in std_logic_vector(Nbit_pred_g-1 downto 0);
        sto_pred_i    : in std_logic_vector(Nbit_pred_g-1 downto 0);
        
        data_valid_o : out std_logic;
        ph_m21_o     : out std_logic_vector(Nbit_ph_g-1 downto 0);
        ph_m7_o      : out std_logic_vector(Nbit_ph_g-1 downto 0);
        ph_p7_o      : out std_logic_vector(Nbit_ph_g-1 downto 0);
        ph_p21_o     : out std_logic_vector(Nbit_ph_g-1 downto 0)
        );


end comp_angle;
