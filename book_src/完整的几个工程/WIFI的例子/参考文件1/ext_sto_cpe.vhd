

--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: ext_sto_cpe.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.3   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Extract CPE and STO from input angles.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/pilot_tracking/vhdl/rtl/ext_sto_cpe.vhd,v  
--  Log: ext_sto_cpe.vhd,v  
-- Revision 1.3  2003/06/25 16:12:56  Dr.F
-- code cleaning.
--
-- Revision 1.2  2003/04/01 16:31:15  Dr.F
-- optimizations.
--
-- Revision 1.1  2003/03/27 07:48:47  Dr.F
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
entity ext_sto_cpe is
  generic (Nbit_ph_g         : integer := 13;
           Nbit_inv_matrix_g : integer := 12
           );

  port (clk                 : in  std_logic;
        reset_n             : in  std_logic;
        sync_reset_n        : in  std_logic;
        matrix_data_valid_i : in  std_logic;
        cordic_data_valid_i : in  std_logic;
        ph_m21_i            : in  std_logic_vector(Nbit_ph_g-1 downto 0);
        ph_m7_i             : in  std_logic_vector(Nbit_ph_g-1 downto 0);
        ph_p7_i             : in  std_logic_vector(Nbit_ph_g-1 downto 0);
        ph_p21_i            : in  std_logic_vector(Nbit_ph_g-1 downto 0);
        p11_i               : in  std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p12_i               : in  std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p13_i               : in  std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p14_i               : in  std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p21_i               : in  std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p22_i               : in  std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p23_i               : in  std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p24_i               : in  std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        data_valid_o        : out std_logic;
        sto_meas_o          : out std_logic_vector(13 downto 0);
        cpe_meas_o          : out std_logic_vector(15 downto 0)
        );

end ext_sto_cpe;
