
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: kalman.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Kalman filter.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/pilot_tracking/vhdl/rtl/kalman.vhd,v  
--  Log: kalman.vhd,v  
-- Revision 1.5  2005/03/11 10:08:41  Dr.C
-- #BugId:1127#
-- Updated x3 value when ckip_cpe_i is not null.
--
-- Revision 1.4  2003/07/17 13:58:47  Dr.F
-- keep cpe_meas between -2PI and +2PI.
--
-- Revision 1.3  2003/06/25 16:15:13  Dr.F
-- size change : 18 -> 17.
--
-- Revision 1.2  2003/04/01 16:31:32  Dr.F
-- optimizations.
--
-- Revision 1.1  2003/03/27 07:48:51  Dr.F
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

--------------------------------------------
-- Entity
--------------------------------------------
entity kalman is
  generic (Nbit_sto_meas_g   : integer := 14;
           Nbit_cpe_meas_g   : integer := 16;
           Nbit_prediction_g : integer := 17);

  port (clk             : in  std_logic;
        reset_n         : in  std_logic;
        sync_reset_n    : in  std_logic;
        start_of_burst_i: in  std_logic;
        sto_cpe_valid_i : in  std_logic;
        sto_measured_i  : in  std_logic_vector(Nbit_sto_meas_g-1 downto 0);
        cpe_measured_i  : in  std_logic_vector(Nbit_cpe_meas_g-1 downto 0);        
        skip_cpe_i      : in  std_logic_vector(1 downto 0);        
        data_ready_o    : out std_logic;
        sto_pred_o      : out std_logic_vector(Nbit_prediction_g-1 downto 0);
        cpe_pred_o      : out std_logic_vector(Nbit_prediction_g-1 downto 0));

end kalman;
