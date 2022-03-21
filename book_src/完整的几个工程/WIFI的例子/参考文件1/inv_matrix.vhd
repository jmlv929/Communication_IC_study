
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: inv_matrix.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.5   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Matrice inversion.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/pilot_tracking/vhdl/rtl/inv_matrix.vhd,v  
--  Log: inv_matrix.vhd,v  
-- Revision 1.5  2003/12/09 16:25:47  Dr.C
-- Added a saturation sub_o_sat to sub_o.
--
-- Revision 1.4  2003/11/24 11:28:38  Dr.C
-- Changed NBIT_DETM_CT to 24.
--
-- Revision 1.3  2003/06/25 16:14:46  Dr.F
-- code cleaning.
--
-- Revision 1.2  2003/04/01 16:31:20  Dr.F
-- optimizations.
--
-- Revision 1.1  2003/03/27 07:48:49  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

--library pilot_tracking_rtl;
library work;
--use pilot_tracking_rtl.pilot_tracking_pkg.all;
use work.pilot_tracking_pkg.all;

--library divider_rtl;
library work;

--------------------------------------------
-- Entity
--------------------------------------------
entity inv_matrix is

  generic (Nbit_weight_g     : integer := 6;
           Nbit_inv_matrix_g : integer := 12);

  port (clk             : in  std_logic;
        reset_n         : in  std_logic;
        sync_reset_n    : in  std_logic;
        data_valid_i    : in  std_logic;
        weight_ch_m21_i : in  std_logic_vector(Nbit_weight_g-1 downto 0);
        weight_ch_m7_i  : in  std_logic_vector(Nbit_weight_g-1 downto 0);
        weight_ch_p7_i  : in  std_logic_vector(Nbit_weight_g-1 downto 0);
        weight_ch_p21_i : in  std_logic_vector(Nbit_weight_g-1 downto 0);
        p11_o           : out std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p12_o           : out std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p13_o           : out std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p14_o           : out std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p21_o           : out std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p22_o           : out std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p23_o           : out std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        p24_o           : out std_logic_vector(Nbit_inv_matrix_g-1 downto 0);
        data_valid_o    : out std_logic;

        p11_dbg         : out std_logic_vector(23 downto 0);
        p12_dbg         : out std_logic_vector(23 downto 0);
        p13_dbg         : out std_logic_vector(23 downto 0);
        p14_dbg         : out std_logic_vector(23 downto 0);
        p21_dbg         : out std_logic_vector(23 downto 0);
        p22_dbg         : out std_logic_vector(23 downto 0);
        p23_dbg         : out std_logic_vector(23 downto 0);
        p24_dbg         : out std_logic_vector(23 downto 0)
        );

end inv_matrix;
