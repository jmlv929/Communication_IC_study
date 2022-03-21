
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: modem802_11g_wildrf.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.91   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : 802.11g modem top for WILD RF.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/WILDRF_FRONTEND/modem802_11g_wildrf/vhdl/rtl/modem802_11g_wildrf.vhd,v  
--  Log: modem802_11g_wildrf.vhd,v  
-- Revision 1.91  2005/10/04 12:32:58  Dr.A
-- #BugId:1288#
-- removed unused signals
--
-- Revision 1.90  2005/04/26 09:23:48  Dr.C
-- #BugId:1226#
-- Added select_rx_ab selection for Analog or HiSS interface.
--
-- Revision 1.89  2005/04/25 13:25:14  Dr.C
-- #BugId:1226#
-- Added mux before phy_cca_ind output to switch Analog or HiSS interface.
--
-- Revision 1.88  2005/03/23 08:28:01  Dr.J
-- #BugId:720#
-- Added Energy Detect control signals
--
-- Revision 1.87  2005/03/11 08:52:20  arisse
-- #BugId:1124#
-- Add one clock cycle to start correlation.
--
-- Revision 1.86  2005/03/01 16:15:27  arisse
-- #BugId:983#
-- Added globals.
--
-- Revision 1.85  2005/02/28 17:21:39  Dr.J
-- #BugId:727#
-- Used the select_rx_ab instead of ab_mode in ofdm_preamble_detector
--
-- Revision 1.84  2005/02/02 14:41:32  arisse
-- #BugId:977#
-- Signal rx_gating was not used correctly.
--
-- Revision 1.83  2005/01/26 17:18:50  Dr.J
-- #BugId:977#
-- Used the rx_gating from the modem11b to gate the rx b clock
--
-- Revision 1.82  2005/01/24 16:21:38  arisse
-- #BugId:684,795,983#
-- Added interp_max_stage.
-- Added generic for front-end registers.
-- Added resynchronization on init_rx_b and connected
-- it to agc_procend and correl_rst.
--
-- Revision 1.81  2005/01/19 12:57:05  Dr.J
-- #BugId:727#
-- Added ofdm_preamble_detection block
--
-- Revision 1.80  2005/01/14 15:21:44  Dr.C
-- #BugId:916#
-- Updated .11g FE.
--
-- Revision 1.79  2005/01/11 10:08:13  Dr.J
-- #BugId:952#
-- Added selection of the modem in rx done by the agc
--
-- Revision 1.78  2005/01/06 14:00:55  Dr.C
-- #BugId:916,942#
-- Updated .11g FE instance.
--
-- Revision 1.77  2005/01/04 17:00:34  Dr.J
-- #BugId:837#
-- Debugged the phy_cca_ind assigment
--
-- Revision 1.76  2005/01/04 16:44:16  Dr.J
-- #BugId:837#
-- Removed the resynchro of phy_cca_ind because the AGC and the BuP are on the same clock domain
--
-- Revision 1.75  2005/01/04 16:41:28  Dr.J
-- #BugId:837#
-- Resynchronize the phy_cca_ind with the BuP clock
--
-- Revision 1.74  2005/01/04 13:45:53  sbizet
-- #BugId:907#
-- Added agc_busy outport
--
-- Revision 1.73  2004/12/21 13:36:07  Dr.J
-- #BugId:921#
-- Connected the wlanrxind signal from the AGC/CCA BB.
-- Added input of the AGC/CCA BB the rxe_errstat from the modems.
--
-- Revision 1.72  2004/12/15 11:46:55  Dr.C
-- #BugId:902#
-- Updated 11g frontend port map.
--
-- Revision 1.71  2004/12/15 10:03:42  arisse
-- #BugId:883,819#
-- Updated Modem B Front-End entities.
--
-- Revision 1.70  2004/12/14 16:47:44  Dr.J
-- #BugId:727,907,606#
-- Updated ports map
--
-- Revision 1.69  2004/11/08 17:13:35  arisse
-- #BugId:828#
-- Updated modem802_11g_front_end
--
-- Revision 1.68  2004/09/24 13:06:08  arisse
-- Modified Interference Filter.
--
-- Revision 1.67  2004/08/24 13:41:47  arisse
-- Added globals for testbench.
--
-- Revision 1.66  2004/07/16 08:28:21  arisse
-- Added globals.
--
-- Revision 1.65  2004/07/05 15:30:03  arisse
-- Added the Translate On and Off to the global signals.
--
-- Revision 1.64  2004/07/02 11:49:30  arisse
-- Added globals.
--
-- Revision 1.63  2004/07/01 11:44:21  Dr.C
-- Changed tx_rx_filter_reset_n to tx_reset_n.
--
-- Revision 1.62  2004/06/16 15:16:14  Dr.C
-- Updated 11g frontend.
--
-- Revision 1.61  2004/06/16 14:06:47  Dr.C
-- Updated rx_b_front_end_wildrf port map.
--
-- Revision 1.60  2004/06/16 08:17:14  Dr.C
-- Force interp_max_stage.
--
-- Revision 1.59  2004/06/15 15:28:13  Dr.C
-- Updated modemg frontend.
--
-- Revision 1.58  2004/06/04 13:59:02  Dr.C
-- Updated 11g frontend and modemg core.
--
-- Revision 1.57  2004/05/18 12:36:11  Dr.A
-- Modem G port map update: added bup_clk for synchronization blocks, and use only one cca_ind input for A and B.
--
-- Revision 1.56  2004/04/19 15:25:25  Dr.C
-- Change structure for modem802_11g_frontend.
--
-- Revision 1.55  2004/03/24 16:36:27  Dr.C
-- Added input select_clk80 for BB AGC block
--
-- Revision 1.54  2004/03/11 11:10:09  arisse
-- Removed tx_path_a_gclk, modema_clk, tx_path_b_gclk and modemb_clk
-- from modem_diag9.
--
-- Revision 1.53  2004/02/10 14:52:45  Dr.C
-- Updated modemg core and added generate for agc_cca_analog_fake.
--
-- Revision 1.52  2004/02/06 09:38:49  Dr.C
-- Move last change to modem802_11a2_core.
--
-- Revision 1.51  2004/01/20 13:57:37  Dr.C
-- Force a_txonoff_req to '0' if the reception is not finished.
--
-- Revision 1.50  2003/12/20 17:13:00  sbizet
-- State machine modem A now reseted by agc_fake at the end of reception
--
-- Revision 1.49  2003/12/12 11:50:05  sbizet
-- integration_end agc_analog_fake's pin added
--
-- Revision 1.48  2003/12/12 11:01:50  Dr.C
-- Updated AGC and changed gating condition for modemb.
--
-- Revision 1.47  2003/12/12 09:12:53  sbizet
-- agc_fake port map updated
--
-- Revision 1.46  2003/12/08 08:56:18  sbizet
-- Added agc_sync_rst in analog mode and rx_startend_ind input for agc_fake
--
-- Revision 1.45  2003/12/04 15:09:07  sbizet
-- Added agc_ab_mode when analog mode for radio controller
--
-- Revision 1.44  2003/12/04 07:36:08  Dr.J
-- Added connection for HiSS mode
-- .,
--
-- Revision 1.43  2003/12/03 15:27:55  Dr.F
-- debugged cca_busy connections.
--
-- Revision 1.42  2003/12/02 12:18:26  Dr.J
-- Added library agc_cca_ananlog_fake_rtl
--
-- Revision 1.41  2003/12/02 11:42:12  arisse
-- Added txiconst, txc2disb and rxc2disb.
--
-- Revision 1.40  2003/12/02 10:15:44  Dr.J
-- Added agc_cca_analog_fake
--
-- Revision 1.39  2003/11/26 10:38:19  Dr.C
-- Connected cca_busy of the modem802_11a2_frontend to agc_sync_rst_n and
-- cca_busy_a of the modem802_11g_core to ed_stat.
--
-- Revision 1.38  2003/11/21 18:34:00  Dr.F
-- fixed modemb_rx_gating and modema_rx_gating.
--
-- Revision 1.37  2003/11/21 16:12:42  Dr.J
-- Added agc_rx_onoff_req
--
-- Revision 1.36  2003/11/21 14:17:49  Dr.C
-- Updated AGC port map and put rssi_s to 0
--
-- Revision 1.35  2003/11/20 16:31:39  Dr.J
-- Added agc_hissbb
--
-- Revision 1.34  2003/11/20 07:28:21  Dr.J
-- Removed resync_init
--
-- Revision 1.33  2003/11/14 15:59:52  Dr.C
-- Updated core and front_end.
--
-- Revision 1.32  2003/11/06 09:08:49  Dr.C
-- Updated generic.
--
-- Revision 1.31  2003/11/03 16:07:50  Dr.C
-- Added a_txbbonoff_req_o.
--
-- Revision 1.30  2003/11/03 15:59:23  Dr.B
-- pa_on, radio_interface, c2disb changes.
--
-- Revision 1.29  2003/10/31 15:54:30  arisse
-- Added hiss controller signals.
--
-- Revision 1.28  2003/10/29 14:46:53  Dr.C
-- Added port on rx 11b front end for AGC
--
-- Revision 1.27  2003/10/24 09:29:33  Dr.C
-- Added generic radio_interface_g.
--
-- Revision 1.26  2003/10/23 17:39:37  Dr.C
-- Updated core and frontend.
--
-- Revision 1.25  2003/10/21 15:08:48  arisse
-- Added filters_reset_n.
--
-- Revision 1.24  2003/10/16 15:10:03  Dr.C
-- Updated diag ports.
--
-- Revision 1.23  2003/10/15 18:18:14  Dr.C
-- Updated diag port.
--
-- Revision 1.22  2003/10/13 10:11:34  Dr.C
-- Added gating condition.
--
-- Revision 1.21  2003/10/09 08:06:32  Dr.B
-- Added interfildisb adn scaling ports.
--
-- Revision 1.20  2003/09/30 15:40:40  arisse
-- Added clk_2skip_i in input.
--
-- Revision 1.19  2003/09/24 13:26:51  Dr.J
-- Added sync_found
--
-- Revision 1.18  2003/09/23 16:45:58  Dr.C
-- Removed debug.
--
-- Revision 1.17  2003/09/23 15:56:35  Dr.C
-- Connected a_rssi to rssi_i for debug purpose.
--
-- Revision 1.16  2003/09/23 13:57:00  Dr.C
-- Replaced cca_busy connection by rssi_i(0).
--
-- Revision 1.15  2003/09/23 07:54:19  Dr.C
-- Added prdata for each modem.
--
-- Revision 1.14  2003/09/18 14:10:08  Dr.J
-- Added filter clk
--
-- Revision 1.13  2003/09/09 14:01:22  Dr.C
-- Updated with modem802_11g_core modifs.
--
-- Revision 1.12  2003/08/29 16:40:47  Dr.B
-- rx_iq_comp goes to 60 MHz area.
--
-- Revision 1.11  2003/08/07 17:26:40  Dr.C
-- Connected cp2_detected.
--
-- Revision 1.10  2003/08/07 09:10:45  Dr.C
-- Updated ports names.
--
-- Revision 1.9  2003/07/30 17:27:43  Dr.F
-- fixed conflicts on power estimation.
--
-- Revision 1.8  2003/07/30 16:44:59  Dr.C
-- Added correl_reset_n output from agc
--
-- Revision 1.7  2003/07/30 10:28:27  Dr.C
-- Debugged connection between core and rx_b_front_end_wildrf.
--
-- Revision 1.6  2003/07/30 06:09:09  Dr.F
-- agc port map changed.
--
-- Revision 1.5  2003/07/28 15:37:52  Dr.C
-- Removed modeselect_rx.
--
-- Revision 1.4  2003/07/28 07:34:56  Dr.B
-- remove modemb_clk in modemb.
--
-- Revision 1.3  2003/07/27 17:27:17  Dr.F
-- added agc_cca_11g_wildrf.
--
-- Revision 1.2  2003/07/22 16:26:28  Dr.C
-- Updated core and port map.
--
-- Revision 1.1  2003/07/22 13:55:10  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all; 

--library modem802_11g_wildrf_rtl;
library work;
--use modem802_11g_wildrf_rtl.modem802_11g_wildrf_pkg.all;
use work.modem802_11g_wildrf_pkg.all;

--library modem802_11g_frontend_rtl;
library work;
--library hiss_buffer_rtl;
library work;

--library modem802_11a2_frontend_rtl;
library work;
--library rx_b_front_end_wildrf_rtl;
library work;
--library tx_b_frontend_wildrf_rtl;
library work;

--library agc_cca_hissbb_rtl;
library work;
--library agc_cca_analog_fake_rtl;
library work;

--library modem802_11g_rtl;
library work;
--library ofdm_preamble_detector_rtl;
library work;


--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity modem802_11g_wildrf is
  generic (
    radio_interface_g : integer := 1   -- 0 -> reserved
    );                                 -- 1 -> only Analog interface
                                       -- 2 -> only HISS interface
  port (                               -- 3 -> both interfaces (HISS and Analog)
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    modema_clk      : in  std_logic; -- Modem 802.11a main clock
    rx_path_a_gclk  : in  std_logic; -- Modem 802.11a gated clock for RX path
    tx_path_a_gclk  : in  std_logic; -- Modem 802.11a gated clock for TX path
    fft_gclk        : in  std_logic; -- Modem 802.11a FFT gated clock
    modemb_clk      : in  std_logic; -- Modem 802.11b main clock
    rx_path_b_gclk  : in  std_logic; -- Modem 802.11b gated clock for RX path
    tx_path_b_gclk  : in  std_logic; -- Modem 802.11b gated clock for TX path
    bus_clk         : in  std_logic; -- APB clock
    bup_clk         : in  std_logic; -- BuP clock
    sampling_clk    : in  std_logic; -- sampling clock
    filta_clk       : in  std_logic; -- sampling clock 11a filters
    filtb_clk       : in  std_logic; -- sampling clock 11b filters
    rcagc_main_clk  : in  std_logic; -- AGC clock at 80 MHz.
    reset_n         : in  std_logic; -- global reset
    select_clk80    : in  std_logic; -- Indicates clock frequency: '1' = 80 MHz
                                     --                            '0' = 44 MHz
    --
    rstn_non_srpg_wild_sync  : in  std_logic;  -- Added for PSO - Santhosh
    -- 
    modema_rx_gating : out std_logic; -- Gating condition for Rx path .11a
    modema_tx_gating : out std_logic; -- Gating condition for Tx path .11a
    modemb_rx_gating : out std_logic; -- Gating condition for Rx path .11b
    modemb_tx_gating : out std_logic; -- Gating condition for Tx path .11b
    --
    clkskip         : out std_logic; -- skip one clock cycle in Rx path
    --
    calib_test      : out std_logic;
  
    --------------------------------------
    -- APB slave
    --------------------------------------
    psel_modema     : in  std_logic; -- Select. modem a registers
    psel_modemb     : in  std_logic; -- Select. modem b registers
    psel_modemg     : in  std_logic; -- Select. modem g registers
    penable         : in  std_logic; -- Defines the enable cycle.
    paddr           : in  std_logic_vector( 5 downto 0); -- Address.
    pwrite          : in  std_logic; -- Write signal.
    pwdata          : in  std_logic_vector(31 downto 0); -- Write data.
    --
    prdata_modema   : out std_logic_vector(31 downto 0); -- Read modem a data.
    prdata_modemb   : out std_logic_vector(31 downto 0); -- Read modem b data.
    prdata_modemg   : out std_logic_vector(31 downto 0); -- Read modem g data.
    
    --------------------------------------------
    -- Interface with Wild Bup
    --------------------------------------------
    -- inputs signals                                                           
    bup_txdata          : in  std_logic_vector(7 downto 0); -- data to send         
    phy_txstartend_req  : in  std_logic; -- request to start a packet transmission    
    phy_data_req        : in  std_logic; -- request to send a byte                  
    phy_ccarst_req      : in  std_logic; -- request to reset CCA state machine                 
    txv_length          : in  std_logic_vector(11 downto 0);  -- RX PSDU length     
    txv_service         : in  std_logic_vector(15 downto 0);  -- tx service field   
    txv_datarate        : in  std_logic_vector( 3 downto 0); -- PSDU transm. rate
    txpwr_level         : in  std_logic_vector( 2 downto 0); -- TX power level.
    rxv_macaddr_match   : in  std_logic;                     -- Stop the reception because the mac 
                                                             -- addresss does not match  
    txv_immstop         : in  std_logic; -- request to stop the transmission               
    
    -- outputs signals                                                          
    phy_txstartend_conf : out std_logic; -- transmission started, ready for data  
    phy_rxstartend_ind  : out std_logic; -- indication of RX packet                     
    phy_ccarst_conf     : out std_logic; 
    phy_data_conf       : out std_logic; -- last byte was read, ready for new one 
    phy_data_ind        : out std_logic; -- received byte ready                  
    rxv_length          : out std_logic_vector(11 downto 0); -- RX PSDU length  
    rxv_service         : out std_logic_vector(15 downto 0); -- rx service field
    rxv_service_ind     : out std_logic;
    rxv_datarate        : out std_logic_vector( 3 downto 0); -- PSDU rec. rate
    rxe_errorstat       : out std_logic_vector( 1 downto 0); -- packet recep. stat
    phy_cca_ind         : out std_logic; -- CCA status from Modems
    bup_rxdata          : out std_logic_vector(7 downto 0); -- data received      
    rxv_rssi            : out std_logic_vector (6 downto 0);  -- Value of measured RSSI
    rxv_rxant           : out std_logic;                      -- Antenna used
    rxv_ccaaddinfo      : out std_logic_vector (15 downto 8); -- Additionnal data

    --------------------------------------
    -- HISS mode
    --------------------------------------
    hiss_mode_n         : in  std_logic;
    
    --------------------------------------
    -- Radio controller interface
    --------------------------------------
    -- 802.11a side
    a_txonoff_conf      : in  std_logic;
    a_txonoff_req       : out std_logic;
    a_txbbonoff_req_o   : out std_logic;
    a_txdatavalid       : out std_logic; -- toggle when new data (only on HiSS)
    a_dac_enable        : out std_logic;
    --
    a_rxonoff_conf      : in  std_logic;
    a_rxonoff_req       : out std_logic;
    a_rxdatavalid       : in  std_logic; -- toggle when new data (only on HiSS)
    -- 802.11b side
    b_txonoff_conf      : in  std_logic;
    b_txonoff_req       : out std_logic;
    b_txbbonoff_req     : out std_logic;
    b_txdatavalid       : out std_logic; -- toggle when new data (only on HiSS)
    b_dac_enable        : out std_logic;
    --
    b_rxonoff_conf      : in  std_logic;
    b_rxonoff_req       : out std_logic;
    b_rxdatavalid       : in  std_logic;  -- toggle when new data (only on HiSS)
    --
    clk_2skip_i         : in  std_logic;
    b_antswitch         : out std_logic;
    -- ADC/DAC
    rxi                 : in  std_logic_vector(10 downto 0);
    rxq                 : in  std_logic_vector(10 downto 0);
    txi                 : out std_logic_vector(9 downto 0);
    txq                 : out std_logic_vector(9 downto 0);
    -- misc
    pa_on               : in  std_logic; -- high when PA is on.
    gain_o              : out std_logic_vector(7 downto 0);
    sync_found          : out std_logic; -- Synchronization found active high

    --
    agc_cca_flags        : in std_logic_vector (5 downto 0);
                                       -- indicates cca procedure stat
    agc_cca_add_flags    : in std_logic_vector (15 downto 0);
                                       -- CCA additional data
    agc_cca_flags_marker : in  std_logic;  -- pulse to indicate cca_flags are val
    agc_cca_cs           : in  std_logic_vector (1 downto 0);
                                       -- carrier sense informati
    agc_cca_cs_valid     : in  std_logic;  -- pulse to indicate cca_cs are valid
    sw_rfoff_req         : in  std_logic; -- pulse resquest by SW to switch idle the WiLDRF  
    
    agc_rx_onoff_conf    : in std_logic; -- Acknowledges start/end of Rx  
    agc_ana_enable       : in std_logic; -- Enable the fake analog AGC
    rf_cca               : in std_logic; 

    agc_stream_enable    : out std_logic;  -- Enable hiss 'pipe' on reception
    agc_ab_mode          : out std_logic;  -- Mode of received packet
    agc_rx_onoff_req     : out std_logic; -- Indicates start/end of Rx  

    agc_rfoff            : out std_logic; -- Indicates that the WiLD RF can be switch off
    agc_rfint            : out std_logic; -- Interrupt from WiLDRF

    agc_busy             : out std_logic;   -- Indicates when receiving a packet(Including RF config)
    --------------------------------------
    -- WLAN Indication
    --------------------------------------
    wlanrxind            : out std_logic; -- Indicates a wlan reception
    
    --------------------------------------
    -- Diag. port
    --------------------------------------
    modem_diag0         : out std_logic_vector(15 downto 0); -- Modem b diag.
    modem_diag1         : out std_logic_vector(15 downto 0);
    modem_diag2         : out std_logic_vector(15 downto 0);
    modem_diag3         : out std_logic_vector(15 downto 0);
    --
    modem_diag4         : out std_logic_vector(15 downto 0); -- Common diag
    modem_diag5         : out std_logic_vector(15 downto 0);
    --
    modem_diag6         : out std_logic_vector(15 downto 0); -- Modem a diag.
    modem_diag7         : out std_logic_vector(15 downto 0);
    modem_diag8         : out std_logic_vector(15 downto 0);
    modem_diag9         : out std_logic_vector(15 downto 0);
    agc_cca_diag0       : out std_logic_vector(15 downto 0)
    );

end modem802_11g_wildrf;
