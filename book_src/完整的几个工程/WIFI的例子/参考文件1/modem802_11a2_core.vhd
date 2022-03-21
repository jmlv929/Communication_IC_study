
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: modem802_11a2_core.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.56   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : 802.11a modem core.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/modem802_11a2/vhdl/rtl/modem802_11a2_core.vhd,v  
--  Log: modem802_11a2_core.vhd,v  
-- Revision 1.56  2005/02/21 12:43:57  Dr.C
-- #BugId:1081#
-- Changed name of resync FFS accordind to coding rules.
--
-- Revision 1.55  2005/01/19 17:24:51  Dr.C
-- #BugId:737#
-- Added residual_dc_offset.
--
-- Revision 1.54  2004/12/20 08:59:24  Dr.C
-- #BugId:810,910#
-- Updated registers, tx_top and rx_top port map.
--
-- Revision 1.53  2004/12/14 17:25:45  Dr.C
-- #BugId:595,855,810,794#
-- Updated port map of rx_top, tx_top and registers.
--
-- Revision 1.52  2004/06/18 12:49:22  Dr.C
-- Updated rx_top and iq_estimation.
--
-- Revision 1.51  2004/05/06 17:01:54  Dr.C
-- Updated fft_sync_reset_n value.
--
-- Revision 1.50  2004/05/06 13:35:13  Dr.C
-- Added fft_sync_reset_n controlled by Tx and Rx path.
--
-- Revision 1.49  2004/02/10 14:42:15  Dr.C
-- Re-synchromized gating conditions.
--
-- Revision 1.48  2004/02/06 09:37:02  Dr.C
-- Force a_txonoff_req if reception not finished.
--
-- Revision 1.47  2003/12/19 15:37:20  Dr.C
-- Connect rxv_rssi to 0.
--
-- Revision 1.46  2003/12/12 10:05:36  Dr.C
-- Added mdma_sm_rst_n.
--
-- Revision 1.45  2003/12/04 09:43:11  sbizet
-- Added intermediate assignement on fft inputs to avoid simulation delta delays
--
-- Revision 1.44  2003/12/03 14:43:39  Dr.C
-- Added dc_off_disb.
--
-- Revision 1.43  2003/12/02 18:55:17  Dr.C
-- Debugged.
--
-- Revision 1.42  2003/12/02 18:53:53  Dr.C
-- Removed synchronization for tx_active.
--
-- Revision 1.41  2003/12/02 15:17:44  Dr.C
-- Added resynchronisation for Tx data to frontend.
--
-- Revision 1.40  2003/12/02 15:01:10  Dr.C
-- Resync data from filter.
--
-- Revision 1.39  2003/12/02 13:44:19  Dr.C
-- Changed connection between iq_estimation and iq_compensation.
--
-- Revision 1.38  2003/11/25 18:31:47  Dr.C
-- Updated iq_estimation and registers.
--
-- Revision 1.37  2003/11/14 15:49:48  Dr.C
-- Updated tx_top and registers.
--
-- Revision 1.36  2003/11/03 15:55:18  Dr.C
-- Added a_txbbonoff_req_o.
--
-- Revision 1.35  2003/11/03 10:39:01  rrich
-- Added iq_mm_est input to iq_estimation block.
--
-- Revision 1.34  2003/11/03 09:18:35  Dr.C
-- Added 2's complement port.
--
-- Revision 1.33  2003/10/24 07:33:18  Dr.C
-- Removed resynchro from frontend.
--
-- Revision 1.32  2003/10/23 17:16:03  Dr.C
-- Added iq_compensation.
--
-- Revision 1.31  2003/10/23 12:57:07  Dr.C
-- Debugged.
--
-- Revision 1.30  2003/10/23 12:52:28  Dr.C
-- Updated iq_estimation port map.
--
-- Revision 1.29  2003/10/15 17:32:24  Dr.C
-- Added diag port.
--
-- Revision 1.28  2003/10/13 14:57:13  Dr.C
-- Updated tx_top_a2.
--
-- Revision 1.27  2003/10/13 12:16:33  Dr.C
-- Changed tx_gating.
--
-- Revision 1.26  2003/10/10 16:37:36  Dr.C
-- Added rx & tx gating.
--
-- Revision 1.25  2003/10/10 15:45:52  Dr.C
-- Updated gated clock.
--
-- Revision 1.24  2003/09/22 10:07:51  Dr.C
-- Updated rx_top and registers port map.
--
-- Revision 1.23  2003/09/17 06:58:40  Dr.F
-- changed enable of iq estim.
--
-- Revision 1.22  2003/09/10 07:21:51  Dr.F
-- removed phy_reset_n in rx_top.
--
-- Revision 1.21  2003/08/29 16:32:43  Dr.B
-- remove rx_iq_comp.
--
-- Revision 1.20  2003/07/29 10:37:41  Dr.C
-- Added cp2_detected output
--
-- Revision 1.19  2003/07/27 07:43:13  Dr.F
-- added cca_busy_i and listen_start_o.
--
-- Revision 1.18  2003/07/22 15:51:28  Dr.C
-- Updated rx_top.
--
-- Revision 1.17  2003/07/21 13:44:21  Dr.C
-- Removed 60Mhz clocked blocks.
--
-- Revision 1.16  2003/07/01 16:05:50  Dr.C
-- Changed ports for radio controller.
--
-- Revision 1.15  2003/06/30 10:27:42  arisse
-- Removed calmstart, calmstop, callen1, callen2, calmav_re,
-- calmav_im, calpow_re, calpow_im.
-- Added detect_thr_carrier.
--
-- Revision 1.14  2003/06/11 09:34:14  Dr.C
-- Removed last version.
--
-- Revision 1.13  2003/06/05 07:06:53  Dr.C
-- Updated tx_rx_filter.
--
-- Revision 1.12  2003/05/26 09:38:19  Dr.F
-- added rx_packet_end.
--
-- Revision 1.11  2003/05/23 16:20:17  Dr.J
-- Changed the FFT size
--
-- Revision 1.10  2003/05/23 16:09:43  Dr.J
-- Debugged
--
-- Revision 1.9  2003/05/23 16:08:39  Dr.J
-- Debugged
--
-- Revision 1.8  2003/05/23 15:33:56  Dr.J
-- changed the datat size of the fft
--
-- Revision 1.7  2003/05/23 14:35:22  Dr.J
-- Changed the fft datasize
--
-- Revision 1.6  2003/05/15 09:47:14  Dr.J
-- Now mapper_data_i_ext is mapper_data_i*4
--
-- Revision 1.5  2003/04/30 09:25:27  Dr.A
-- RX IQ compensation added.
--
-- Revision 1.4  2003/04/29 09:01:49  Dr.A
-- rx_ampl and rx_phase set to 0.
--
-- Revision 1.3  2003/04/28 10:10:09  arisse
-- Changed port map of modema2 registers.
-- Compliant with spec 0.13 of modema2.
--
-- Revision 1.2  2003/04/24 12:03:58  Dr.A
-- New iq_compensation block.
--
-- Revision 1.1  2003/04/23 08:48:21  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all; 
 
--library modem802_11a2_rtl;
library work;
--use modem802_11a2_rtl.modem802_11a2_pkg.all;
use work.modem802_11a2_pkg.all;

--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library rx_top_rtl;
library work;
--library tx_top_a2_rtl;
library work;
--library fft_shell_rtl;
library work;
--library modema2_registers_rtl;
library work;
--library iq_estimation_rtl;
library work;
--library iq_compensation_rtl;
library work;
--library residual_dc_offset_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity modem802_11a2_core is
  generic (
    -- Use of Front-end register : 1 or 3 for use, 2 for don't use
    -- If the HiSS interface is used, the front-end is a part of the radio and
    -- so during the synthesis these registers could be removed.
    radio_interface_g   : integer := 1 -- 0 -> reserved
    );                                 -- 1 -> only Analog interface
                                       -- 2 -> only HISS interface
  port (                               -- 3 -> both interfaces (HISS and Analog)
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk            : in  std_logic; -- State machine clock
    rx_path_a_gclk : in  std_logic; -- Rx path gated clock
    tx_path_a_gclk : in  std_logic; -- Tx path gated clock
    fft_gclk       : in  std_logic; -- FFT gated clock
    pclk           : in  std_logic; -- APB clock
    reset_n        : in  std_logic; -- Reset
    mdma_sm_rst_n  : in  std_logic; -- synchronous reset for state machine
    --
    rx_gating      : out std_logic; -- Gating condition for Rx path
    tx_gating      : out std_logic; -- Gating condition for Tx path
    --
    calib_test     : out std_logic; -- Do not gate clocks when high.

    --------------------------------------
    -- WILD bup interface
    --------------------------------------
    phy_txstartend_req_i  : in  std_logic;
    txv_immstop_i         : in  std_logic;
    txv_length_i          : in  std_logic_vector(11 downto 0);
    txv_datarate_i        : in  std_logic_vector(3 downto 0);
    txv_service_i         : in  std_logic_vector(15 downto 0);
    txpwr_level_i         : in  std_logic_vector(2 downto 0);
    phy_data_req_i        : in  std_logic;
    bup_txdata_i          : in  std_logic_vector(7 downto 0);
    phy_txstartend_conf_o : out std_logic;
    phy_data_conf_o       : out std_logic;

    --                                                      
    phy_ccarst_req_i     : in  std_logic;
    phy_rxstartend_ind_o : out std_logic;
    rxv_length_o         : out std_logic_vector(11 downto 0);
    rxv_datarate_o       : out std_logic_vector(3 downto 0);
    rxv_rssi_o           : out std_logic_vector(7 downto 0);
    rxv_service_o        : out std_logic_vector(15 downto 0);
    rxv_service_ind_o    : out std_logic;
    rxe_errorstat_o      : out std_logic_vector(1 downto 0);
    phy_ccarst_conf_o    : out std_logic; 
    phy_cca_ind_o        : out std_logic;
    phy_data_ind_o       : out std_logic;
    bup_rxdata_o         : out std_logic_vector(7 downto 0);
    --                                            
    --------------------------------------
    -- APB interface
    --------------------------------------
    penable_i         : in  std_logic;
    paddr_i           : in  std_logic_vector(5 downto 0);
    pwrite_i          : in  std_logic;
    psel_i            : in  std_logic;
    pwdata_i          : in  std_logic_vector(31 downto 0);
    prdata_o          : out std_logic_vector(31 downto 0);

    --------------------------------------
    -- Radio controller interface
    --------------------------------------
    a_txonoff_conf_i    : in  std_logic;
    a_rxactive_conf_i   : in  std_logic;
    a_txonoff_req_o     : out std_logic;
    a_txbbonoff_req_o   : out std_logic;
    a_txpga_o           : out std_logic_vector(2 downto 0);
    a_rxactive_req_o    : out std_logic;
    dac_on_o            : out std_logic;
    --
    adc_powerctrl_o     : out std_logic_vector(1 downto 0);
    --
    rssi_on_o           : out std_logic;

    --------------------------------------------
    -- CCA
    --------------------------------------------
    cca_busy_i          : in  std_logic;
    listen_start_o      : out std_logic; -- high when start to listen

    --------------------------------------------
    -- DC offset
    --------------------------------------------    
    cp2_detected_o      : out std_logic; -- Detected preamble

    --------------------------------------
    -- Tx & Rx filter
    --------------------------------------
    -- Rx
    filter_valid_rx_i   : in  std_logic;
    rx_filtered_data_i  : in  std_logic_vector(10 downto 0);
    rx_filtered_data_q  : in  std_logic_vector(10 downto 0);
    -- Tx
    tx_active_o             : out std_logic;
    filter_start_of_burst_o : out std_logic;
    filter_valid_tx_o       : out std_logic;
    tx_data2filter_i        : out std_logic_vector( 9 downto 0);
    tx_data2filter_q        : out std_logic_vector( 9 downto 0);
    -- Register
    tx_filter_bypass_o      : out std_logic;
    tx_norm_o               : out std_logic_vector( 7 downto 0);
    
    --------------------------------------
    -- Registers
    --------------------------------------
    -- calibration_mux
    calmode_o               : out std_logic;
    -- IQ calibration signal generator
    calfrq0_o               : out std_logic_vector(22 downto 0);
    calgain_o               : out std_logic_vector( 2 downto 0);
    -- Modules control signals for transmitter
    tx_iq_phase_o           : out std_logic_vector( 5 downto 0);
    tx_iq_ampl_o            : out std_logic_vector( 8 downto 0);
    -- dc offset
    rx_del_dc_cor_o         : out std_logic_vector(7 downto 0);
    dc_off_disb_o           : out std_logic;    
    -- 2's complement
    c2disb_tx_o             : out std_logic;
    c2disb_rx_o             : out std_logic;
    -- Constant generator
    tx_const_o              : out std_logic_vector(7 downto 0);
    
    ---------------------------------
    -- Diag. port
    ---------------------------------
    modem_diag0     : out std_logic_vector(15 downto 0); -- Rx
    modem_diag1     : out std_logic_vector(15 downto 0);
    modem_diag2     : out std_logic_vector(15 downto 0);
    modem_diag3     : out std_logic_vector(8 downto 0)   -- Tx
    );

end modem802_11a2_core;
