
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD Modem 802.11b
--    ,' GoodLuck ,'      RCSfile: filter.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.20   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : 2nd order filter for decision directed phase estimation.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11b/phase_estimation/vhdl/rtl/filter.vhd,v  
--  Log: filter.vhd,v  
-- Revision 1.20  2005/01/24 14:18:29  arisse
-- #BugId:624#
-- Added status signal for registers.
--
-- Revision 1.19  2004/08/26 10:07:28  arisse
-- Added synthesis pragma for global_pkg.
--
-- Revision 1.18  2004/08/24 13:44:00  arisse
-- Added globals for testbench.
--
-- Revision 1.17  2004/06/14 14:05:38  arisse
-- Changed PRECOMP_PSI_MAX_CT.
--
-- Revision 1.16  2004/04/05 16:17:43  Dr.B
-- Synchronized mu & rho INPUT with load INPUT.
-- Registered and delayed (2chips) omega & sigma.
--
-- Revision 1.15  2002/12/09 16:53:24  Dr.J
-- Changed threshold of omega
--
-- Revision 1.14  2002/11/20 13:25:45  Dr.J
-- Changed synchronization
--
-- Revision 1.13  2002/10/29 09:13:40  Dr.J
-- Updated to debug phi
--
-- Revision 1.12  2002/10/15 15:51:31  Dr.J
-- Added enable_error in the filter
-- ,
--
-- Revision 1.11  2002/09/27 07:57:43  Dr.J
-- Updated the precompensation
-- ,
--
-- Revision 1.10  2002/09/16 14:11:26  Dr.A
-- Added constants for Synopsys.
--
-- Revision 1.9  2002/08/14 18:12:29  Dr.J
-- Added tau calculation
-- ,
--
-- Revision 1.8  2002/07/31 08:00:31  Dr.J
-- Debugged the calculation of sigma
-- Beautified the code
--
-- Revision 1.7  2002/07/11 12:24:39  Dr.J
-- Changed the data size
--
-- Revision 1.6  2002/06/28 16:11:52  Dr.J
-- Added sigma generation and misc debug
--
-- Revision 1.5  2002/06/10 13:15:21  Dr.J
-- Misc update
--
-- Revision 1.4  2002/05/22 08:33:13  Dr.J
-- Added omega generation
--
-- Revision 1.3  2002/05/02 09:24:16  Dr.A
-- Added theta reinit with phi value every symbol
-- Added work around for Synopsys synthesis
--
-- Revision 1.2  2002/03/29 13:14:16  Dr.A
-- New synchronization and filter loop changes.
--
-- Revision 1.1  2002/03/28 12:42:14  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL; 
 
--library commonlib;
library work;
--use commonlib.mdm_math_func_pkg.all;
use work.mdm_math_func_pkg.all;

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
entity filter is
  generic (
    esize_g  : integer := 13; -- size of error (must >= dsize_g).
    phisize_g    : integer := 15; -- size of angle phi
    omegasize_g  : integer := 12; -- size of angle omega
    sigmasize_g  : integer := 10; -- size of angle sigma
    tausize_g    : integer := 19  -- size of angle tau
  );
  port (
    -- clock and reset.
    clk            : in  std_logic;                   
    reset_n        : in  std_logic;    
    --
    load           : in  std_logic; -- Filter synchronization.
    precomp_enable : in  std_logic; -- Reload the omega accumulator
    interpolation_enable : in  std_logic; -- load the tau accumulator
    enable_error   : in std_logic; -- Enable the compensation.
    symbol_sync    : in  std_logic; -- Symbol synchronization.
    mod_type       : in  std_logic; -- Modulation type: '0' for DSSS, 
                                    -- '1' for CCK.
    phase_error    : in  std_logic_vector(esize_g-1 downto 0);-- Error
    rho            : in  std_logic_vector(3 downto 0); -- rho parameter value.
    mu             : in  std_logic_vector(3 downto 0); -- mu parameter value.

    -- Filter outputs.
    freqoffestim_stat : out std_logic_vector(7 downto 0);  -- Status register.
    phi            : out std_logic_vector(phisize_g-1 downto 0);  -- phi.
    sigma          : out std_logic_vector(sigmasize_g-1 downto 0);-- sigma.
    omega          : out std_logic_vector(omegasize_g-1 downto 0); -- omega.
    tau            : out std_logic_vector(tausize_g-1 downto 0) -- tau.
  
  );

end filter;
