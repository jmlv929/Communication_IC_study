
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: equalizer.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.16   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Feedforward Equalizer.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/equalizer/vhdl/rtl/equalizer.vhd,v  
--  Log: equalizer.vhd,v  
-- Revision 1.16  2005/01/24 14:14:25  arisse
-- #BugId:624#
-- Added status signals for registers.
--
-- Revision 1.15  2004/08/24 13:44:33  arisse
-- Added globals for testbench.
--
-- Revision 1.14  2004/03/15 13:07:49  Dr.B
-- Added saturation on error_i/q calculus.
--
-- Revision 1.13  2003/10/16 16:18:58  arisse
-- Changed diag_error_i/q to 8 bits instead of 9 bits.
--
-- Revision 1.12  2003/10/16 14:21:15  arisse
-- Added diag ports.
--
-- Revision 1.11  2003/09/18 08:37:42  Dr.A
-- Removed unused generics.
--
-- Revision 1.10  2003/09/09 12:58:51  Dr.C
-- Removed power_estim links.
--
-- Revision 1.9  2002/12/03 15:06:32  Dr.B
-- change condition on multiplier sharing.
--
-- Revision 1.8  2002/11/06 17:16:50  Dr.A
-- Changed abs_2 signals size.
--
-- Revision 1.7  2002/10/18 15:34:22  Dr.J
-- Removed the DC Offset
--
-- Revision 1.6  2002/09/19 17:00:37  Dr.A
-- Added ports to use a multiplier from outside.
-- data size debug.
--
-- Revision 1.5  2002/07/31 13:06:51  Dr.B
-- new size.
--
-- Revision 1.4  2002/07/11 12:36:39  Dr.B
-- delay_g in half-chip.
--
-- Revision 1.3  2002/06/27 16:15:27  Dr.B
-- synchro with matlab changes.
--
-- Revision 1.2  2002/05/07 16:52:09  Dr.A
-- Corrected structure and blocks.
--
-- Revision 1.1  2002/03/28 13:48:54  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all; 

--library equalizer_rtl;
library work;
--use equalizer_rtl.equalizer_pkg.all;
use work.equalizer_pkg.all;

--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;


-- pragma translate_off
--use equalizer_rtl.equalizer_global_pkg.all;
-- pragma translate_on 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity equalizer is
  generic (
    dsize_g : integer := 8;  -- Input data size
    csize_g : integer := 8;  -- Coefficient size 
    coeff_g : integer := 36; -- Number of filter coefficients 
    delay_g : integer := 44; -- Delay for remodulation (in half-chip)
    
    -- for ffwd_estimation:
    -- generics for coefficients calculation
    shifta_g : integer := 14;  -- data size after shifting by alpha.
    cacsize_g: integer := 19;  -- accumulated coeff size  

    -- generics for DC_output calculation
    dccoeff_g : integer := 19; -- numbers of bits kept from coeff to calc sum.
    sum_g     : integer := 8; -- data size of the sum
    multerr_g : integer := 12; -- data size after the mult by error
    shiftb_g  : integer := 14; -- data size after shifting by beta
    dcacsize_g: integer := 17; -- accumulated dc_offset size  
    dcsize_g  : integer := 6;   -- DC_offset size (output)
    outsize_g : integer := 9;
    p_size_g  : integer := 4 -- nb of input bits from correlator for peak_detect
    
  );
  port (
    -------------------------------
    -- reset and clock
    -------------------------------
    reset_n         : in  std_logic; 
    clk             : in  std_logic;
    -------------------------------
    -- Control signals
    -------------------------------
    equ_activate    : in std_logic;  -- activate the block
    equalizer_init_n: in  std_logic; -- filter coeffs= 0  when low.
    equalizer_disb  : in  std_logic; -- Disable the filter when high.
                                     -- data_in are shifted to data_out 
    data_sync       : in  std_logic; -- Pulse at first data.
    alpha_accu_disb : in  std_logic; -- stop coeff accu when high
    beta_accu_disb  : in  std_logic; -- stop dc accu when high
    -------------------------------
    -- Equalizer inputs
    -------------------------------
    -- Incoming data stream at 22 MHz (I and Q).
    data_fil_i      : in  std_logic_vector(dsize_g-1 downto 0);
    data_fil_q      : in  std_logic_vector(dsize_g-1 downto 0);
    -- Remodulated data at 11 MHz (I and Q).
    remod_data_i    : in  std_logic_vector(outsize_g-1 downto 0);
    remod_data_q    : in  std_logic_vector(outsize_g-1 downto 0);
    -- Equalizer parameters.
    alpha           : in  std_logic_vector(2 downto 0);
    beta            : in  std_logic_vector(2 downto 0);
    -- Data to multiply  when equ is disable for peak detector
    d_signed_peak_i   : in  std_logic_vector(p_size_g-1 downto 0);
    d_signed_peak_q   : in  std_logic_vector(p_size_g-1 downto 0);
    -------------------------------
    -- Equalizer outputs
    -------------------------------
    equalized_data_i      : out std_logic_vector(outsize_g-1 downto 0);
    equalized_data_q      : out std_logic_vector(outsize_g-1 downto 0);    
    -- Output for peak_detect
    abs_2_corr            : out std_logic_vector (2*p_size_g-1 downto 0);

    -- Register stat
    coeff_sum_i_stat : out std_logic_vector(sum_g-1 downto 0);
    coeff_sum_q_stat : out std_logic_vector(sum_g-1 downto 0);
    
    -- DC Offset outputs.
    dc_offset_i      : out std_logic_vector(dcsize_g-1 downto 0);
    dc_offset_q      : out std_logic_vector(dcsize_g-1 downto 0);
    
    -------------------------------
    -- Diag ports
    -------------------------------
    diag_error_i     : out std_logic_vector(outsize_g-2 downto 0); 
    diag_error_q     : out std_logic_vector(outsize_g-2 downto 0)
  );

end equalizer;
