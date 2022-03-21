
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLDBuP2
--    ,' GoodLuck ,'      RCSfile: bup2_registers.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.27  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : WILD Burst Processor 2 Registers.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_registers/vhdl/rtl/bup2_registers.vhd,v  
--  Log: bup2_registers.vhd,v  
-- Revision 1.27  2006/03/13 08:43:13  Dr.A
-- #BugId:2328#
-- Increased size of reg_clk32cntl to support 131.072 kHz config
--
-- Revision 1.26  2006/02/03 08:34:37  Dr.A
-- #BugId:1140#
-- Send IAC IFS write indication to the timers
--
-- Revision 1.25  2006/02/02 08:28:23  Dr.A
-- #BugId:1213#
-- Added bit to ignore VCS for channel assessment
--
-- Revision 1.24  2005/10/21 13:22:07  Dr.A
-- #BugId:1246#
-- Added absolute count timers
--
-- Revision 1.23  2005/03/29 08:45:44  Dr.A
-- #BugId:907#
-- Added TX force disable
--
-- Revision 1.22  2005/03/25 11:12:16  Dr.A
-- #BugId:1152#
-- Removed ARTIM counter
--
-- Revision 1.21  2005/03/22 10:15:21  Dr.A
-- #BugId:1152#
-- Arrival time counter enable. Cleaned write_bckoff ports.
--
-- Revision 1.20  2005/02/10 15:20:32  Dr.A
-- #BugId:1041#
-- Use apb0 instead of apb1 to reset CHASSTIM
--
-- Revision 1.19  2005/02/09 16:11:27  Dr.A
-- #BugId:1037#
-- RX buffer registers all aligned on 8bytes boundary
--
-- Revision 1.18  2004/12/23 10:19:56  Dr.A
-- #BugId:835#
-- rxrssi bit 8 stuck to 1 in register read
--
-- Revision 1.17  2004/12/22 17:10:53  Dr.A
-- #BugId:850#
-- Connected iacaftersifs acknowledge
--
-- Revision 1.16  2004/12/20 12:53:03  Dr.A
-- #BugId:702#
-- Added ACK time-out interrupt acknowledge
--
-- Revision 1.15  2004/12/17 13:03:13  Dr.A
-- #BugId:912#
-- Removed 'enable' register
--
-- Revision 1.14  2004/12/10 10:10:39  Dr.A
-- #BugId:640#
-- Added registers for ccaaddinfo and rxant.
-- rxabtcnt min value set to 13.
--
-- Revision 1.13  2004/12/03 14:15:58  Dr.A
-- #BugId:606#
-- Added registers from spec v2.3, for bugs #606, #821/822, #850, #702.
--
-- Revision 1.12  2004/11/10 10:34:01  Dr.A
-- #BugId:837#
-- Added registers for Channel assessment and multi ssid
--
-- Revision 1.11  2004/11/09 14:11:10  Dr.A
-- #BugId:835#
-- RSSI field is now only 7 bits
--
-- Revision 1.10  2004/04/08 14:38:17  Dr.A
-- Added register on prdata busses.
--
-- Revision 1.9  2004/02/06 14:45:05  Dr.F
-- added testdata_in.
--
-- Revision 1.8  2004/02/05 18:28:11  Dr.F
-- removed modsel.
--
-- Revision 1.7  2004/01/21 17:40:54  Dr.F
-- beautified version register.
--
-- Revision 1.6  2004/01/13 07:31:12  Dr.F
-- fixed sensitivity list.
--
-- Revision 1.5  2003/12/12 12:53:55  pbressy
-- correct error on apb write cycle, apb1 insteand of apb0
-- corrected error on apb write cycle, apb1 insteand of apb0
--
-- Revision 1.4  2003/12/11 17:46:10  Dr.F
-- removed multiple drive.
--
-- Revision 1.3  2003/12/11 09:56:55  Dr.F
-- removed multiple drive on int_rssi.
--
-- Revision 1.2  2003/12/05 08:36:48  pbressy
-- added new registers (Coldfire)
--
-- Revision 1.1  2003/11/19 16:25:34  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------
-- Taken from revision 1.9 of bup_registers
--
-- Revision 1.9  2003/11/13 18:42:44  Dr.F
-- added SIFS and low power clock freq selection.
--
-- Revision 1.8  2003/10/21 13:05:38  Dr.A
-- Debugged enablea/b read access.
--
-- Revision 1.7  2003/10/17 13:48:59  sbizet
-- Debugged reg_enablea/b
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.std_logic_unsigned.ALL; 
 
--library bup2_registers_rtl; 
library work;
--use bup2_registers_rtl.bup2_registers_pkg.all;
use work.bup2_registers_pkg.all;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity bup2_registers is
  generic (
    num_queues_g    : integer := 8; -- number of data queues.
    num_abstimer_g  : integer := 16 -- number of absolute count timers (max is 16)
    );
  port (
    --------------------------------------------
    -- clock and reset
    --------------------------------------------
    reset_n         : in  std_logic; -- Reset.
    pclk            : in  std_logic; -- APB clock.

    --------------------------------------------
    -- APB slave 0
    --------------------------------------------
    apb0_psel       : in  std_logic; -- Device select.
    apb0_penable    : in  std_logic; -- Defines the enable cycle.
    apb0_paddr      : in  std_logic_vector( 7 downto 0); -- Address.
    apb0_pwrite     : in  std_logic; -- Write signal.
    apb0_pwdata     : in  std_logic_vector(31 downto 0); -- Write data.
    --
    apb0_prdata     : out std_logic_vector(31 downto 0); -- Read data.
    
    --------------------------------------------
    -- APB slave 1
    --------------------------------------------
    apb1_psel       : in  std_logic; -- Device select.
    apb1_penable    : in  std_logic; -- Defines the enable cycle.
    apb1_paddr      : in  std_logic_vector( 7 downto 0); -- Address.
    apb1_pwrite     : in  std_logic; -- Write signal.
    apb1_pwdata     : in  std_logic_vector(31 downto 0); -- Write data.
    --
    apb1_prdata     : out std_logic_vector(31 downto 0); -- Read data.
    
    --------------------------------------------
    -- BuP registers inputs
    --------------------------------------------
    -- BuPtime register when read
    bup_timer       : in  std_logic_vector(25 downto 0);
    -- Beacon backoff register when read
    bcon_bkoff_timer: in  std_logic_vector( 9 downto 0);
    -- ACP backoff registers when read
    acp7_bkoff_timer: in  std_logic_vector( 9 downto 0);
    acp6_bkoff_timer: in  std_logic_vector( 9 downto 0);
    acp5_bkoff_timer: in  std_logic_vector( 9 downto 0);
    acp4_bkoff_timer: in  std_logic_vector( 9 downto 0);
    acp3_bkoff_timer: in  std_logic_vector( 9 downto 0);
    acp2_bkoff_timer: in  std_logic_vector( 9 downto 0);
    acp1_bkoff_timer: in  std_logic_vector( 9 downto 0);
    acp0_bkoff_timer: in  std_logic_vector( 9 downto 0);
    -- BuPintstat register.
    reg_iacaftersifs: in  std_logic; -- Set when IAC tx request arrived after SIFS
    reg_txqueue     : in  std_logic_vector( 3 downto 0); -- Tx packet queue.
    -- Reception and transmission status. Bit set when:
    reg_fcserr_stat : in  std_logic; -- FCS is incorrect.
    reg_fullbuf_stat: in  std_logic; -- Rx buffer full, packet truncated.
    reg_a1match_stat: in  std_logic; -- Address1 field matches BUPADDR1L/H reg.
    reg_errstat     : in  std_logic_vector( 1 downto 0); -- Reception status.
    reg_rxendstat   : in  std_logic_vector( 1 downto 0); -- RX reception status.
    reg_txendstat   : in  std_logic_vector( 1 downto 0); -- TX reception status.
    -- Interrupt sources:
    reg_ackto_src   : in  std_logic; -- ACK time-out status.
    reg_genirq_src  : in  std_logic; -- Software interrupt.
    -- Absolute counter interrupts.
    reg_abscntirq_src : in  std_logic;
    reg_abscntfiq_src : in  std_logic;
    reg_abscnt_src  : in  std_logic_vector(num_abstimer_g-1 downto 0);
    reg_timewrap_src: in  std_logic; -- Wrapping around of buptime.
    reg_ccabusy_src : in  std_logic; -- Ccabusy.
    reg_ccaidle_src : in  std_logic; -- Ccaidle.
    reg_rxstart_src : in  std_logic; -- Rx packet start.
    reg_rxend_src   : in  std_logic; -- Rx packet end.
    reg_txend_src   : in  std_logic; -- Tx packet end.
    reg_txstartirq_src : in  std_logic; -- Tx packet start.
    reg_txstartfiq_src : in  std_logic; -- Tx packet start (fast interrupt).
    -- BuPinttime register.
    reg_inttime     : in  std_logic_vector(25 downto 0); -- Interrupt time tag.
    -- BuPmachdr register: values from the received MAC header.
    reg_durid       : in  std_logic_vector(15 downto 0); -- Duration/Id field.
    reg_frmcntl     : in  std_logic_vector(15 downto 0); -- Frame control field.
    -- BuPTestdata input register for validation purpose
    testdata_in     : in  std_logic_vector(31 downto 0);
    -- Channel assessment timers
    reg_chassbsy    : in  std_logic_vector(25 downto 0);
    reg_chasstim    : in  std_logic_vector(25 downto 0);
    -- RX control structure 0 fields:
    -- service field of received packet
    rxserv          : in std_logic_vector(15 downto 0);
    rxlen           : in std_logic_vector(11 downto 0); -- length of PSDU received
    -- RX control structure 1 fields:
    rxccaaddinfo    : in std_logic_vector( 7 downto 0); -- CCA additional information
    rxrate          : in std_logic_vector( 3 downto 0); -- Rate received packet
    rxant           : in std_logic; -- Antenna used for reception.
    -- Radio signal strength of received packet
    rxrssi          : in std_logic_vector(6 downto 0);

    --------------------------------------------
    -- BuP Registers outputs
    --------------------------------------------
    -- BuPcntl register.
    reg_forcetxdis  : out std_logic; -- Disable all TX queues.
    reg_tximmstop   : out std_logic; -- TX immediate stop.
    reg_ccarst      : out std_logic; -- Reset the CCA state machines.
    reg_enrxabort   : out std_logic; -- Enable abort of RX packets
    reg_bufempty    : out std_logic; -- '1' when RX buffer has been emptied.
    genirq          : out std_logic; -- Software interrupt (pulse).
    reg_cntxtsel    : out std_logic; -- Select context.
    -- low power clock freq selection : 0 : 32kHz; 1 : 32.768kHz
    reg_clk32sel    : out std_logic_vector(1 downto 0); 
    -- BuPvcs register.
    reg_vcsenable   : out std_logic; -- Virtual carrier sense enable.
    reg_vcs         : out std_logic_vector(25 downto 0); -- VCS time tag.
    -- BuPtime register.
    reg_buptimer    : out std_logic_vector(25 downto 0); -- Time counter written.
    -- BuPabscnt registers.
    reg_abstime0          : out std_logic_vector(25 downto 0);
    reg_abstime1          : out std_logic_vector(25 downto 0);
    reg_abstime2          : out std_logic_vector(25 downto 0);
    reg_abstime3          : out std_logic_vector(25 downto 0);
    reg_abstime4          : out std_logic_vector(25 downto 0);
    reg_abstime5          : out std_logic_vector(25 downto 0);
    reg_abstime6          : out std_logic_vector(25 downto 0);
    reg_abstime7          : out std_logic_vector(25 downto 0);
    reg_abstime8          : out std_logic_vector(25 downto 0);
    reg_abstime9          : out std_logic_vector(25 downto 0);
    reg_abstime10         : out std_logic_vector(25 downto 0);
    reg_abstime11         : out std_logic_vector(25 downto 0);
    reg_abstime12         : out std_logic_vector(25 downto 0);
    reg_abstime13         : out std_logic_vector(25 downto 0);
    reg_abstime14         : out std_logic_vector(25 downto 0);
    reg_abstime15         : out std_logic_vector(25 downto 0);
    -- Register for abscount interrupt type
    reg_abscnt_irqsel     : out std_logic_vector(num_abstimer_g-1 downto 0);
    -- BuPintmask register: enable/disable interrupts on the following events.
    -- Absolute counter interrupt.
    reg_abscnt_en   : out std_logic_vector(num_abstimer_g-1 downto 0);
    reg_timewrap_en : out std_logic; -- Wrapping around of buptime.
    reg_ccabusy_en  : out std_logic; -- Ccabusy.
    reg_ccaidle_en  : out std_logic; -- Ccaidle.
    reg_rxstart_en  : out std_logic; -- Rx packet start.
    reg_rxend_en    : out std_logic; -- Rx packet end.
    reg_txend_en    : out std_logic; -- Tx packet end.
    reg_txstartirq_en : out std_logic; -- Tx packet start.
    reg_txstartfiq_en : out std_logic; -- TX packet start (fast interrupt).
    reg_ackto_en    : out std_logic; -- ACK packet time-out.
    -- BuPintack register: acknowledge of the following interrupts
    reg_iacaftersifs_ack  : out std_logic; -- IAC after SIFS sticky bit.
    reg_genirq_ack  : out std_logic; -- Software interrupt.
    -- Absolute counter interrupt.
    reg_abscnt_ack  : out std_logic_vector(num_abstimer_g-1 downto 0);
    reg_timewrap_ack: out std_logic; -- Wrapping around of buptime.
    reg_ccabusy_ack : out std_logic; -- Ccabusy.
    reg_ccaidle_ack : out std_logic; -- Ccaidle.
    reg_rxstart_ack : out std_logic; -- Rx packet start.
    reg_rxend_ack   : out std_logic; -- Rx packet end.
    reg_txend_ack   : out std_logic; -- Tx packet end.
    reg_txstartirq_ack : out std_logic; -- Tx packet start.
    reg_txstartfiq_ack : out std_logic; -- Tx packet start (fast interrupt).
    reg_ackto_ack   : out std_logic; -- ACK packet time-out.
    -- BuPcount register (Durations expressed in us).
    reg_txdstartdel : out std_logic_vector(2 downto 0); -- TX start delay.
    reg_macslot     : out std_logic_vector(7 downto 0); -- MAC slots.
    reg_txsifsb     : out std_logic_vector(5 downto 0); -- SIFS period after TX (modem b)
    reg_rxsifsb     : out std_logic_vector(5 downto 0); -- SIFS period after RX (modem b)
    reg_txsifsa     : out std_logic_vector(5 downto 0); -- SIFS period after TX (modem a)
    reg_rxsifsa     : out std_logic_vector(5 downto 0); -- SIFS period after RX (modem a)
    reg_sifs        : out std_logic_vector(5 downto 0); -- SIFS after CCAidle or
                                                        -- absolute count events
    -- Buptxcntl_bcon register:
    reg_bcon_bakenable  : out std_logic; -- '1' to enable backoff counter.
    reg_bcon_txenable   : out std_logic; -- '1' to enable packets transmission.
    -- Number of MAC slots to add to create Beacon inter-frame spacing.
    reg_bcon_ifs        : out std_logic_vector( 3 downto 0);
    -- Beacon Backoff counter init value.
    reg_bcon_backoff    : out std_logic_vector( 9 downto 0);
    -- Channel assessment register.
    reg_chassen         : out std_logic; -- Channel assessment enable
    reg_ignvcs          : out std_logic; -- Include VCS in measurement when HIGH
    
    --------------------------------------------
    -- Access Priority Context Registers.
    --------------------------------------------
    -- Buptxcntl_acp7 register:
    reg_acp_bakenable7  : out std_logic; -- '1' to enable backoff counter.
    reg_acp_txenable7   : out std_logic; -- '1' to enable packets transmission.
    -- Number of MAC slots to add to create ACP inter-frame spacing.
    reg_acp_ifs7        : out std_logic_vector( 3 downto 0);
    -- ACP Backoff counter init value.
    reg_acp_backoff7    : out std_logic_vector( 9 downto 0);
    -- Buptxcntl_acp6 register:
    reg_acp_bakenable6  : out std_logic;
    reg_acp_txenable6   : out std_logic;
    reg_acp_ifs6        : out std_logic_vector( 3 downto 0);
    reg_acp_backoff6    : out std_logic_vector( 9 downto 0);
    -- Buptxcntl_acp5 register:
    reg_acp_bakenable5  : out std_logic;
    reg_acp_txenable5   : out std_logic;
    reg_acp_ifs5        : out std_logic_vector( 3 downto 0);
    reg_acp_backoff5    : out std_logic_vector( 9 downto 0);
    -- Buptxcntl_acp4 register:
    reg_acp_bakenable4  : out std_logic;
    reg_acp_txenable4   : out std_logic;
    reg_acp_ifs4        : out std_logic_vector( 3 downto 0);
    reg_acp_backoff4    : out std_logic_vector( 9 downto 0);
    -- Buptxcntl_acp3 register:
    reg_acp_bakenable3  : out std_logic;
    reg_acp_txenable3   : out std_logic;
    reg_acp_ifs3        : out std_logic_vector( 3 downto 0);
    reg_acp_backoff3    : out std_logic_vector( 9 downto 0);
    -- Buptxcntl_acp2 register:
    reg_acp_bakenable2  : out std_logic;
    reg_acp_txenable2   : out std_logic;
    reg_acp_ifs2        : out std_logic_vector( 3 downto 0);
    reg_acp_backoff2    : out std_logic_vector( 9 downto 0);
    -- Buptxcntl_acp1 register:
    reg_acp_bakenable1  : out std_logic;
    reg_acp_txenable1   : out std_logic;
    reg_acp_ifs1        : out std_logic_vector( 3 downto 0);
    reg_acp_backoff1    : out std_logic_vector( 9 downto 0);
    -- Buptxcntl_acp0 register:
    reg_acp_bakenable0  : out std_logic;
    reg_acp_txenable0   : out std_logic;
    reg_acp_ifs0        : out std_logic_vector( 3 downto 0);
    reg_acp_backoff0    : out std_logic_vector( 9 downto 0);
    
    -- Tx register for Immediate Action Control context:
    reg_iac_txenable    : out std_logic; -- '1' to enable packets transmission.
    -- Number of MAC slots to add to create IAC inter-frame spacing.
    reg_iac_ifs         : out std_logic_vector( 3 downto 0);
    
    -- BuPtxptr register: Start address of the transmit buffer.
    reg_buptxptr    : out std_logic_vector(31 downto 0);
    -- BuPrxptr register: Start address of the receive buffer.
    reg_buprxptr    : out std_logic_vector(31 downto 0);
    -- BuPrxoff register: Start address of the next packet to be stored inside
    -- the RX ring buffer.
    reg_rxoff       : out std_logic_vector(15 downto 0);
    -- BuPrxsize register: size in bytes of theRx ring buffer.
    reg_rxsize      : out std_logic_vector(15 downto 0); 
    -- BuPrxunload register: pointer to the next packet to be retreived from 
    reg_rxunload    : out std_logic_vector(15 downto 0); -- RX buffer.
    -- Bupaddr1l/h registers.
    reg_addr1       : out std_logic_vector(47 downto 0); -- Address 1.
    -- Bupaddr1mask register.
    reg_addr1mskh   : out std_logic_vector( 3 downto 0); -- Mask Address1(43:40)
    reg_addr1mskl   : out std_logic_vector( 3 downto 0); -- Mask Address1(27:24)
    -- BuPTest register.
    reg_testenable  : out std_logic; -- '1' for test mode.
    reg_datatype    : out std_logic_vector( 1 downto 0); -- Select test pattern.
    reg_fcsdisb     : out std_logic; -- '0' to enable FCS computation.
    reg_buptestmode : out std_logic_vector( 1 downto 0); -- Select test type.
    -- BuPTestdata register read (transmit mode).
    -- Continuous transmit test mode: data pattern for transmission test.
    reg_testpattern : out std_logic_vector(31 downto 0);
    -- Buprxabtcnt register.
    reg_rxabtcnt    : out std_logic_vector( 5 downto 0);
    -- Pointer to the IAC control structure
    reg_csiac_ptr   : out std_logic_vector(31 downto 0);

    --------------------------------------------
    -- Timers Control
    --------------------------------------------
    -- BuP Timer
    write_buptimer      : out std_logic; -- update buptimer with register value.
    write_buptimer_done : in  std_logic; -- update done.

    -- Beacon Backoff Timer.
    write_bcon_bkoff        : out std_logic; -- reinit beacon backoff timer.
    -- ACP Backoff Timers.
    write_acp_bkoff         : out std_logic_vector( 7 downto 0); -- reinit.
    -- IAC IFS Timer.
    write_iac_bkoff         : out std_logic; -- reinit.

    -- Channel Assessment timers.
    reset_chassbsy      : out std_logic; -- Reset channel busy timer
    reset_chasstim      : out std_logic; -- Reset channel timer
    
    --------------------------------------------
    -- Misc. control
    --------------------------------------------
    phy_ccarst_conf : in  std_logic; -- Reset reg_ccarst.
    reset_bufempty  : in  std_logic; -- A new packet is stored in RX buffer.
    -- Pulse to reset bcon_txenable.
    reset_bcon_txen : in  std_logic;
    -- Pulse to reset acp_txenable.
    reset_acp_txen  : in  std_logic_vector(7 downto 0);
    -- Pulse to reset iac_txenable.
    reset_iac_txen  : in  std_logic;
    reset_vcs       : in  std_logic

  );

end bup2_registers;
