
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLDBuP2
--    ,' GoodLuck ,'      RCSfile: backoff2.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.9  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Backoff timer.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_timers/vhdl/rtl/backoff2.vhd,v  
--  Log: backoff2.vhd,v  
-- Revision 1.9  2005/03/22 10:10:57  Dr.A
-- #BugId:1150#
-- Test Tximmstop before starting TX when IFS = backoff = 0. Cleaned write_bckoff ports.
--
-- Revision 1.8  2005/02/22 13:26:46  Dr.A
-- #BugId:1086#
-- Delayed context switch if TX is about to start.
--
-- Revision 1.7  2005/02/18 16:16:14  Dr.A
-- #BugId:1065#
-- Immediate TX if txenable is set less than txstartdel us before end of complete SIFS period.
--
-- Revision 1.6  2005/02/02 17:55:02  Dr.A
-- #BugId:979,980,1009#
-- Backoff reenabled by SW write access (979)
-- All backoff counters aligned on txstartdel when one counts the last slot (980)
-- Backoff interrupt generated only when context is selected (1009)
--
-- Revision 1.5  2005/01/21 15:38:29  Dr.A
-- #BugId:978#
-- Backoff stopped when immediate stop is set
--
-- Revision 1.4  2005/01/20 14:45:16  Dr.A
-- #BugId:964#
-- Counter sizes increased in backoff and sifs counters.
--
-- Revision 1.3  2005/01/10 13:13:58  Dr.A
-- #BugId:912,931,637,941#
-- Removed enable_bup (bug 912)
-- New output to indicate when txstartdel must be removed from SIFS (bug 931)
-- Backenable LOW now freezes backoff instead of cancelling it (bug 941)
-- Backoff re-written with counters incrementing instead of decrementing to allow max value update during count (bug 637)
--
-- Revision 1.2  2004/12/20 12:50:32  Dr.A
-- #BugId:702#
-- Added ACK time-out mechanism.
--
-- Revision 1.1  2003/11/19 16:26:56  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Taken from revision 1.8 of backoff :
--
-- Revision 1.8  2003/11/13 18:38:18  Dr.F
-- go to wait_state when reg_vcs = 1.
--
-- Revision 1.7  2003/09/10 07:08:35  Dr.F
-- debuged txstartdelay.
--
-- Revision 1.6  2003/06/27 15:12:57  Dr.F
-- reordered libraries declaration.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 

use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_arith.ALL; 
use ieee.std_logic_unsigned.all;

--library bup2_timers_rtl; 
library work;
--use bup2_timers_rtl.bup2_timers_pkg.all;
use work.bup2_timers_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity backoff2 is
  port (
    --------------------------------------------
    -- clock and reset
    --------------------------------------------
    reset_n             : in  std_logic; -- Reset.
    pclk                : in  std_logic; -- APB clock.

    --------------------------------------------
    -- Port for 1 Mhz enable.
    --------------------------------------------
    enable_1mhz         : in  std_logic; -- Enable at 1 MHz.

    --------------------------------------------
    -- Backoff Timer Control.
    --------------------------------------------
    reg_backoff         : in  std_logic_vector( 9 downto 0); -- Backoff init value
    write_backoff       : in  std_logic; -- update backoff timer with init value
    -- BuPbackoff register when read
    backoff_timer       : out std_logic_vector( 9 downto 0);
    backoff_timer_end   : out std_logic; -- interrupt when backoff reaches 0.
    tx_without_backoff  : out std_logic; -- TX will start without backoff,
                      -- do not wait for backoff end to remove txstartdel from SIFS
    -- indicates when high that this is the last MACslot
    last_slot           : out std_logic;

    -- 
    global_last_slot    : in  std_logic;
    context_change      : in  std_logic; -- Pulse at ACP/BCON context switch request
    reg_vcs             : in  std_logic; -- Virtual carrier sense.
    cca_busy            : in  std_logic; -- CCA busy
    backenable          : in  std_logic; -- backoff counter enable
    tx_enable           : in  std_logic; -- transmit enable coming from reg.
    tximmstop_sm        : in  std_logic; -- Immediate stop from the state machines
    sifs_end            : in  std_logic; -- end of SIFS counter
    bup_sm_idle         : in  std_logic; -- no packet in progress when high
    global_backoff_it   : in  std_logic; -- pulse when another backoff counter
                                         -- has reached 0 
    ackto_timer_on      : in  std_logic; -- ACK time-out counter is running.
    reg_macslot         : in  std_logic_vector(7 downto 0); -- Slot duration (us)
    reg_ifs             : in  std_logic_vector(3 downto 0); -- nbr of MACslots
                                     -- that should be added after SIFS
    txstartdel          : in  std_logic_vector(2 downto 0) -- Nb of us to remove
                                     -- from last slot before TX.
    
    );

end backoff2;
