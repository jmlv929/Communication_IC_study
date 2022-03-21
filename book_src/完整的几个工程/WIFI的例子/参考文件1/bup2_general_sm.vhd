
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILDBuP2
--    ,' GoodLuck ,'      RCSfile: bup2_general_sm.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.29  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : General BuP2 state machine.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_sm/vhdl/rtl/bup2_general_sm.vhd,v  
--  Log: bup2_general_sm.vhd,v  
-- Revision 1.29  2006/03/31 12:04:33  Dr.A
-- #BugId:2356#
-- Removed delay on CCA and VCS indication when signals go low.
--
-- Revision 1.28  2006/02/03 08:36:23  Dr.A
-- #BugId:1140#
-- Support of IAC IFS
--
-- Revision 1.27  2005/03/29 08:17:08  Dr.A
-- #BugId:1163#
-- Go to busy state after Modem error.
--
-- Revision 1.26  2005/03/25 11:11:45  Dr.A
-- #BugId:1152#
-- Removed ARTIM counter
--
-- Revision 1.25  2005/03/22 10:13:44  Dr.A
-- #BugId:1149,1152#
-- (1149) IAC txenable not reset when TXimmstop and CCA idle.
-- (1152) Rewrote arrival time counter
--
-- Revision 1.24  2005/02/22 17:02:56  Dr.A
-- #BugId:1086#
-- CCA busy indication delayed to avoid discarding a TX queue in the timers.
--
-- Revision 1.23  2005/02/18 16:21:00  Dr.A
-- #BugId:1070#
-- iacaftersifs bit is set if iac_txenable occurs in the last txstartdel us of the complete SIFS period.
--
-- Revision 1.22  2005/02/10 12:54:38  Dr.A
-- #BugId:903#
-- Added rx_abort to fsm diag
--
-- Revision 1.21  2005/02/09 17:48:20  Dr.A
-- #BugId:1016#
-- Listen to CCA during NORMSIFS
--
-- Revision 1.20  2005/01/21 15:41:53  Dr.A
-- #BugId:822,978#
-- TX immediate stop debug. Added output to timers.
--
-- Revision 1.19  2005/01/13 14:02:15  Dr.A
-- #BugId:903,956#
-- New diag ports (903)
-- Rewrote RX state machine for fake bytes and control structure memory accesses. 'rx' signal to the memory sequencer now comes from the RX state machine (956)
--
-- Revision 1.18  2005/01/05 17:05:26  Dr.A
-- #BugId:606#
-- rxabort_end not generated at end of rx_state if next state is rx_abort_state
--
-- Revision 1.17  2004/12/23 16:03:13  Dr.A
-- #BugId:606#
-- rx_abortend generated when leaving rx_state or rx_abort_state, whatever the next state is.
--
-- Revision 1.16  2004/12/22 17:09:08  Dr.A
-- #BugId:906#
-- Removed ring buffer mechanism and added new checks for end of buffer.
--
-- Revision 1.15  2004/12/20 17:00:28  Dr.A
-- #BugId:850#
-- Added IAC after SIFS mechanism.
--
-- Revision 1.14  2004/12/17 12:53:06  Dr.A
-- #BugId:606#
-- Reset A1 match interrupt flag at beginning of packet
--
-- Revision 1.13  2004/12/10 10:36:29  Dr.A
-- #BugId:606#
-- Added RX abort after address 1 mismatch
--
-- Revision 1.12  2004/05/18 10:47:02  Dr.A
-- Only one input port for phy_cca_ind.
--
-- Revision 1.11  2004/03/02 12:07:31  Dr.F
-- beautified reset_txenable process to satisfy equivalence checking.
--
-- Revision 1.10  2004/02/10 18:29:35  Dr.F
-- removed test on bup_testmode = 01.
--
-- Revision 1.9  2004/02/05 18:27:24  Dr.F
-- removed modsel.
--
-- Revision 1.8  2004/01/29 17:55:05  Dr.F
-- fixed problem on iac transmission.
--
-- Revision 1.7  2004/01/26 08:47:53  Dr.F
-- beautify.
--
-- Revision 1.6  2004/01/14 12:57:21  pbressy
-- added iac_txenable to sensitivity list
--
-- Revision 1.5  2004/01/06 15:03:53  pbressy
-- bugzilla 331 fix
--
-- Revision 1.4  2003/12/09 15:52:52  Dr.F
-- added rx_mode_and_rxsifs.
--
-- Revision 1.3  2003/11/28 12:53:42  Dr.F
-- changed condition to reset txenable.
--
-- Revision 1.2  2003/11/25 07:50:27  Dr.F
-- rx_mode = 1 even if in rxsifs_state.
--
-- Revision 1.1  2003/11/19 16:26:19  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Taken from revision 1.15 of bup_general_sm.
--
-- Revision 1.15  2003/11/13 18:31:10  Dr.F
-- added arrival time check and interrupt generation on VCS event (idle or busy).
--
-- Revision 1.14  2003/10/09 07:05:34  Dr.F
-- added diag port.
--
-- Revision 1.13  2003/04/18 14:36:53  Dr.F
-- added modsel handling.
--------------------------------------------------------------------------------


library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 


entity bup2_general_sm is
  port (
    --------------------------------------
    -- Clocks & Reset
    -------------------------------------- 
    hresetn            : in  std_logic; -- AHB reset line.
    hclk               : in  std_logic; -- AHB clock line.
    --------------------------------------
    -- Generic BuP Registers
    -------------------------------------- 
    bup_sm_idle        : out std_logic; -- indicates that the state machines 
                                        -- are in idle mode
    -- Pulse to reset bcon_txenable.
    reset_bcon_txen    : out std_logic;
    -- Pulse to reset acp_txenable.
    reset_acp_txen     : out std_logic_vector(7 downto 0);
    -- Pulse to reset iac_txenable.
    reset_iac_txen     : out std_logic;
    -- queue that generated the it :
    --          1000 : IAC
    --          1001 : Beacon
    --   0000 - 0111 : ACP[0-7]
    queue_it_num       : in  std_logic_vector(3 downto 0);

    --------------------------------------
    -- Commands from BuP Registers
    -------------------------------------- 
    vcs_enable         : in  std_logic; -- Virtual carrier sense enable.
    tximmstop          : in  std_logic; -- Immediate stop
    
    --------------------------------------
    -- Modem test mode
    -------------------------------------- 
    testenable         : in  std_logic; -- enable BuP test mode
    bup_testmode       : in  std_logic_vector(1 downto 0); -- type of test
    --------------------------------------
    -- Interrupt Generator
    -------------------------------------- 
    ccabusy_it         : out std_logic; -- pulse for interrupt on CCA BUSY
    ccaidle_it         : out std_logic; -- pulse for interrupt on CCA IDLE
    --------------------------------------
    -- Timers
    -------------------------------------- 
    backoff_timer_it   : in  std_logic; -- interrupt when backoff reaches 0.
    sifs_timer_it      : in  std_logic; -- interrupt when sifs reaches 0.
    txstartdel_flag    : in  std_logic; -- Flag set when SIFS count reaches txstartdel.
    iac_without_ifs    : in  std_logic; -- flag set when no IFS in IAC queue
    --------------------------------------
    -- Modem
    -------------------------------------- 
    phy_cca_ind        : in  std_logic; -- CCA status from modems
                                        -- 0 => no signal detected 
                                        -- 1 => busy channel detected 
    phy_rxstartend_ind : in  std_logic; -- preamble detected 
    --------------------------------------
    -- RX/TX state machine
    -------------------------------------- 
    rxend_stat         : in  std_logic_vector(1 downto 0); -- RX end status.
    rx_end             : in  std_logic; -- end of packet and no auto resp needed
    rx_err             : in  std_logic; -- unexpected end of packet 
    tx_end             : in  std_logic; -- end of transmit packet
    iac_txenable       : in  std_logic;
    iacaftersifs_ack   : in  std_logic; -- IAC after SIFS sticky bit acknowledge
    --
    tx_mode            : out std_logic; -- Bup in transmit mode
    rx_mode            : out std_logic; -- Bup in reception mode
    rxv_macaddr_match  : out std_logic; -- Address1 match flag.
    rx_abortend        : out std_logic; -- End of packet or end of RX abort.
    iacaftersifs       : out std_logic;
    --------------------------------------
    -- Diag
    --------------------------------------
    gene_sm_diag       : out std_logic_vector(2 downto 0)

    );
end bup2_general_sm;
