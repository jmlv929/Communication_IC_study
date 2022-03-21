
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: chass_timers.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.2   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : BuP timers for channel assessment.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_timers/vhdl/rtl/chass_timers.vhd,v  
--  Log: chass_timers.vhd,v  
-- Revision 1.2  2006/02/02 08:27:44  Dr.A
-- #BugId:1213#
-- Added bit to ignore VCS for channel assessment
--
-- Revision 1.1  2004/12/03 14:12:48  Dr.A
-- #BugId:837#
-- Channel assessment timers
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
 
--library bup2_timers_rtl;
library work;
--use bup2_timers_rtl.bup2_timers_pkg.all;
use work.bup2_timers_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity chass_timers is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n             : in  std_logic; -- Reset
    clk                 : in  std_logic; -- Clock
    enable_1mhz         : in  std_logic; -- Enable at 1 MHz
    mode32k             : in  std_logic; -- High during low-power mode

    --------------------------------------
    -- Controls
    --------------------------------------
    vcs_enable          : in  std_logic; -- Virtual carrier sense enable
    phy_cca_ind         : in  std_logic; -- CCA status
    phy_txstartend_conf : in  std_logic; -- Transmission status
    reg_chassen         : in  std_logic; -- Channel assessment enable
    reg_ignvcs          : in  std_logic; -- Ignore VCS in channel assessment
    reset_chassbsy      : in  std_logic; -- Reset channel busy timer
    reset_chasstim      : in  std_logic; -- Reset channel timer

    --------------------------------------
    -- Channel assessment timers
    --------------------------------------
    reg_chassbsy        : out std_logic_vector(25 downto 0);
    reg_chasstim        : out std_logic_vector(25 downto 0)
    
  );

end chass_timers;
