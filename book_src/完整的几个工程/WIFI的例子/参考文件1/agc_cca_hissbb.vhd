
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--       ------------      Project :  Wild RF
--    ,' GoodLuck ,'      RCSfile: agc_cca_hissbb.vhd,v   
--   '-----------'     Only for Study   
--
--  Revision: 1.39   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : AGC FSM for the HISS interface on the RF side.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/agc_cca_hissbb/vhdl/rtl/agc_cca_hissbb.vhd,v  
--  Log: agc_cca_hissbb.vhd,v  
-- Revision 1.39  2006/02/27 15:19:49  Dr.J
-- #BugId:1509#
-- RF Interrupt bug correction
--
-- Revision 1.38  2006/02/01 08:33:06  Dr.J
-- #BugId:1503#
-- Debugged the agc_busy generation
--
-- Revision 1.37  2005/04/08 14:01:14  Dr.J
-- #BugId:1197#
-- Debugged rx_onoff_req
--
-- Revision 1.36  2005/04/06 08:15:18  Dr.J
-- #BugId:720#
-- Debugged the reset of the edtransmode register.
--
-- Revision 1.35  2005/03/30 11:41:41  Dr.J
-- #BugId:1170#
-- Debugged the sw_rfoff during energy detect mode
--
-- Revision 1.34  2005/03/23 08:26:44  Dr.J
-- #BugId:720#
-- Added Energy Detect Mode in b/g
--
-- Revision 1.33  2005/03/10 14:04:45  Dr.J
-- #BugId:1126#
-- Debugged the diag port
--
-- Revision 1.32  2005/03/09 16:00:05  Dr.J
-- #BugId:1126#
-- Updated the diag port
--
-- Revision 1.31  2005/03/09 10:30:20  arisse
-- #BugId:1124#
-- Modify waitting time during delay_init_rx state from 5 to 33.
--
-- Revision 1.30  2005/03/01 16:45:24  Dr.J
-- #BugId:854#
-- Keep the phy_cca_ind high during the reception when a rate_error append.
--
-- Revision 1.29  2005/02/02 16:13:39  Dr.J
-- #BugId:977#
-- Set to one the cca_busy after wait_deldc state in A mode and during the search_sfd state in B mode
--
-- Revision 1.28  2005/01/27 17:09:15  Dr.J
-- #BugId:977#
-- Removed the delay added before to stop the 11b modem
--
-- Revision 1.27  2005/01/20 15:32:31  Dr.J
-- #BugId:837#
-- Debugged the overflow during the duration computing.
--
-- Revision 1.26  2005/01/11 16:49:25  Dr.J
-- #BugId:837,907#
-- Debugged the phy_cca_ind in 11a.
-- Removed resynchro of sw_rfoff_req.
--
-- Revision 1.25  2005/01/11 09:46:44  Dr.J
-- #BugId:952,907,693#
-- Added selection of the modem iin rx done by the AGC
-- Removed the agc_rfoff when a sw_rfoff is received
-- Updated the wait_cs state to support the new timing of the WILDRF's agc.
-- Updated to use the phy_rxstartend_ind.
-- Added some resynchro.
--
-- Revision 1.24  2004/12/21 13:51:43  Dr.J
-- #BugId:921,837,606,907#
-- Added the stop rx when the packet address does not match or when the modems reports a error (rxe_errorstat).
-- Added rampdown delay.
-- Added Software immediate stop.
-- Changed the length calculation in 11a mode to save gate count.
--
-- Revision 1.23  2004/12/14 16:58:42  Dr.J
-- #BugId:643,837,640#
-- Added WiLDRF Interrupt pulse for the Radio Controller
-- Provided RSSI value, CCA Additionnal infos and RX Antenna to the BuP
-- Added calculation of the phy_cca_ind
-- Updated port map to support the software immediate stop and the address doe not match.
--
-- Revision 1.22  2004/09/09 15:26:45  Dr.C
-- Added synchronization FFs on modem b signals
--
-- Revision 1.21  2004/07/13 15:33:54  Dr.C
-- Corrected energy detect setting and carrier sense
--
-- Revision 1.20  2004/03/24 16:34:18  Dr.C
-- Added input select_clk80 and changed constatnts
--
-- Revision 1.19  2004/03/24 09:18:18  Dr.C
-- Delayed rx_11a_enable when the modem is transmitting, for correct reset of the modemA state machine.
--
-- Revision 1.18  2004/01/30 09:34:18  rrich
-- Added global signals for testbench access across hierarchy.
--
-- Revision 1.17  2003/12/19 18:07:38  ahemani
-- Hiss stream is enable in 11b only mode as well when going to the
-- wait_cs state
--
-- Revision 1.16  2003/12/19 13:26:43  ahemani
-- gt_62dbm signal commented out. Should be removed during the code cleanup phase.
-- In 11a only made cca_busy and energy detect were being asserted when signal
-- crossed -62dbm threhold but not deasserted when the signal went below -62dbm
-- This has been fixed.
--
-- Revision 1.15  2003/12/17 12:01:42  ahemani
-- rx_11a_enable deasserted after asserting modem_a_rst_n
-- cca_busy_internal(cca_busy) lowered if cs -ve for 11a only
-- when returning to idle
--
-- Revision 1.14  2003/12/16 09:02:46  ahemani
-- reutrn to idle state added to remove the modem a reset.
--
-- Revision 1.13  2003/12/16 08:33:30  ahemani
-- Modem A is reset when noise is detected
--
-- Revision 1.12  2003/12/12 12:48:23  ahemani
-- Fixed the problem with timer logic.
--
-- Revision 1.11  2003/12/12 10:44:05  ahemani
-- In wait_cs state when 11b/g is detected modem a's is not immediately
-- disabled. A new signal to reset modem a is asserted(active low) and is
-- deasserted five cycles later in wait2_signal_valid state.
-- Three cycles in the wait2_signal_valid state the modem is disable, i.e. two cycles before deasserting the modem a reset
--
-- Revision 1.10  2003/12/09 08:31:32  Dr.F
-- replaced DEL_128_US_CT by DEL_144_US_CT.
--
-- Revision 1.9  2003/12/04 07:47:29  ahemani
-- wait_16us state added between wait_cs and continue_reception_11a
--
-- Revision 1.8  2003/12/03 15:54:10  ahemani
-- Fixed the problem of not making transition to delay_init_rx
--
-- Revision 1.7  2003/12/03 14:44:25  Dr.F
-- redebugged diag port.
--
-- Revision 1.6  2003/12/03 14:36:55  Dr.F
-- debugged diag port assigment.
--
-- Revision 1.5  2003/12/03 13:25:04  ahemani
-- 126 us delay changed to 128 us
-- delay_rx_init state added to delay the assertion of rx_init compared to rx_11b_enable
-- diagnostic port added and changes related to it.
--
-- Revision 1.4  2003/11/26 16:36:26  Dr.C
-- Force rx_11a_enable to 0 when a_rxstartend_ind is low after a reception.
--
-- Revision 1.3  2003/11/25 07:30:42  Dr.F
-- added 1 us before cca_busy falls down to let modem b to finish its rx processing.
--
-- Revision 1.2  2003/11/21 13:46:13  ahemani
-- phy_ccarst_n changed to phy_ccarst_req with positive high sense
-- Condition for continuing relaxed to just checking for sig valid on only.
--
-- Revision 1.1  2003/11/17 17:10:07  ahemani
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;

--library agc_cca_hissbb_rtl; 
library work;
--use agc_cca_hissbb_rtl.agc_cca_hissbb_pkg.all;
use work.agc_cca_hissbb_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity agc_cca_hissbb is
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk     : in STD_LOGIC;             -- 80 MHz
    reset_n : in STD_LOGIC;

    --------------------------------------
    -- Registers
    --------------------------------------

    -- cca_mode used only for 11b
    -- 000: Reserved, 001: Carrier Sense only, 010: Carrier Sense Only
    -- 011: Carrier sense with energy above threshold
    -- 100: Carrier sense with timer
    -- 101: A combination of carrier sense and energy above threshold
    cca_mode     : in STD_LOGIC_VECTOR(2 downto 0);
    modeabg      : in STD_LOGIC_VECTOR(1 downto 0);  -- Reception Mode 11a(01) 11b(10) 11g(00)
    deldc2       : in STD_LOGIC_VECTOR(4 downto 0);  -- Delay for DC loop convergence
    longslot     : in STD_LOGIC;        -- Long slot mode : 1
                                        -- short slot mode: 0
    wait_cs_max  : in STD_LOGIC_VECTOR(3 downto 0);  -- Max time to wait for cca_cs
    wait_sig_max : in STD_LOGIC_VECTOR(3 downto 0);  -- Max time to wait for
                                                     -- signal valid on
    select_clk80 : in STD_LOGIC;    -- Indicates clock frequency: '1' = 80 MHz
                                    --                            '0' = 44 MHz
    -- MDMgADDESTMDUR register.
    reg_addestimdura : in STD_LOGIC_VECTOR(3 downto 0); -- additional time duration 11a
    reg_addestimdurb : in STD_LOGIC_VECTOR(3 downto 0); -- additional time duration 11b
    reg_rampdown     : in STD_LOGIC_VECTOR(2 downto 0); -- ramp-down time duration
    -- MDMgAGCCCA register.
    reg_edtransmode  : in STD_LOGIC; -- Energy Detect Transitional Mode
    reg_edmode       : in STD_LOGIC; -- Energy Detect Mode

    edtransmode_reset : out STD_LOGIC; -- Reset the edtransmode register     

    ---------------------------------------------------------------------------
    -- Modem 11a
    ---------------------------------------------------------------------------
    cp2_detected      : in  STD_LOGIC;  -- Indicates synchronization has been found
    rxv_length        : in  STD_LOGIC_VECTOR(11 downto 0); -- RX PSDU length  
    rxv_datarate      : in  STD_LOGIC_VECTOR( 3 downto 0); -- PSDU rec. rate
    rxe_errorstat     : in  STD_LOGIC_VECTOR( 1 downto 0); -- RX Error status
    rx_11a_enable     : out STD_LOGIC;  -- Enables .11a RX path block
    modem_a_fsm_rst_n : out STD_LOGIC;  -- reset modem a

    ---------------------------------------------------------------------------
    -- Modem 11b
    ---------------------------------------------------------------------------
    sfd_found        : in  STD_LOGIC;   -- SFD has been detected when hi
    packet_length    : in  STD_LOGIC_VECTOR (15 downto 0);  -- Packet length in us 
    
    energy_detect    : out STD_LOGIC;   -- Energy above threshold
    cca_busy         : out STD_LOGIC;   -- Indicates correlation result:
                                        -- a signal is present when high
    init_rx          : out STD_LOGIC;   -- Initializes the modem 11b 
    rx_11b_enable    : out STD_LOGIC;   -- Enables .11a RX path bloc

    ---------------------------------------------------------------------------
    -- BUP
    ---------------------------------------------------------------------------
    phy_rxstartend_ind : in  STD_LOGIC;                      -- Indicates start/end of Rx packet
    phy_txstartend_req : in  STD_LOGIC;                      -- Indicates start/end of transmissi
    phy_ccarst_req     : in  STD_LOGIC;                      -- Reset AGC procedu
    rxv_macaddr_match  : in  STD_LOGIC;                      -- Stop the reception because the mac 
                                                             -- addresss does not match  

    phy_ccarst_conf    : out STD_LOGIC;                      -- Acknowledges reset request
    phy_cca_ind        : out STD_LOGIC;                      -- Indicates to occupation of the medium 
    rxv_rssi           : out STD_LOGIC_VECTOR (6 downto 0);  -- Value of measured RSSI
    rxv_rxant          : out STD_LOGIC;                      -- Antenna used
    rxv_ccaaddinfo     : out STD_LOGIC_VECTOR (15 downto 8); -- Additionnal data
    
    select_rx_ab       : out STD_LOGIC;                      -- Selection Rx A or B for BuP2Modem IF
    ---------------------------------------------------------------------------
    -- Radio Controller
    ---------------------------------------------------------------------------
    cca_flags          : in  STD_LOGIC_VECTOR (5 downto 0);
                                         -- CCA marcker flag
    cca_add_flags      : in  STD_LOGIC_VECTOR (15 downto 0);
                                         -- CCA additionnal info
    cca_flags_marker   : in  STD_LOGIC;  -- Pulse to indicate cca_flags are val
    cca_cs             : in  STD_LOGIC_VECTOR (1 downto 0);
                                         -- Carrier sense informati
    cca_cs_valid       : in  STD_LOGIC;  -- Pulse to indicate cca_cs are valid
    agc_disb           : in  STD_LOGIC;  -- Disable AGC procedure
    agc_rxonoff_conf   : in  STD_LOGIC;  -- Acknowledges start/end of Rx packet
    sw_rfoff_req       : in  STD_LOGIC;  -- Request by the SW to switch to IDLE the WiLDRF  

    a_b_mode           : out STD_LOGIC;  -- Indicates the reception mode
    hiss_stream_enable : out STD_LOGIC;  -- Enable Hiss master to receive data
    agc_rxonoff_req    : out STD_LOGIC;  -- Indicates start/end of Rx packet
    agc_rfint          : out STD_LOGIC;  -- Interrupt from WiLDRF  
    agc_rfoff          : out STD_LOGIC;  -- Request to switch to IDLE the WiLDRF  
    agc_busy           : out STD_LOGIC;  -- Indicates start/end of Rx packet

    ---------------------------------------------------------------------------
    -- WLAN Indication
    ---------------------------------------------------------------------------
    wlanrxind            : out std_logic; -- Indicates a wlan reception
    ---------------------------------------------------------------------------
    -- Diag port
    ---------------------------------------------------------------------------
    agc_cca_hissbb_diag_port : out STD_LOGIC_VECTOR (15 downto 0)
    );

end agc_cca_hissbb;
