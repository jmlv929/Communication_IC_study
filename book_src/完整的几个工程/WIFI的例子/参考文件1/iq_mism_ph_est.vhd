
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11a2
--    ,' GoodLuck ,'      RCSfile: iq_mism_ph_est.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.11  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : IQ Phase Mismatch Estimation block.
--               Bit-true with MATLAB 23/10/03
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/iq_estimation/vhdl/rtl/iq_mism_ph_est.vhd,v  
--  Log: iq_mism_ph_est.vhd,v  
-- Revision 1.11  2004/11/02 15:08:54  Dr.C
-- #BugId:703#
-- Removed Kgs coefficient in the phase estimation.
--
-- Revision 1.10  2003/12/22 16:11:08  Dr.C
-- Increase ph_step and ph_step_inv by one bit.
--
-- Revision 1.9  2003/12/03 14:46:06  rrich
-- Fixed problem with initialisation (see top-level comment).
--
-- Revision 1.8  2003/12/02 13:18:27  rrich
-- Mods to allow ph_est to be initialised (converted to correct format)
-- immediately after loading presets.
--
-- Revision 1.7  2003/11/25 18:28:04  Dr.C
-- Change condition for init value.
--
-- Revision 1.6  2003/11/03 10:40:52  rrich
-- Addded new IQMMEST input.
--
-- Revision 1.5  2003/10/23 13:11:26  rrich
-- Bit-true with MATLAB
--
-- Revision 1.4  2003/10/23 11:45:54  rrich
-- Removed old architecture, causing problems.
--
-- Revision 1.3  2003/10/23 07:56:16  rrich
-- Complete revision of estimation post-processing algorithm.
--
-- Revision 1.2  2003/08/26 14:51:29  rrich
-- Bit-truified phase estimate.
--
-- Revision 1.1  2003/06/04 15:23:41  rrich
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
entity iq_mism_ph_est is
  generic (
    iq_accum_width_g : integer := 7;   -- Width of input accumulated IQ signals
    phase_width_g    : integer := 6;   -- Phase mismatch width
    preset_width_g   : integer := 16); -- Preset width
  
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Data in
    ---------------------------------------------------------------------------
    iq_accum     : in  std_logic_vector(iq_accum_width_g-1 downto 0);
    
    --------------------------------------
    -- Controls
    --------------------------------------
    iqmm_est     : in  std_logic; -- IQMMEST register
    est_start    : in  std_logic; -- Start estimation
    est_en       : in  std_logic; -- Estimation enable
    est_reset    : in  std_logic; -- Restart estimation
    ph_pset      : in  std_logic_vector(preset_width_g-1 downto 0);
    ph_step_in   : in  std_logic_vector(7 downto 0); 
    ctrl_cnt     : in  std_logic_vector(5 downto 0);
    initialise   : in  std_logic; -- Initialising estimation
    
    --------------------------------------
    -- Estimate out
    --------------------------------------
    ph_est_valid : out std_logic;
    ph_est       : out std_logic_vector(phase_width_g-1 downto 0);
    phase_accum  : out std_logic_vector(preset_width_g-1 downto 0));
    
end iq_mism_ph_est;
