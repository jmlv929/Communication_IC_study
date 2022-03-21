
--------------------------------------------------------------------------------
-- End of file
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       ------------      Project : WILD
--    ,' GoodLuck ,'      RCSfile: tx_top_a2.vhd,v   
--   '-----------'     Author: DR \*
--
--  Revision: 1.21   
--  Date: 1999.12.31
--  State: Exp  
--  Locker:   
--------------------------------------------------------------------------------
--
-- Description : Top of the Modem 802.11a2 transmitter.
--
--------------------------------------------------------------------------------
--
--  Source: ./git/COMMON/IPs/WILD/MODEM802_11a2/TX_TOP/tx_top_a2/vhdl/rtl/tx_top_a2.vhd,v  
--  Log: tx_top_a2.vhd,v  
-- Revision 1.21  2004/12/20 09:08:10  Dr.C
-- #BugId:630#
-- Updated port names of scrambler according to spec 1.02.
--
-- Revision 1.20  2004/12/14 13:51:12  Dr.C
-- #BugId:630,595#
-- Added txv_immstop input port. Updated fft_serial and scrambler port map.
--
-- Revision 1.19  2004/05/18 12:33:33  Dr.A
-- modema_tx_sm port map update.
--
-- Revision 1.18  2003/12/02 15:32:33  Dr.C
-- Delayed a_txbbonoff_req_o by 1 cycle.
--
-- Revision 1.17  2003/11/14 15:42:34  Dr.C
-- Changed dac_on2off in tx_enddel.
--
-- Revision 1.16  2003/11/03 16:48:48  Dr.C
-- Removed unused signal.
--
-- Revision 1.15  2003/11/03 16:44:20  Dr.C
-- Debugged sync_reset_n_o connection.
--
-- Revision 1.14  2003/11/03 15:51:58  Dr.C
-- Added a_txbbonoff_req_o.
--
-- Revision 1.13  2003/10/15 09:03:09  Dr.C
-- Added diag port.
--
-- Revision 1.12  2003/10/13 14:55:30  Dr.C
-- Added gclk gated clock.
--
-- Revision 1.11  2003/04/14 07:58:51  Dr.A
-- Removed tx_filter_a1. Moved blocks using sampling_clk outside of the tx_top.
--
-- Revision 1.10  2003/04/07 13:47:40  Dr.A
-- Removed calgener port.
--
-- Revision 1.9  2003/04/07 13:25:40  Dr.A
-- New calibration_gen and calibration_mux.
--
-- Revision 1.8  2003/04/02 08:03:10  Dr.A
-- Added generics and sync_reset_n to FFT shell.
--
-- Revision 1.7  2003/04/01 13:00:59  Dr.A
-- Corrected tx_filter_a1 sync_reset connection.
--
-- Revision 1.6  2003/03/31 15:16:01  Dr.A
-- Inverted reset for internal_filter_g.
--
-- Revision 1.5  2003/03/28 16:06:23  Dr.A
-- Changed output size.
--
-- Revision 1.4  2003/03/28 14:16:49  Dr.A
-- Moved fft_serial into tx_top_a2.
--
-- Revision 1.3  2003/03/28 07:48:40  Dr.A
-- Added clk_60MHz.
--
-- Revision 1.2  2003/03/27 17:35:12  Dr.A
-- Modifications for tx_filter interface.
--
-- Revision 1.1  2003/03/26 14:49:18  Dr.A
-- Initial revision
--
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
 
--library modem802_11a2_pkg;
library work;
--use modem802_11a2_pkg.modem802_11a2_pack.all;
use work.modem802_11a2_pack.all;

--library tx_top_a2_rtl;
library work;
--use tx_top_a2_rtl.tx_top_a2_pkg.all;
use work.tx_top_a2_pkg.all;

--library encoder_rtl;
library work;

--library scrambler_a2_rtl;
library work;

--library modema_tx_sm_rtl;
library work;

--library interleaver_rtl;
library work;

--library mac_interface_rtl;
library work;

--library mapper_rtl;
library work;

--library tx_mux_rtl;
library work;

--library pilot_scr_rtl;
library work;

--library preamble_gen_rtl;
library work;

--library puncturer_rtl;
library work;

--library padding_rtl;
library work;

--library fft_serial_rtl;
library work;

--------------------------------------------------------------------------------
-- Entity
--------------------------------------------------------------------------------
entity tx_top_a2 is
  generic (
    fsize_in_g        : integer := 10 -- I & Q size for filter input.
  );
  port (
    --------------------------------------
    -- Clocks & Reset
    --------------------------------------
    clk                      : in  std_logic; -- Clock at 80 MHz for state machine.
    gclk                     : in  std_logic; -- Gated clock at 80 MHz.
    reset_n                  : in  std_logic; -- asynchronous reset
    --------------------------------------
    -- BuP interface
    --------------------------------------
    phy_txstartend_req_i     : in  std_logic;
    phy_txstartend_conf_o    : out std_logic;
    txv_immstop_i            : in  std_logic;
    phy_data_req_i           : in  std_logic;
    phy_data_conf_o          : out std_logic;
    bup_txdata_i             : in  std_logic_vector( 7 downto 0);
    -- Frame parameters: rate, length, service field, TX power level.
    txv_rate_i               : in  std_logic_vector( 3 downto 0);
    txv_length_i             : in  std_logic_vector(11 downto 0);
    txv_service_i            : in  std_logic_vector(15 downto 0);
    txv_txpwr_level_i        : in  std_logic_vector( 2 downto 0);
    --------------------------------------
    -- RF control FSM interface
    --------------------------------------
    dac_powerdown_dyn_i      : in  std_logic;
    a_txonoff_req_o          : out std_logic;
    a_txbbonoff_req_o        : out std_logic;
    a_txonoff_conf_i         : in  std_logic;
    a_txpga_o                : out std_logic_vector( 2 downto 0);
    dac_on_o                 : out std_logic;
    -- to rx
    tx_active_o              : out std_logic;
    sync_reset_n_o           : out std_logic; -- FFT synchronous reset.
    --------------------------------------
    -- IFFT interface
    --------------------------------------
    -- Controls to FFT
    tx_start_signal_o        : out std_logic; -- 'start of signal' marker.
    tx_end_burst_o           : out std_logic; -- 'end of burst' marker.
    mapper_data_valid_o      : out std_logic; -- High when mapper data is valid.
    fft_serial_data_ready_o  : out std_logic;
    -- Data to FFT
    mapper_data_i_o          : out std_logic_vector(7 downto 0);
    mapper_data_q_o          : out std_logic_vector(7 downto 0);
    -- Controls from FFT
    ifft_tx_start_of_signal_i: in  std_logic;   -- 'start of signal' marker.
    ifft_tx_end_burst_i      : in  std_logic;   -- 'end of burst' marker.
    ifft_data_ready_i        : in  std_logic;
    -- Data from FFT
    ifft_data_i_i            : in  FFT_ARRAY_T; -- Data from FFT.
    ifft_data_q_i            : in  FFT_ARRAY_T; -- Data from FFT.
    --------------------------------------
    -- TX filter interface
    --------------------------------------
    data2filter_i_o          : out std_logic_vector(fsize_in_g-1 downto 0);
    data2filter_q_o          : out std_logic_vector(fsize_in_g-1 downto 0);
    filter_start_of_burst_o  : out std_logic;
    filter_sampleready_o     : out std_logic;
    --------------------------------------
    -- Parameters from registers
    --------------------------------------
    add_short_pre_i          : in  std_logic_vector( 1 downto 0); -- prepreamble value.
    tx_enddel_i              : in  std_logic_vector( 7 downto 0); -- front delay.
    -- Test signals
    prbs_sel_i               : in  std_logic_vector( 1 downto 0);
    prbs_inv_i               : in  std_logic;
    prbs_init_i              : in  std_logic_vector(22 downto 0);
    -- Scrambler
    scrmode_i                : in  std_logic;  -- '1' to reinit the scrambler btw two bursts.
    scrinitval_i             : in  std_logic_vector(6 downto 0); -- Seed init value.
    tx_scrambler_o           : out std_logic_vector(6 downto 0); -- scrambler init value
    --------------------------------------
    -- Diag port
    --------------------------------------
    tx_top_diag              : out std_logic_vector(8 downto 0)
  );

end tx_top_a2;
