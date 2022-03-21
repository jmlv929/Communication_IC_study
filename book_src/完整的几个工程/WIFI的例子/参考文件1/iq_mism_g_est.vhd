
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: iq_mism_g_est.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.13  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : IQ Gain Mismatch Estimation block.
--               Bit-true with MATLAB 23/10/03
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/iq_estimation/vhdl/rtl/iq_mism_g_est.vhd,v  
--  Log: iq_mism_g_est.vhd,v  
-- Revision 1.13  2004/11/02 15:08:51  Dr.C
-- #BugId:703#
-- Removed Kgs coefficient in the phase estimation.
--
-- Revision 1.12  2004/01/06 16:01:41  Dr.C
-- Changed init value of av_g_reg.
--
-- Revision 1.11  2003/12/22 16:10:20  Dr.C
-- Increase g_step & g_step_inv by one bit.
--
-- Revision 1.10  2003/12/03 16:10:27  Dr.C
-- Added G_EST_INIT_CT init value for g_est.
--
-- Revision 1.9  2003/12/03 14:45:51  rrich
-- Fixed initialisation problem (see top-level comment).
--
-- Revision 1.8  2003/12/02 13:18:01  rrich
-- Mods to allow g_est to be initialised immediately after loading presets.
--
-- Revision 1.7  2003/11/25 18:27:43  Dr.C
-- Change condition for init value.
--
-- Revision 1.6  2003/11/03 10:40:41  rrich
-- Added new IQMMEST input.
--
-- Revision 1.5  2003/10/23 13:11:08  rrich
-- Bit-true with MATLAB
--
-- Revision 1.4  2003/10/23 07:54:17  rrich
-- Complete revision of estimation post-processing algorithm, removal of divider
-- and square-root blocks.
--
-- Revision 1.3  2003/09/09 14:46:53  rrich
-- Changed reset value of gain estimate to 0x100 to avoid problems with
-- compensation block.
--
-- Revision 1.2  2003/08/26 14:51:13  rrich
-- Bit-truified gain estimate.
--
-- Revision 1.1  2003/06/04 15:23:37  rrich
-- Initial revision
--
--
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use IEEE.STD_LOGIC_ARITH.ALL; 

--library bit_ser_adder_rtl;
library work;
--use bit_ser_adder_rtl.bit_ser_adder_pkg.all;
use work.bit_ser_adder_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity iq_mism_g_est is
  generic (
    iq_accum_width_g : integer := 10;  -- Width of input accumulated IQ signals
    gain_width_g     : integer := 9;   -- Gain mismatch width
    preset_width_g   : integer := 16); -- Preset width 
  
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Data in
    ---------------------------------------------------------------------------
    i_accum : in  std_logic_vector(iq_accum_width_g-1 downto 0);
    q_accum : in  std_logic_vector(iq_accum_width_g-1 downto 0);

    --------------------------------------
    -- Controls
    --------------------------------------
    iqmm_est  : in  std_logic; -- IQMMEST register
    est_start : in  std_logic; -- Start estimation
    est_en    : in  std_logic; -- Estimation enable
    est_reset : in  std_logic; -- Restart estimation
    g_pset    : in  std_logic_vector(preset_width_g-1 downto 0);
    g_step_in : in  std_logic_vector(7 downto 0);
    ctrl_cnt  : in  std_logic_vector(5 downto 0);
    initialise: in  std_logic; -- Initialising estimation
    
    --------------------------------------
    -- Estimate out
    --------------------------------------
    g_est_valid : out std_logic;
    g_est       : out std_logic_vector(gain_width_g-1 downto 0);
    gain_accum  : out std_logic_vector(preset_width_g-1 downto 0));

    
end iq_mism_g_est;
