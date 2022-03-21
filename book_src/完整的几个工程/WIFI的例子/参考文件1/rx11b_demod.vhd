
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : Wild Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: rx11b_demod.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.26   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : 802.11b demodulation including DSSS demodulation, CCK
--              demodulation, precompensation, phase correction and frequency
--              offset compensation.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/rx11b_demod/vhdl/rtl/rx11b_demod.vhd,v  
--  Log: rx11b_demod.vhd,v  
-- Revision 1.26  2005/10/04 08:28:43  arisse
-- #BugId:1396#
-- Added globals
--
-- Revision 1.25  2005/01/24 14:20:10  arisse
-- #BugId:624#
-- Added status signal for registers.
--
-- Revision 1.24  2004/08/24 13:43:30  arisse
-- Added globals for testbench.
--
-- Revision 1.23  2004/04/30 15:07:22  arisse
-- Added reset of signals between two packets into fwt_assign_p process.
-- Added input cck_demod_enable in declaration of fwt entity.
--
-- Revision 1.22  2004/04/16 14:24:36  arisse
-- Changed generation of signal valid_symbol sent to decode_path.
--
-- Revision 1.21  2004/04/06 13:26:42  Dr.B
-- Re-worked the remodulation path (data_to_remod, remod_data_sync...)
-- to catch  "valid" output from compensation_cordic_1.
--
-- Revision 1.20  2003/07/07 12:35:55  Dr.J
-- Debugged the range of the cordic
--
-- Revision 1.19  2003/07/07 08:29:38  Dr.J
-- Updated with the new size of the cordic
--
-- Revision 1.18  2003/05/07 13:53:12  Dr.J
-- Added cordic enable
--
-- Revision 1.17  2002/11/20 13:22:23  Dr.J
-- Debugged
--
-- Revision 1.16  2002/11/13 13:35:59  Dr.J
-- Removed initila value
--
-- Revision 1.15  2002/11/12 12:29:09  Dr.J
-- Change mo_type sync
--
-- Revision 1.14  2002/10/15 15:49:31  Dr.J
-- Added interpolation enable
--
-- Revision 1.13  2002/10/10 15:02:36  Dr.J
-- Added tau
--
-- Revision 1.12  2002/09/18 15:23:50  Dr.J
-- Misc modification to support the CCK 5.5
--
-- Revision 1.11  2002/09/13 11:21:34  Dr.J
-- Debugged the CCK 11Mbits
--
-- Revision 1.10  2002/08/19 14:20:55  Dr.A
-- Added tau and interpolation enable in phase_estimation port map.
--
-- Revision 1.9  2002/08/14 18:13:48  Dr.J
-- Changed the direction of the Biggest_picker value
--
-- Revision 1.8  2002/07/31 13:06:29  Dr.J
-- Changed the omega_load to precomp_enable
-- Beautified the code
--
-- Revision 1.7  2002/07/11 12:29:01  Dr.J
-- Updated with the new data size
--
-- Revision 1.6  2002/06/28 16:32:00  Dr.J
-- Added libraries
--
-- Revision 1.5  2002/06/28 16:24:22  Dr.J
-- Removed comma.
--
-- Revision 1.4  2002/06/28 16:23:16  Dr.J
-- Added cck_rate in the port map of the Biggest picker
--
-- Revision 1.3  2002/06/28 16:19:24  Dr.J
-- Added synchro of the data out
--
-- Revision 1.2  2002/06/11 15:21:17  Dr.J
-- Added data_out_sync output
--
-- Revision 1.1  2002/06/11 10:18:44  Dr.F
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

--library rx11b_demod_rtl; 
library work;
--use rx11b_demod_rtl.rx11b_demod_pkg.ALL; 
use work.rx11b_demod_pkg.ALL; 

--library cordic_rtl; 
library work;
--library fwt_rtl; 
library work;
--library phase_estimation_rtl; 
library work;
--library demapping_rtl; 
library work;
--library biggest_picker_rtl; 
library work;
--library dsss_demod_rtl;
library work;
--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity rx11b_demod is
  generic (
    -- assignment of global signals :
    global_enable_g : integer := 0; -- 0 : no ; 1 : yes
    -- number of bits for the complex data :                                                         
    data_length_g          : integer := 9;                                            
    -- number of bits for the input angle z_in :                                                         
    angle_length_g         : integer := 15;                                            
    -- number of microrotation stages in a combinational path :
    nbr_cordic_combstage_g : integer := 3;   -- must be > 0                                         
    -- number of pipes in the cordic
    nbr_cordic_pipe_g      : integer := 4    -- must be > 0                                        
    -- NOTE : the total number of microrotations is :
    --          nbr_cordic_combstage_g * nbr_cordic_pipe_g = data_length_g
  );
  port (
    -- clock and reset.
    reset_n      : in  std_logic; -- Global reset.
    clk          : in  std_logic; -- Clock for Modem 802.11b (44 Mhz).

    symbol_sync  : in  std_logic; -- Symbol synchronization at 1 Mhz.
    precomp_enable   : in  std_logic; -- Reload the omega accumulator

--    cck_demod_enable : in  std_logic; -- window when enabled
    mod_type     : in  std_logic; -- Modulation type: '0' for DSSS, '1' for CCK.
    demod_rate   : in  std_logic; -- '0' for BPSK, '1' for QPSK
    cck_rate     : in  std_logic; -- '0' for 5.5 Mhz, '1' for 11 Mhz
    enable_error : in  std_logic; -- Enable error calculation when high
    interpolation_enable : in std_logic; -- Enable the Interpolation.
    rho          : in  std_logic_vector(3 downto 0); -- rho parameter value.
    mu           : in  std_logic_vector(3 downto 0); -- mu parameter value.

    -- Angles.
        -- Compensation angle. (only used for the simulation of this block)
    phi          : in  std_logic_vector(angle_length_g-1 downto 0);
        -- Precompensation angle. (only used for the simulation of this block)
    omega        : in  std_logic_vector(11 downto 0);
       -- before equalizer estimation
    sigma        : out std_logic_vector(9 downto 0);
       -- Tau for interpolator
    tau          : out std_logic_vector(17 downto 0);
    
    -- Data In.
    data_in_i    : in  std_logic_vector(data_length_g-1 downto 0);
    data_in_q    : in  std_logic_vector(data_length_g-1 downto 0);

    -- Data Out.
    freqoffestim_stat: out std_logic_vector(7 downto 0);  -- Status register.
    demap_data_out   : out std_logic_vector(1 downto 0);
    biggest_index    : out std_logic_vector(5 downto 0);
    valid_symbol     : out std_logic;

    remod_type       : out std_logic;
    data_to_remod    : out std_logic_vector(7 downto 0);
    remod_data_sync  : out std_logic
  );

end rx11b_demod;
