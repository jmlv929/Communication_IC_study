
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: pilot_tracking.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.4   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Pilot tracking top level.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/FREQ_DOMAIN/pilot_tracking/vhdl/rtl/pilot_tracking.vhd,v  
--  Log: pilot_tracking.vhd,v  
-- Revision 1.4  2003/11/24 11:29:01  Dr.C
-- Updated inv_matrix port map.
--
-- Revision 1.3  2003/06/25 16:16:24  Dr.F
-- generic name changed.
--
-- Revision 1.2  2003/04/01 16:31:46  Dr.F
-- new equ_pilot.
--
-- Revision 1.1  2003/03/27 07:48:55  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

--library pilot_tracking_rtl;
library work;
--use pilot_tracking_rtl.pilot_tracking_pkg.all;
use work.pilot_tracking_pkg.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity pilot_tracking is

  port (clk                 : in  std_logic;
        reset_n             : in  std_logic;
        sync_reset_n        : in  std_logic;
        start_of_burst_i    : in  std_logic;
        start_of_symbol_i   : in  std_logic;
        ch_valid_i          : in  std_logic;
        -- pilots
        pilot_p21_i_i       : in  std_logic_vector(11 downto 0);
        pilot_p21_q_i       : in  std_logic_vector(11 downto 0);
        pilot_p7_i_i        : in  std_logic_vector(11 downto 0);
        pilot_p7_q_i        : in  std_logic_vector(11 downto 0);
        pilot_m21_i_i       : in  std_logic_vector(11 downto 0);
        pilot_m21_q_i       : in  std_logic_vector(11 downto 0);
        pilot_m7_i_i        : in  std_logic_vector(11 downto 0);
        pilot_m7_q_i        : in  std_logic_vector(11 downto 0);
        -- channel response for the pilot subcarriers
        ch_m21_coef_i_i     : in  std_logic_vector(11 downto 0);
        ch_m21_coef_q_i     : in  std_logic_vector(11 downto 0);
        ch_m7_coef_i_i      : in  std_logic_vector(11 downto 0);
        ch_m7_coef_q_i      : in  std_logic_vector(11 downto 0);
        ch_p7_coef_i_i      : in  std_logic_vector(11 downto 0);
        ch_p7_coef_q_i      : in  std_logic_vector(11 downto 0);
        ch_p21_coef_i_i     : in  std_logic_vector(11 downto 0);
        ch_p21_coef_q_i     : in  std_logic_vector(11 downto 0);
        -- equalizer coefficients 1/(channel response)
        eq_p21_i_i          : in  std_logic_vector(11 downto 0);
        eq_p21_q_i          : in  std_logic_vector(11 downto 0);
        eq_p7_i_i           : in  std_logic_vector(11 downto 0);
        eq_p7_q_i           : in  std_logic_vector(11 downto 0);
        eq_m21_i_i          : in  std_logic_vector(11 downto 0);
        eq_m21_q_i          : in  std_logic_vector(11 downto 0);
        eq_m7_i_i           : in  std_logic_vector(11 downto 0);
        eq_m7_q_i           : in  std_logic_vector(11 downto 0);
        skip_cpe_o          : out std_logic_vector(1 downto 0);
        estimate_done_o     : out std_logic;
        sto_o               : out std_logic_vector(16 downto 0);
        cpe_o               : out std_logic_vector(16 downto 0);
        -- debug signals
        -- equalized pilots
        pilot_p21_i_dbg     : out std_logic_vector(11 downto 0);
        pilot_p21_q_dbg     : out std_logic_vector(11 downto 0);
        pilot_p7_i_dbg      : out std_logic_vector(11 downto 0);
        pilot_p7_q_dbg      : out std_logic_vector(11 downto 0);
        pilot_m21_i_dbg     : out std_logic_vector(11 downto 0);
        pilot_m21_q_dbg     : out std_logic_vector(11 downto 0);
        pilot_m7_i_dbg      : out std_logic_vector(11 downto 0);
        pilot_m7_q_dbg      : out std_logic_vector(11 downto 0);
        equalize_done_dbg   : out std_logic;
        -- unwrapped cordic phases
        ph_m21_dbg          : out std_logic_vector(12 downto 0);
        ph_m7_dbg           : out std_logic_vector(12 downto 0);
        ph_p7_dbg           : out std_logic_vector(12 downto 0);
        ph_p21_dbg          : out std_logic_vector(12 downto 0);
        cordic_done_dbg     : out std_logic;
        -- ext_sto_cpe
        sto_meas_dbg        : out std_logic_vector(13 downto 0);
        cpe_meas_dbg        : out std_logic_vector(15 downto 0);
        ext_done_dbg        : out std_logic;        
        -- est_mag
        weight_ch_m21_dbg   : out std_logic_vector(5 downto 0);
        weight_ch_m7_dbg    : out std_logic_vector(5 downto 0);
        weight_ch_p7_dbg    : out std_logic_vector(5 downto 0);
        weight_ch_p21_dbg   : out std_logic_vector(5 downto 0);
        est_mag_done_dbg    : out std_logic;
        -- inv_matrix
        p11_dbg             : out std_logic_vector(11 downto 0);
        p12_dbg             : out std_logic_vector(11 downto 0);
        p13_dbg             : out std_logic_vector(11 downto 0);
        p14_dbg             : out std_logic_vector(11 downto 0);
        p21_dbg             : out std_logic_vector(11 downto 0);
        p22_dbg             : out std_logic_vector(11 downto 0);
        p23_dbg             : out std_logic_vector(11 downto 0);
        p24_dbg             : out std_logic_vector(11 downto 0);
        -- inv matrix debug signals
        p11_f_dbg           : out std_logic_vector(23 downto 0);
        p12_f_dbg           : out std_logic_vector(23 downto 0);
        p13_f_dbg           : out std_logic_vector(23 downto 0);
        p14_f_dbg           : out std_logic_vector(23 downto 0);
        p21_f_dbg           : out std_logic_vector(23 downto 0);
        p22_f_dbg           : out std_logic_vector(23 downto 0);
        p23_f_dbg           : out std_logic_vector(23 downto 0);
        p24_f_dbg           : out std_logic_vector(23 downto 0);
        inv_matrix_done_dbg : out std_logic
        );

end pilot_tracking;
