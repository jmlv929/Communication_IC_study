
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLDBuP2
--    ,' GoodLuck ,'      RCSfile: bup2_kernel.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.47  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : WILD Burst Processor 2 kernel.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBuP2/bup2_kernel/vhdl/rtl/bup2_kernel.vhd,v  
--  Log: bup2_kernel.vhd,v  
-- Revision 1.47  2006/03/13 08:45:31  Dr.A
-- #BugId:2328#
-- Increased size of reg_clk32cntl to support 131.072 kHz config
--
-- Revision 1.46  2006/02/03 08:37:35  Dr.A
-- #BugId:1140#
-- Debug of IAC IFS
--
-- Revision 1.45  2006/02/02 15:37:51  Dr.A
-- #BugId:1204#
-- Use two clocks for BuP timers block (gated and not)
--
-- Revision 1.44  2006/02/02 08:28:55  Dr.A
-- #BugId:1213#
-- Added bit to ignore VCS for channel assessment
--
-- Revision 1.43  2005/10/21 13:29:02  Dr.A
-- #BugId:1246#
-- Added absolute count timers
--
-- Revision 1.42  2005/10/04 12:12:24  Dr.A
-- #BugId:1288#
-- Removed unused signals
--
-- Revision 1.41  2005/04/19 08:52:29  Dr.A
-- #BugId:938#
-- Updated diags
--
-- Revision 1.40  2005/04/19 07:59:08  Dr.A
-- #BugId:1181#
-- Connected ports for ackto enable
--
-- Revision 1.39  2005/03/29 08:45:08  Dr.A
-- #BugId:907#
-- Added TX force disable
--
-- Revision 1.38  2005/03/25 11:12:40  Dr.A
-- #BugId:1152#
-- Removed ARTIM counter
--
-- Revision 1.37  2005/03/22 10:16:34  Dr.A
-- #BugId:1152#
-- Connected arrival time counter enable. Cleaned write_bckoff ports.
--
-- Revision 1.36  2005/03/18 14:58:32  Dr.A
-- #BugId:938#
-- Changed some SW diags
--
-- Revision 1.35  2005/02/18 16:21:51  Dr.A
-- #BugId:1070#
-- Connected txstartdel_flag. Added iac_txenable to the diags.
--
-- Revision 1.34  2005/02/09 17:50:02  Dr.A
-- #BugId:974#
-- reset_bufempty now coming from memory sequencer.
--
-- Revision 1.33  2005/01/21 15:51:27  Dr.A
-- #BugId:964,978#
-- Connected registers and immediate stop control to BuP timers.
--
-- Revision 1.32  2005/01/13 14:03:16  Dr.A
-- #BugId:903#
-- New diag ports.
--
-- Revision 1.31  2005/01/10 13:15:20  Dr.A
-- #BugId:912#
-- Removed enable_bup
--
-- Revision 1.30  2004/12/20 17:02:14  Dr.A
-- #BugId:850#
-- Added IAC after SIFS mechanism.
--
-- Revision 1.29  2004/12/20 12:55:12  Dr.A
-- #BugId:702,822#
-- Connecte ACK time-out interrupt lines (702).
-- Connected txend_stat status line (822)
--
-- Revision 1.28  2004/12/17 13:04:08  Dr.A
-- #BugId:606,912#
-- New signal from RX FSM used as 'rx end' for timers (606)
-- Enable bit removed from registers (912)
--
-- Revision 1.27  2004/12/10 10:37:55  Dr.A
-- #BugId:606#
-- Connected RX abort and ack time-out registers
--
-- Revision 1.26  2004/12/06 09:14:15  Dr.A
-- #BugId:836#
-- Adress1 mask register connected to state machine
--
-- Revision 1.25  2004/12/03 14:18:12  Dr.A
-- #BugId:837#
-- Added channel assessment timers to bup2_timers port map and connected misc. registers to default values.
--
-- Revision 1.24  2004/12/02 10:29:32  Dr.A
-- #BugId:822#
-- Connect tx_immstop to state machines and output port.
--
-- Revision 1.23  2004/11/10 10:35:30  Dr.A
-- #BugId:837#
-- New registers for channel assessment and multi SSID
--
-- Revision 1.22  2004/11/09 14:13:48  Dr.A
-- #BugId:835#
-- New rxv_ and txv_ ports connected to state machines
--
-- Revision 1.21  2004/11/03 17:18:53  Dr.A
-- #BugId:820#
-- enable_1mhz input now synchronous to BuP clocks
--
-- Revision 1.20  2004/08/26 17:07:37  Dr.A
-- Removed mode32k in resync block.
--
-- Revision 1.19  2004/08/06 16:17:57  Dr.A
-- Do not used resync. mode32k
--
-- Revision 1.18  2004/08/05 16:15:05  Dr.A
-- Added mode32k resync. Moved resync to a separate block.
--
-- Revision 1.17  2004/07/21 16:34:53  Dr.A
-- Use ungated clock buptimer_clk for interrupt generator (Bugzilla # 677)
--
-- Revision 1.16  2004/07/20 07:52:05  Dr.A
-- enable_1mhz synchronized with buptimer_clk.
--
-- Revision 1.15  2004/05/18 10:50:28  Dr.A
-- Only one input port for phy_cca_ind, and resync removed.
--
-- Revision 1.14  2004/04/14 16:11:29  Dr.A
-- Removed unused signal last_word_size.
--
-- Revision 1.13  2004/02/26 18:13:23  Dr.F
-- resynchonized enable_1mhz.
--
-- Revision 1.12  2004/02/06 14:47:58  Dr.F
-- added buptestdin.
--
-- Revision 1.11  2004/02/06 13:55:28  pbressy
-- 8 acp queues
--
-- Revision 1.10  2004/02/05 18:29:27  Dr.F
-- removed modeselect.
--
-- Revision 1.9  2004/01/26 08:51:45  Dr.F
-- added ready_load.
--
-- Revision 1.8  2004/01/09 08:16:48  Dr.F
-- added gpo.
--
-- Revision 1.7  2004/01/06 15:10:51  pbressy
-- bugzilla 331 fix
--
-- Revision 1.6  2003/12/09 16:03:46  Dr.F
-- fixed acctype.
--
-- Revision 1.5  2003/12/05 09:11:34  Dr.F
-- changed paddr size and resynchronized some signals.
--
-- Revision 1.4  2003/12/05 08:36:13  pbressy
-- added connectivity for new bup register
--
-- Revision 1.3  2003/11/25 14:20:05  Dr.F
-- added prdata1.
--
-- Revision 1.2  2003/11/25 07:57:19  Dr.F
-- port map changed.
--
-- Revision 1.1  2003/11/19 16:33:01  Dr.F
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library bup2_kernel_rtl;
library work;
--use bup2_kernel_rtl.bup2_kernel_pkg.all;
use work.bup2_kernel_pkg.all;

--library mem2_seq_rtl;
library work;
--library bup2_registers_rtl;
library work;
--library bup2_intgen_rtl;
library work;
--library crc32_rtl;
library work;
--library bup2_sm_rtl;
library work;
--library master_interface_rtl;
library work;
--library bup2_timers_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity bup2_kernel is
  generic (
    num_queues_g      : integer := 8;
    num_abstimer_g    : integer := 8
    );
  port (    
    --------------------------------------------
    -- Clock and reset.
    --------------------------------------------
    reset_n          : in std_logic; -- Global reset.
    hclk             : in std_logic; -- AHB clock.
    buptimer_clk     : in std_logic; -- buptimer clock (not gated)
    enable_1mhz      : in std_logic; -- 1 MHz enable
    mode32k          : in std_logic; -- buptimer_clk = 32kHz when high
    
    --------------------------------------------
    -- AHB master 
    --------------------------------------------
    hgrant           : in  std_logic;                      -- Bus grant.
    hready           : in  std_logic;                      -- Ready (Active LOW)
    hrdata           : in  std_logic_vector(31 downto 0);  -- AHB read data.
    hresp            : in  std_logic_vector( 1 downto 0);  -- Transfer status.
    --
    hbusreq          : out std_logic;                      -- Bus request.
    hlock            : out std_logic;                      -- Bus lock.
    hwrite           : out std_logic;                      -- Write transaction.
    htrans           : out std_logic_vector( 1 downto 0);  -- Transfer type.
    hsize            : out std_logic_vector( 2 downto 0);  -- Transfer size.
    hburst           : out std_logic_vector( 2 downto 0);  -- Burst type.
    hprot            : out std_logic_vector( 3 downto 0);  -- Protection.
    haddr            : out std_logic_vector(31 downto 0);  -- AHB address.
    hwdata           : out std_logic_vector(31 downto 0);  -- AHB write data.
    -- access type for endianness converter
    acctype          : out std_logic_vector(1 downto 0);   -- access type
    --------------------------------------------
    -- APB slave
    --------------------------------------------  
    -- From master 0  
    psel0            : in  std_logic;                      -- Device select.
    penable0         : in  std_logic;                      -- Enable.
    paddr0           : in  std_logic_vector( 7 downto 0);  -- Address.
    pwrite0          : in  std_logic;                      -- Write signal.
    pwdata0          : in  std_logic_vector(31 downto 0);  -- Write data.
    --
    prdata0          : out std_logic_vector(31 downto 0);  -- Read data.
    -- From master 1
    psel1            : in  std_logic;                      -- Device select.
    penable1         : in  std_logic;                      -- Enable.
    paddr1           : in  std_logic_vector( 7 downto 0);  -- Address.
    pwrite1          : in  std_logic;                      -- Write signal.
    pwdata1          : in  std_logic_vector(31 downto 0);  -- Write data.
    --
    prdata1          : out std_logic_vector(31 downto 0);  -- Read data.

    --------------------------------------------
    -- Modem
    --------------------------------------------    
    -- Data
    bup_rxdata          : in  std_logic_vector(7 downto 0);
    -- Modem Status signals
    phy_txstartend_conf : in  std_logic; -- transmission started, ready for
                                         -- data, or transmission ended.
    phy_rxstartend_ind  : in  std_logic; -- preamble detected
                                         -- or end of rx packet
    phy_data_conf       : in  std_logic; -- last byte read, ready for new one.
    phy_data_ind        : in  std_logic; -- received byte ready.
    
    rxv_datarate        : in  std_logic_vector( 3 downto 0); -- RX PSDU rate.
    rxv_length          : in  std_logic_vector(11 downto 0); -- RX PSDU length.
    rxv_errorstat       : in  std_logic_vector( 1 downto 0); -- packet status.
    phy_cca_ind         : in  std_logic; -- CCA status from modems.
    
    rxv_rssi            : in  std_logic_vector( 6 downto 0); -- preamble RSSI.
    -- bits (15:8) of the CCA data field received from the radio.
    rxv_ccaaddinfo     	: in  std_logic_vector( 7 downto 0);
    rxv_rxant           : in  std_logic; -- Antenna used during reception.
    rxv_service         : in  std_logic_vector(15 downto 0); -- RX SERVICE field.
    rxv_service_ind     : in  std_logic; -- Service field is ready for Modem A.
    phy_ccarst_conf     : in  std_logic; -- confirmation of CCA sm reset.    
    -- Modem Control signals
    phy_txstartend_req  : out std_logic; -- req. to start a packet transmission
    phy_ccarst_req      : out std_logic; -- request to reset CCA state machine
                                         -- or request for end of transmission.
    phy_data_req        : out std_logic; -- request to send a byte.
    -- Indication that MAC Address 1 of received packet matches
    rxv_macaddr_match   : out std_logic;
    --------------------------------------------
    -- BuP
    --------------------------------------------    
    txv_datarate     : out std_logic_vector( 3 downto 0); -- TX PSDU rate.
    txv_length       : out std_logic_vector(11 downto 0); -- TX PSDU length.
    txpwr_level      : out std_logic_vector( 3 downto 0); -- TX power level.
    txv_service      : out std_logic_vector(15 downto 0); -- TX SERVICE 802.11a
    -- Index into the PABIAS table to select PA bias programming value
    txv_paindex      : out std_logic_vector( 4 downto 0);
    txv_txant        : out std_logic; -- Antenna to be used for transmission
    -- Additional transmission control
    txv_txaddcntl    : out std_logic_vector( 1 downto 0);
    -- TX immediate stop status
    txv_immstop      : out std_logic;
    bup_txdata       : out std_logic_vector( 7 downto 0);
    
    --------------------------------------------
    -- Interrupt lines
    --------------------------------------------    
    bup_irq          : out std_logic; -- BuP normal interrupt line.
    bup_fiq          : out std_logic; -- BuP fast interrupt line.
    
    --------------------------------------------
    -- GPO (General Purpose Output)
    -- connected to the testdata registers
    --------------------------------------------
    gpo              : out std_logic_vector(31 downto 0);

    --------------------------------------------
    -- General Purpose Input
    --------------------------------------------
    buptestdin       : in  std_logic_vector(31 downto 0);
    
    --------------------------------------------
    -- Diag signals
    --------------------------------------------
    bup_diag0        : out std_logic_vector(15 downto 0);
    bup_diag1        : out std_logic_vector(15 downto 0);
    bup_diag2        : out std_logic_vector(15 downto 0);
    bup_diag3        : out std_logic_vector(15 downto 0)
    
    
  );

end bup2_kernel;
