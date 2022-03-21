--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD_IP_LIB
--    ,' GoodLuck ,'      RCSfile: wildbb_11g_hiss.vhd,v  
--   '-----------'     Author: DR \*
--
--  Revision: 1.19  
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Wildcore top for Modem a/b/g mode. Adapted to Wild RF.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDBB_11G_HISS/wildbb_11g_hiss/vhdl/rtl/wildbb_11g_hiss.vhd,v  
--  Log: wildbb_11g_hiss.vhd,v  
-- Revision 1.19  2005/10/21 13:34:55  Dr.A
-- #BugId:1246#
-- Added generic for absolute timers
--
-- Revision 1.18  2005/10/04 12:29:37  Dr.A
-- #BugId:1288#
-- Removed unused signals and rf_goto_sleep port
--
-- Revision 1.17  2005/04/07 08:40:21  sbizet
-- #BugId:1191#
-- Added port select_clk80
--
-- Revision 1.16  2005/01/19 09:23:20  pbressy
-- #BugId:936#
-- rewiring of wlanrxind to the top, to go to platform
--
-- Revision 1.15  2005/01/13 14:12:11  Dr.A
-- #BugId:903#
-- New diag ports.
--
-- Revision 1.14  2005/01/04 13:44:00  sbizet
-- #BugId:907#
-- Added agc_busy outport
--
-- Revision 1.13  2004/12/15 08:40:13  sbizet
-- #BugId:907#
-- Added txv_immstop BuP output
--
-- Revision 1.12  2004/12/14 17:42:02  sbizet
-- #BugId:907#
-- updated modem and radioctrl port map
--
-- Revision 1.11  2004/11/09 14:15:33  Dr.A
-- #BugId:835#
-- New bup2_kernel ports
--
-- Revision 1.10  2004/10/07 16:36:39  Dr.A
-- #BugId:780#
-- radio_interface_g hard-coded to '2'
--
-- Revision 1.9  2004/08/27 09:17:14  Dr.A
-- Radio controller generic set to accept 44 MHz clock.
--
-- Revision 1.8  2004/07/01 08:29:13  Dr.A
-- Added hiss_reset_n
--
-- Revision 1.7  2004/06/04 14:13:18  Dr.C
-- Updated modem802_11g_wildrf and radioctrl.
--
-- Revision 1.6  2004/05/18 13:32:49  Dr.A
-- Added bup_clk input for BuP-Modem synchro blocks.
-- Use only one phy_cca_ind input for A and B modems.
--
-- Revision 1.5  2004/05/07 09:47:48  pbressy
-- corrected error
--
-- Revision 1.4  2004/05/06 15:48:57  pbressy
-- added clk80 for modem
--
-- Revision 1.3  2004/04/22 15:13:05  pbressy
-- removed some analog ports I had forgotten
--
-- Revision 1.2  2004/04/08 14:49:25  pbressy
-- removed all analog ports
--
-- Revision 1.1  2004/04/06 13:40:31  pbressy
-- initial release
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library wildbb_11g_hiss_rtl;
library work;
--use wildbb_11g_hiss_rtl.wildbb_11g_hiss_pkg.all;
use work.wildbb_11g_hiss_pkg.all;

--library modem802_11g_wildrf_rtl;
library work;

--library stream_processor_rtl;
library work;

--library radioctrl_rtl;
library work;

--library bup2_kernel_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity wildbb_11g_hiss is
  generic (
    num_queues_g      : integer := 4;
    num_abstimer_g    : integer := 8
    );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    reset_n            : in  std_logic; -- Global reset.
    hiss_resetn        : in  std_logic; -- Reset for Radio Controller (synch to hiss_sclk).
    modema_clk         : in  std_logic; -- Clock for Modem 802.11a (80 MHz).
    rx_path_a_clk      : in  std_logic; -- Gated Clock for Modem 802.11a RX Path
    tx_path_a_clk      : in  std_logic; -- Gated Clock for Modem 802.11a TX Path
    fft_gclk           : in  std_logic; -- Gated clock for Modem 802.11a FFT
    modemb_clk         : in  std_logic; -- Clock for Modem 802.11b (44 MHz).
    rx_path_b_clk      : in  std_logic; -- Gated Clock for Modem 802.11b RX Path
    tx_path_b_clk      : in  std_logic; -- Gated Clock for Modem 802.11b TX Path
    bus_gclk           : in  std_logic; -- AHB and APB clock.
    bus_clk            : in  std_logic; -- AHB and APB clock (not gated).
    rcagc_main_clk     : in  std_logic; -- Sampling clock at 60 MHz for radio cntl.
    enable_1mhz        : in  std_logic; -- 1 MHz enable.
    strp_clk           : in  std_logic; -- Stream PRocessor Clock
    mode32k            : in  std_logic; -- bus_clk = 32kHz when high
    select_clk80       : in  std_logic; -- bus_clk running at 80MHz(1) or 44MHz(0)
    --
    rx_path_b_gclk_en  : out std_logic; -- High to enable rx_path_b_clk.
    tx_path_b_gclk_en  : out std_logic; -- High to enable tx_path_b_clk.
    rx_path_a_gclk_en  : out std_logic; -- High to enable rx_path_a_clk.
    tx_path_a_gclk_en  : out std_logic; -- High to enable tx_path_a_clk.
    --
    clkskip            : out std_logic; -- skip one clock cycle in 802.11b Rx path
    --
    calib_test         : out std_logic; -- RF calibration test mode
    
    --------------------------------------
    -- Interrupt lines
    --------------------------------------    
    bup_irq           : out std_logic; -- BuP interrupt
    bup_fiq           : out std_logic; -- BuP interrupt
    stream_proc_irq   : out std_logic; -- 802.11 stream processing interrupt
    radio_ctrl_irq    : out std_logic; -- Radio controller interrupt
   
    --------------------------------------
    -- PSO related signals
    --------------------------------------
    gate_clk_wild_sync       : in  std_logic;  -- Added for PSO - Santhosh  
    rstn_non_srpg_wild_sync  : in  std_logic;  -- Added for PSO - Santhosh  

    --------------------------------------
    -- AHB bus
    --------------------------------------
    hgrant_bup        : in  std_logic; -- BuP AHB Bus granted.
    hgrant_streamproc : in  std_logic; -- 802.11 stream proc. AHB Bus granted.
    hready_streamproc : in  std_logic; -- Ready signal. Active LOW.
    hresp_streamproc  : in  std_logic_vector( 1 downto 0);-- Transfer status.
    hrdata_streamproc : in  std_logic_vector(31 downto 0);-- Read data bus.
    hready_bup        : in  std_logic; -- Ready signal. Active LOW.
    hresp_bup         : in  std_logic_vector( 1 downto 0);-- Transfer status.
    hrdata_bup        : in  std_logic_vector(31 downto 0);-- Read data bus.
    -- from BuP
    hbusreq_bup       : out std_logic; -- AHB Bus request.
    haddr_bup         : out std_logic_vector(31 downto 0);-- Address bus
    hwrite_bup        : out std_logic; -- Transfer direction. 1=>Write;0=>Read.
    htrans_bup        : out std_logic_vector( 1 downto 0);-- Transfer type.
    hsize_bup         : out std_logic_vector( 2 downto 0);-- Transfer size.
    hburst_bup        : out std_logic_vector( 2 downto 0);-- Burst information.
    hwdata_bup        : out std_logic_vector(31 downto 0);-- Write data bus.
    hlock_bup         : out std_logic; -- Lock transfer.
    hprot_bup         : out std_logic_vector( 3 downto 0);-- Protection mode.
    -- from 802.11 stream processing
    hbusreq_streamproc: out std_logic; -- AHB Bus request.
    haddr_streamproc  : out std_logic_vector(31 downto 0);-- Address bus
    hwrite_streamproc : out std_logic; -- Transfer direction. 1=>Write;0=>Read.
    htrans_streamproc : out std_logic_vector( 1 downto 0);-- Transfer type.
    hsize_streamproc  : out std_logic_vector( 2 downto 0);-- Transfer size.
    hburst_streamproc : out std_logic_vector( 2 downto 0);-- Burst information.
    hwdata_streamproc : out std_logic_vector(31 downto 0);-- Write data bus.
    hlock_streamproc  : out std_logic; -- Lock transfer.
    hprot_streamproc  : out std_logic_vector( 3 downto 0);-- Protection mode.
 
    --------------------------------------
    -- APB bus
    --------------------------------------
    paddr             : in  std_logic_vector(15 downto 0); -- APB Address bus.
    psel_modema       : in  std_logic; -- 802.11a modem selection line.
    psel_modemb       : in  std_logic; -- 802.11b modem selection line.
    psel_modemg       : in  std_logic; -- 802.11g modem selection line.
    psel_bup          : in  std_logic; -- BuP Selection line.
    psel_radio        : in  std_logic; -- Radio controller Selection line.
    psel_streamproc   : in  std_logic; -- Stream processing selection line.
    pwrite            : in  std_logic; -- 0 => Read; 1 => Write.
    penable           : in  std_logic; -- APB enable line.
    pwdata            : in  std_logic_vector(31 downto 0);-- APB Write data bus.
    --
    prdata_modema     : out std_logic_vector(31 downto 0);-- Modem a data bus.
    prdata_modemb     : out std_logic_vector(31 downto 0);-- Modem b data bus.
    prdata_modemg     : out std_logic_vector(31 downto 0);-- Modem g data bus.
    prdata_bup        : out std_logic_vector(31 downto 0);-- BuP data bus.
    prdata_radio      : out std_logic_vector(31 downto 0);-- Radio ctrl data bus
    prdata_streamproc : out std_logic_vector(31 downto 0);-- Str. proc. data bus

    -------------------------------------------
    -- Hiss radio interface                        
    -------------------------------------------
    hiss_rxi          : in  std_logic;
    hiss_rxq          : in  std_logic;
    rfh_fastclk       : in  std_logic; -- 240 MHz clock without clktree (directly from pad) 
    hiss_fastclk      : in  std_logic; -- 240 MHz clock
    hiss_en_force     : in  std_logic;
    --
    hiss_txi          : out std_logic;
    hiss_txq          : out std_logic;
    hiss_txen         : out std_logic;
    hiss_rxen         : out std_logic;
    rf_en             : out std_logic;
    hiss_biasen       : out std_logic;        -- enable HiSS drivers and receivers
    hiss_replien      : out std_logic;       -- enable HiSS drivers and receivers
    hiss_clken        : out std_logic;       -- Enable HiSS clock receivers
    hiss_curr         : out std_logic;       -- Select high/low-current mode for HiSS drivers

    -------------------------------------------
    -- Clock control                       
    -------------------------------------------

    clk_div           : out std_logic_vector(2 downto 0);
    clk_switched      : out std_logic;
    --------------------------------------DB !!!-----
    -- Radio control                       
    -------------------------------------------
    hiss_mode_n       : in  std_logic;

    rf_sw             : out std_logic_vector(3 downto 0);
    --------------------------------------------
    -- AES SRAM:
    --------------------------------------------
    aesram_do_i       : in  std_logic_vector(127 downto 0);-- Data read.
    --
    aesram_di_o       : out std_logic_vector(127 downto 0);-- Data to be written
    aesram_a_o        : out std_logic_vector(  3 downto 0);-- Address.
    aesram_rw_no      : out std_logic; -- Write Enable. Inverted logic.
    aesram_cs_no      : out std_logic; -- Chip Enable. Inverted logic.

    --------------------------------------------
    -- RC4 SRAM:
    --------------------------------------------
    rc4ram_do_i       : in  std_logic_vector(7 downto 0);-- Data read.
    --
    rc4ram_di_o       : out std_logic_vector(7 downto 0);-- Data to be written.
    rc4ram_a_o        : out std_logic_vector(8 downto 0);-- Address.
    rc4ram_rw_no      : out std_logic; -- Write Enable. Inverted logic.
    rc4ram_cs_no      : out std_logic; -- Chip Enable. Inverted logic.

    --------------------------------------
    -- Diagnostic port:
    --------------------------------------
    modem_diag0       : out std_logic_vector(15 downto 0); -- Modemb diag.
    modem_diag1       : out std_logic_vector(15 downto 0);
    modem_diag2       : out std_logic_vector(15 downto 0);
    modem_diag3       : out std_logic_vector(15 downto 0);
    modem_diag4       : out std_logic_vector(15 downto 0); -- Modem common diag.
    modem_diag5       : out std_logic_vector(15 downto 0);
    modem_diag6       : out std_logic_vector(15 downto 0); -- Modema diag.
    modem_diag7       : out std_logic_vector(15 downto 0);
    modem_diag8       : out std_logic_vector(15 downto 0);
    modem_diag9       : out std_logic_vector(15 downto 0);
    stream_proc_diag  : out std_logic_vector(31 downto 0);
    radio_ctrl_diag0  : out std_logic_vector(15 downto 0); 
    radio_ctrl_diag1  : out std_logic_vector(15 downto 0); 
    bup_diag0         : out std_logic_vector(15 downto 0);
    bup_diag1         : out std_logic_vector(15 downto 0);
    bup_diag2         : out std_logic_vector(15 downto 0);
    bup_diag3         : out std_logic_vector(15 downto 0);
    agc_cca_diag0     : out std_logic_vector(15 downto 0);

    scan_mode         : in  std_logic;

    --------------------------------------
    -- WLAN Indication
    --------------------------------------
    wlanrxind : out std_logic
    
    );

end wildbb_11g_hiss;
