
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: iq_estimation.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.15  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : IQ Mismatch Estimation block.
--               Bit-true with MATLAB 23/10/03
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/iq_estimation/vhdl/rtl/iq_estimation.vhd,v  
--  Log: iq_estimation.vhd,v  
-- Revision 1.15  2004/11/02 15:08:46  Dr.C
-- #BugId:703#
-- Removed Kgs coefficient in the phase estimation.
--
-- Revision 1.14  2004/06/18 09:40:28  Dr.C
-- Added rx_iqmm_out_dis.
--
-- Revision 1.13  2003/12/03 16:10:17  Dr.C
-- Removed unused signals.
--
-- Revision 1.12  2003/12/03 14:44:51  rrich
-- Fixed block so that it initialises after presets are set, regardless of
-- whether estimation is enabled or not.
--
-- Revision 1.11  2003/12/02 18:03:57  Dr.C
-- Removed unused library.
--
-- Revision 1.10  2003/12/02 13:15:51  rrich
-- Mods to allow initialisation of ph_est and g_est immediately after loading
-- presets.
--
-- Revision 1.9  2003/12/01 14:03:45  Dr.C
-- Cleaned.
--
-- Revision 1.8  2003/11/28 08:33:07  Dr.C
-- Added reset of accumulation when the block is disable.
--
-- Revision 1.6  2003/11/03 10:40:08  rrich
-- Added new IQMMEST input.
--
-- Revision 1.5  2003/10/23 13:10:36  rrich
-- Bit-true with MATLAB 23/10/03.
--
-- Revision 1.4  2003/10/23 07:53:33  rrich
-- Added inputs for gain and phase step, as required for new algorithm.
--
-- Revision 1.3  2003/09/09 14:45:37  rrich
-- Changed reset value of gain estimate to 0x100 to avoid problems with
-- compensation block.
--
-- Revision 1.2  2003/08/26 14:50:24  rrich
-- Bit-truified gain and phase estimate calculations.
--
-- Revision 1.1  2003/06/04 15:23:29  rrich
-- Initial revision
--
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all; 
use IEEE.std_logic_arith.all; 
use IEEE.std_logic_misc.all;

--library iq_estimation_rtl;
library work;
--use iq_estimation_rtl.iq_estimation_pkg.all;
use work.iq_estimation_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity iq_estimation is

  generic (
    iq_i_width_g   : integer := 11;   -- Width of the input IQ signals
    gain_width_g   : integer := 9;    -- Gain  mismatch estimate width
    phase_width_g  : integer := 6;    -- Phase mismatch estimate width
    preset_width_g : integer := 16    -- Estimate presets width 
  );
  
  port (
    clk             : in  std_logic; -- Module clock
    reset_n         : in  std_logic; -- Asynchronous reset

    --------------------------------------
    -- Controls
    --------------------------------------
    rx_iqmm_est     : in  std_logic; -- Enable from register
    rx_iqmm_est_en  : in  std_logic; -- Estimation enable (high during data)
    rx_iqmm_out_dis : in  std_logic; -- Outputs disable (high after signal field error)
    rx_iqmm_reset   : in  std_logic; -- Restart estimation
    rx_packet_end   : in  std_logic; -- Packet end
    rx_iqmm_g_pset  : in  std_logic_vector(preset_width_g-1 downto 0);
    rx_iqmm_ph_pset : in  std_logic_vector(preset_width_g-1 downto 0);
    rx_iqmm_g_step  : in  std_logic_vector(7 downto 0);
    rx_iqmm_ph_step : in  std_logic_vector(7 downto 0);
    --
    iqmm_reset_done : out std_logic; -- Restart estimation done

    --------------------------------------
    -- Data in
    --------------------------------------
    data_valid_in   : in  std_logic; -- High when a new data is available
    i_in            : in  std_logic_vector(iq_i_width_g-1 downto 0);
    q_in            : in  std_logic_vector(iq_i_width_g-1 downto 0);

    --------------------------------------
    -- Estimates out
    --------------------------------------
    rx_iqmm_g_est         : out std_logic_vector(gain_width_g-1 downto 0);
    rx_iqmm_ph_est        : out std_logic_vector(phase_width_g-1 downto 0);
    gain_accum            : out std_logic_vector(preset_width_g-1 downto 0);
    phase_accum           : out std_logic_vector(preset_width_g-1 downto 0)
  );

end iq_estimation;
