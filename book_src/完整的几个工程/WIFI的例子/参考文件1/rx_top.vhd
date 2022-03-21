
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WiLD
--    ,' GoodLuck ,'      RCSfile: rx_top.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.19   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : RX top.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/RX_TOP/rx_top/vhdl/rtl/rx_top.vhd,v  
--  Log: rx_top.vhd,v  
-- Revision 1.19  2005/03/09 12:06:35  Dr.C
-- #BugId:1123#
-- Updated mdma2_rx_sm and rx_mac_if.
--
-- Revision 1.18  2004/12/20 09:04:57  Dr.C
-- #BugId:810#
-- Updated port dedicated to validation registers.
--
-- Revision 1.17  2004/12/14 17:42:52  Dr.C
-- #BugId:772,810#
-- Updated debug port and length limit port for channel decoder.
--
-- Revision 1.16  2004/06/18 09:47:17  Dr.C
-- Updated mdma2_rx_sm port map and removed some unused port.
--
-- Revision 1.15  2003/12/12 10:02:41  Dr.C
-- Added mdma_sm_rst_n for state machine.
--
-- Revision 1.14  2003/10/16 07:21:32  Dr.C
-- Debugged diag port connection.
--
-- Revision 1.13  2003/10/15 16:57:31  Dr.C
-- Added diag port.
--
-- Revision 1.12  2003/10/10 15:24:51  Dr.C
-- Added gclk gated clock input.
--
-- Revision 1.11  2003/09/22 09:44:45  Dr.C
-- Removed calgain_i and cal_valid_i unused.
--
-- Revision 1.10  2003/09/17 06:55:00  Dr.F
-- added enable_iq_estim.
--
-- Revision 1.9  2003/09/10 07:22:19  Dr.F
-- phy_reset_n port removed.
-- removed phy_reset_n port.
--
-- Revision 1.8  2003/07/29 10:32:38  Dr.C
-- Added cp2_detected output
--
-- Revision 1.7  2003/07/27 07:39:15  Dr.F
-- added cca_busy_i and listen_start_o.
--
-- Revision 1.6  2003/07/22 15:52:59  Dr.C
-- Removed sampling_clk.
--
-- Revision 1.5  2003/06/30 09:46:07  arisse
-- Added input register detect_thr_carrier.
-- Removed inputs registers : calmstart, calmstop, calfrq1,
-- callen1,acllen2, calmav_re, calmav_im, calpow_re, calpow_im.
--
-- Revision 1.4  2003/05/26 09:26:39  Dr.F
-- added rx_packet_end_o.
--
-- Revision 1.3  2003/04/30 09:17:45  Dr.A
-- IQ comp moved to top of modem.
--
-- Revision 1.2  2003/04/07 15:59:27  Dr.F
-- removed calgener_i.
--
-- Revision 1.1  2003/03/28 16:22:47  Dr.C
-- Initial revision
--
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;



--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library time_domain_rtl;
library work;
--library freq_domain_rtl;
library work;
--library mdma2_rx_sm_rtl;
library work;
--library rx_mac_if_rtl;
library work;

--library rx_top_rtl;
library work;
--use rx_top_rtl.rx_top_pkg.all;
use work.rx_top_pkg.all;

--------------------------------------------
-- Entity
--------------------------------------------
entity rx_top is

  port (
    ---------------------------------------
    -- Clock & reset
    ---------------------------------------
    clk                : in  std_logic;     -- Clock for state machine
    gclk               : in  std_logic;     -- Gated clock
    reset_n            : in  std_logic;
    mdma_sm_rst_n      : in  std_logic;     -- synchronous reset for state machine

    ---------------------------------------
    -- FFT
    ---------------------------------------
    fft_data_ready_i      : in  std_logic;  -- FFT control signals
    fft_start_of_burst_i  : in  std_logic;
    fft_start_of_symbol_i : in  std_logic;
    fft_data_valid_i      : in  std_logic;
    fft_i_i               : in  FFT_ARRAY_T;
    fft_q_i               : in  FFT_ARRAY_T;
    td_start_of_symbol_o  : out std_logic;  -- Time domain control signals
    td_start_of_burst_o   : out std_logic;
    td_data_valid_o       : out std_logic;
    fd_data_ready_o       : out std_logic;
    td_i_o                : out std_logic_vector(10 downto 0);
    td_q_o                : out std_logic_vector(10 downto 0); 

    ---------------------------------------
    -- Bup interface
    ---------------------------------------
    phy_ccarst_req_i     : in  std_logic;
    tx_dac_on_i          : in  std_logic;  -- TX DAC ON (1). Signal the status
                                           -- of TX to RX state machine.
    rxe_errorstat_o      : out std_logic_vector(1 downto 0);   --RXERROR vector
                                        -- is valid at the falling edge
                                        -- of rx_start_end_ind_o
                                        -- The coding is as follows:
                                        -- 0b00: No Error
                                        -- 0b01: Format Violation
                                        -- 0b10: Carrier lost
                                        -- 0b11: Unsupported rate
    rxv_length_o         : out std_logic_vector(11 downto 0);  -- RXVECTOR length
                                           -- parameter is valid rx_start_end_ind_o
                                           -- goes from 0 to 1.
    rxv_datarate_o       : out std_logic_vector(3 downto 0);
                                        -- RXVECTOR rate parameter
    phy_cca_ind_o        : out std_logic;  -- 0: IDLE
                                           -- 1: BUSY 
    phy_ccarst_conf_o    : out std_logic;
    rxv_service_o        : out std_logic_vector(15 downto 0);
    rxv_service_ind_o    : out std_logic;
    bup_rxdata_o         : out std_logic_vector(7 downto 0);
    phy_data_ind_o       : out std_logic;
    phy_rxstartend_ind_o : out std_logic;  -- rising edge: PHY_RXSTART.ind 
                                           -- falling edge: PHY_RXEND.ind
    ---------------------------------------
    -- Radio controller
    ---------------------------------------
    rxactive_conf_i     : in  std_logic;
    rssi_on_o           : out std_logic;
    rxactive_req_o      : out std_logic;
    adc_powerctrl_o     : out std_logic_vector(1 downto 0);
                                           -- falling edge: PHY_RXEND.ind
    --------------------------------------------
    -- CCA
    --------------------------------------------
    cca_busy_i          : in  std_logic;
    listen_start_o      : out std_logic; -- high when start to listen
    cp2_detected_o      : out std_logic; -- Detected preamble

    ---------------------------------------
    -- IQ compensation
    ---------------------------------------
    i_iqcomp_i          : in std_logic_vector(10 downto 0);
    q_iqcomp_i          : in std_logic_vector(10 downto 0);
    iqcomp_data_valid_i : in std_logic;
    --
    rx_dpath_reset_n_o  : out std_logic;
    rx_packet_end_o     : out std_logic;  -- pulse on end of RX packet

    enable_iq_estim_o   : out std_logic;  -- `1': enable iq estimation block.
    disable_output_iq_estim_o : out std_logic;  -- `1': disable iq estimation outputs.
    
    ---------------------------------------
    -- Registers
    ---------------------------------------
    -- INIT sync
    detect_thr_carrier_i: in std_logic_vector(3 downto 0);-- Thres carrier sense
    initsync_autothr0_i : in  std_logic_vector(5 downto 0);-- Thresholds for
    initsync_autothr1_i : in  std_logic_vector(5 downto 0);-- preamble detection
    -- Samplefifo                                           
    sampfifo_timoffst_i : in  std_logic_vector(2 downto 0);  -- Timing acquisition
                                                             -- headroom
    -- For IQ calibration module -- TBD
    calmode_i           : in  std_logic;  -- Calibration mode
    -- ADC mode
    adcpdmod_i          : in  std_logic;  -- Power down mode enable
    -- Wiener filter
    wf_window_i         : in  std_logic_vector(1 downto 0);  -- Window length
    reducerasures_i     : in  std_logic_vector(1 downto 0);  -- Reduce erasures
    -- Channel decoder
    length_limit_i      : in  std_logic_vector(11 downto 0); -- Max. Rx length
    rx_length_chk_en_i  : in  std_logic;                     -- Rx length check enable
    -- Equalizer
    histoffset_54_i  : in std_logic_vector(1 downto 0);  -- Histogram offset
    histoffset_48_i  : in std_logic_vector(1 downto 0);
    histoffset_36_i  : in std_logic_vector(1 downto 0);
    histoffset_24_i  : in std_logic_vector(1 downto 0);
    histoffset_18_i  : in std_logic_vector(1 downto 0);
    histoffset_12_i  : in std_logic_vector(1 downto 0);
    histoffset_09_i  : in std_logic_vector(1 downto 0);
    histoffset_06_i  : in std_logic_vector(1 downto 0);
    satmaxncarr_54_i : in std_logic_vector(5 downto 0); -- Saturate max N carrier
    satmaxncarr_48_i : in std_logic_vector(5 downto 0);
    satmaxncarr_36_i : in std_logic_vector(5 downto 0);
    satmaxncarr_24_i : in std_logic_vector(5 downto 0);
    satmaxncarr_18_i : in std_logic_vector(5 downto 0);
    satmaxncarr_12_i : in std_logic_vector(5 downto 0);
    satmaxncarr_09_i : in std_logic_vector(5 downto 0);
    satmaxncarr_06_i : in std_logic_vector(5 downto 0);
    -- Frequency correction
    freq_off_est_o   : out std_logic_vector(19 downto 0);
    -- Preprocessing sample number before sync
    ybnb_o           : out std_logic_vector(6 downto 0);
   
    ---------------------------------
    -- Diag. port
    ---------------------------------
    rx_top_diag0     : out std_logic_vector(15 downto 0);
    rx_top_diag1     : out std_logic_vector(15 downto 0);
    rx_top_diag2     : out std_logic_vector(15 downto 0)
    );

end rx_top;
