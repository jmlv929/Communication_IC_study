
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: phase_estimation.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.11   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Phase and carrier offset estimation.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/phase_estimation/vhdl/rtl/phase_estimation.vhd,v  
--  Log: phase_estimation.vhd,v  
-- Revision 1.11  2005/01/24 14:18:44  arisse
-- #BugId:624#
-- Added status signal for registers.
--
-- Revision 1.10  2004/08/24 13:44:07  arisse
-- Added globals for testbench.
--
-- Revision 1.9  2002/10/15 15:51:46  Dr.J
-- Added enable_error in the filter
--
-- Revision 1.8  2002/08/14 18:12:41  Dr.J
-- Added Tau output
--
-- Revision 1.7  2002/07/31 08:01:36  Dr.J
-- Renamed omega_load by precomp_enable
--
-- Revision 1.6  2002/07/11 12:24:56  Dr.J
-- Changed the data size
--
-- Revision 1.5  2002/06/28 16:13:01  Dr.J
-- Renamed theta
--
-- Revision 1.4  2002/06/10 13:15:41  Dr.J
-- Changed severals size and added signals
--
-- Revision 1.3  2002/05/22 08:34:00  Dr.J
-- Added omega generation
--
-- Revision 1.2  2002/03/29 13:14:59  Dr.A
-- Added symbol_sync port on filter.
--
-- Revision 1.1  2002/03/28 12:42:23  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library phase_estimation_rtl;
library work;
--use phase_estimation_rtl.phase_estimation_pkg.all;
use work.phase_estimation_pkg.all;
-- ambit synthesis off
-- synopsys translate_off
-- synthesis translate_off 
--use phase_estimation_rtl.phase_estimation_global_pkg.all;
-- ambit synthesis on
-- synopsys translate_on
-- synthesis translate_on
 

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity phase_estimation is
  generic (
    dsize_g      : integer := 13; -- size of data in
    esize_g      : integer := 13; -- size of error (must >= dsize_g).
    phisize_g    : integer := 15; -- size of angle phi
    omegasize_g  : integer := 12; -- size of angle omega
    sigmasize_g  : integer := 10; -- size of angle sigma
    tausize_g    : integer := 18  -- size of tau
  );
  port (
    -- clock and reset.
    clk                  : in  std_logic;
    reset_n              : in  std_logic;
    --
    symbol_sync          : in  std_logic;  -- Symbol synchronization pulse.
    precomp_enable       : in  std_logic;  -- Enable the precompensation
    interpolation_enable : in  std_logic;  -- Load the tau accumulator
    data_i               : in  std_logic_vector(dsize_g-1 downto 0);  -- Real data in
    data_q               : in  std_logic_vector(dsize_g-1 downto 0);  -- Im data in.
    demap_data           : in  std_logic_vector(1 downto 0);  -- Data from demapping.
    enable_error         : in  std_logic;  -- Enable the error calculation.
    mod_type             : in  std_logic;  -- Modulation type: '0' for DSSS, '1' for CCK.
    rho                  : in  std_logic_vector(3 downto 0);  -- rho parameter value.
    mu                   : in  std_logic_vector(3 downto 0);  -- mu parameter value.
    -- Filtered outputs.
    freqoffestim_stat    : out std_logic_vector(7 downto 0);  -- Status register.
    phi                  : out std_logic_vector(phisize_g-1 downto 0);  -- phi angle.
    sigma                : out std_logic_vector(sigmasize_g-1 downto 0);  -- sigma angle.
    omega                : out std_logic_vector(omegasize_g-1 downto 0);  -- omega angle.
    tau                  : out std_logic_vector(tausize_g-1 downto 0)   -- tau.
    );

end phase_estimation;
