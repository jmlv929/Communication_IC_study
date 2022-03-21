
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--       ------------      Project : WiLDBuP2
--    ,' GoodLuck ,'      RCSfile: bup2_timers.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.26  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Timers for the WILD BuP.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_timers/vhdl/rtl/bup2_timers.vhd,v  
--  Log: bup2_timers.vhd,v  
-- Revision 1.26  2006/03/13 08:41:05  Dr.A
-- #BugId:2328#
-- Added support of 131.072 kHz clock for 1 MHz counter in low-power mode
--
-- Revision 1.25  2006/02/03 08:35:26  Dr.A
-- #BugId:1140#
-- Send IAC IFS write indication to IAC timer.
-- Send IAC IFS indication to state machines
--
-- Revision 1.24  2006/02/02 15:35:51  Dr.A
-- #BugId:1204#
-- Ungated clock used for BuP timer only
--
-- Revision 1.23  2006/02/02 08:27:36  Dr.A
-- #BugId:1213#
-- Added bit to ignore VCS for channel assessment
--
-- Revision 1.22  2005/10/21 13:26:52  Dr.A
-- #BugId:1246#
-- Added absolute count timers
--
-- Revision 1.21  2005/04/19 07:25:49  Dr.A
-- #BugId:1181#
-- Ackto counter reset when ackto interrupt disabled.
--
-- Revision 1.20  2005/04/07 08:44:41  Dr.A
-- #BugId:938#
-- Add txenable to diag ports
--
-- Revision 1.19  2005/04/06 15:44:11  sbizet
-- #BugId:1188#
-- Added intermediate assignement for delta-delay problem
--
-- Revision 1.18  2005/03/29 08:46:18  Dr.A
-- #BugId:907#
-- Added TX force disable
--
-- Revision 1.17  2005/03/22 10:11:53  Dr.A
-- #BugId:1150#
-- Cleaned write_bckoff ports
--
-- Revision 1.16  2005/02/22 13:26:52  Dr.A
-- #BugId:1086#
-- Delayed context switch if TX is about to start.
--
-- Revision 1.15  2005/02/18 16:18:58  Dr.A
-- #BugId:1067,1070#
-- <= check on txstartdel (1067).
-- Added flag to indicate the last txstartdel us of the SIFS period (1070)
--
-- Revision 1.14  2005/02/09 17:53:24  Dr.A
-- #BugId:1016#
-- Stop SIFS count if BuP state machine is not idle. This means a CCA has been received during NORMSIFS.
--
-- Revision 1.13  2005/02/02 17:55:09  Dr.A
-- #BugId:979,980,1009#
-- Backoff reenabled by SW write access (979)
-- All backoff counters aligned on txstartdel when one counts the last slot (980)
-- Backoff interrupt generated only when context is selected (1009)
--
-- Revision 1.12  2005/01/21 15:38:33  Dr.A
-- #BugId:978#
-- Backoff stopped when immediate stop is set
--
-- Revision 1.11  2005/01/20 14:45:23  Dr.A
-- #BugId:964#
-- Counter sizes increased in backoff and sifs counters.
--
-- Revision 1.10  2005/01/13 13:52:16  Dr.A
-- #BugId:903#
-- New diag ports.
--
-- Revision 1.9  2005/01/10 13:11:02  Dr.A
-- #BugId:912,931#
-- Removed enable_bup (bug 912).
-- New output from backoff timer indicating when txstartdel must be removed from SIFS (bug 931).
--
-- Revision 1.8  2004/12/20 12:50:39  Dr.A
-- #BugId:702#
-- Added ACK time-out mechanism.
--
-- Revision 1.7  2004/12/03 14:09:18  Dr.A
-- #BugId:837#
-- Added channel assessment timers
--
-- Revision 1.6  2004/10/07 09:37:15  Dr.A
-- #BugId:738#
-- BuP timer increased of 4 low-power clock periods when mode32k goes HIGH.
--
-- Revision 1.5  2004/10/06 13:14:50  Dr.A
-- #BugId:679#
-- Comparison between abscount timer and BuP timer does not use 5 LSB in low-power mode.
--
-- Revision 1.4  2004/01/29 17:56:00  Dr.F
-- fixed transmission queue update on iac transmission.
--
-- Revision 1.3  2004/01/06 15:08:37  pbressy
-- bugzilla 331 fix
--
-- Revision 1.2  2003/12/09 15:58:59  Dr.F
-- set reg_vcs input of iac_backoff to zero.
--
-- Revision 1.1  2003/11/19 16:26:58  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Taken from revision 1.18 of bup_timers :
--
-- Revision 1.18  2003/11/13 18:38:55  Dr.F
-- update according to 1.03 specs : new SIFS periods + low power feature.
--
-- Revision 1.17  2003/09/10 07:06:01  Dr.F
-- disabled ACP backoff counters when in beacon context, and vice versa.
--
-- Revision 1.16  2003/06/27 15:13:43  Dr.F
-- added bup_timer counting capability in low power mode (mod32k = 1).
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
entity bup2_timers is
  generic (
    num_queues_g      : integer := 4;
    num_abstimer_g  : integer := 16 -- number of absolute count timers (max is 16)
    );
  port (
    --------------------------------------------
    -- clock and reset
    --------------------------------------------
    reset_n             : in  std_logic; -- Reset.
    pclk                : in  std_logic; -- APB clock.
    buptimer_clk        : in  std_logic; -- Clock not gated.
    enable_1mhz         : in  std_logic; -- Enable at 1 MHz.
    mode32k             : in  std_logic; -- buptimer_clk = 32kHz when high

    --------------------------------------------
    -- BuP Timer Control.
    --------------------------------------------
    reg_buptimer        : in  std_logic_vector( 25 downto 0); -- value from register
    write_buptimer      : in  std_logic; -- update buptimer with register value
    write_buptimer_done : out std_logic; -- update done.
    -- BuPtimer register when read
    bup_timer           : out std_logic_vector(25 downto 0);

    -- Pulse interrupt sent on buptime wrapping around.
    timewrap_interrupt  : out std_logic;
    
    --------------------------------------
    -- Channel assessment timers
    --------------------------------------
    phy_txstartend_conf : in  std_logic; -- Transmission status
    reg_chassen         : in  std_logic; -- Channel assessment enable
    reg_ignvcs          : in  std_logic; -- Ignore VCS in channel measurement
    reset_chassbsy      : in  std_logic; -- Reset channel busy timer
    reset_chasstim      : in  std_logic; -- Reset channel timer
    --
    reg_chassbsy        : out std_logic_vector(25 downto 0);
    reg_chasstim        : out std_logic_vector(25 downto 0);

    --------------------------------------
    -- ACK timer control
    --------------------------------------
    txstart_it          : in  std_logic; -- Start of transmission pulse
    txend_it            : in  std_logic; -- End of transmission pulse
    rxstart_it          : in  std_logic; -- Start of reception pulse
    -- Control fields from tx packet control structure:
    ackto_count         : in  std_logic_vector(8 downto 0); -- Time-out value
    -- Enable ACK time-out generation
    ackto_en            : in  std_logic; -- From TX control structure
    reg_ackto_en        : in  std_logic; -- From BuP registers
    --
    ackto_it            : out std_logic; -- Time-out pulse

    --------------------------------------------
    -- Backoff Timer Control.
    --------------------------------------------
    -- initial values from registers for beacon, IAC and ACP[0-7] backoff
    reg_backoff_bcon      : in  std_logic_vector( 9 downto 0); 
    reg_backoff_acp0      : in  std_logic_vector( 9 downto 0); 
    reg_backoff_acp1      : in  std_logic_vector( 9 downto 0); 
    reg_backoff_acp2      : in  std_logic_vector( 9 downto 0); 
    reg_backoff_acp3      : in  std_logic_vector( 9 downto 0); 
    reg_backoff_acp4      : in  std_logic_vector( 9 downto 0); 
    reg_backoff_acp5      : in  std_logic_vector( 9 downto 0); 
    reg_backoff_acp6      : in  std_logic_vector( 9 downto 0); 
    reg_backoff_acp7      : in  std_logic_vector( 9 downto 0); 

    -- update beacon, IAC and ACP[0-7] backoff timer with init value
    write_backoff_bcon      : in  std_logic;
    write_backoff_iac       : in  std_logic;
    write_backoff_acp0      : in  std_logic;
    write_backoff_acp1      : in  std_logic;
    write_backoff_acp2      : in  std_logic;
    write_backoff_acp3      : in  std_logic;
    write_backoff_acp4      : in  std_logic;
    write_backoff_acp5      : in  std_logic;
    write_backoff_acp6      : in  std_logic;
    write_backoff_acp7      : in  std_logic;

    -- Backoff registers when read
    backoff_timer_bcon    : out std_logic_vector( 9 downto 0);
    backoff_timer_acp0    : out std_logic_vector( 9 downto 0);
    backoff_timer_acp1    : out std_logic_vector( 9 downto 0);
    backoff_timer_acp2    : out std_logic_vector( 9 downto 0);
    backoff_timer_acp3    : out std_logic_vector( 9 downto 0);
    backoff_timer_acp4    : out std_logic_vector( 9 downto 0);
    backoff_timer_acp5    : out std_logic_vector( 9 downto 0);
    backoff_timer_acp6    : out std_logic_vector( 9 downto 0);
    backoff_timer_acp7    : out std_logic_vector( 9 downto 0);
    
    --------------------------------------------
    -- BUP TX control
    --------------------------------------------
    -- backoff timer enable
    backenable_bcon       : in  std_logic; 
    backenable_acp0       : in  std_logic; 
    backenable_acp1       : in  std_logic; 
    backenable_acp2       : in  std_logic; 
    backenable_acp3       : in  std_logic; 
    backenable_acp4       : in  std_logic; 
    backenable_acp5       : in  std_logic; 
    backenable_acp6       : in  std_logic; 
    backenable_acp7       : in  std_logic; 

    -- transmit enable
    txenable_iac          : in  std_logic;
    txenable_bcon         : in  std_logic;
    txenable_acp0         : in  std_logic;
    txenable_acp1         : in  std_logic;
    txenable_acp2         : in  std_logic;
    txenable_acp3         : in  std_logic;
    txenable_acp4         : in  std_logic;
    txenable_acp5         : in  std_logic;
    txenable_acp6         : in  std_logic;
    txenable_acp7         : in  std_logic;
    forcetxdis            : in  std_logic; -- Disable all TX queues.

    -- inter frame spacing : number of MACSlots added to SIFS
    ifs_iac               : in  std_logic_vector(3 downto 0);
    ifs_bcon              : in  std_logic_vector(3 downto 0);
    ifs_acp0              : in  std_logic_vector(3 downto 0);
    ifs_acp1              : in  std_logic_vector(3 downto 0);
    ifs_acp2              : in  std_logic_vector(3 downto 0);
    ifs_acp3              : in  std_logic_vector(3 downto 0);
    ifs_acp4              : in  std_logic_vector(3 downto 0);
    ifs_acp5              : in  std_logic_vector(3 downto 0);
    ifs_acp6              : in  std_logic_vector(3 downto 0);
    ifs_acp7              : in  std_logic_vector(3 downto 0);
    
    sifs_timer_it         : out std_logic; -- interrupt when sifs reaches 0.
    backoff_timer_it      : out std_logic; -- interrupt when backoff reaches 0.
    txstartdel_flag       : out std_logic; -- Flag set when less than txstartdel us left in SIFS
    iac_without_ifs       : out std_logic; -- flag set when no IFS in IAC queue
    -- queue that generated the it :
    --          1000 : IAC
    --          1001 : Beacon
    --   0000 - 0111 : ACP[0-7]
    queue_it_num          : out std_logic_vector(3 downto 0);

    -- BuPvcs register.
    vcs_enable   : in  std_logic; -- Virtual carrier sense enable.
    vcs          : in  std_logic_vector(25 downto 0); -- Time tag at which VCS should end
    reset_vcs    : out std_logic; -- reset vcs_enable
    
    -- BUPControl register
    reg_cntxtsel   : in std_logic; -- 0: select BCON context ; 
                                   -- 1: select ACP[0-7] context
    -- low power clock freq selection : 0 : 32kHz ; 1 : 32.768kHz
    reg_clk32sel   : in  std_logic_vector(1 downto 0); 
    
    -- BuPcount register (Durations expressed in us).
    reg_txstartdel : in  std_logic_vector(2 downto 0); -- TX start delay
    reg_macslot    : in  std_logic_vector(7 downto 0); -- MAC slots.
    reg_txsifsb    : in  std_logic_vector(5 downto 0); -- SIFS period after TX (modem b)
    reg_rxsifsb    : in  std_logic_vector(5 downto 0); -- SIFS period after RX (modem b)
    reg_txsifsa    : in  std_logic_vector(5 downto 0); -- SIFS period after TX (modem a)
    reg_rxsifsa    : in  std_logic_vector(5 downto 0); -- SIFS period after RX (modem a)
    reg_sifs       : in  std_logic_vector(5 downto 0); -- SIFS after CCAidle or
                                                       -- absolute count events
    -- Events to trigger the SIFS counter
    tx_end              : in  std_logic; -- end of transmitted packet
    rx_end              : in  std_logic; -- end of received packet
    phy_cca_ind         : in  std_logic; -- CCA status
    bup_sm_idle         : in  std_logic; -- no packet in progress when high
    -- Indicates what was the previous packet (TX or RX)
    rx_packet_type      : in  std_logic;  -- 0 : modem b RX packet; 1 modem a RX packet
    tx_packet_type      : in  std_logic;  -- 0 : modem b TX packet; 1 modem a TX packet
    tximmstop_sm        : in  std_logic; -- Immediate stop from the state machines
    
    --------------------------------------------
    -- Absolute count timers
    --------------------------------------------
    -- BuPabscnt registers.
    reg_abstime0          : in  std_logic_vector(25 downto 0);
    reg_abstime1          : in  std_logic_vector(25 downto 0);
    reg_abstime2          : in  std_logic_vector(25 downto 0);
    reg_abstime3          : in  std_logic_vector(25 downto 0);
    reg_abstime4          : in  std_logic_vector(25 downto 0);
    reg_abstime5          : in  std_logic_vector(25 downto 0);
    reg_abstime6          : in  std_logic_vector(25 downto 0);
    reg_abstime7          : in  std_logic_vector(25 downto 0);
    reg_abstime8          : in  std_logic_vector(25 downto 0);
    reg_abstime9          : in  std_logic_vector(25 downto 0);
    reg_abstime10         : in  std_logic_vector(25 downto 0);
    reg_abstime11         : in  std_logic_vector(25 downto 0);
    reg_abstime12         : in  std_logic_vector(25 downto 0);
    reg_abstime13         : in  std_logic_vector(25 downto 0);
    reg_abstime14         : in  std_logic_vector(25 downto 0);
    reg_abstime15         : in  std_logic_vector(25 downto 0);
    -- Pulse interrupt sent when absolute counter time tag is reached.
    abscount_it           : out std_logic_vector(num_abstimer_g-1 downto 0);

    --------------------------------------------
    -- Diag ports
    --------------------------------------------
    bup_timers_diag     : out std_logic_vector(7 downto 0)
    );

end bup2_timers;
